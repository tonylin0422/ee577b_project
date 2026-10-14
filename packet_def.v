//---------------------------------------------------------------------
// This file includes the packet and header format definitions.    
//---------------------------------------------------------------------

`ifndef PACKET_DEF_V
`define PACKET_DEF_V

`define PACKET_WIDTH 64
`define HEADER_WIDTH 32

// Header/Payload
`define HEADER      63:32
`define PAYLOAD     31:0

// Header fields
`define VC          63
`define X_DIR       62
`define Y_DIR       61
`define RESERVED    60:56
`define HCX         55:52
`define HCY         51:48
`define SOURCE_X    47:40
`define SOURCE_Y    39:32

`endif
