////////////////////////////////////////////////////////////////////////////
// 4x4 Cardinal mesh - top-level module template (EE577B Phase 3)
//
// PHASE3_MESH_TEMPLATE: REPLACE THIS FILE WITH YOUR PROJECT 1 MESH.
//
// This file only fixes the interface of the mesh that cardinal_cmp.v
// instantiates: the module name gold_mesh_4x4, the parameter PACKET_SIZE
// and the port names of the Project 1 rules (section 2). Copy your Project
// 1 mesh (gold_mesh_4x4 and every submodule it uses) into design/ in place
// of this file; keep this header exactly. Node N is the router at mesh
// coordinate (x = N % 4, y = N / 4); (0, 0) is the upper-left corner.
//
// Port semantics (Project 1 rules, section 5; the PE side is the NIC):
//   nodeN_pesi/pedi   packet from NIC N (net_so/net_do), captured at a
//                     rising edge where pesi = 1 and peri = 1
//   nodeN_peri        the router can accept a packet of the current phase
//   nodeN_peso/pedo   packet to NIC N (net_si/net_di), taken at a rising
//                     edge where peso = 1; peso = 0 whenever pero = 0
//   nodeN_pero        NIC N can accept a packet (net_ri)
//   nodeN_polarity    0 during reset, toggles at every rising edge
// Bit numbering is [PACKET_SIZE-1:0] as in Project 1 (bit 63 = vc bit);
// cardinal_cmp connects these buses to the NIC's [0:63] buses directly.
//
// The placeholder assignments below only let the framework elaborate
// before you add your mesh (no packet is ever delivered). The grading
// treats a submission that still contains this template as a missing
// mesh.
////////////////////////////////////////////////////////////////////////////
module gold_mesh_4x4 #(
    parameter PACKET_SIZE = 64
) (
    input clk,
    input reset,

    // Router 0: coordinate (0, 0)
    input node0_pesi, node0_pero,
    output node0_peri, node0_peso,
    input [PACKET_SIZE - 1:0] node0_pedi,
    output [PACKET_SIZE - 1:0] node0_pedo,
    output node0_polarity,

    // Router 1: coordinate (1, 0)
    input node1_pesi, node1_pero,
    output node1_peri, node1_peso,
    input [PACKET_SIZE - 1:0] node1_pedi,
    output [PACKET_SIZE - 1:0] node1_pedo,
    output node1_polarity,

    // Router 2: coordinate (2, 0)
    input node2_pesi, node2_pero,
    output node2_peri, node2_peso,
    input [PACKET_SIZE - 1:0] node2_pedi,
    output [PACKET_SIZE - 1:0] node2_pedo,
    output node2_polarity,

    // Router 3: coordinate (3, 0)
    input node3_pesi, node3_pero,
    output node3_peri, node3_peso,
    input [PACKET_SIZE - 1:0] node3_pedi,
    output [PACKET_SIZE - 1:0] node3_pedo,
    output node3_polarity,

    // Router 4: coordinate (0, 1)
    input node4_pesi, node4_pero,
    output node4_peri, node4_peso,
    input [PACKET_SIZE - 1:0] node4_pedi,
    output [PACKET_SIZE - 1:0] node4_pedo,
    output node4_polarity,

    // Router 5: coordinate (1, 1)
    input node5_pesi, node5_pero,
    output node5_peri, node5_peso,
    input [PACKET_SIZE - 1:0] node5_pedi,
    output [PACKET_SIZE - 1:0] node5_pedo,
    output node5_polarity,

    // Router 6: coordinate (2, 1)
    input node6_pesi, node6_pero,
    output node6_peri, node6_peso,
    input [PACKET_SIZE - 1:0] node6_pedi,
    output [PACKET_SIZE - 1:0] node6_pedo,
    output node6_polarity,

    // Router 7: coordinate (3, 1)
    input node7_pesi, node7_pero,
    output node7_peri, node7_peso,
    input [PACKET_SIZE - 1:0] node7_pedi,
    output [PACKET_SIZE - 1:0] node7_pedo,
    output node7_polarity,

    // Router 8: coordinate (0, 2)
    input node8_pesi, node8_pero,
    output node8_peri, node8_peso,
    input [PACKET_SIZE - 1:0] node8_pedi,
    output [PACKET_SIZE - 1:0] node8_pedo,
    output node8_polarity,

    // Router 9: coordinate (1, 2)
    input node9_pesi, node9_pero,
    output node9_peri, node9_peso,
    input [PACKET_SIZE - 1:0] node9_pedi,
    output [PACKET_SIZE - 1:0] node9_pedo,
    output node9_polarity,

    // Router 10: coordinate (2, 2)
    input node10_pesi, node10_pero,
    output node10_peri, node10_peso,
    input [PACKET_SIZE - 1:0] node10_pedi,
    output [PACKET_SIZE - 1:0] node10_pedo,
    output node10_polarity,

    // Router 11: coordinate (3, 2)
    input node11_pesi, node11_pero,
    output node11_peri, node11_peso,
    input [PACKET_SIZE - 1:0] node11_pedi,
    output [PACKET_SIZE - 1:0] node11_pedo,
    output node11_polarity,

    // Router 12: coordinate (0, 3)
    input node12_pesi, node12_pero,
    output node12_peri, node12_peso,
    input [PACKET_SIZE - 1:0] node12_pedi,
    output [PACKET_SIZE - 1:0] node12_pedo,
    output node12_polarity,

    // Router 13: coordinate (1, 3)
    input node13_pesi, node13_pero,
    output node13_peri, node13_peso,
    input [PACKET_SIZE - 1:0] node13_pedi,
    output [PACKET_SIZE - 1:0] node13_pedo,
    output node13_polarity,

    // Router 14: coordinate (2, 3)
    input node14_pesi, node14_pero,
    output node14_peri, node14_peso,
    input [PACKET_SIZE - 1:0] node14_pedi,
    output [PACKET_SIZE - 1:0] node14_pedo,
    output node14_polarity,

    // Router 15: coordinate (3, 3)
    input node15_pesi, node15_pero,
    output node15_peri, node15_peso,
    input [PACKET_SIZE - 1:0] node15_pedi,
    output [PACKET_SIZE - 1:0] node15_pedo,
    output node15_polarity
);

    // ---------------------------------------------------------------------
    // TODO: your Project 1 mesh (sixteen routers and their links). Remove
    // these placeholders when you add it.
    // ---------------------------------------------------------------------
    assign node0_peri = 1'b1; assign node0_peso = 1'b0; assign node0_pedo = {PACKET_SIZE{1'b0}}; assign node0_polarity = 1'b0;
    assign node1_peri = 1'b1; assign node1_peso = 1'b0; assign node1_pedo = {PACKET_SIZE{1'b0}}; assign node1_polarity = 1'b0;
    assign node2_peri = 1'b1; assign node2_peso = 1'b0; assign node2_pedo = {PACKET_SIZE{1'b0}}; assign node2_polarity = 1'b0;
    assign node3_peri = 1'b1; assign node3_peso = 1'b0; assign node3_pedo = {PACKET_SIZE{1'b0}}; assign node3_polarity = 1'b0;
    assign node4_peri = 1'b1; assign node4_peso = 1'b0; assign node4_pedo = {PACKET_SIZE{1'b0}}; assign node4_polarity = 1'b0;
    assign node5_peri = 1'b1; assign node5_peso = 1'b0; assign node5_pedo = {PACKET_SIZE{1'b0}}; assign node5_polarity = 1'b0;
    assign node6_peri = 1'b1; assign node6_peso = 1'b0; assign node6_pedo = {PACKET_SIZE{1'b0}}; assign node6_polarity = 1'b0;
    assign node7_peri = 1'b1; assign node7_peso = 1'b0; assign node7_pedo = {PACKET_SIZE{1'b0}}; assign node7_polarity = 1'b0;
    assign node8_peri = 1'b1; assign node8_peso = 1'b0; assign node8_pedo = {PACKET_SIZE{1'b0}}; assign node8_polarity = 1'b0;
    assign node9_peri = 1'b1; assign node9_peso = 1'b0; assign node9_pedo = {PACKET_SIZE{1'b0}}; assign node9_polarity = 1'b0;
    assign node10_peri = 1'b1; assign node10_peso = 1'b0; assign node10_pedo = {PACKET_SIZE{1'b0}}; assign node10_polarity = 1'b0;
    assign node11_peri = 1'b1; assign node11_peso = 1'b0; assign node11_pedo = {PACKET_SIZE{1'b0}}; assign node11_polarity = 1'b0;
    assign node12_peri = 1'b1; assign node12_peso = 1'b0; assign node12_pedo = {PACKET_SIZE{1'b0}}; assign node12_polarity = 1'b0;
    assign node13_peri = 1'b1; assign node13_peso = 1'b0; assign node13_pedo = {PACKET_SIZE{1'b0}}; assign node13_polarity = 1'b0;
    assign node14_peri = 1'b1; assign node14_peso = 1'b0; assign node14_pedo = {PACKET_SIZE{1'b0}}; assign node14_polarity = 1'b0;
    assign node15_peri = 1'b1; assign node15_peso = 1'b0; assign node15_pedo = {PACKET_SIZE{1'b0}}; assign node15_polarity = 1'b0;

endmodule
