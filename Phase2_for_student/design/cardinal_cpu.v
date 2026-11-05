////////////////////////////////////////////////////////////////////////////
// Cardinal processor - top-level module (EE577B Project Phase 2)
//
// DO NOT CHANGE THE MODULE NAME OR THE PORT LIST BELOW.
// The grading testbench instantiates cardinal_cpu by these exact port names.
// If the module name, a port name, a direction or a width differs, the
// elaboration step (ncelab) stops with an error.
//
// Implement the 4-stage pipeline (IF, ID, EX/MEM, WB) described in the
// Phase 2 handout and the Cardinal Processor ISA manual. You may add any
// number of other modules and files in design/ (register file, ALU,
// decoder, ...); only this interface is fixed.
//
// Memory interface (models in include/, part of the testbench):
//   * Instruction memory: asynchronous. inst_in = IMEM[pc_out[22:29]].
//   * Data memory: synchronous. memEn, memWrEn, addr_out[24:31] and d_out
//     are sampled at a rising clock edge; a store is written at that edge,
//     and load data appears on d_in after that edge (for the next cycle).
////////////////////////////////////////////////////////////////////////////
module cardinal_cpu (
    input         clk,        // rising-edge clock
    input         reset,      // synchronous, active high
    input  [0:31] inst_in,    // instruction from the instruction memory
    input  [0:63] d_in,       // load data from the data memory
    output [0:31] pc_out,     // instruction memory address (byte address)
    output [0:31] addr_out,   // data memory address (64-bit word address)
    output        memEn,      // data memory enable (load or store)
    output        memWrEn,    // data memory write enable (store)
    output [0:63] d_out       // store data to the data memory
);

    reg [0:31] addr_out_i;
    reg        memEn_i;
    reg        memWrEn_i;
    reg [0:63] d_out_i;

    // Program counter
    reg [0:31] pc;
    reg [0:31] pc_d;
    
    // IF/ID register
    reg [0:31] if_id;
    reg [0:31] if_id_d;

    // ID/EX pipeline registers
    reg [0:63] id_ex_a;
    reg [0:63] id_ex_b;
    reg [0:63] id_ex_store_data;
    reg [0:63] id_ex_a_d;
    reg [0:63] id_ex_b_d;
    reg [0:63] id_ex_store_data_d;

    reg [0:4]  id_ex_rd;
    reg [0:5]  id_ex_func;
    reg [0:1]  id_ex_ww;
    reg [0:2]  id_ex_ppp;
    reg [0:15] id_ex_imm;
    reg [0:4]  id_ex_rd_d;
    reg [0:5]  id_ex_func_d;
    reg [0:1]  id_ex_ww_d;
    reg [0:2]  id_ex_ppp_d;
    reg [0:15] id_ex_imm_d;

    reg id_ex_regWrite;
    reg id_ex_memRead;
    reg id_ex_memWrite;
    reg id_ex_valid;
    reg id_ex_regWrite_d;
    reg id_ex_memRead_d;
    reg id_ex_memWrite_d;
    reg id_ex_valid_d;
    reg if_id_valid;


    // Helper wires
    wire [0:5]  opcode = if_id[0:5];
    wire [0:4]  rD     = if_id[6:10];
    wire [0:4]  rA     = if_id[11:15];
    wire [0:4]  rB     = if_id[16:20];
    wire [0:1]  WW     = if_id[24:25];
    wire [0:2]  ppp    = if_id[21:23];
    wire [0:5]  func   = if_id[26:31];
    wire [0:15] addr   = if_id[16:31]; 
    

    reg  [0:4]  rdAddr0;
    reg  [0:4]  rdAddr1;
    wire [0:63] rdData0;
    wire [0:63] rdData1;

    // EX/WB pipeline registers
    reg  [0:63] ex_wb_result;
    reg  [0:63] ex_wb_result_d;
    reg  [0:4]  ex_wb_rd;
    reg  [0:4]  ex_wb_rd_d;
    reg         ex_wb_regWrite;
    reg         ex_wb_regWrite_d;
    reg         ex_wb_memRead;
    reg         ex_wb_memRead_d;
    reg  [0:7]  ex_wb_byteEn;
    reg  [0:7]  ex_wb_byteEn_d;
    reg         ex_wb_valid;
    reg         ex_wb_valid_d;

    reg [0:63] wb_data;

    assign pc_out   = pc;
    assign addr_out = addr_out_i;
    assign memEn    = memEn_i;
    assign memWrEn  = memWrEn_i;
    assign d_out    = d_out_i;


    // Opcodes
    // Primary opcodes
    localparam 
    OP_RTYPE = 6'b101010,
    OP_LD    = 6'b100000,
    OP_SD    = 6'b100001,
    OP_BEZ   = 6'b100010,
    OP_BNEZ  = 6'b100011,
    OP_NOP   = 6'b111100;

    // R-type function codes
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

    wire is_rtype  = (opcode == OP_RTYPE);
    wire is_store  = (opcode == OP_SD);
    wire is_branch = (opcode == OP_BEZ || opcode == OP_BNEZ);

    wire is_unary = is_rtype &&
        (func == F_NOT  || func == F_MOV  ||
         func == F_RTTH || func == F_SQEU ||
         func == F_SQOU || func == F_SQRT);

    wire uses_a  = is_rtype;
    wire uses_b  = is_rtype && !is_unary;
    wire uses_rd = is_store || is_branch;

    wire hazard_id_ex =
        id_ex_valid && id_ex_regWrite && (id_ex_rd != 0) &&
        ((uses_a  && rA == id_ex_rd) ||
         (uses_b  && rB == id_ex_rd) ||
         (uses_rd && rD == id_ex_rd));

    wire hazard_ex_wb =
        ex_wb_valid && ex_wb_regWrite && (ex_wb_rd != 0) &&
        ((uses_a  && rA == ex_wb_rd) ||
         (uses_b  && rB == ex_wb_rd) ||
         (uses_rd && rD == ex_wb_rd));

    wire stall = if_id_valid && (hazard_id_ex || hazard_ex_wb);

    wire branch_taken =
        if_id_valid && !stall &&
        ((opcode == OP_BEZ  && rdData0 == 64'd0) ||
         (opcode == OP_BNEZ && rdData0 != 64'd0));

    wire invalid_ww =
        (WW == 2'b11) &&
        (func == F_MULEU || func == F_MULOU ||
        func == F_SQEU  || func == F_SQOU);

    // Register file 
    register_file register_file_inst (
        .clk(clk),
        .reset(reset),

        // Writeback stage (WB)
        .wrEn(ex_wb_regWrite && ex_wb_valid),
        .wrAddr(ex_wb_rd),
        .wrData(wb_data),
        .wrByteEn(ex_wb_byteEn),

        // Decode stage (ID)
        .rdAddr0(rdAddr0),
        .rdData0(rdData0),
        .rdAddr1(rdAddr1),
        .rdData1(rdData1)
    );

    // Instantiate ALU and SFU
    wire [0:63] alu_result;
    wire [0:63] sfu_result;

    alu alu_inst (
        .a(id_ex_a),
        .b(id_ex_b),
        .func(id_ex_func),
        .ww(id_ex_ww),
        .result(alu_result)
    );

    sfu sfu_inst (
        .a(id_ex_a),
        .b(id_ex_b),
        .func(id_ex_func),
        .ww(id_ex_ww),
        .result(sfu_result)
    );


    // Pipeline Registers
    always @(posedge clk) begin
        if (reset) begin
            pc               <= 32'd0;
            if_id            <= 32'd0;
            id_ex_a          <= 64'd0;
            id_ex_b          <= 64'd0;
            id_ex_store_data <= 64'd0;
            id_ex_rd         <= 5'd0;
            id_ex_func       <= 6'd0;
            id_ex_ww         <= 2'd0;
            id_ex_ppp        <= 3'd0;
            id_ex_imm        <= 16'd0;
            id_ex_regWrite   <= 1'b0;
            id_ex_memRead    <= 1'b0;
            id_ex_memWrite   <= 1'b0;
            id_ex_valid      <= 1'b0;
            ex_wb_result      <= 64'd0;
            ex_wb_rd          <= 5'd0;
            ex_wb_regWrite    <= 1'b0;
            ex_wb_memRead     <= 1'b0;
            ex_wb_byteEn     <= 8'h00;
            ex_wb_valid       <= 1'b0;
            if_id_valid      <= 1'b0;
        end else begin
            pc               <= pc_d;
            if_id            <= if_id_d;
            id_ex_a          <= id_ex_a_d;
            id_ex_b          <= id_ex_b_d;
            id_ex_store_data <= id_ex_store_data_d;
            id_ex_rd         <= id_ex_rd_d;
            id_ex_func       <= id_ex_func_d;
            id_ex_ww         <= id_ex_ww_d;
            id_ex_ppp        <= id_ex_ppp_d;
            id_ex_imm        <= id_ex_imm_d;
            id_ex_regWrite   <= id_ex_regWrite_d;
            id_ex_memRead    <= id_ex_memRead_d;
            id_ex_memWrite   <= id_ex_memWrite_d;
            id_ex_valid      <= id_ex_valid_d;
            ex_wb_result      <= ex_wb_result_d;
            ex_wb_rd          <= ex_wb_rd_d;
            ex_wb_regWrite    <= ex_wb_regWrite_d;
            ex_wb_memRead     <= ex_wb_memRead_d;
            ex_wb_byteEn     <= ex_wb_byteEn_d;
            ex_wb_valid       <= ex_wb_valid_d;
            if_id_valid      <= !branch_taken;
        end 
    end

    // Combinational logic
    always @(*) begin

        //----------------------------------------------------------------------
        // IF stage
        //----------------------------------------------------------------------

        if (stall) begin
            pc_d    = pc;
            if_id_d = if_id;
        end
        else if (branch_taken) begin
            pc_d    = {16'd0, addr};
            if_id_d = 32'd0;
        end
        else begin
            pc_d    = pc + 32'd4;
            if_id_d = inst_in;
        end

        //----------------------------------------------------------------------
        // ID stage
        //----------------------------------------------------------------------

        // Default values (prevent inferred latches)
        rdAddr0           = 5'd0;
        rdAddr1           = 5'd0;

        id_ex_a_d          = 64'd0;
        id_ex_b_d          = 64'd0;
        id_ex_store_data_d = 64'd0;

        id_ex_rd_d         = 5'd0;
        id_ex_func_d       = 6'd0;
        id_ex_ww_d         = 2'd0;
        id_ex_ppp_d        = 3'd0;
        id_ex_imm_d        = 16'd0;

        id_ex_regWrite_d   = 1'b0;
        id_ex_memRead_d    = 1'b0;
        id_ex_memWrite_d   = 1'b0;
        id_ex_valid_d      = 1'b0;

        if (if_id_valid) begin
            case (opcode)
                // Arithmetic / logical instructions
                OP_RTYPE: begin
                    if (ppp <= 3'b100 && func >= 6'd1 && func <= 6'd18 && !invalid_ww) begin
                        rdAddr0 = rA;
                        rdAddr1 = rB;

                        id_ex_a_d        = rdData0;
                        id_ex_b_d        = rdData1;
                        id_ex_rd_d       = rD;
                        id_ex_func_d     = func;
                        id_ex_ww_d       = WW;
                        id_ex_ppp_d      = ppp;

                        id_ex_regWrite_d = 1'b1;
                        id_ex_valid_d    = 1'b1;
                    end
                end

                // Load: rD = MEM[addr]
                OP_LD: begin
                    id_ex_rd_d       = rD;
                    id_ex_imm_d      = addr;

                    id_ex_regWrite_d = 1'b1;
                    id_ex_memRead_d  = 1'b1;
                    id_ex_valid_d    = 1'b1;
                end

                // Store: MEM[addr] = rD
                OP_SD: begin
                    rdAddr0 = rD;

                    id_ex_store_data_d = rdData0;
                    id_ex_imm_d        = addr;

                    id_ex_memWrite_d   = 1'b1;
                    id_ex_valid_d      = 1'b1;
                end

                // Branches
                OP_BEZ, OP_BNEZ: begin
                    rdAddr0 = rD;
                end

                // No operation
                OP_NOP: begin
                end

                default: begin
                end
            endcase
        end

        // Add a bubble if stall
        if (stall) begin
            id_ex_valid_d    = 1'b0;
        end
        
        //------------------------------------------------------------------
        // EX/MEM stage
        //------------------------------------------------------------------

        ex_wb_result_d = 64'd0;
        ex_wb_rd_d = 5'd0;
        ex_wb_regWrite_d = 1'b0;
        ex_wb_memRead_d = 1'b0;
        ex_wb_byteEn_d = 8'h00;
        ex_wb_valid_d = 1'b0;

        addr_out_i = 32'd0;
        memEn_i    = 1'b0;
        memWrEn_i  = 1'b0;
        d_out_i    = 64'd0;

        if (id_ex_valid) begin
            ex_wb_rd_d = id_ex_rd;
            ex_wb_regWrite_d = id_ex_regWrite;
            ex_wb_memRead_d = id_ex_memRead;
            ex_wb_valid_d = id_ex_valid;

            if (id_ex_memRead) begin
                // Load: memory data becomes available after clock edge
                addr_out_i = {16'd0, id_ex_imm};
                memEn_i    = 1'b1;
                ex_wb_byteEn_d = 8'hFF;
            end

            else if (id_ex_memWrite) begin
                // Store: write register value into memory
                addr_out_i = {16'd0, id_ex_imm};
                memEn_i    = 1'b1;
                memWrEn_i  = 1'b1;
                d_out_i    = id_ex_store_data;
            end

            else if (id_ex_regWrite) begin
                // R-type: select ALU or SFU
                case (id_ex_ppp)
                    3'b000: ex_wb_byteEn_d = 8'hFF;
                    3'b001: ex_wb_byteEn_d = 8'hF0;
                    3'b010: ex_wb_byteEn_d = 8'h0F;
                    3'b011: ex_wb_byteEn_d = 8'hAA;
                    3'b100: ex_wb_byteEn_d = 8'h55;
                    default: ex_wb_byteEn_d = 8'h00;
                endcase

                if (id_ex_func == F_DIV ||
                    id_ex_func == F_MOD ||
                    id_ex_func == F_SQRT)
                ex_wb_result_d = sfu_result;
                else
                    ex_wb_result_d = alu_result;
            end
        end


        //------------------------------------------------------------------
        // WB stage
        //------------------------------------------------------------------

        wb_data = ex_wb_memRead ? d_in : ex_wb_result;

    end
    
endmodule
