/////////////////////////////////////////////////////////////////////////////
// Filename    : tb_cmp.v
// Description : Self-checking testbench for the Cardinal 16-node chip
//               multiprocessor (Phase 3)
//
// The testbench
//   1. loads the instruction memory of node N (N = 0..15) from
//      "cmp_test.imem.N.fill" and its data memory from "cmp_test.dmem.N.fill"
//      ($readmemh; words that the files do not set are 0),
//   2. holds reset for 5 cycles, then runs until every node has fetched
//      the end-of-program word 32'h0000_0000 (or until MAX_CYCLES). A node
//      that has fetched it keeps receiving 0 (the instruction memory does
//      not wrap around), so it executes nothing more while the other nodes
//      finish,
//   3. waits 5 more cycles to drain the pipelines, prints the cycle count
//      of every node and dumps data memory locations 0-31 (sample) or 0-255 (custom) of node N to
//      "dumps/cmp_test.dmem.N.dump" (the makefile passes +DUMP=dumps/cmp_test;
//      make clean keeps the dumps/ directory),
//   4. with +EXPECTED=<prefix> (make test), compares each data memory with
//      "<prefix>.N.dump" and prints every location that differs. An x
//      nibble in an expected value is a don't-care (the hop field of a
//      received packet depends on the mesh); a value that is all x is not
//      compared. With +UNORDERED=<lo>:<hi> the locations lo..hi are
//      compared as a set: received packets are stored in arrival order,
//      and that order depends on the design.
//
// The provided cmp_test files are the course CMP test: every processor
// sends one packet to each of three other processors (right neighbour,
// lower neighbour, opposite node) and stores the three packets it receives
// at MEM[5]-MEM[7]. Write your own programs for everything else (handout
// item 7).
//
// Your design is graded on a TA testbench that uses the same cardinal_cmp
// instance, memories, clock, reset sequence and end-of-program rule. It runs
// many program sets back to back with a reset before each one, so reset
// must clear all state of the processors, the NICs and the mesh.
//
// Set the clock period with CYCLE_TIME below (4 ns = 250 MHz).
// File names can be overridden: +PREFIX=<prefix> (default cmp_test) reads
// <prefix>.imem.N.fill / <prefix>.dmem.N.fill, and +DUMP=<path> (default
// <prefix>) writes <path>.dmem.N.dump.
//
// DO NOT change the cardinal_cmp instance. The grading testbench connects
// your design by these exact port names.
/////////////////////////////////////////////////////////////////////////////
`timescale 1ns/10ps

// Define the clock cycle
`define CYCLE_TIME 4
// Upper bound on the program length in clock cycles
`define MAX_CYCLES 20000
// Number of nodes
`define NODES 16

// Memory models (provided, do not modify)
`include "./include/dmem.v"
`include "./include/imem.v"

module tb_cmp;

reg CLK, RESET;

// One entry per node (node N = mesh coordinate (x = N % 4, y = N / 4))
wire [0:31] pc_out   [0:15];
wire [0:31] imem_out [0:15];
wire [0:31] inst_in  [0:15];
wire [0:31] addr_out [0:15];
wire [0:63] d_out    [0:15];
wire [0:63] d_in     [0:15];
wire        memEn    [0:15];
wire        memWrEn  [0:15];

// A node that has fetched the end-of-program word keeps receiving 0.
reg [0:15] done;

integer cycle_number;

//// ******************** Module Instantiations ******************** \\\\

