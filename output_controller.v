//=======================================================================
// This module implements the output controller.
// Each output port has an OC, which is wired to the other inputs (not itself), 
// and the OC is responsible for arbitrating between the inputs, 
// buffering the chosen packet, and outputting to the next node.
//=======================================================================

module output_controller (
    input clk,
    input reset,
    input polarity,

    input [3:0] request,

    input [63:0] di0,
    input [63:0] di1,
    input [63:0] di2,
    input [63:0] di3,

    output reg [3:0] grant,
 
    input ro,
    output reg        so,
    output reg [63:0] data_out
);


    // Selects one of the two pointers above based on polarity
    wire [1:0] active_priority;

    // Determines if the buffer is full (for arbiter to send)
    wire active_full;

    // Determine if there is contention
    // Spec says "as there are not multiple (or contending) requests for an output channel, 
    // the priority ranking is irrelevant and doesn’t change. The priority ranking changes
    // only when multiple requests conflict and the highest-priority request is granted."
    wire contention;

    wire no_request;

    // Pointer for the rotating priority arbitration
    reg [1:0] priority_even;
    reg [1:0] priority_even_d;
    reg [1:0] priority_odd;
    reg [1:0] priority_odd_d;

    // Output Buffer
    reg [63:0] buffer_even;
    reg [63:0] buffer_even_d;
    reg [63:0] buffer_odd;
    reg [63:0] buffer_odd_d;

    // Buffer full/empty
    reg       full_even;
    reg       full_even_d;
    reg       full_odd;
    reg       full_odd_d;

    //=======================================================================
    // Registers
    //=======================================================================
    always @(posedge clk) begin
        if (reset) begin
            buffer_even   <= 64'b0;
            buffer_odd    <= 64'b0;
            full_even     <= 1'b0;
            full_odd      <= 1'b0;
            priority_even <= 2'b0;
            priority_odd  <= 2'b0;
        end else begin
            buffer_even   <= buffer_even_d;
            buffer_odd    <= buffer_odd_d;
            full_even     <= full_even_d;
            full_odd      <= full_odd_d;
            priority_even <= priority_even_d;
            priority_odd  <= priority_odd_d;
        end
    end

    //=======================================================================
    // Combinational Logic
    //=======================================================================

    // Internal capture odd buffer on odd polarity, even buffer on even polarity
    assign active_priority = polarity ? priority_odd : priority_even;

    // Same logic for full
    assign active_full = polarity ? full_odd : full_even;

    // Determine if there is contention
    // request is one-hot, so there is contention if more than one bit is set to 1
    assign contention = |(request & (request - 4'd1));  

    // Determine if there is no input requesting 
    assign no_request = !(|request);

    //---------------------------------------------------------------------
    // Arbitration + Buffer Logic 
    //---------------------------------------------------------------------

        
    always @(*) begin
        priority_even_d = priority_even;
        priority_odd_d  = priority_odd;
        buffer_even_d   = buffer_even;
        buffer_odd_d    = buffer_odd;
        full_even_d     = full_even;
        full_odd_d      = full_odd;

        grant = 4'b0000;

        // If no one requests or buffer is full, grant nobody
        if (reset || no_request || active_full) grant = 4'b0000;
        else begin
            // If there is no contention, grant whoever was requesting
            if (!contention) grant = request;
            // Otherwise grant based on the priority and increment the priority pointer
            else begin
                case (active_priority)
                    // Prioritize di0
                    2'b00: begin
                        if      (request[0]) grant = 4'b0001;
                        else if (request[1]) grant = 4'b0010;
                        else if (request[2]) grant = 4'b0100;
                        else if (request[3]) grant = 4'b1000;
                    end
                    // Prioritize di1
                    2'b01: begin
                        if      (request[1]) grant = 4'b0010;
                        else if (request[2]) grant = 4'b0100;
                        else if (request[3]) grant = 4'b1000;
                        else if (request[0]) grant = 4'b0001;
                    end
                    // Prioritize di2
                    2'b10: begin
                        if      (request[2]) grant = 4'b0100;
                        else if (request[3]) grant = 4'b1000;
                        else if (request[0]) grant = 4'b0001;
                        else if (request[1]) grant = 4'b0010;
                    end
                    // Prioritize di3
                    2'b11: begin
                        if      (request[3]) grant = 4'b1000;
                        else if (request[0]) grant = 4'b0001;
                        else if (request[1]) grant = 4'b0010;
                        else if (request[2]) grant = 4'b0100;
                    end
                endcase

                if (polarity) begin
                    if      (grant[0]) priority_odd_d = 2'd1;
                    else if (grant[1]) priority_odd_d = 2'd2;
                    else if (grant[2]) priority_odd_d = 2'd3;
                    else if (grant[3]) priority_odd_d = 2'd0;
                end else begin
                    if      (grant[0]) priority_even_d = 2'd1;
                    else if (grant[1]) priority_even_d = 2'd2;
                    else if (grant[2]) priority_even_d = 2'd3;
                    else if (grant[3]) priority_even_d = 2'd0;
                end
            end

            // Capture the selected input into the buffer
            if (polarity) begin
                if      (grant[0]) buffer_odd_d = di0;
                else if (grant[1]) buffer_odd_d = di1;
                else if (grant[2]) buffer_odd_d = di2;
                else if (grant[3]) buffer_odd_d = di3;

                full_odd_d = 1'b1;
            end else begin
                if      (grant[0]) buffer_even_d = di0;
                else if (grant[1]) buffer_even_d = di1;
                else if (grant[2]) buffer_even_d = di2;
                else if (grant[3]) buffer_even_d = di3;

                full_even_d = 1'b1;
            end
        end

        // Clear output buffer after successful external transfer
        if (so) begin
            if (polarity) full_even_d = 1'b0;
            else          full_odd_d  = 1'b0;
        end
    end


    //---------------------------------------------------------------------
    // Output Logic
    // Output odd buffer on even polarity and even buffer on odd polarity
    // Only assert so when ro is asserted
    //---------------------------------------------------------------------

    always @(*) begin
        data_out = polarity ? buffer_even : buffer_odd;
        so       = !reset && (ro & (polarity ? full_even : full_odd));
    end

endmodule