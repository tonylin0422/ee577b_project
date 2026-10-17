//---------------------------------------------------------------------
// This file implements the input controller. 
// Each input port of the router has a controller which is responsible
// for buffering the input, determining direction, and sending 
// outputs per channel. 
//---------------------------------------------------------------------
module input_controller #(
    parameter X = 0,
    parameter Y = 0
) (
    input clk,
    input reset,
    input polarity,

    // I/O ports
    input             si,
    input      [63:0] di,
    output            ri,

    // Output to arbiter
    input         [4:0]  grant,
    output reg    [63:0] packet_out,
    output reg    [4:0]  request
);
    localparam NORTH = 0;
    localparam EAST  = 1;
    localparam SOUTH = 2;
    localparam WEST  = 3;
    localparam PE    = 4;

    // Destination coordinate
    wire [1:0] dest_x;
    wire [1:0] dest_y;

    // Create buffer registers for the two virtual channels
    reg [63:0] buffer_even;
    reg [63:0] buffer_even_d;
    reg [63:0] buffer_odd;
    reg [63:0] buffer_odd_d;

    // Buffer full/empty
    reg       full_even;
    reg       full_even_d;
    reg       full_odd;
    reg       full_odd_d;

    wire [63:0] forward_packet;  // This is the packet sitting in the input buffer waiting to be forwarded
    wire        forward_valid;   // Whether there is valid data to forward based on polarity
    wire        forward;


    //=======================================================================
    // Registers
    //=======================================================================
    always @(posedge clk) begin
        if (reset) begin
            buffer_even <= 64'b0;
            buffer_odd  <= 64'b0;
            full_even   <= 1'b0;
            full_odd    <= 1'b0;
        end else begin
            buffer_even <= buffer_even_d;
            buffer_odd  <= buffer_odd_d;
            full_even   <= full_even_d;
            full_odd    <= full_odd_d;
        end
    end

    //=======================================================================
    // Combinational Logic
    //=======================================================================

    // Forward even buffer on even polarity, odd buffer on odd polarity
    assign forward_packet = polarity ? buffer_odd : buffer_even;


    // There is valid data to forward if the even buffer is full on even polarity, vice versa
    assign forward_valid = polarity ? full_odd : full_even;

    // Parse the packet waiting to be forwarded for necessary fields
    assign dest_x = forward_packet[61:60];
    assign dest_y = forward_packet[59:58];

    // alternating vc, so ri is based on if the input buffer of the opposite polarity is empty
    // - (on rising edge) cycle 1: even polarity, capture in odd buffer
    // - (on rising edge) cycle 2: odd polarity, forward odd buffer to output buffer
    // - (on rising edge) cycle 3: even polarity (odd was sent so it’s empty), send ri 
    //   so odd buffer can capture

    assign ri = polarity ? !full_even : !full_odd;

    //---------------------------------------------------------------------
    // Buffer Logic:
    // On odd polarity, capture into even buffer
    // On even polarity, capture into odd buffer
    //
    // Combinationally set packet_out = forward_packet (let arbiter handle)
    // but only deassert buffer full flag when grant is received so the next packet can be buffered
    //---------------------------------------------------------------------

    always @(*) begin
        buffer_even_d = buffer_even;
        buffer_odd_d  = buffer_odd;
        full_even_d   = full_even;
        full_odd_d    = full_odd;
        
        if (si) begin
            if (polarity) begin
                buffer_even_d = di;
                full_even_d   = 1'b1;
            end else begin
                buffer_odd_d = di;
                full_odd_d   = 1'b1;
            end
        end

        if (forward_valid && |(request & grant)) begin
            if (polarity) full_odd_d  = 1'b0;
            else          full_even_d = 1'b0;
        end
    end

    //----------------------------------------------------------------------------------------
    // Routing logic: 
    // Spec: (0,0) is the upper-left corner, x increases to the right, y increases downward.
    //----------------------------------------------------------------------------------------
    
    always @(*) begin
        request = 5'b0;

        if (forward_valid) begin
            // X-first routing
            if      (dest_x > X) request[EAST]  = 1'b1;
            else if (dest_x < X) request[WEST]  = 1'b1;
            // Route Y-direction
            else if (dest_y > Y) request[SOUTH] = 1'b1;
            else if (dest_y < Y) request[NORTH] = 1'b1;
            // Route to PE
            else                 request[PE]    = 1'b1;
        end
    end


    //---------------------------------------------------------------------
    // Forwarding Logic
    //---------------------------------------------------------------------

    always @(*) begin
        packet_out = forward_packet;
    end




endmodule