// Multiprocessor under test (top-level module name and port names are fixed)
cardinal_cmp CMP (
	.clk            (CLK),
	.reset          (RESET),
	.node0_inst_in   (inst_in[0]),
	.node0_d_in      (d_in[0]),
	.node0_pc_out    (pc_out[0]),
	.node0_d_out     (d_out[0]),
	.node0_addr_out  (addr_out[0]),
	.node0_memWrEn   (memWrEn[0]),
	.node0_memEn     (memEn[0]),
	.node1_inst_in   (inst_in[1]),
	.node1_d_in      (d_in[1]),
	.node1_pc_out    (pc_out[1]),
	.node1_d_out     (d_out[1]),
	.node1_addr_out  (addr_out[1]),
	.node1_memWrEn   (memWrEn[1]),
	.node1_memEn     (memEn[1]),
	.node2_inst_in   (inst_in[2]),
	.node2_d_in      (d_in[2]),
	.node2_pc_out    (pc_out[2]),
	.node2_d_out     (d_out[2]),
	.node2_addr_out  (addr_out[2]),
	.node2_memWrEn   (memWrEn[2]),
	.node2_memEn     (memEn[2]),
	.node3_inst_in   (inst_in[3]),
	.node3_d_in      (d_in[3]),
	.node3_pc_out    (pc_out[3]),
	.node3_d_out     (d_out[3]),
	.node3_addr_out  (addr_out[3]),
	.node3_memWrEn   (memWrEn[3]),
	.node3_memEn     (memEn[3]),
	.node4_inst_in   (inst_in[4]),
	.node4_d_in      (d_in[4]),
	.node4_pc_out    (pc_out[4]),
	.node4_d_out     (d_out[4]),
	.node4_addr_out  (addr_out[4]),
	.node4_memWrEn   (memWrEn[4]),
	.node4_memEn     (memEn[4]),
	.node5_inst_in   (inst_in[5]),
	.node5_d_in      (d_in[5]),
	.node5_pc_out    (pc_out[5]),
	.node5_d_out     (d_out[5]),
	.node5_addr_out  (addr_out[5]),
	.node5_memWrEn   (memWrEn[5]),
	.node5_memEn     (memEn[5]),
	.node6_inst_in   (inst_in[6]),
	.node6_d_in      (d_in[6]),
	.node6_pc_out    (pc_out[6]),
	.node6_d_out     (d_out[6]),
	.node6_addr_out  (addr_out[6]),
	.node6_memWrEn   (memWrEn[6]),
	.node6_memEn     (memEn[6]),
	.node7_inst_in   (inst_in[7]),
	.node7_d_in      (d_in[7]),
	.node7_pc_out    (pc_out[7]),
	.node7_d_out     (d_out[7]),
	.node7_addr_out  (addr_out[7]),
	.node7_memWrEn   (memWrEn[7]),
	.node7_memEn     (memEn[7]),
	.node8_inst_in   (inst_in[8]),
	.node8_d_in      (d_in[8]),
	.node8_pc_out    (pc_out[8]),
	.node8_d_out     (d_out[8]),
	.node8_addr_out  (addr_out[8]),
	.node8_memWrEn   (memWrEn[8]),
	.node8_memEn     (memEn[8]),
	.node9_inst_in   (inst_in[9]),
	.node9_d_in      (d_in[9]),
	.node9_pc_out    (pc_out[9]),
	.node9_d_out     (d_out[9]),
	.node9_addr_out  (addr_out[9]),
	.node9_memWrEn   (memWrEn[9]),
	.node9_memEn     (memEn[9]),
	.node10_inst_in  (inst_in[10]),
	.node10_d_in     (d_in[10]),
	.node10_pc_out   (pc_out[10]),
	.node10_d_out    (d_out[10]),
	.node10_addr_out (addr_out[10]),
	.node10_memWrEn  (memWrEn[10]),
	.node10_memEn    (memEn[10]),
	.node11_inst_in  (inst_in[11]),
	.node11_d_in     (d_in[11]),
	.node11_pc_out   (pc_out[11]),
	.node11_d_out    (d_out[11]),
	.node11_addr_out (addr_out[11]),
	.node11_memWrEn  (memWrEn[11]),
	.node11_memEn    (memEn[11]),
	.node12_inst_in  (inst_in[12]),
	.node12_d_in     (d_in[12]),
	.node12_pc_out   (pc_out[12]),
	.node12_d_out    (d_out[12]),
	.node12_addr_out (addr_out[12]),
	.node12_memWrEn  (memWrEn[12]),
	.node12_memEn    (memEn[12]),
	.node13_inst_in  (inst_in[13]),
	.node13_d_in     (d_in[13]),
	.node13_pc_out   (pc_out[13]),
	.node13_d_out    (d_out[13]),
	.node13_addr_out (addr_out[13]),
	.node13_memWrEn  (memWrEn[13]),
	.node13_memEn    (memEn[13]),
	.node14_inst_in  (inst_in[14]),
	.node14_d_in     (d_in[14]),
	.node14_pc_out   (pc_out[14]),
	.node14_d_out    (d_out[14]),
	.node14_addr_out (addr_out[14]),
	.node14_memWrEn  (memWrEn[14]),
	.node14_memEn    (memEn[14]),
	.node15_inst_in  (inst_in[15]),
	.node15_d_in     (d_in[15]),
	.node15_pc_out   (pc_out[15]),
	.node15_d_out    (d_out[15]),
	.node15_addr_out (addr_out[15]),
	.node15_memWrEn  (memWrEn[15]),
	.node15_memEn    (memEn[15])
	);

