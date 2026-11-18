// R1. Drive on falling edges, check transfers on rising edges, and sample
// registered CPU read data 1 ns later. case_id marks each figure in SimVision.
`timescale 1ns/10ps
module tb_cardinal_nic;
    reg clk, reset, nicEn, nicWrEn, net_si, net_ro, net_polarity;
    reg [0:1] addr;
    reg [0:63] d_in, net_di;
    wire net_ri, net_so;
    wire [0:63] d_out, net_do;
    cardinal_nic NIC (
        .clk(clk), .reset(reset), .addr(addr), .d_in(d_in), .d_out(d_out),
        .nicEn(nicEn), .nicWrEn(nicWrEn), .net_si(net_si), .net_ri(net_ri),
        .net_di(net_di), .net_so(net_so), .net_ro(net_ro), .net_do(net_do),
        .net_polarity(net_polarity)
    );

    localparam [0:63] EVEN = 64'h1001_1234_5678_9ABC,
                      ODD  = 64'h9001_ABCD_1357_2468,
                      RX   = 64'h2003_CAFE_F00D_2211;
    reg [7:0] case_id;
    reg [0:63] pending_packet;
    reg pending;
    integer sends, receives, simultaneous, case_start;

    always #2 clk = ~clk;
    always @(posedge clk)
        if (reset) net_polarity <= 0;
        else net_polarity <= ~net_polarity;

    task check;
        input [8*48-1:0] what;
        input [0:63] actual, expected;
        begin
            if (actual !== expected) begin
                $display("NIC TEST FAILED R1(%c) %0t ns %0s expected=%h observed=%h",
                         case_id, $time, what, expected, actual);
                $finish;
            end
        end
    endtask

    // The scoreboard queues a processor store only if its slot was free
    // before this edge. It retires a packet only on an observed transfer.
    always @(posedge clk) begin
        if (reset) pending = 0;
        else begin
            if (net_so !== 0 && net_so !== 1) check("known net_so", net_so, 0);
            if (net_so) begin
                check("queued packet", pending, 1);
                check("router ready", net_ro, 1);
                check("opposite VC phase", net_polarity, !pending_packet[0]);
                check("delivered packet", net_do, pending_packet);
                sends = sends + 1;
            end
            if (net_si) begin
                check("receiver handshake", net_ri, 1);
                receives = receives + 1;
                if (net_so) simultaneous = simultaneous + 1;
            end
            if (nicEn && nicWrEn && addr == 2 && !pending) begin
                pending_packet = d_in;
                pending = 1;
            end
            if (net_so) pending = 0;
        end
    end

    // Called on a falling edge; inputs stay stable for exactly one transfer edge.
    task cycle;
        begin
            @(posedge clk); #1;
            @(negedge clk);
        end
    endtask
    task store_packet;
        input [0:63] packet;
        begin
            nicEn = 1; nicWrEn = 1; addr = 2; d_in = packet;
            cycle;
            nicEn = 0; nicWrEn = 0;
        end
    endtask
    task load_check;
        input [0:1] address;
        input [0:63] expected;
        begin
            nicEn = 1; nicWrEn = 0; addr = address;
            @(posedge clk); #1; check("CPU read data", d_out, expected);
            @(negedge clk); nicEn = 0;
        end
    endtask
    task start_case;
        input [7:0] id;
        begin case_id = id; case_start = $time; end
    endtask
    task pass_case;
        begin
            $display("NIC CASE R1(%c) PASS  time_ns=%0d..%0d sends=%0d receives=%0d",
                     case_id, case_start, $time, sends, receives);
        end
    endtask

    initial begin
        $timeformat(-9, 0, "", 0);
        clk = 0; reset = 1; net_polarity = 0;
        addr = 0; d_in = 0; net_di = 0; net_si = 0; net_ro = 0;
        nicEn = 0; nicWrEn = 0; sends = 0; receives = 0; simultaneous = 0;
        start_case("a");
        repeat (5) cycle;
        check("ready after reset", net_ri, 1); check("send after reset", net_so, 0);
        check("CPU output after reset", d_out, 0);
        reset = 0;
        load_check(1, 0); load_check(3, 0); pass_case;

        start_case("b"); net_ro = 1;
        store_packet(EVEN); repeat (4) cycle;
        check("unblocked sends", sends, 1); load_check(3, 0); pass_case;

        start_case("c"); net_ro = 0;
        store_packet(ODD); repeat (6) cycle;
        load_check(3, 1); check("blocked sends", sends, 1);
        net_ro = 1; repeat (4) cycle; check("released exactly once", sends, 2);
        load_check(3, 0); pass_case;

        start_case("d"); net_ro = 0; load_check(3, 0);
        store_packet(EVEN); load_check(3, 1); pass_case;

        start_case("e"); store_packet(ODD); load_check(3, 1);
        net_ro = 1; repeat (4) cycle; check("original packet only", sends, 3);
        load_check(3, 0); pass_case;

        start_case("f"); net_si = 1; net_di = RX; cycle; net_si = 0;
        check("input backpressure", net_ri, 0); load_check(1, 1);
        load_check(0, RX); check("input free after read", net_ri, 1);
        load_check(1, 0); pass_case;

        start_case("g"); nicEn = 1; addr = 0; cycle; nicEn = 0;
        // Data from an empty slot is unspecified. Check only the specified state.
        check("empty read preserves ready", net_ri, 1); load_check(1, 0); pass_case;

        start_case("h"); net_ro = 0; net_si = 1; net_di = RX;
        store_packet(ODD); net_si = 0; // CPU store and router arrival share an edge.
        load_check(0, RX);
        while (net_polarity != 0) cycle;
        net_ro = 1; net_si = 1; net_di = EVEN; cycle; net_si = 0;
        check("simultaneous router send and receive", simultaneous, 1);
        load_check(0, EVEN); load_check(3, 0); pass_case;

        start_case("i"); store_packet(EVEN); repeat (4) cycle;
        store_packet(ODD); repeat (4) cycle;
        check("total sends on legal phases", sends, 6);
        check("total packets received", receives, 3);
        cycle; check("disabled CPU read data", d_out, 0); pass_case;
        $display("NIC TEST PASSED");
        $finish;
    end
endmodule
