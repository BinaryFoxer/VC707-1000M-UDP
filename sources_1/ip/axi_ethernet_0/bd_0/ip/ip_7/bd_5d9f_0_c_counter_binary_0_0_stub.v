// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
// Date        : Wed Dec 17 15:19:55 2025
// Host        : BinaryFoxer running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               d:/Allprojects/vivado/test_vc707/test_vc707.srcs/sources_1/ip/axi_ethernet_0/bd_0/ip/ip_7/bd_5d9f_0_c_counter_binary_0_0_stub.v
// Design      : bd_5d9f_0_c_counter_binary_0_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx485tffg1761-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "c_counter_binary_v12_0_12,Vivado 2018.3" *)
module bd_5d9f_0_c_counter_binary_0_0(CLK, SCLR, THRESH0, Q)
/* synthesis syn_black_box black_box_pad_pin="CLK,SCLR,THRESH0,Q[23:0]" */;
  input CLK;
  input SCLR;
  output THRESH0;
  output [23:0]Q;
endmodule
