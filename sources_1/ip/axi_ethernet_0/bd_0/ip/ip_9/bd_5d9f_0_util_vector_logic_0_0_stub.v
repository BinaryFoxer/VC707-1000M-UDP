// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
// Date        : Wed Dec 17 15:19:52 2025
// Host        : BinaryFoxer running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               d:/Allprojects/vivado/test_vc707/test_vc707.srcs/sources_1/ip/axi_ethernet_0/bd_0/ip/ip_9/bd_5d9f_0_util_vector_logic_0_0_stub.v
// Design      : bd_5d9f_0_util_vector_logic_0_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx485tffg1761-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "util_vector_logic_v2_0_1_util_vector_logic,Vivado 2018.3" *)
module bd_5d9f_0_util_vector_logic_0_0(Op1, Res)
/* synthesis syn_black_box black_box_pad_pin="Op1[0:0],Res[0:0]" */;
  input [0:0]Op1;
  output [0:0]Res;
endmodule
