//=======================================================================
// This module implements the top-level design for the 4x4 mesh.
//=======================================================================

module gold_mesh_4x4 #(parameter PACKET_SIZE = 64) (
    input                      clk,
    input                      reset,

    // Node 0
    input                      node0_pesi,
    output                     node0_peri,
    input  [PACKET_SIZE-1:0]   node0_pedi,
    output                     node0_peso,
    input                      node0_pero,
    output [PACKET_SIZE-1:0]   node0_pedo,
    output                     node0_polarity,

    // Node 1
    input                      node1_pesi,
    output                     node1_peri,
    input  [PACKET_SIZE-1:0]   node1_pedi,
    output                     node1_peso,
    input                      node1_pero,
    output [PACKET_SIZE-1:0]   node1_pedo,
    output                     node1_polarity,

    // Node 2
    input                      node2_pesi,
    output                     node2_peri,
    input  [PACKET_SIZE-1:0]   node2_pedi,
    output                     node2_peso,
    input                      node2_pero,
    output [PACKET_SIZE-1:0]   node2_pedo,
    output                     node2_polarity,

    // Node 3
    input                      node3_pesi,
    output                     node3_peri,
    input  [PACKET_SIZE-1:0]   node3_pedi,
    output                     node3_peso,
    input                      node3_pero,
    output [PACKET_SIZE-1:0]   node3_pedo,
    output                     node3_polarity,

    // Node 4
    input                      node4_pesi,
    output                     node4_peri,
    input  [PACKET_SIZE-1:0]   node4_pedi,
    output                     node4_peso,
    input                      node4_pero,
    output [PACKET_SIZE-1:0]   node4_pedo,
    output                     node4_polarity,

    // Node 5
    input                      node5_pesi,
    output                     node5_peri,
    input  [PACKET_SIZE-1:0]   node5_pedi,
    output                     node5_peso,
    input                      node5_pero,
    output [PACKET_SIZE-1:0]   node5_pedo,
    output                     node5_polarity,

    // Node 6
    input                      node6_pesi,
    output                     node6_peri,
    input  [PACKET_SIZE-1:0]   node6_pedi,
    output                     node6_peso,
    input                      node6_pero,
    output [PACKET_SIZE-1:0]   node6_pedo,
    output                     node6_polarity,

    // Node 7
    input                      node7_pesi,
    output                     node7_peri,
    input  [PACKET_SIZE-1:0]   node7_pedi,
    output                     node7_peso,
    input                      node7_pero,
    output [PACKET_SIZE-1:0]   node7_pedo,
    output                     node7_polarity,

    // Node 8
    input                      node8_pesi,
    output                     node8_peri,
    input  [PACKET_SIZE-1:0]   node8_pedi,
    output                     node8_peso,
    input                      node8_pero,
    output [PACKET_SIZE-1:0]   node8_pedo,
    output                     node8_polarity,

    // Node 9
    input                      node9_pesi,
    output                     node9_peri,
    input  [PACKET_SIZE-1:0]   node9_pedi,
    output                     node9_peso,
    input                      node9_pero,
    output [PACKET_SIZE-1:0]   node9_pedo,
    output                     node9_polarity,

    // Node 10
    input                      node10_pesi,
    output                     node10_peri,
    input  [PACKET_SIZE-1:0]   node10_pedi,
    output                     node10_peso,
    input                      node10_pero,
    output [PACKET_SIZE-1:0]   node10_pedo,
    output                     node10_polarity,

    // Node 11
    input                      node11_pesi,
    output                     node11_peri,
    input  [PACKET_SIZE-1:0]   node11_pedi,
    output                     node11_peso,
    input                      node11_pero,
    output [PACKET_SIZE-1:0]   node11_pedo,
    output                     node11_polarity,

    // Node 12
    input                      node12_pesi,
    output                     node12_peri,
    input  [PACKET_SIZE-1:0]   node12_pedi,
    output                     node12_peso,
    input                      node12_pero,
    output [PACKET_SIZE-1:0]   node12_pedo,
    output                     node12_polarity,

    // Node 13
    input                      node13_pesi,
    output                     node13_peri,
    input  [PACKET_SIZE-1:0]   node13_pedi,
    output                     node13_peso,
    input                      node13_pero,
    output [PACKET_SIZE-1:0]   node13_pedo,
    output                     node13_polarity,

    // Node 14
    input                      node14_pesi,
    output                     node14_peri,
    input  [PACKET_SIZE-1:0]   node14_pedi,
    output                     node14_peso,
    input                      node14_pero,
    output [PACKET_SIZE-1:0]   node14_pedo,
    output                     node14_polarity,

    // Node 15
    input                      node15_pesi,
    output                     node15_peri,
    input  [PACKET_SIZE-1:0]   node15_pedi,
    output                     node15_peso,
    input                      node15_pero,
    output [PACKET_SIZE-1:0]   node15_pedo,
    output                     node15_polarity
);  

    //=======================================================================
    // Generate 4x4 mesh
    //=======================================================================

    wire        nsi[0:15], esi[0:15], ssi[0:15], wsi[0:15];   
    wire [63:0] ndi[0:15], edi[0:15], sdi[0:15], wdi[0:15];
    wire        nri[0:15], eri[0:15], sri[0:15], wri[0:15];  

    wire        nro[0:15], ero[0:15], sro[0:15], wro[0:15];
    wire        nso[0:15], eso[0:15], sso[0:15], wso[0:15];
    wire [63:0] ndo[0:15], edo[0:15], sdo[0:15], wdo[0:15];


    wire        pe_si[0:15], pe_ri[0:15], pe_so[0:15], pe_ro[0:15];
    wire [63:0] pe_di[0:15], pe_do[0:15];
    wire        pol[0:15];


    // Map PE and polarity nets (no edgees needed to consider)

    // Node 0
    assign pe_si[0]         = node0_pesi;
    assign node0_peri       = pe_ri[0];
    assign pe_di[0]         = node0_pedi;
    assign node0_peso       = pe_so[0];
    assign pe_ro[0]         = node0_pero;
    assign node0_pedo       = pe_do[0];
    assign node0_polarity   = pol[0];

    // Node 1
    assign pe_si[1]         = node1_pesi;
    assign node1_peri       = pe_ri[1];
    assign pe_di[1]         = node1_pedi;
    assign node1_peso       = pe_so[1];
    assign pe_ro[1]         = node1_pero;
    assign node1_pedo       = pe_do[1];
    assign node1_polarity   = pol[1];

    // Node 2
    assign pe_si[2]         = node2_pesi;
    assign node2_peri       = pe_ri[2];
    assign pe_di[2]         = node2_pedi;
    assign node2_peso       = pe_so[2];
    assign pe_ro[2]         = node2_pero;
    assign node2_pedo       = pe_do[2];
    assign node2_polarity   = pol[2];

    // Node 3
    assign pe_si[3]         = node3_pesi;
    assign node3_peri       = pe_ri[3];
    assign pe_di[3]         = node3_pedi;
    assign node3_peso       = pe_so[3];
    assign pe_ro[3]         = node3_pero;
    assign node3_pedo       = pe_do[3];
    assign node3_polarity   = pol[3];

    // Node 4
    assign pe_si[4]         = node4_pesi;
    assign node4_peri       = pe_ri[4];
    assign pe_di[4]         = node4_pedi;
    assign node4_peso       = pe_so[4];
    assign pe_ro[4]         = node4_pero;
    assign node4_pedo       = pe_do[4];
    assign node4_polarity   = pol[4];

    // Node 5
    assign pe_si[5]         = node5_pesi;
    assign node5_peri       = pe_ri[5];
    assign pe_di[5]         = node5_pedi;
    assign node5_peso       = pe_so[5];
    assign pe_ro[5]         = node5_pero;
    assign node5_pedo       = pe_do[5];
    assign node5_polarity   = pol[5];

    // Node 6
    assign pe_si[6]         = node6_pesi;
    assign node6_peri       = pe_ri[6];
    assign pe_di[6]         = node6_pedi;
    assign node6_peso       = pe_so[6];
    assign pe_ro[6]         = node6_pero;
    assign node6_pedo       = pe_do[6];
    assign node6_polarity   = pol[6];

    // Node 7
    assign pe_si[7]         = node7_pesi;
    assign node7_peri       = pe_ri[7];
    assign pe_di[7]         = node7_pedi;
    assign node7_peso       = pe_so[7];
    assign pe_ro[7]         = node7_pero;
    assign node7_pedo       = pe_do[7];
    assign node7_polarity   = pol[7];

    // Node 8
    assign pe_si[8]         = node8_pesi;
    assign node8_peri       = pe_ri[8];
    assign pe_di[8]         = node8_pedi;
    assign node8_peso       = pe_so[8];
    assign pe_ro[8]         = node8_pero;
    assign node8_pedo       = pe_do[8];
    assign node8_polarity   = pol[8];

    // Node 9
    assign pe_si[9]         = node9_pesi;
    assign node9_peri       = pe_ri[9];
    assign pe_di[9]         = node9_pedi;
    assign node9_peso       = pe_so[9];
    assign pe_ro[9]         = node9_pero;
    assign node9_pedo       = pe_do[9];
    assign node9_polarity   = pol[9];

    // Node 10
    assign pe_si[10]        = node10_pesi;
    assign node10_peri      = pe_ri[10];
    assign pe_di[10]        = node10_pedi;
    assign node10_peso      = pe_so[10];
    assign pe_ro[10]        = node10_pero;
    assign node10_pedo      = pe_do[10];
    assign node10_polarity  = pol[10];

    // Node 11
    assign pe_si[11]        = node11_pesi;
    assign node11_peri      = pe_ri[11];
    assign pe_di[11]        = node11_pedi;
    assign node11_peso      = pe_so[11];
    assign pe_ro[11]        = node11_pero;
    assign node11_pedo      = pe_do[11];
    assign node11_polarity  = pol[11];

    // Node 12
    assign pe_si[12]        = node12_pesi;
    assign node12_peri      = pe_ri[12];
    assign pe_di[12]        = node12_pedi;
    assign node12_peso      = pe_so[12];
    assign pe_ro[12]        = node12_pero;
    assign node12_pedo      = pe_do[12];
    assign node12_polarity  = pol[12];

    // Node 13
    assign pe_si[13]        = node13_pesi;
    assign node13_peri      = pe_ri[13];
    assign pe_di[13]        = node13_pedi;
    assign node13_peso      = pe_so[13];
    assign pe_ro[13]        = node13_pero;
    assign node13_pedo      = pe_do[13];
    assign node13_polarity  = pol[13];

    // Node 14
    assign pe_si[14]        = node14_pesi;
    assign node14_peri      = pe_ri[14];
    assign pe_di[14]        = node14_pedi;
    assign node14_peso      = pe_so[14];
    assign pe_ro[14]        = node14_pero;
    assign node14_pedo      = pe_do[14];
    assign node14_polarity  = pol[14];

    // Node 15
    assign pe_si[15]        = node15_pesi;
    assign node15_peri      = pe_ri[15];
    assign pe_di[15]        = node15_pedi;
    assign node15_peso      = pe_so[15];
    assign pe_ro[15]        = node15_pero;
    assign node15_pedo      = pe_do[15];
    assign node15_polarity  = pol[15];

    genvar x, y;

    generate
        for (x = 0; x < 4; x = x + 1) begin : genrow
            for (y = 0; y < 4; y = y + 1) begin: gencol
                // Handle west edge
                if (x == 0) begin
                    assign wsi[x + 4*y] = 1'b0;
                    assign wdi[x + 4*y] = 64'b0;
                    assign wro[x + 4*y] = 1'b0;
                end else begin
                    assign wsi[x + 4*y] = eso[(x + 4*y) - 1];
                    assign wdi[x + 4*y] = edo[(x + 4*y) - 1];
                    assign wro[x + 4*y] = eri[(x + 4*y) - 1];
                end

                // East edge
                if (x == 3) begin
                    assign esi[x + 4*y] = 1'b0;
                    assign edi[x + 4*y] = 64'b0;
                    assign ero[x + 4*y] = 1'b0;
                end else begin
                    assign esi[x + 4*y] = wso[(x + 4*y) + 1];
                    assign edi[x + 4*y] = wdo[(x + 4*y) + 1];
                    assign ero[x + 4*y] = wri[(x + 4*y) + 1];
                end

                // North edge
                if (y == 0) begin
                    assign nsi[x + 4*y] = 1'b0;
                    assign ndi[x + 4*y] = 64'b0;
                    assign nro[x + 4*y] = 1'b0;
                end else begin
                    assign nsi[x + 4*y] = sso[(x + 4*y) - 4];
                    assign ndi[x + 4*y] = sdo[(x + 4*y) - 4];
                    assign nro[x + 4*y] = sri[(x + 4*y) - 4];
                end

                // South edge
                if (y == 3) begin
                    assign ssi[x + 4*y] = 1'b0;
                    assign sdi[x + 4*y] = 64'b0;
                    assign sro[x + 4*y] = 1'b0;
                end else begin
                    assign ssi[x + 4*y] = nso[(x + 4*y) + 4];
                    assign sdi[x + 4*y] = ndo[(x + 4*y) + 4];
                    assign sro[x + 4*y] = nri[(x + 4*y) + 4];
                end

                // Instantiate the routers

                gold_router #(.X(x), .Y(y)) gold_router_inst (
                    .clk      (clk),
                    .reset    (reset),
                    .polarity (pol[x + 4*y]),

                    // North
                    .nsi      (nsi[x + 4*y]),
                    .ndi      (ndi[x + 4*y]),
                    .nri      (nri[x + 4*y]),
                    .nro      (nro[x + 4*y]),
                    .nso      (nso[x + 4*y]),
                    .ndo      (ndo[x + 4*y]),

                    // East
                    .esi      (esi[x + 4*y]),
                    .edi      (edi[x + 4*y]),
                    .eri      (eri[x + 4*y]),
                    .ero      (ero[x + 4*y]),
                    .eso      (eso[x + 4*y]),
                    .edo      (edo[x + 4*y]),

                    // South
                    .ssi      (ssi[x + 4*y]),
                    .sdi      (sdi[x + 4*y]),
                    .sri      (sri[x + 4*y]),
                    .sro      (sro[x + 4*y]),
                    .sso      (sso[x + 4*y]),
                    .sdo      (sdo[x + 4*y]),

                    // West
                    .wsi      (wsi[x + 4*y]),
                    .wdi      (wdi[x + 4*y]),
                    .wri      (wri[x + 4*y]),
                    .wro      (wro[x + 4*y]),
                    .wso      (wso[x + 4*y]),
                    .wdo      (wdo[x + 4*y]),

                    // Processing element
                    .pesi     (pe_si[x + 4*y]),
                    .pedi     (pe_di[x + 4*y]),
                    .peri     (pe_ri[x + 4*y]),
                    .pero     (pe_ro[x + 4*y]),
                    .peso     (pe_so[x + 4*y]),
                    .pedo     (pe_do[x + 4*y])
                );

            end
        end
    endgenerate


endmodule