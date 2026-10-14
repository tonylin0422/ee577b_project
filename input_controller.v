//---------------------------------------------------------------------
// This file implements the input controller. 
// Each input port of the router has a controller which is responsible
// for buffering the input, determining direction, and sending 
// outputs per channel. 
//---------------------------------------------------------------------
`include "packet_def.v"

module input_controller #(
    parameter PORT_ID = 0
) (
    input clk,
    input reset,
    input polarity,

    // I/O ports
    input             si,
    input      [63:0] di,
    output            ri,

    // Output to arbiter
    output reg    [63:0] packet_out,
    output reg    [4:0]  request,
    input      [4:0]  grant
);

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

    wire [63:0] active_packet;
    wire        active_valid;
    wire        forward;


    // Registers
    always @(posedge clk) begin
        if (reset) begin
            buffer_even      <= 64'b0;
            buffer_odd       <= 64'b0;
            full_even <= 1'b0;
            full_odd  <= 1'b0;
        end else begin
            buffer_even <= buffer_even_d;
            buffer_odd  <= buffer_odd_d;
            full_even   <= full_even_d;
            full_odd    <= full_odd_d;
        end
    end

    // Continuous assignments

    // This keeps track of which VC is active
    assign active_packet = polarity ? buffer_odd : buffer_even;
    assign active_valid   = polarity ? full_odd : full_even;

    assign ri = polarity ? !full_even : !full_odd;

    // Forward only if an active request is granted
    assign forward = active_valid && (|(grant & request));

    // Buffer Logic
    always @(*) begin
        // Default assignments to avoid latches
        buffer_even_d = buffer_even;
        buffer_odd_d  = buffer_odd;
        full_even_d   = full_even;
        full_odd_d    = full_odd;

        // Buffer logic per channel
        // If router has valid data on input ports AND buffer is not full, buffer it
        if (si && ri) begin
            if (polarity) begin
                buffer_even_d = di;
                full_even_d   = 1'b1;
            end
            else begin
                buffer_odd_d = di;
                full_odd_d   = 1'b1;
            end
        end

        if (forward) begin
            if (polarity)
                full_odd_d = 1'b0;
            else
                full_even_d = 1'b0;
        end
    end



    // Routing Logic: X-first routing
    // ASSUMPTION: that all hop counts and direction bits are valid values
    // For example, there will be no illegal routing like PE trying to route to itself
    // or NESW inputs trying to route back to itself (e.g. north-to-north)
    always @(*) begin
        request = 5'b0;
        // Make sure there is valid data in the buffer
        if (active_valid) begin
            // X-first routing: prioritize routing in east-west direction
            if ((active_packet[`HCX] != 4'd0)) begin
                if (active_packet[`X_DIR] == 1'b0) begin
                    request[`WEST] = 1'b1;
                end else begin
                    request[`EAST] = 1'b1;
                end
            // Route Y-direction if HCX = 0
            end else if ((active_packet[`HCY] != 4'd0)) begin
                if (active_packet[`Y_DIR] == 1'b0) begin
                    request[`SOUTH] = 1'b1;
                end else begin
                    request[`NORTH] = 1'b1;
                end
            end else begin
                // If hop count for x and y are both 0 then route to PE
                request[`PE] = 1'b1;
            end
            
        end
    end

    always @(*) begin
        packet_out = active_packet;

        if (active_valid) begin
            if (active_packet[`HCX] != 4'd0) begin
                packet_out[`HCX] = active_packet[`HCX] - 4'd1;
            end
            else if (active_packet[`HCY] != 4'd0) begin
                packet_out[`HCY] = active_packet[`HCY] - 4'd1;
            end
        end
    end

endmodule

/* Another routing implementation (more explicit)
    case (PORT_ID) 
                // North input: if hop count = 0, then go to PE, else go south
                `NORTH: begin
                    if (active_packet[`HCY] == 4'b0) begin
                        request[`PE] = 1'b1;
                    end else begin
                        request[`SOUTH] = 1'b1;
                    end
                end

                // East input: can go west, north, south, or PE
                `EAST: begin
                    if ((active_packet[`HCX] == 4'b0) && (active_packet[`HCY] == 4'b0)) begin
                        request[`PE] = 1'b1;
                    end else if (active_packet[`HCX] == 4'b0) begin
                        if (active_packet[`Y_DIR] == 1'b0) begin
                            request[`SOUTH] = 1'b1;
                        end else begin
                            request[`NORTH] = 1'b1;
                        end
                    end else begin
                        request[`WEST] = 1'b1;
                    end
                end
                
                // South input: can go north or to PE
                `SOUTH: begin
                    if (active_packet[`HCY] == 4'b0) begin
                        request[`PE] = 1'b1;
                    end else begin
                        request[`NORTH] = 1'b1;
                    end
                end

                // West input: can go east, north, south, or PE
                `WEST: begin
                    if ((active_packet[`HCX] == 4'b0) && (active_packet[`HCY] == 4'b0)) begin
                        request[`PE] = 1'b1;
                    end else if (active_packet[`HCX] == 4'b0) begin
                        if (active_packet[`Y_DIR] == 1'b0) begin
                            request[`SOUTH] = 1'b1;
                        end else begin
                            request[`NORTH] = 1'b1;
                        end
                    end else begin
                        request[`EAST] = 1'b1;
                    end
                end

                // PE input: can go NESW
                
            `PE: begin
                if (active_packet[`HCX] != 4'b0) begin
                    if (active_packet[`X_DIR] == 1'b0)
                        request[`WEST] = 1'b1;
                    else
                        request[`EAST] = 1'b1;
                end
                else if (active_packet[`HCY] != 4'b0) begin
                    if (active_packet[`Y_DIR] == 1'b0)
                        request[`SOUTH] = 1'b1;
                    else
                        request[`NORTH] = 1'b1;
                end
            end


                default: request = 5'b0;
            endcase
*/