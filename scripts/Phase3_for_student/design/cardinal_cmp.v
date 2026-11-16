////////////////////////////////////////////////////////////////////////////
// Cardinal 16-node chip multiprocessor - top-level module (EE577B Phase 3)
//
// DO NOT CHANGE THE MODULE NAME OR THE PORT LIST BELOW.
// The grading testbench instantiates cardinal_cmp by these exact port
// names: the memory interface of every node (N = 0..15), plus clk and
// reset. If the module name, a port name, a direction or a width differs,
// the elaboration step (ncelab) stops with an error.
//
// Integrate sixteen Cardinal processors, sixteen Cardinal NICs and your
// 4x4 Cardinal mesh of Project 1 (module gold_mesh_4x4 with the Project 1
// ports: replace the port-only template design/gold_mesh_4x4.v with your
// mesh and all of its submodules). Node N is the processor and
// the NIC connected to the mesh port nodeN_* at coordinate
// (x = N % 4, y = N / 4). The instruction and data memories are simulation
// models in the testbench; each node's memory ports come out of this
// module. The NIC signals (nodeN_addr_nic, nodeN_din_nic, nodeN_dout_nic,
// nodeN_nicEn, nodeN_nicWrEn) are internal wires between the processor and
// the NIC of each node; the testbench does not connect them.
//
// NIC <-> mesh connections for node N (the mesh ports are [63:0], the NIC
// ports [0:63]; connecting them is fine, bit 63 of the mesh is bit 0 of
// the NIC):
//   nic.net_so -> mesh.nodeN_pesi      nic.net_do -> mesh.nodeN_pedi
//   nic.net_ro <- mesh.nodeN_peri      nic.net_si <- mesh.nodeN_peso
//   nic.net_di <- mesh.nodeN_pedo      nic.net_ri -> mesh.nodeN_pero
//   nic.net_polarity <- mesh.nodeN_polarity
////////////////////////////////////////////////////////////////////////////
module cardinal_cmp (
    input         clk,
    input         reset,
    input  [0:31] node0_inst_in,
    input  [0:63] node0_d_in,
    output [0:31] node0_pc_out,
    output [0:63] node0_d_out,
    output [0:31] node0_addr_out,
    output        node0_memWrEn,
    output        node0_memEn,
    input  [0:31] node1_inst_in,
    input  [0:63] node1_d_in,
    output [0:31] node1_pc_out,
    output [0:63] node1_d_out,
    output [0:31] node1_addr_out,
    output        node1_memWrEn,
    output        node1_memEn,
    input  [0:31] node2_inst_in,
    input  [0:63] node2_d_in,
    output [0:31] node2_pc_out,
    output [0:63] node2_d_out,
    output [0:31] node2_addr_out,
    output        node2_memWrEn,
    output        node2_memEn,
    input  [0:31] node3_inst_in,
    input  [0:63] node3_d_in,
    output [0:31] node3_pc_out,
    output [0:63] node3_d_out,
    output [0:31] node3_addr_out,
    output        node3_memWrEn,
    output        node3_memEn,
    input  [0:31] node4_inst_in,
    input  [0:63] node4_d_in,
    output [0:31] node4_pc_out,
    output [0:63] node4_d_out,
    output [0:31] node4_addr_out,
    output        node4_memWrEn,
    output        node4_memEn,
    input  [0:31] node5_inst_in,
    input  [0:63] node5_d_in,
    output [0:31] node5_pc_out,
    output [0:63] node5_d_out,
    output [0:31] node5_addr_out,
    output        node5_memWrEn,
    output        node5_memEn,
    input  [0:31] node6_inst_in,
    input  [0:63] node6_d_in,
    output [0:31] node6_pc_out,
    output [0:63] node6_d_out,
    output [0:31] node6_addr_out,
    output        node6_memWrEn,
    output        node6_memEn,
    input  [0:31] node7_inst_in,
    input  [0:63] node7_d_in,
    output [0:31] node7_pc_out,
    output [0:63] node7_d_out,
    output [0:31] node7_addr_out,
    output        node7_memWrEn,
    output        node7_memEn,
    input  [0:31] node8_inst_in,
    input  [0:63] node8_d_in,
    output [0:31] node8_pc_out,
    output [0:63] node8_d_out,
    output [0:31] node8_addr_out,
    output        node8_memWrEn,
    output        node8_memEn,
    input  [0:31] node9_inst_in,
    input  [0:63] node9_d_in,
    output [0:31] node9_pc_out,
    output [0:63] node9_d_out,
    output [0:31] node9_addr_out,
    output        node9_memWrEn,
    output        node9_memEn,
    input  [0:31] node10_inst_in,
    input  [0:63] node10_d_in,
    output [0:31] node10_pc_out,
    output [0:63] node10_d_out,
    output [0:31] node10_addr_out,
    output        node10_memWrEn,
    output        node10_memEn,
    input  [0:31] node11_inst_in,
    input  [0:63] node11_d_in,
    output [0:31] node11_pc_out,
    output [0:63] node11_d_out,
    output [0:31] node11_addr_out,
    output        node11_memWrEn,
    output        node11_memEn,
    input  [0:31] node12_inst_in,
    input  [0:63] node12_d_in,
    output [0:31] node12_pc_out,
    output [0:63] node12_d_out,
    output [0:31] node12_addr_out,
    output        node12_memWrEn,
    output        node12_memEn,
    input  [0:31] node13_inst_in,
    input  [0:63] node13_d_in,
    output [0:31] node13_pc_out,
    output [0:63] node13_d_out,
    output [0:31] node13_addr_out,
    output        node13_memWrEn,
    output        node13_memEn,
    input  [0:31] node14_inst_in,
    input  [0:63] node14_d_in,
    output [0:31] node14_pc_out,
    output [0:63] node14_d_out,
    output [0:31] node14_addr_out,
    output        node14_memWrEn,
    output        node14_memEn,
    input  [0:31] node15_inst_in,
    input  [0:63] node15_d_in,
    output [0:31] node15_pc_out,
    output [0:63] node15_d_out,
    output [0:31] node15_addr_out,
    output        node15_memWrEn,
    output        node15_memEn
);

    // Processor <-> NIC and NIC <-> mesh wires (one set per node)
    // Node 0 (x = 0, y = 0)
    wire [0:1]  node0_addr_nic;
    wire [0:63] node0_din_nic, node0_dout_nic;
    wire        node0_nicEn, node0_nicWrEn;
    wire        node0_net_si, node0_net_ri, node0_net_so, node0_net_ro, node0_polarity;
    wire [0:63] node0_net_di, node0_net_do;
    // Node 1 (x = 1, y = 0)
    wire [0:1]  node1_addr_nic;
    wire [0:63] node1_din_nic, node1_dout_nic;
    wire        node1_nicEn, node1_nicWrEn;
    wire        node1_net_si, node1_net_ri, node1_net_so, node1_net_ro, node1_polarity;
    wire [0:63] node1_net_di, node1_net_do;
    // Node 2 (x = 2, y = 0)
    wire [0:1]  node2_addr_nic;
    wire [0:63] node2_din_nic, node2_dout_nic;
    wire        node2_nicEn, node2_nicWrEn;
    wire        node2_net_si, node2_net_ri, node2_net_so, node2_net_ro, node2_polarity;
    wire [0:63] node2_net_di, node2_net_do;
    // Node 3 (x = 3, y = 0)
    wire [0:1]  node3_addr_nic;
    wire [0:63] node3_din_nic, node3_dout_nic;
    wire        node3_nicEn, node3_nicWrEn;
    wire        node3_net_si, node3_net_ri, node3_net_so, node3_net_ro, node3_polarity;
    wire [0:63] node3_net_di, node3_net_do;
    // Node 4 (x = 0, y = 1)
    wire [0:1]  node4_addr_nic;
    wire [0:63] node4_din_nic, node4_dout_nic;
    wire        node4_nicEn, node4_nicWrEn;
    wire        node4_net_si, node4_net_ri, node4_net_so, node4_net_ro, node4_polarity;
    wire [0:63] node4_net_di, node4_net_do;
    // Node 5 (x = 1, y = 1)
    wire [0:1]  node5_addr_nic;
    wire [0:63] node5_din_nic, node5_dout_nic;
    wire        node5_nicEn, node5_nicWrEn;
    wire        node5_net_si, node5_net_ri, node5_net_so, node5_net_ro, node5_polarity;
    wire [0:63] node5_net_di, node5_net_do;
    // Node 6 (x = 2, y = 1)
    wire [0:1]  node6_addr_nic;
    wire [0:63] node6_din_nic, node6_dout_nic;
    wire        node6_nicEn, node6_nicWrEn;
    wire        node6_net_si, node6_net_ri, node6_net_so, node6_net_ro, node6_polarity;
    wire [0:63] node6_net_di, node6_net_do;
    // Node 7 (x = 3, y = 1)
    wire [0:1]  node7_addr_nic;
    wire [0:63] node7_din_nic, node7_dout_nic;
    wire        node7_nicEn, node7_nicWrEn;
    wire        node7_net_si, node7_net_ri, node7_net_so, node7_net_ro, node7_polarity;
    wire [0:63] node7_net_di, node7_net_do;
    // Node 8 (x = 0, y = 2)
    wire [0:1]  node8_addr_nic;
    wire [0:63] node8_din_nic, node8_dout_nic;
    wire        node8_nicEn, node8_nicWrEn;
    wire        node8_net_si, node8_net_ri, node8_net_so, node8_net_ro, node8_polarity;
    wire [0:63] node8_net_di, node8_net_do;
    // Node 9 (x = 1, y = 2)
    wire [0:1]  node9_addr_nic;
    wire [0:63] node9_din_nic, node9_dout_nic;
    wire        node9_nicEn, node9_nicWrEn;
    wire        node9_net_si, node9_net_ri, node9_net_so, node9_net_ro, node9_polarity;
    wire [0:63] node9_net_di, node9_net_do;
    // Node 10 (x = 2, y = 2)
    wire [0:1]  node10_addr_nic;
    wire [0:63] node10_din_nic, node10_dout_nic;
    wire        node10_nicEn, node10_nicWrEn;
    wire        node10_net_si, node10_net_ri, node10_net_so, node10_net_ro, node10_polarity;
    wire [0:63] node10_net_di, node10_net_do;
    // Node 11 (x = 3, y = 2)
    wire [0:1]  node11_addr_nic;
    wire [0:63] node11_din_nic, node11_dout_nic;
    wire        node11_nicEn, node11_nicWrEn;
    wire        node11_net_si, node11_net_ri, node11_net_so, node11_net_ro, node11_polarity;
    wire [0:63] node11_net_di, node11_net_do;
    // Node 12 (x = 0, y = 3)
    wire [0:1]  node12_addr_nic;
    wire [0:63] node12_din_nic, node12_dout_nic;
    wire        node12_nicEn, node12_nicWrEn;
    wire        node12_net_si, node12_net_ri, node12_net_so, node12_net_ro, node12_polarity;
    wire [0:63] node12_net_di, node12_net_do;
    // Node 13 (x = 1, y = 3)
    wire [0:1]  node13_addr_nic;
    wire [0:63] node13_din_nic, node13_dout_nic;
    wire        node13_nicEn, node13_nicWrEn;
    wire        node13_net_si, node13_net_ri, node13_net_so, node13_net_ro, node13_polarity;
    wire [0:63] node13_net_di, node13_net_do;
    // Node 14 (x = 2, y = 3)
    wire [0:1]  node14_addr_nic;
    wire [0:63] node14_din_nic, node14_dout_nic;
    wire        node14_nicEn, node14_nicWrEn;
    wire        node14_net_si, node14_net_ri, node14_net_so, node14_net_ro, node14_polarity;
    wire [0:63] node14_net_di, node14_net_do;
    // Node 15 (x = 3, y = 3)
    wire [0:1]  node15_addr_nic;
    wire [0:63] node15_din_nic, node15_dout_nic;
    wire        node15_nicEn, node15_nicWrEn;
    wire        node15_net_si, node15_net_ri, node15_net_so, node15_net_ro, node15_polarity;
    wire [0:63] node15_net_di, node15_net_do;

    // ---------------------------------------------------------------------
    // TODO: instantiate your processor and your NIC for every node 0..15.
    // The processor ports below are those of the design/cardinal_cpu.v
    // header; the NIC ports are fixed by the specification.
    // Node 0 is shown; repeat for nodes 1 to 15 with the nodeN_* wires.
    // ---------------------------------------------------------------------
    // cardinal_cpu cpu0 (
    //     .clk(clk), .reset(reset),
    //     .inst_in(node0_inst_in), .d_in(node0_d_in), .pc_out(node0_pc_out),
    //     .addr_out(node0_addr_out), .memEn(node0_memEn), .memWrEn(node0_memWrEn),
    //     .d_out(node0_d_out),
    //     .addr_nic(node0_addr_nic), .din_nic(node0_din_nic), .dout_nic(node0_dout_nic),
    //     .nicEn(node0_nicEn), .nicWrEn(node0_nicWrEn)
    // );
    //
    // cardinal_nic nic0 (
    //     .clk(clk), .reset(reset),
    //     .addr(node0_addr_nic), .d_in(node0_din_nic), .d_out(node0_dout_nic),
    //     .nicEn(node0_nicEn), .nicWrEn(node0_nicWrEn),
    //     .net_si(node0_net_si), .net_ri(node0_net_ri), .net_di(node0_net_di),
    //     .net_so(node0_net_so), .net_ro(node0_net_ro), .net_do(node0_net_do),
    //     .net_polarity(node0_polarity)
    // );

    // Placeholders so that the template elaborates; remove them when you
    // instantiate your processors and NICs.
    assign node0_pc_out = 32'd0; assign node0_addr_out = 32'd0; assign node0_d_out = 64'd0;
    assign node0_memEn = 1'b0;   assign node0_memWrEn = 1'b0;
    assign node0_net_so = 1'b0;  assign node0_net_do = 64'd0; assign node0_net_ri = 1'b1;
    assign node1_pc_out = 32'd0; assign node1_addr_out = 32'd0; assign node1_d_out = 64'd0;
    assign node1_memEn = 1'b0;   assign node1_memWrEn = 1'b0;
    assign node1_net_so = 1'b0;  assign node1_net_do = 64'd0; assign node1_net_ri = 1'b1;
    assign node2_pc_out = 32'd0; assign node2_addr_out = 32'd0; assign node2_d_out = 64'd0;
    assign node2_memEn = 1'b0;   assign node2_memWrEn = 1'b0;
    assign node2_net_so = 1'b0;  assign node2_net_do = 64'd0; assign node2_net_ri = 1'b1;
    assign node3_pc_out = 32'd0; assign node3_addr_out = 32'd0; assign node3_d_out = 64'd0;
    assign node3_memEn = 1'b0;   assign node3_memWrEn = 1'b0;
    assign node3_net_so = 1'b0;  assign node3_net_do = 64'd0; assign node3_net_ri = 1'b1;
    assign node4_pc_out = 32'd0; assign node4_addr_out = 32'd0; assign node4_d_out = 64'd0;
    assign node4_memEn = 1'b0;   assign node4_memWrEn = 1'b0;
    assign node4_net_so = 1'b0;  assign node4_net_do = 64'd0; assign node4_net_ri = 1'b1;
    assign node5_pc_out = 32'd0; assign node5_addr_out = 32'd0; assign node5_d_out = 64'd0;
    assign node5_memEn = 1'b0;   assign node5_memWrEn = 1'b0;
    assign node5_net_so = 1'b0;  assign node5_net_do = 64'd0; assign node5_net_ri = 1'b1;
    assign node6_pc_out = 32'd0; assign node6_addr_out = 32'd0; assign node6_d_out = 64'd0;
    assign node6_memEn = 1'b0;   assign node6_memWrEn = 1'b0;
    assign node6_net_so = 1'b0;  assign node6_net_do = 64'd0; assign node6_net_ri = 1'b1;
    assign node7_pc_out = 32'd0; assign node7_addr_out = 32'd0; assign node7_d_out = 64'd0;
    assign node7_memEn = 1'b0;   assign node7_memWrEn = 1'b0;
    assign node7_net_so = 1'b0;  assign node7_net_do = 64'd0; assign node7_net_ri = 1'b1;
    assign node8_pc_out = 32'd0; assign node8_addr_out = 32'd0; assign node8_d_out = 64'd0;
    assign node8_memEn = 1'b0;   assign node8_memWrEn = 1'b0;
    assign node8_net_so = 1'b0;  assign node8_net_do = 64'd0; assign node8_net_ri = 1'b1;
    assign node9_pc_out = 32'd0; assign node9_addr_out = 32'd0; assign node9_d_out = 64'd0;
    assign node9_memEn = 1'b0;   assign node9_memWrEn = 1'b0;
    assign node9_net_so = 1'b0;  assign node9_net_do = 64'd0; assign node9_net_ri = 1'b1;
    assign node10_pc_out = 32'd0; assign node10_addr_out = 32'd0; assign node10_d_out = 64'd0;
    assign node10_memEn = 1'b0;   assign node10_memWrEn = 1'b0;
    assign node10_net_so = 1'b0;  assign node10_net_do = 64'd0; assign node10_net_ri = 1'b1;
    assign node11_pc_out = 32'd0; assign node11_addr_out = 32'd0; assign node11_d_out = 64'd0;
    assign node11_memEn = 1'b0;   assign node11_memWrEn = 1'b0;
    assign node11_net_so = 1'b0;  assign node11_net_do = 64'd0; assign node11_net_ri = 1'b1;
    assign node12_pc_out = 32'd0; assign node12_addr_out = 32'd0; assign node12_d_out = 64'd0;
    assign node12_memEn = 1'b0;   assign node12_memWrEn = 1'b0;
    assign node12_net_so = 1'b0;  assign node12_net_do = 64'd0; assign node12_net_ri = 1'b1;
    assign node13_pc_out = 32'd0; assign node13_addr_out = 32'd0; assign node13_d_out = 64'd0;
    assign node13_memEn = 1'b0;   assign node13_memWrEn = 1'b0;
    assign node13_net_so = 1'b0;  assign node13_net_do = 64'd0; assign node13_net_ri = 1'b1;
    assign node14_pc_out = 32'd0; assign node14_addr_out = 32'd0; assign node14_d_out = 64'd0;
    assign node14_memEn = 1'b0;   assign node14_memWrEn = 1'b0;
    assign node14_net_so = 1'b0;  assign node14_net_do = 64'd0; assign node14_net_ri = 1'b1;
    assign node15_pc_out = 32'd0; assign node15_addr_out = 32'd0; assign node15_d_out = 64'd0;
    assign node15_memEn = 1'b0;   assign node15_memWrEn = 1'b0;
    assign node15_net_so = 1'b0;  assign node15_net_do = 64'd0; assign node15_net_ri = 1'b1;

    // ---------------------------------------------------------------------
    // Your 4x4 mesh of Project 1 (module gold_mesh_4x4, Project 1 ports).
    // Keep this instance as it is: it connects the NIC of node N to the
    // mesh port nodeN_*. design/gold_mesh_4x4.v is a port-only template:
    // replace it with your Project 1 mesh (same module name and ports).
    // ---------------------------------------------------------------------
    gold_mesh_4x4 #(.PACKET_SIZE(64)) mesh (
        .clk(clk), .reset(reset),

        .node0_pesi(node0_net_so), .node0_peri(node0_net_ro), .node0_pedi(node0_net_do),
        .node0_peso(node0_net_si), .node0_pero(node0_net_ri), .node0_pedo(node0_net_di),
        .node0_polarity(node0_polarity),

        .node1_pesi(node1_net_so), .node1_peri(node1_net_ro), .node1_pedi(node1_net_do),
        .node1_peso(node1_net_si), .node1_pero(node1_net_ri), .node1_pedo(node1_net_di),
        .node1_polarity(node1_polarity),

        .node2_pesi(node2_net_so), .node2_peri(node2_net_ro), .node2_pedi(node2_net_do),
        .node2_peso(node2_net_si), .node2_pero(node2_net_ri), .node2_pedo(node2_net_di),
        .node2_polarity(node2_polarity),

        .node3_pesi(node3_net_so), .node3_peri(node3_net_ro), .node3_pedi(node3_net_do),
        .node3_peso(node3_net_si), .node3_pero(node3_net_ri), .node3_pedo(node3_net_di),
        .node3_polarity(node3_polarity),

        .node4_pesi(node4_net_so), .node4_peri(node4_net_ro), .node4_pedi(node4_net_do),
        .node4_peso(node4_net_si), .node4_pero(node4_net_ri), .node4_pedo(node4_net_di),
        .node4_polarity(node4_polarity),

        .node5_pesi(node5_net_so), .node5_peri(node5_net_ro), .node5_pedi(node5_net_do),
        .node5_peso(node5_net_si), .node5_pero(node5_net_ri), .node5_pedo(node5_net_di),
        .node5_polarity(node5_polarity),

        .node6_pesi(node6_net_so), .node6_peri(node6_net_ro), .node6_pedi(node6_net_do),
        .node6_peso(node6_net_si), .node6_pero(node6_net_ri), .node6_pedo(node6_net_di),
        .node6_polarity(node6_polarity),

        .node7_pesi(node7_net_so), .node7_peri(node7_net_ro), .node7_pedi(node7_net_do),
        .node7_peso(node7_net_si), .node7_pero(node7_net_ri), .node7_pedo(node7_net_di),
        .node7_polarity(node7_polarity),

        .node8_pesi(node8_net_so), .node8_peri(node8_net_ro), .node8_pedi(node8_net_do),
        .node8_peso(node8_net_si), .node8_pero(node8_net_ri), .node8_pedo(node8_net_di),
        .node8_polarity(node8_polarity),

        .node9_pesi(node9_net_so), .node9_peri(node9_net_ro), .node9_pedi(node9_net_do),
        .node9_peso(node9_net_si), .node9_pero(node9_net_ri), .node9_pedo(node9_net_di),
        .node9_polarity(node9_polarity),

        .node10_pesi(node10_net_so), .node10_peri(node10_net_ro), .node10_pedi(node10_net_do),
        .node10_peso(node10_net_si), .node10_pero(node10_net_ri), .node10_pedo(node10_net_di),
        .node10_polarity(node10_polarity),

        .node11_pesi(node11_net_so), .node11_peri(node11_net_ro), .node11_pedi(node11_net_do),
        .node11_peso(node11_net_si), .node11_pero(node11_net_ri), .node11_pedo(node11_net_di),
        .node11_polarity(node11_polarity),

        .node12_pesi(node12_net_so), .node12_peri(node12_net_ro), .node12_pedi(node12_net_do),
        .node12_peso(node12_net_si), .node12_pero(node12_net_ri), .node12_pedo(node12_net_di),
        .node12_polarity(node12_polarity),

        .node13_pesi(node13_net_so), .node13_peri(node13_net_ro), .node13_pedi(node13_net_do),
        .node13_peso(node13_net_si), .node13_pero(node13_net_ri), .node13_pedo(node13_net_di),
        .node13_polarity(node13_polarity),

        .node14_pesi(node14_net_so), .node14_peri(node14_net_ro), .node14_pedi(node14_net_do),
        .node14_peso(node14_net_si), .node14_pero(node14_net_ri), .node14_pedo(node14_net_di),
        .node14_polarity(node14_polarity),

        .node15_pesi(node15_net_so), .node15_peri(node15_net_ro), .node15_pedi(node15_net_do),
        .node15_peso(node15_net_si), .node15_pero(node15_net_ri), .node15_pedo(node15_net_di),
        .node15_polarity(node15_polarity)
    );

endmodule
