//=======================================================================
// This module implements the NIC.
//=======================================================================

module cardinal_nic (
    input         clk, reset,
    input  [1:0]  addr,
    input  [63:0] d_in,
    output [63:0] d_out,
    input         nicEn, nicEnWr,
    input         net_si,
    output        net_ri,
    input  [63:0] net_di,
    output        net_so,
    input         net_ro,
    output [63:0] net_do,
    input         net_polarity
);

    // Network input/output channel buffers
    reg [63:0] input_buffer;
    reg [63:0] input_buffer_d;

    reg [63:0] output_buffer;
    reg [63:0] output_buffer_d;

    // Buffer status registers
    reg        input_buffer_full;
    reg        input_buffer_full_d;

    reg        output_buffer_full;
    reg        output_buffer_full_d;

    // The register selected by addr to be read via d_out to the processor
    // Spec says: If nicEn is high and nicWrEN is low, the content of the register
    // specified by addr[0:1] is placed onto the d_out port at the next rising clock edge.
    reg [63:0] d_out_reg;
    reg [63:0] d_out_reg_d;

    //=======================================================================
    // Registers
    //=======================================================================

    always @(posedge clk) begin
        if (reset) begin
            input_buffer       <= 64'b0;
            output_buffer      <= 64'b0;
            input_buffer_full  <= 1'b0;
            output_buffer_full <= 1'b0;
            d_out_reg          <= 64'd0;
        end else begin
            input_buffer       <= input_buffer_d;
            output_buffer      <= output_buffer_d;
            input_buffer_full  <= input_buffer_full_d;
            output_buffer_full <= output_buffer_full_d;
            d_out_reg          <= d_out_reg_d;
        end
    end

    assign d_out  = nicEn ? d_out_reg : 64'd0;
    assign net_so = !reset && net_ro && output_buffer_full && (net_polarity != output_buffer[63]);
    assign net_do = output_buffer;
    assign net_ri = reset || !input_buffer_full;

    always @(*) begin
        input_buffer_d       = input_buffer;
        output_buffer_d      = output_buffer;
        input_buffer_full_d  = input_buffer_full;
        output_buffer_full_d = output_buffer_full;
        d_out_reg_d            = 64'd0;

        // Processor-side interface logic
        // Check enable signals and let processor access registers
        case (addr) 
            2'b00: begin
                if (nicEn && !nicEnWr) begin
                    d_out_reg_d = input_buffer;
                    input_buffer_full_d = 1'b0;
                end
            end

            2'b01: begin
                if (nicEn && !nicEnWr) begin
                    d_out_reg_d = {63'd0, input_buffer_full};
                end
            end

            2'b10: begin
                if (nicEn) begin
                    // Write into output channel buffer if not full
                    if (nicEnWr && !output_buffer_full) begin
                        output_buffer_d      = d_in;
                        output_buffer_full_d = 1'b1;
                    end
                end
            end

            2'b11: begin
                if (nicEn && !nicEnWr) begin
                    d_out_reg_d = {63'd0, output_buffer_full};
                end
            end

            default: ;
        endcase

        // Router-side interface logic
        // Write to input buffer
        if (net_si && !input_buffer_full) begin
            input_buffer_d      = net_di;
            input_buffer_full_d = 1'b1;
        end

        // Deassert output status register when read
        if (net_so && net_ro) output_buffer_full_d = 1'b0;

    end


endmodule