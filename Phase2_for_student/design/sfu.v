
module sfu (
    input  [0:63] a,
    input  [0:63] b,
    input  [0:5]  func,
    input  [0:1]  ww,
    output reg [0:63] result
);

    localparam
        F_DIV  = 6'b001110,
        F_MOD  = 6'b001111,
        F_SQRT = 6'b010010;

    wire [0:63] div8,  mod8,  sqrt8;
    wire [0:63] div16, mod16, sqrt16;
    wire [0:63] div32, mod32, sqrt32;
    wire [0:63] div64, mod64, sqrt64;

    genvar i;

    // 8-bit lanes: 8 parallel operations
    generate
        for (i = 0; i < 8; i = i + 1) begin: gen8
            wire [0:7] root;
            wire divide_by_zero;

            DW_div #(
                .a_width(8),
                .b_width(8),
                .tc_mode(0),
                .rem_mode(1)
            ) div_inst (
                .a(a[i*8 +: 8]),
                .b(b[i*8 +: 8]),
                .quotient(div8[i*8 +: 8]),
                .remainder(mod8[i*8 +: 8]),
                .divide_by_0(divide_by_zero)
            );

            DW_sqrt #(
                .width(8),
                .tc_mode(0)
            ) sqrt_inst (
                .a(a[i*8 +: 8]),
                .root(root[4:7])
            );

            assign root[0:3] = 4'd0;
            assign sqrt8[i*8 +: 8] = root;
        end
    endgenerate

    // 16-bit lanes: 4 parallel operations
    generate
        for (i = 0; i < 4; i = i + 1) begin: gen16
            wire [0:15] root;
            wire divide_by_zero;

            DW_div #(
                .a_width(16),
                .b_width(16),
                .tc_mode(0),
                .rem_mode(1)
            ) div_inst (
                .a(a[i*16 +: 16]),
                .b(b[i*16 +: 16]),
                .quotient(div16[i*16 +: 16]),
                .remainder(mod16[i*16 +: 16]),
                .divide_by_0(divide_by_zero)
            );

            DW_sqrt #(
                .width(16),
                .tc_mode(0)
            ) sqrt_inst (
                .a(a[i*16 +: 16]),
                .root(root[8:15])
            );

            assign root[0:7] = 8'd0;
            assign sqrt16[i*16 +: 16] = root;
        end
    endgenerate

    // 32-bit lanes: 2 parallel operations
    generate
        for (i = 0; i < 2; i = i + 1) begin: gen32
            wire [0:31] root;
            wire divide_by_zero;

            DW_div #(
                .a_width(32),
                .b_width(32),
                .tc_mode(0),
                .rem_mode(1)
            ) div_inst (
                .a(a[i*32 +: 32]),
                .b(b[i*32 +: 32]),
                .quotient(div32[i*32 +: 32]),
                .remainder(mod32[i*32 +: 32]),
                .divide_by_0(divide_by_zero)
            );

            DW_sqrt #(
                .width(32),
                .tc_mode(0)
            ) sqrt_inst (
                .a(a[i*32 +: 32]),
                .root(root[16:31])
            );

            assign root[0:15] = 16'd0;
            assign sqrt32[i*32 +: 32] = root;
        end
    endgenerate

    // 64-bit lane: one operation
    wire [0:31] root64;
    wire divide_by_zero64;

    DW_div #(
        .a_width(64),
        .b_width(64),
        .tc_mode(0),
        .rem_mode(1)
    ) div64_inst (
        .a(a),
        .b(b),
        .quotient(div64),
        .remainder(mod64),
        .divide_by_0(divide_by_zero64)
    );

    DW_sqrt #(
        .width(64),
        .tc_mode(0)
    ) sqrt64_inst (
        .a(a),
        .root(root64)
    );

    assign sqrt64 = {32'd0, root64};

    always @(*) begin
        result = 64'd0;

        case (func)
            F_DIV: begin
                case (ww)
                    2'b00: result = div8;
                    2'b01: result = div16;
                    2'b10: result = div32;
                    2'b11: result = div64;
                endcase
            end

            F_MOD: begin
                case (ww)
                    2'b00: result = mod8;
                    2'b01: result = mod16;
                    2'b10: result = mod32;
                    2'b11: result = mod64;
                endcase
            end

            F_SQRT: begin
                case (ww)
                    2'b00: result = sqrt8;
                    2'b01: result = sqrt16;
                    2'b10: result = sqrt32;
                    2'b11: result = sqrt64;
                endcase
            end

            default: result = 64'd0;
        endcase
    end

endmodule
