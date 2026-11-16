////////////////////////////////////////////////////////////////////////////
// Cardinal processor - top-level module (EE577B Phase 3)
//
// Start from your Phase 2 processor and add the NIC interface described in
// the NIC specification ("Interfacing with Processor"). Keep the module
// name and the port list below as provided: the Phase 2 ports plus the
// five NIC ports (Figure 1 of the handout). They are what the cardinal_cmp
// template connects.
//
// NIC address decoding (memAddr = {16'b0, immediate} = addr_out):
//   * memAddr[16] and memAddr[17] both 1 (immediate[0:1] == 2'b11): the
//     load or store accesses the NIC. memAddr[30:31] (immediate[14:15])
//     selects the NIC register (addr_nic). Assert nicEn, and nicWrEn for a
//     store; memEn and memWrEn must stay 0.
//   * Otherwise it is a data memory access, as in Phase 2 (only
//     memAddr[24:31] are used by the memory model); nicEn stays 0.
//
// NIC timing (same as the data memory): addr_nic, din_nic, nicEn and
// nicWrEn are sampled at a rising clock edge; a store is written at that
// edge, and the register selected by a load appears on dout_nic after that
// edge, during the following cycle. A load from the NIC therefore takes
// its data from dout_nic where a load from the data memory takes d_in.
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
    output [0:63] d_out,      // store data to the data memory
    output [0:1]  addr_nic,   // NIC register address (memAddr[30:31])
    output [0:63] din_nic,    // store data to the NIC (NIC port d_in)
    input  [0:63] dout_nic,   // load data from the NIC (NIC port d_out)
    output        nicEn,      // NIC enable (load or store to a NIC address)
    output        nicWrEn     // NIC write enable (store to a NIC address)
);

    // ---------------------------------------------------------------------
    // TODO: your Phase 2 design plus the NIC interface. Remove these
    // placeholder assignments when you drive the outputs from your pipeline.
    // ---------------------------------------------------------------------
    assign pc_out   = 32'd0;
    assign addr_out = 32'd0;
    assign memEn    = 1'b0;
    assign memWrEn  = 1'b0;
    assign d_out    = 64'd0;
    assign addr_nic = 2'd0;
    assign din_nic  = 64'd0;
    assign nicEn    = 1'b0;
    assign nicWrEn  = 1'b0;

endmodule