// Instruction memories (256 x 32, asynchronous read, word address = PC / 4)
// and data memories (256 x 64, synchronous), one pair per node
genvar g;
generate
	for (g = 0; g < `NODES; g = g + 1) begin : mem
		imem IM (.memAddr(pc_out[g][22:29]), .dataOut(imem_out[g]));
		dmem DM (.clk(CLK), .memEn(memEn[g]), .memWrEn(memWrEn[g]),
			.memAddr(addr_out[g][24:31]), .dataIn(d_out[g]), .dataOut(d_in[g]));
		assign inst_in[g] = done[g] ? 32'd0 : imem_out[g];
	end
endgenerate

//// ******************** Clock ******************** \\\\

always #(`CYCLE_TIME / 2.0) CLK = ~CLK;

//// ******************** Cycle Counter ******************** \\\\

always @(posedge CLK)
begin
	if (RESET)
		cycle_number <= 0;
	else
		cycle_number <= cycle_number + 1;
end

reg [8*256:1] prefix, dump_prefix, expected_prefix, file_name, imem_name, dmem_name, range_arg;
reg [8*256:1] line, word1, word2, word3, word4;
reg [0:63]    expected;
reg [0:63]    expected_set [0:255];   // expected values of the unordered range
reg [0:63]    actual_set   [0:255];
integer dump_fd, expected_fd;
integer i, j, k, node, address, checked, node_checked, errors;
integer run_number, runs, total_errors, dump_words;
integer tx_even, rx_even, tx_odd, rx_odd;
integer tx_count [0:15], rx_count [0:15];
integer blocked_edges, full_polls, monitor_node;
reg pending0, poll_response_due;
reg [0:63] offered0;
reg check_counts, require_block, compare_expected, keep_passes;
reg [8*64-1:0] counts_arg;
reg [0:255] seen;
wire [0:15] transfers_out = {CMP.node0_net_so, CMP.node1_net_so, CMP.node2_net_so, CMP.node3_net_so,
    CMP.node4_net_so, CMP.node5_net_so, CMP.node6_net_so, CMP.node7_net_so,
    CMP.node8_net_so, CMP.node9_net_so, CMP.node10_net_so, CMP.node11_net_so,
    CMP.node12_net_so, CMP.node13_net_so, CMP.node14_net_so, CMP.node15_net_so};
wire [0:15] transfers_in = {CMP.node0_net_si, CMP.node1_net_si, CMP.node2_net_si, CMP.node3_net_si,
    CMP.node4_net_si, CMP.node5_net_si, CMP.node6_net_si, CMP.node7_net_si,
    CMP.node8_net_si, CMP.node9_net_si, CMP.node10_net_si, CMP.node11_net_si,
    CMP.node12_net_si, CMP.node13_net_si, CMP.node14_net_si, CMP.node15_net_si};
wire [0:15] nic_en = {CMP.node0_nicEn, CMP.node1_nicEn, CMP.node2_nicEn, CMP.node3_nicEn,
    CMP.node4_nicEn, CMP.node5_nicEn, CMP.node6_nicEn, CMP.node7_nicEn,
    CMP.node8_nicEn, CMP.node9_nicEn, CMP.node10_nicEn, CMP.node11_nicEn,
    CMP.node12_nicEn, CMP.node13_nicEn, CMP.node14_nicEn, CMP.node15_nicEn};
wire [0:15] nic_write = {CMP.node0_nicWrEn, CMP.node1_nicWrEn, CMP.node2_nicWrEn, CMP.node3_nicWrEn,
    CMP.node4_nicWrEn, CMP.node5_nicWrEn, CMP.node6_nicWrEn, CMP.node7_nicWrEn,
    CMP.node8_nicWrEn, CMP.node9_nicWrEn, CMP.node10_nicWrEn, CMP.node11_nicWrEn,
    CMP.node12_nicWrEn, CMP.node13_nicWrEn, CMP.node14_nicWrEn, CMP.node15_nicWrEn};
