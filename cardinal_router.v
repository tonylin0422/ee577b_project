//=======================================================================
// This module implements the top-level design for a single router.
// Each router has 5 input ports and 5 output ports.
//=======================================================================

module cardinal_router #(
    parameter X = 0,
    parameter Y = 0
)(
    input clk,
    input reset,
    output reg polarity,

    // North input
    input             nsi,
    input      [63:0] ndi,
    output            nri,

    // North output
    input             nro,
    output            nso,
    output     [63:0] ndo,

    // East input
    input             esi,
    input      [63:0] edi,
    output            eri,

    // East output
    input             ero,
    output            eso,
    output     [63:0] edo,

    // South input
    input             ssi,
    input      [63:0] sdi,
    output            sri,

    // South output
    input             sro,
    output            sso,
    output     [63:0] sdo,

    // West input
    input             wsi,
    input      [63:0] wdi,
    output            wri,

    // West output
    input             wro,
    output            wso,
    output     [63:0] wdo,

    // Processing element input channel
    input             pesi,
    input      [63:0] pedi,
    output            peri,

    // Processing element output channel
    input             pero,
    output            peso,
    output     [63:0] pedo
);

    localparam NORTH = 0;
    localparam EAST  = 1;
    localparam SOUTH = 2;
    localparam WEST  = 3;
    localparam PE    = 4;

    //=======================================================================
    // Polarity
    //=======================================================================
    always @(posedge clk) begin
        if (reset)
            polarity <= 1'b0;
        else
            polarity <= ~polarity;
    end

    //=======================================================================
    // Internal Wires
    //=======================================================================

    // Input controller packet outputs
    wire [63:0] n_packet, e_packet, s_packet, w_packet, pe_packet;

    // Input controller requests
    wire [4:0] n_request, e_request, s_request, w_request, pe_request;

    // Grants returned to input controllers
    wire [4:0] n_grant, e_grant, s_grant, w_grant, pe_grant;

    //=======================================================================
    // Input Controllers
    //=======================================================================

    input_controller #(.X(X), .Y(Y)) n_input_controller_inst (
        .clk        (clk),
        .reset      (reset),
        .polarity   (polarity),
        .si         (nsi),
        .di         (ndi),
        .ri         (nri),
        .grant      (n_grant),
        .packet_out (n_packet),
        .request    (n_request)
    );

    input_controller #(.X(X), .Y(Y)) e_input_controller_inst (
        .clk        (clk),
        .reset      (reset),
        .polarity   (polarity),
        .si         (esi),
        .di         (edi),
        .ri         (eri),
        .grant      (e_grant),
        .packet_out (e_packet),
        .request    (e_request)
    );

    input_controller #(.X(X), .Y(Y)) s_input_controller_inst (
        .clk        (clk),
        .reset      (reset),
        .polarity   (polarity),
        .si         (ssi),
        .di         (sdi),
        .ri         (sri),
        .grant      (s_grant),
        .packet_out (s_packet),
        .request    (s_request)
    );

    input_controller #(.X(X), .Y(Y)) w_input_controller_inst (
        .clk        (clk),
        .reset      (reset),
        .polarity   (polarity),
        .si         (wsi),
        .di         (wdi),
        .ri         (wri),
        .grant      (w_grant),
        .packet_out (w_packet),
        .request    (w_request)
    );

    input_controller #(.X(X), .Y(Y)) pe_input_controller_inst (
        .clk        (clk),
        .reset      (reset),
        .polarity   (polarity),
        .si         (pesi),
        .di         (pedi),
        .ri         (peri),
        .grant      (pe_grant),
        .packet_out (pe_packet),
        .request    (pe_request)
    );

    //=======================================================================
    // Output Controllers
    //=======================================================================

    // North output: East, South, West, PE
    output_controller n_output_controller_inst (
        .clk        (clk),
        .reset      (reset),
        .polarity   (polarity),
        .request    ({pe_request[NORTH], w_request[NORTH],
                      s_request[NORTH],  e_request[NORTH]}),
        .di0        (e_packet),
        .di1        (s_packet),
        .di2        (w_packet),
        .di3        (pe_packet),
        .grant      ({pe_grant[NORTH], w_grant[NORTH],
                      s_grant[NORTH],  e_grant[NORTH]}),
        .ro         (nro),
        .so         (nso),
        .data_out   (ndo)
    );

    // East output: North, South, West, PE
    output_controller e_output_controller_inst (
        .clk        (clk),
        .reset      (reset),
        .polarity   (polarity),
        .request    ({pe_request[EAST], w_request[EAST],
                      s_request[EAST],  n_request[EAST]}),
        .di0        (n_packet),
        .di1        (s_packet),
        .di2        (w_packet),
        .di3        (pe_packet),
        .grant      ({pe_grant[EAST], w_grant[EAST],
                      s_grant[EAST],  n_grant[EAST]}),
        .ro         (ero),
        .so         (eso),
        .data_out   (edo)
    );

    // South output: North, East, West, PE
    output_controller s_output_controller_inst (
        .clk        (clk),
        .reset      (reset),
        .polarity   (polarity),
        .request    ({pe_request[SOUTH], w_request[SOUTH],
                      e_request[SOUTH],  n_request[SOUTH]}),
        .di0        (n_packet),
        .di1        (e_packet),
        .di2        (w_packet),
        .di3        (pe_packet),
        .grant      ({pe_grant[SOUTH], w_grant[SOUTH],
                      e_grant[SOUTH],  n_grant[SOUTH]}),
        .ro         (sro),
        .so         (sso),
        .data_out   (sdo)
    );

    // West output: North, East, South, PE
    output_controller w_output_controller_inst (
        .clk        (clk),
        .reset      (reset),
        .polarity   (polarity),
        .request    ({pe_request[WEST], s_request[WEST],
                      e_request[WEST],  n_request[WEST]}),
        .di0        (n_packet),
        .di1        (e_packet),
        .di2        (s_packet),
        .di3        (pe_packet),
        .grant      ({pe_grant[WEST], s_grant[WEST],
                      e_grant[WEST],  n_grant[WEST]}),
        .ro         (wro),
        .so         (wso),
        .data_out   (wdo)
    );

    // PE output: North, East, South, West
    output_controller pe_output_controller_inst (
        .clk        (clk),
        .reset      (reset),
        .polarity   (polarity),
        .request    ({w_request[PE], s_request[PE],
                      e_request[PE], n_request[PE]}),
        .di0        (n_packet),
        .di1        (e_packet),
        .di2        (s_packet),
        .di3        (w_packet),
        .grant      ({w_grant[PE], s_grant[PE],
                      e_grant[PE], n_grant[PE]}),
        .ro         (pero),
        .so         (peso),
        .data_out   (pedo)
    );

    // Unused self-direction grants
    assign n_grant[NORTH]  = 1'b0;
    assign e_grant[EAST]   = 1'b0;
    assign s_grant[SOUTH]  = 1'b0;
    assign w_grant[WEST]   = 1'b0;
    assign pe_grant[PE]    = 1'b0;

endmodule
