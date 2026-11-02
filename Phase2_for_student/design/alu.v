module alu (
    input  [0:63] a,
    input  [0:63] b,
    input  [0:5]  func,
    input  [0:1]  ww,
    output reg [0:63] result
);

    localparam 
        F_AND   = 6'b000001,
        F_OR    = 6'b000010,
        F_XOR   = 6'b000011,
        F_NOT   = 6'b000100,
        F_MOV   = 6'b000101,
        F_ADD   = 6'b000110,
        F_SUB   = 6'b000111,
        F_MULEU = 6'b001000,
        F_MULOU = 6'b001001,
        F_SLL   = 6'b001010,
        F_SRL   = 6'b001011,
        F_SRA   = 6'b001100,
        F_RTTH  = 6'b001101,
        F_DIV   = 6'b001110,
        F_MOD   = 6'b001111,
        F_SQEU  = 6'b010000,
        F_SQOU  = 6'b010001,
        F_SQRT  = 6'b010010;

    integer i;

    always @(*) begin
        result = 64'd0;
        case (func)

            // Simple operations that do not require WW
            F_AND: result = a & b;

            F_OR: result = a | b;

            F_XOR: result = a ^ b;

            F_NOT: result = ~a;

            F_MOV: result = a;


            // Arithmetic that depends on WW

            F_ADD: begin
                case (ww)
                    2'b00: begin
                        for (i = 0; i < 8; i = i + 1)
                            result[i*8 +: 8] = a[i*8 +: 8] + b[i*8 +: 8];
                    end

                    2'b01: begin
                        for (i = 0; i < 4; i = i + 1)
                            result[i*16 +: 16] = a[i*16 +: 16] + b[i*16 +: 16];
                    end

                    2'b10: begin
                        for (i = 0; i < 2; i = i + 1)
                            result[i*32 +: 32] = a[i*32 +: 32] + b[i*32 +: 32];
                    end

                    2'b11: result = a + b;
                endcase
            end


            F_SUB: begin
                case (ww)
                    2'b00: begin
                        for (i = 0; i < 8; i = i + 1)
                            result[i*8 +: 8] = a[i*8 +: 8] - b[i*8 +: 8];
                    end

                    2'b01: begin
                        for (i = 0; i < 4; i = i + 1)
                            result[i*16 +: 16] = a[i*16 +: 16] - b[i*16 +: 16];
                    end

                    2'b10: begin
                        for (i = 0; i < 2; i = i + 1)
                            result[i*32 +: 32] = a[i*32 +: 32] - b[i*32 +: 32];
                    end

                    2'b11: result = a - b;
                endcase
            end


            F_MULEU: begin
                case (ww)
                    2'b00: begin
                        for (i = 0; i < 4; i = i + 1)
                            result[i*16 +: 16] =
                                a[i*16 +: 8] * b[i*16 +: 8];
                    end

                    2'b01: begin
                        for (i = 0; i < 2; i = i + 1)
                            result[i*32 +: 32] =
                                a[i*32 +: 16] * b[i*32 +: 16];
                    end

                    2'b10: begin
                        result = a[0:31] * b[0:31];
                    end
                endcase
            end

            F_MULOU: begin
                case (ww)
                    2'b00: begin
                        for (i = 0; i < 4; i = i + 1)
                            result[i*16 +: 16] =
                                a[i*16+8 +: 8] * b[i*16+8 +: 8];
                    end

                    2'b01: begin
                        for (i = 0; i < 2; i = i + 1)
                            result[i*32 +: 32] =
                                a[i*32+16 +: 16] * b[i*32+16 +: 16];
                    end

                    2'b10: begin
                        result = a[32:63] * b[32:63];
                    end
                endcase
            end

            F_SLL: begin
                case (ww)
                    2'b00: for (i = 0; i < 8; i = i + 1)
                        result[i*8 +: 8] = a[i*8 +: 8] << b[i*8+5 +: 3];

                    2'b01: for (i = 0; i < 4; i = i + 1)
                        result[i*16 +: 16] = a[i*16 +: 16] << b[i*16+12 +: 4];

                    2'b10: for (i = 0; i < 2; i = i + 1)
                        result[i*32 +: 32] = a[i*32 +: 32] << b[i*32+27 +: 5];

                    2'b11: result = a << b[58:63];
                endcase
            end

            F_SRL: begin
                case (ww)
                    2'b00: for (i = 0; i < 8; i = i + 1)
                        result[i*8 +: 8] = a[i*8 +: 8] >> b[i*8+5 +: 3];

                    2'b01: for (i = 0; i < 4; i = i + 1)
                        result[i*16 +: 16] = a[i*16 +: 16] >> b[i*16+12 +: 4];

                    2'b10: for (i = 0; i < 2; i = i + 1)
                        result[i*32 +: 32] = a[i*32 +: 32] >> b[i*32+27 +: 5];

                    2'b11: result = a >> b[58:63];
                endcase
            end

            F_SRA: begin
                case (ww)
                    2'b00: for (i = 0; i < 8; i = i + 1)
                        result[i*8 +: 8] = $signed(a[i*8 +: 8]) >>> b[i*8+5 +: 3];

                    2'b01: for (i = 0; i < 4; i = i + 1)
                        result[i*16 +: 16] = $signed(a[i*16 +: 16]) >>> b[i*16+12 +: 4];

                    2'b10: for (i = 0; i < 2; i = i + 1)
                        result[i*32 +: 32] = $signed(a[i*32 +: 32]) >>> b[i*32+27 +: 5];

                    2'b11: result = $signed(a) >>> b[58:63];
                endcase
            end

            F_RTTH: begin
                case (ww)
                    2'b00: for (i = 0; i < 8; i = i + 1)
                        result[i*8 +: 8] = {
                            a[i*8+4 +: 4], a[i*8 +: 4]
                        };

                    2'b01: for (i = 0; i < 4; i = i + 1)
                        result[i*16 +: 16] = {
                            a[i*16+8 +: 8], a[i*16 +: 8]
                        };

                    2'b10: for (i = 0; i < 2; i = i + 1)
                        result[i*32 +: 32] = {
                            a[i*32+16 +: 16], a[i*32 +: 16]
                        };

                    2'b11: result = {a[32:63], a[0:31]};
                endcase
            end

            F_SQOU: begin
                case (ww)
                    2'b00: for (i = 0; i < 4; i = i + 1)
                        result[i*16 +: 16] =
                            a[i*16+8 +: 8] * a[i*16+8 +: 8];

                    2'b01: for (i = 0; i < 2; i = i + 1)
                        result[i*32 +: 32] =
                            a[i*32+16 +: 16] * a[i*32+16 +: 16];

                    2'b10: result = a[32:63] * a[32:63];
                endcase
            end

            F_SQEU: begin
                case (ww)
                    2'b00: for (i = 0; i < 4; i = i + 1)
                        result[i*16 +: 16] =
                            a[i*16 +: 8] * a[i*16 +: 8];

                    2'b01: for (i = 0; i < 2; i = i + 1)
                        result[i*32 +: 32] =
                            a[i*32 +: 16] * a[i*32 +: 16];

                    2'b10: result = a[0:31] * a[0:31];
                endcase
            end

            default: result = 64'd0;

        endcase


    end


endmodule