integer lo, hi, count_expected, count_actual;
integer node_cycles [0:`NODES-1];
reg     finished, unordered;

// Observe accepted transfers independently of end-of-program memory comparisons.
// Node 0 is a sender in both blocking programs. Record actual edges for SimVision.
always @(posedge CLK) begin
    if (RESET) begin
        pending0 = 0; poll_response_due = 0; offered0 = 0;
        blocked_edges = 0;
        full_polls = 0;
        for (monitor_node = 0; monitor_node < 16; monitor_node = monitor_node + 1) begin
            tx_count[monitor_node] = 0;
            rx_count[monitor_node] = 0;
        end
    end else begin
        for (monitor_node = 0; monitor_node < 16; monitor_node = monitor_node + 1) begin
            if ((memEn[monitor_node] && addr_out[monitor_node][16:17] == 3) ||
                (nic_en[monitor_node] && addr_out[monitor_node][16:17] != 3) ||
                (memEn[monitor_node] && nic_en[monitor_node]) ||
                (memWrEn[monitor_node] && !memEn[monitor_node]) ||
                (nic_write[monitor_node] && !nic_en[monitor_node])) begin
                $display("TEST FAILED: bus enables node=%0d addr=%h time_ns=%0d",
                         monitor_node, addr_out[monitor_node], $time);
                $finish;
            end
            if (transfers_out[monitor_node]) tx_count[monitor_node] = tx_count[monitor_node] + 1;
            if (transfers_in[monitor_node]) rx_count[monitor_node] = rx_count[monitor_node] + 1;
        end
        if (pending0 && !CMP.node0_net_ro && CMP.node0_polarity != offered0[0]) begin
            if (blocked_edges == 0)
                $display("EDGE run=%0d node=0 blocked eligible packet time_ns=%0d", run_number, $time);
            blocked_edges = blocked_edges + 1;
        end
        if (poll_response_due && CMP.node0_dout_nic === 64'd1) full_polls = full_polls + 1;
        poll_response_due = CMP.node0_nicEn && !CMP.node0_nicWrEn && CMP.node0_addr_nic == 3;
        if (CMP.node0_nicEn && CMP.node0_nicWrEn && CMP.node0_addr_nic == 2 && !pending0) begin
            pending0 = 1;
            offered0 = CMP.node0_din_nic;
        end
        if (transfers_out[0]) pending0 = 0;
        if (transfers_out[0] && tx_count[0] == 1)
            $display("EDGE run=%0d node=0 first inject time_ns=%0d packet=%h", run_number, $time, CMP.node0_net_do);
        if (transfers_in[0] && rx_count[0] == 1)
            $display("EDGE run=%0d node=0 first receive time_ns=%0d packet=%h", run_number, $time, CMP.node0_net_di);
    end
end

//// ******************** Helpers ******************** \\\\

// Data memory word of one node
function [0:63] dmem_word;
	input integer node, address;
	begin
		case (node)
			 0: dmem_word = mem[0].DM.MEM[address];
			 1: dmem_word = mem[1].DM.MEM[address];
			 2: dmem_word = mem[2].DM.MEM[address];
			 3: dmem_word = mem[3].DM.MEM[address];
			 4: dmem_word = mem[4].DM.MEM[address];
			 5: dmem_word = mem[5].DM.MEM[address];
			 6: dmem_word = mem[6].DM.MEM[address];
			 7: dmem_word = mem[7].DM.MEM[address];
			 8: dmem_word = mem[8].DM.MEM[address];
			 9: dmem_word = mem[9].DM.MEM[address];
			10: dmem_word = mem[10].DM.MEM[address];
			11: dmem_word = mem[11].DM.MEM[address];
			12: dmem_word = mem[12].DM.MEM[address];
			13: dmem_word = mem[13].DM.MEM[address];
			14: dmem_word = mem[14].DM.MEM[address];
			default: dmem_word = mem[15].DM.MEM[address];
		endcase
	end
endfunction

// Instruction and data memory of one node set to 0
task clear_node;
	input integer node;
	integer k;
	begin
		for (k = 0; k < 256; k = k + 1)
			case (node)
				 0: begin mem[0].IM.MEM[k] = 32'd0; mem[0].DM.MEM[k] = 64'd0; end
				 1: begin mem[1].IM.MEM[k] = 32'd0; mem[1].DM.MEM[k] = 64'd0; end
				 2: begin mem[2].IM.MEM[k] = 32'd0; mem[2].DM.MEM[k] = 64'd0; end
				 3: begin mem[3].IM.MEM[k] = 32'd0; mem[3].DM.MEM[k] = 64'd0; end
				 4: begin mem[4].IM.MEM[k] = 32'd0; mem[4].DM.MEM[k] = 64'd0; end
				 5: begin mem[5].IM.MEM[k] = 32'd0; mem[5].DM.MEM[k] = 64'd0; end
				 6: begin mem[6].IM.MEM[k] = 32'd0; mem[6].DM.MEM[k] = 64'd0; end
				 7: begin mem[7].IM.MEM[k] = 32'd0; mem[7].DM.MEM[k] = 64'd0; end
				 8: begin mem[8].IM.MEM[k] = 32'd0; mem[8].DM.MEM[k] = 64'd0; end
				 9: begin mem[9].IM.MEM[k] = 32'd0; mem[9].DM.MEM[k] = 64'd0; end
				10: begin mem[10].IM.MEM[k] = 32'd0; mem[10].DM.MEM[k] = 64'd0; end
				11: begin mem[11].IM.MEM[k] = 32'd0; mem[11].DM.MEM[k] = 64'd0; end
				12: begin mem[12].IM.MEM[k] = 32'd0; mem[12].DM.MEM[k] = 64'd0; end
				13: begin mem[13].IM.MEM[k] = 32'd0; mem[13].DM.MEM[k] = 64'd0; end
				14: begin mem[14].IM.MEM[k] = 32'd0; mem[14].DM.MEM[k] = 64'd0; end
				default: begin mem[15].IM.MEM[k] = 32'd0; mem[15].DM.MEM[k] = 64'd0; end
			endcase
	end
endtask

// $readmemh into the memories of one node
task load_node;
	input integer       node;
	input [8*128-1:0]   imem_name, dmem_name;
	begin
		case (node)
			 0: begin $readmemh(imem_name, mem[0].IM.MEM); $readmemh(dmem_name, mem[0].DM.MEM); end
			 1: begin $readmemh(imem_name, mem[1].IM.MEM); $readmemh(dmem_name, mem[1].DM.MEM); end
			 2: begin $readmemh(imem_name, mem[2].IM.MEM); $readmemh(dmem_name, mem[2].DM.MEM); end
			 3: begin $readmemh(imem_name, mem[3].IM.MEM); $readmemh(dmem_name, mem[3].DM.MEM); end
			 4: begin $readmemh(imem_name, mem[4].IM.MEM); $readmemh(dmem_name, mem[4].DM.MEM); end
			 5: begin $readmemh(imem_name, mem[5].IM.MEM); $readmemh(dmem_name, mem[5].DM.MEM); end
			 6: begin $readmemh(imem_name, mem[6].IM.MEM); $readmemh(dmem_name, mem[6].DM.MEM); end
			 7: begin $readmemh(imem_name, mem[7].IM.MEM); $readmemh(dmem_name, mem[7].DM.MEM); end
			 8: begin $readmemh(imem_name, mem[8].IM.MEM); $readmemh(dmem_name, mem[8].DM.MEM); end
			 9: begin $readmemh(imem_name, mem[9].IM.MEM); $readmemh(dmem_name, mem[9].DM.MEM); end
			10: begin $readmemh(imem_name, mem[10].IM.MEM); $readmemh(dmem_name, mem[10].DM.MEM); end
			11: begin $readmemh(imem_name, mem[11].IM.MEM); $readmemh(dmem_name, mem[11].DM.MEM); end
			12: begin $readmemh(imem_name, mem[12].IM.MEM); $readmemh(dmem_name, mem[12].DM.MEM); end
			13: begin $readmemh(imem_name, mem[13].IM.MEM); $readmemh(dmem_name, mem[13].DM.MEM); end
			14: begin $readmemh(imem_name, mem[14].IM.MEM); $readmemh(dmem_name, mem[14].DM.MEM); end
			default: begin $readmemh(imem_name, mem[15].IM.MEM); $readmemh(dmem_name, mem[15].DM.MEM); end
		endcase
	end
endtask

// 1 if got equals expected on every bit where expected is not x
// (x nibbles in an expected value are don't-care bits)
function matches;
	input [0:63] got, expected;
	integer b;
	begin
		matches = 1;
		for (b = 0; b < 64; b = b + 1)
			if (expected[b] !== 1'bx && got[b] !== expected[b])
				matches = 0;
	end
endfunction

task require_input_file;
    input [8*256-1:0] name;
    integer fd;
    begin
        fd = $fopen(name, "r");
        if (!fd) begin
            $display("TEST FAILED: cannot open input %0s", name);
            $finish;
        end
        $fclose(fd);
    end
endtask

//// ******************** Stimulus ******************** \\\\

initial
begin
    if (!$value$plusargs("PREFIX=%s", prefix)) prefix = "cmp_test";
    if (!$value$plusargs("DUMP=%s", dump_prefix)) dump_prefix = prefix;
    unordered = $value$plusargs("UNORDERED=%s", range_arg);
    lo = 0; hi = -1;
    if (unordered && ($sscanf(range_arg, "%d:%d", lo, hi) != 2 || lo < 0 || hi < lo || hi > 255)) begin
        $display("TEST FAILED: +UNORDERED expects <lo>:<hi>");
        $finish;
    end

    compare_expected = $value$plusargs("EXPECTED=%s", expected_prefix);
    if (!$value$plusargs("RUNS=%d", runs)) runs = 1;
    if (runs < 1) begin $display("TEST FAILED: RUNS must be positive"); $finish; end
    check_counts = $value$plusargs("COUNTS=%s", counts_arg);
    if (check_counts && $sscanf(counts_arg, "%d,%d,%d,%d", tx_even, rx_even, tx_odd, rx_odd) != 4) begin
        $display("TEST FAILED: COUNTS expects even_tx,even_rx,odd_tx,odd_rx"); $finish;
    end
    require_block = $test$plusargs("CHECK_BLOCK");
    keep_passes = $test$plusargs("KEEP_PASSES");
    dump_words = prefix == "cmp_test" ? 32 : 256;
    CLK = 0;
    total_errors = 0;
    for (run_number = 1; run_number <= runs; run_number = run_number + 1) begin
        errors = 0;
        checked = 0;
        RESET = 1;
        finished = 0;
        done = 0;
        repeat (5) @(negedge CLK);
        for (node = 0; node < `NODES; node = node + 1) begin
            node_cycles[node] = -1;
            clear_node(node);
            $sformat(imem_name, "%0s.imem.%0d.fill", prefix, node);
            $sformat(dmem_name, "%0s.dmem.%0d.fill", prefix, node);
            require_input_file(imem_name);
            require_input_file(dmem_name);
            load_node(node, imem_name, dmem_name);
        end
        RESET = 0;

        // The last instruction of every program is 32'h0000_0000.
        while (!finished) begin
            @(negedge CLK);
            for (node = 0; node < `NODES; node = node + 1)
                if (!done[node] && inst_in[node] === 32'h00000000) begin
                    done[node]        = 1;
                    node_cycles[node] = cycle_number;
                end
            if (&done) begin
                finished = 1;
                $write("All nodes completed; node cycle counts:");
                for (node = 0; node < `NODES; node = node + 1) $write(" %0d", node_cycles[node]);
                $write("\n");
            end else if (cycle_number >= `MAX_CYCLES) begin
                finished = 1;
                errors = errors + 1;
                $display("TIMEOUT: not every node fetched the end-of-program word after %0d cycles (done, node 0..15: %b)",
                    cycle_number, done);
            end
        end

        // Let the pipelines drain
        repeat (5) @(negedge CLK);

        // The final pass keeps the framework filename; prior passes have separate dumps.
        for (node = 0; node < `NODES; node = node + 1) begin
            $sformat(file_name, "%0s.dmem.%0d.dump", dump_prefix, node);
            if (keep_passes && run_number < runs)
                $sformat(file_name, "%0s.run%0d.dmem.%0d.dump", dump_prefix, run_number, node);
            dump_fd = $fopen(file_name, "w");
            if (dump_fd == 0) begin
                $display("TEST FAILED: cannot write %0s", file_name); $finish;
            end
            for (i = 0; i < dump_words; i = i + 1)
                $fdisplay(dump_fd, "Memory location #%d : %h ", i, dmem_word(node, i));
            $fclose(dump_fd);
        end
        $sformat(file_name, "%0s.dmem.N.dump", dump_prefix);
        $display("Data memories of the %0d nodes dumped to %0s", `NODES, file_name);

        // Compare with expected dumps ("Memory location # <n> : <hex>" lines)
        if (compare_expected) begin
            for (node = 0; node < `NODES; node = node + 1) begin
                $sformat(file_name, "%0s.%0d.dump", expected_prefix, node);
                expected_fd = $fopen(file_name, "r");
                if (expected_fd == 0) begin
                    $display("TEST FAILED: cannot open %0s", file_name);
                    errors = errors + 1;
                end else begin
                    for (k = 0; k < 256; k = k + 1) begin expected_set[k] = 64'bx; actual_set[k] = 64'bx; end
                    seen = 0; node_checked = 0;
                    line = 0;
                    while ($fgets(line, expected_fd)) begin
                        if ($sscanf(line, "%s %s %s %d %s %h", word1, word2, word3, address,
                                    word4, expected) != 6 || address < 0 || address > 255 || seen[address]) begin
                            errors = errors + 1;
                            $display("Malformed or duplicate expected row in %0s: %0s", file_name, line);
                        end else begin
                            seen[address] = 1;
                            if (expected !== 64'bx) begin
                                node_checked = node_checked + 1;
                                checked = checked + 1;
                                if (unordered && address >= lo && address <= hi) begin
                                    expected_set[address] = expected;
                                    actual_set[address]   = dmem_word(node, address);
                                end else if (!matches(dmem_word(node, address), expected)) begin
                                    errors = errors + 1;
                                    $display("MISMATCH node %0d memory location %0d: expected %h, got %h",
                                        node, address, expected, dmem_word(node, address));
                                end
                            end
                        end
                        line = 0;
                    end
                    $fclose(expected_fd);
                    if (node_checked == 0) begin
                        errors = errors + 1; $display("Empty comparison for node %0d", node);
                    end
                    // The unordered range: every expected value must be found as
                    // often as it is expected, and every found value must be one
                    // of the expected values.
                    if (unordered)
                        for (i = lo; i <= hi; i = i + 1)
                            if (expected_set[i] !== 64'bx) begin
                                count_expected = 0; count_actual = 0;
                                for (j = lo; j <= hi; j = j + 1) begin
                                    if (matches(expected_set[j], expected_set[i])) count_expected = count_expected + 1;
                                    if (matches(actual_set[j], expected_set[i]))   count_actual   = count_actual + 1;
                                end
                                if (count_expected != count_actual) begin
                                    errors = errors + 1;
                                    $display("MISMATCH node %0d locations %0d-%0d (any order): expected value %h found %0d time(s), expected %0d",
                                        node, lo, hi, expected_set[i], count_actual, count_expected);
                                end
                                count_actual = 0;
                                for (j = lo; j <= hi; j = j + 1)
                                    if (expected_set[j] !== 64'bx && matches(actual_set[i], expected_set[j]))
                                        count_actual = count_actual + 1;
                                if (count_actual == 0) begin
                                    errors = errors + 1;
                                    $display("MISMATCH node %0d memory location %0d: value %h is not among the expected values",
                                        node, i, actual_set[i]);
                                end
                            end
                end
            end
        end
        for (node = 0; node < 16; node = node + 1) begin
            if (check_counts && (tx_count[node] != (node % 2 == 0 ? tx_even : tx_odd) ||
                                 rx_count[node] != (node % 2 == 0 ? rx_even : rx_odd))) begin
                $display("COUNT MISMATCH node=%0d tx=%0d rx=%0d", node, tx_count[node], rx_count[node]);
                errors = errors + 1;
            end
            $display("NODE run=%0d node=%0d cycles=%0d tx=%0d rx=%0d", run_number, node,
                     node_cycles[node], tx_count[node], rx_count[node]);
        end
        if (require_block && (blocked_edges == 0 || full_polls == 0)) begin
            errors = errors + 1;
            $display("BLOCKING MISSED: sender must see backpressure and poll a full output buffer");
        end
        $display("RUN %0d words=%0d mismatches=%0d blocked_edges=%0d full_polls=%0d",
                 run_number, checked, errors, blocked_edges, full_polls);
        total_errors = total_errors + errors;
    end // repeat in the same CMP instance
    if (total_errors != 0)
        $display("TEST FAILED: %0d errors in %0s", total_errors, prefix);
    else if (compare_expected)
        $display("TEST PASSED: %0s (%0d runs)", prefix, runs);
    $finish;
end

endmodule
