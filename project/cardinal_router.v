//---------------------------------------------------------------------
// This file includes the cardinal router module
//---------------------------------------------------------------------

`include "packet_def.v"

module cardinal_router (
    input      clk,
    input      reset,
    output reg polarity,

    // North input 
    input             nsi,
    input      [63:0] ndi,
    output reg        nri,

    // North output 
    input             nro,
    output reg        nso,
    output reg [63:0] ndo,

    // East input 
    input             esi,
    input      [63:0] edi,
    output reg        eri,

    // East output 
    input             ero,
    output reg        eso,
    output reg [63:0] edo,

    // South input 
    input             ssi,
    input      [63:0] sdi,
    output reg        sri,

    // South output 
    input             sro,
    output reg        sso,
    output reg [63:0] sdo,

    // West input 
    input             wsi,
    input      [63:0] wdi,
    output reg        wri,

    // West output 
    input             wro,
    output reg        wso,
    output reg [63:0] wdo,

    // Processing element input channel
    input             pesi,
    input      [63:0] pedi,
    output reg        peri,

    // Processing element output channel
    input             pero,
    output reg        peso,
    output reg [63:0] pedo

);

endmodule