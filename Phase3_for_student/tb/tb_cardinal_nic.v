/////////////////////////////////////////////////////////////////////////////
// Filename    : tb_cardinal_nic.v
// Description : Basic testbench for the Cardinal NIC (Phase 3)
//
// A starting point for your own NIC testbench (handout item 3). It drives
// the processor side and the router side of one cardinal_nic and checks a
// few basic operations:
//   1. reset values: net_so = 0, net_ri = 1, both status registers 0
//   2. a processor store to the output channel buffer (addr 10), the
//      output status (addr 11), and the send to the router: net_so must
//      be 1, with the packet on net_do, at exactly one rising edge, an
//      edge where net_ro = 1 and net_polarity = ~vc (the phase in which
//      the mesh router transfers that VC). net_so may be a registered or
//      a combinational output; the router (and this testbench) only looks
//      at it at the rising edge
//   3. a packet from the router (net_si) into the input channel buffer:
//      net_ri drops, the input status (addr 01) reads 1, a load from
//      addr 00 returns the packet and empties the buffer
// It does not test blocking (net_ro = 0 for a while), a store to a full
// output buffer, a second packet while the first waits, sending and
// receiving in the same cycle, or both VC polarities. Add those cases.
//
// The polarity is generated as the mesh router does it: 0 during reset,
// toggling at every rising edge afterwards. Processor inputs change at
// falling edges so that they are stable at the rising edge.
//
// The TA testbench instantiates cardinal_nic by the port names below.
/////////////////////////////////////////////////////////////////////////////
`timescale 1ns/10ps

`define CYCLE_TIME 4

module tb_cardinal_nic;

reg         clk, reset;
reg  [0:1]  addr;
reg  [0:63] d_in;
wire [0:63] d_out;
reg         nicEn, nicWrEn;
reg         net_si, net_ro, net_polarity;
reg  [0:63] net_di;
wire        net_ri, net_so;
wire [0:63] net_do;

reg  [0:63] packet;
integer     errors, sends, k;

cardinal_nic NIC (
	.clk(clk), .reset(reset),
	.addr(addr), .d_in(d_in), .d_out(d_out), .nicEn(nicEn), .nicWrEn(nicWrEn),
	.net_si(net_si), .net_ri(net_ri), .net_di(net_di),
	.net_so(net_so), .net_ro(net_ro), .net_do(net_do), .net_polarity(net_polarity)
	);

always #(`CYCLE_TIME / 2.0) clk = ~clk;

// Polarity of the connected router
always @(posedge clk)
	if (reset) net_polarity <= 1'b0;
	else       net_polarity <= ~net_polarity;

// Count the edges at which net_so is 1 (sampled like a router does) and
// check the packet on net_do at those edges
always @(posedge clk) begin
	if (!reset && net_so === 1'b1) begin
		sends = sends + 1;
		$display("%0t: net_so = 1 at this edge, net_do = %h, net_polarity = %0d",
			$time, net_do, net_polarity);
		if (net_do !== packet) begin
			$display("  ERROR: net_do should be %h", packet);
			errors = errors + 1;
		end
	end
end

task check;
	input [8*64-1:0] what;
	input [0:63]     got, want;
	begin
		if (got !== want) begin
			$display("%0t: ERROR: %0s is %h, expected %h", $time, what, got, want);
			errors = errors + 1;
		end else
			$display("%0t: ok: %0s = %h", $time, what, got);
	end
endtask

// A processor load: drive the address at a falling edge, the register
// appears on d_out after the next rising edge
task cpu_load;
	input  [0:1]  a;
	output [0:63] value;
	begin
		@(negedge clk);
		nicEn = 1; nicWrEn = 0; addr = a;
		@(posedge clk); #1;
		value = d_out;
		@(negedge clk);
		nicEn = 0;
	end
endtask

task cpu_store;
	input [0:1]  a;
	input [0:63] value;
	begin
		@(negedge clk);
		nicEn = 1; nicWrEn = 1; addr = a; d_in = value;
		@(negedge clk);
		nicEn = 0; nicWrEn = 0;
	end
endtask

reg [0:63] value;

initial begin
	clk = 0; reset = 1; errors = 0; sends = 0;
	addr = 0; d_in = 0; nicEn = 0; nicWrEn = 0; net_si = 0; net_ro = 0; net_di = 0;
	packet = 64'h9001_0000_0000_0001;	// vc 1, to node 1 (x 1, y 0), 1 hop, source 0, payload 0001

	// 1. reset
	repeat (3) @(negedge clk);
	check("net_so during reset", net_so, 0);
	check("net_ri during reset", net_ri, 1);
	reset = 0;
	cpu_load(2'b01, value); check("input status after reset", value, 0);
	cpu_load(2'b11, value); check("output status after reset", value, 0);

	// 2. processor store, then the send to the router
	cpu_store(2'b10, packet);
	cpu_load(2'b11, value); check("output status after the store", value, 1);
	@(negedge clk);
	net_ro = 1;			// the router can accept a packet
	repeat (4) @(negedge clk);	// the eligible polarity comes within 2 cycles
	check("number of edges with net_so = 1", sends, 1);
	cpu_load(2'b11, value); check("output status after the send", value, 0);
	net_ro = 0;

	// 3. a packet from the router, then the processor reads it
	@(negedge clk);
	net_si = 1; net_di = 64'h0000_0002_0000_0200;	// vc 0, to node 0, delivered (hop 0), source 2
	@(negedge clk);
	net_si = 0;
	check("net_ri with a full input buffer", net_ri, 0);
	cpu_load(2'b01, value); check("input status with a packet", value, 1);
	cpu_load(2'b00, value); check("input buffer", value, 64'h0000_0002_0000_0200);
	cpu_load(2'b01, value); check("input status after the read", value, 0);
	check("net_ri after the read", net_ri, 1);

	repeat (2) @(negedge clk);
	if (errors == 0)
		$display("BASIC NIC TEST PASSED");
	else
		$display("BASIC NIC TEST FAILED: %0d error(s)", errors);
	$finish;
end

endmodule
