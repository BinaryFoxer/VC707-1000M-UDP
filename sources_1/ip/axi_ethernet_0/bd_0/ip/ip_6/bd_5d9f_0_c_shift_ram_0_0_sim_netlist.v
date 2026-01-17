// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
// Date        : Wed Dec 17 15:19:54 2025
// Host        : BinaryFoxer running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               d:/Allprojects/vivado/test_vc707/test_vc707.srcs/sources_1/ip/axi_ethernet_0/bd_0/ip/ip_6/bd_5d9f_0_c_shift_ram_0_0_sim_netlist.v
// Design      : bd_5d9f_0_c_shift_ram_0_0
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7vx485tffg1761-2
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "bd_5d9f_0_c_shift_ram_0_0,c_shift_ram_v12_0_12,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "c_shift_ram_v12_0_12,Vivado 2018.3" *) 
(* NotValidForBitStream *)
module bd_5d9f_0_c_shift_ram_0_0
   (D,
    CLK,
    CE,
    SCLR,
    Q);
  (* x_interface_info = "xilinx.com:signal:data:1.0 d_intf DATA" *) (* x_interface_parameter = "XIL_INTERFACENAME d_intf, LAYERED_METADATA undef" *) input [0:0]D;
  (* x_interface_info = "xilinx.com:signal:clock:1.0 clk_intf CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME clk_intf, ASSOCIATED_BUSIF q_intf:sinit_intf:sset_intf:d_intf:a_intf, ASSOCIATED_RESET SCLR, ASSOCIATED_CLKEN CE, FREQ_HZ 100000000, PHASE 0.000, INSERT_VIP 0" *) input CLK;
  (* x_interface_info = "xilinx.com:signal:clockenable:1.0 ce_intf CE" *) (* x_interface_parameter = "XIL_INTERFACENAME ce_intf, POLARITY ACTIVE_LOW" *) input CE;
  (* x_interface_info = "xilinx.com:signal:reset:1.0 sclr_intf RST" *) (* x_interface_parameter = "XIL_INTERFACENAME sclr_intf, POLARITY ACTIVE_HIGH, INSERT_VIP 0" *) input SCLR;
  (* x_interface_info = "xilinx.com:signal:data:1.0 q_intf DATA" *) (* x_interface_parameter = "XIL_INTERFACENAME q_intf, LAYERED_METADATA xilinx.com:interface:datatypes:1.0 {DATA {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value data} bitwidth {attribs {resolve_type generated dependency data_bitwidth format long minimum {} maximum {}} value 1} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0}}} DATA_WIDTH 1}" *) output [0:0]Q;

  wire CE;
  wire CLK;
  wire [0:0]D;
  wire [0:0]Q;
  wire SCLR;

  (* C_AINIT_VAL = "0" *) 
  (* C_HAS_CE = "1" *) 
  (* C_HAS_SCLR = "1" *) 
  (* C_HAS_SINIT = "0" *) 
  (* C_HAS_SSET = "0" *) 
  (* C_SINIT_VAL = "0" *) 
  (* C_SYNC_ENABLE = "0" *) 
  (* C_SYNC_PRIORITY = "1" *) 
  (* C_WIDTH = "1" *) 
  (* c_addr_width = "4" *) 
  (* c_default_data = "0" *) 
  (* c_depth = "1" *) 
  (* c_elaboration_dir = "./" *) 
  (* c_has_a = "0" *) 
  (* c_mem_init_file = "no_coe_file_loaded" *) 
  (* c_opt_goal = "0" *) 
  (* c_parser_type = "0" *) 
  (* c_read_mif = "0" *) 
  (* c_reg_last_bit = "1" *) 
  (* c_shift_type = "0" *) 
  (* c_verbosity = "0" *) 
  (* c_xdevicefamily = "virtex7" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  bd_5d9f_0_c_shift_ram_0_0_c_shift_ram_v12_0_12 U0
       (.A({1'b0,1'b0,1'b0,1'b0}),
        .CE(CE),
        .CLK(CLK),
        .D(D),
        .Q(Q),
        .SCLR(SCLR),
        .SINIT(1'b0),
        .SSET(1'b0));
endmodule

(* C_ADDR_WIDTH = "4" *) (* C_AINIT_VAL = "0" *) (* C_DEFAULT_DATA = "0" *) 
(* C_DEPTH = "1" *) (* C_ELABORATION_DIR = "./" *) (* C_HAS_A = "0" *) 
(* C_HAS_CE = "1" *) (* C_HAS_SCLR = "1" *) (* C_HAS_SINIT = "0" *) 
(* C_HAS_SSET = "0" *) (* C_MEM_INIT_FILE = "no_coe_file_loaded" *) (* C_OPT_GOAL = "0" *) 
(* C_PARSER_TYPE = "0" *) (* C_READ_MIF = "0" *) (* C_REG_LAST_BIT = "1" *) 
(* C_SHIFT_TYPE = "0" *) (* C_SINIT_VAL = "0" *) (* C_SYNC_ENABLE = "0" *) 
(* C_SYNC_PRIORITY = "1" *) (* C_VERBOSITY = "0" *) (* C_WIDTH = "1" *) 
(* C_XDEVICEFAMILY = "virtex7" *) (* ORIG_REF_NAME = "c_shift_ram_v12_0_12" *) (* downgradeipidentifiedwarnings = "yes" *) 
module bd_5d9f_0_c_shift_ram_0_0_c_shift_ram_v12_0_12
   (A,
    D,
    CLK,
    CE,
    SCLR,
    SSET,
    SINIT,
    Q);
  input [3:0]A;
  input [0:0]D;
  input CLK;
  input CE;
  input SCLR;
  input SSET;
  input SINIT;
  output [0:0]Q;

  wire CE;
  wire CLK;
  wire [0:0]D;
  wire [0:0]Q;
  wire SCLR;

  (* C_AINIT_VAL = "0" *) 
  (* C_HAS_CE = "1" *) 
  (* C_HAS_SCLR = "1" *) 
  (* C_HAS_SINIT = "0" *) 
  (* C_HAS_SSET = "0" *) 
  (* C_SINIT_VAL = "0" *) 
  (* C_SYNC_ENABLE = "0" *) 
  (* C_SYNC_PRIORITY = "1" *) 
  (* C_WIDTH = "1" *) 
  (* c_addr_width = "4" *) 
  (* c_default_data = "0" *) 
  (* c_depth = "1" *) 
  (* c_elaboration_dir = "./" *) 
  (* c_has_a = "0" *) 
  (* c_mem_init_file = "no_coe_file_loaded" *) 
  (* c_opt_goal = "0" *) 
  (* c_parser_type = "0" *) 
  (* c_read_mif = "0" *) 
  (* c_reg_last_bit = "1" *) 
  (* c_shift_type = "0" *) 
  (* c_verbosity = "0" *) 
  (* c_xdevicefamily = "virtex7" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  bd_5d9f_0_c_shift_ram_0_0_c_shift_ram_v12_0_12_viv i_synth
       (.A({1'b0,1'b0,1'b0,1'b0}),
        .CE(CE),
        .CLK(CLK),
        .D(D),
        .Q(Q),
        .SCLR(SCLR),
        .SINIT(1'b0),
        .SSET(1'b0));
endmodule
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2015"
`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="cds_rsa_key", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=64)
`pragma protect key_block
PkyhyBb59EPgq8kANKUgNUvJSxwVgcYTKLlfXroHeM6zPnPHm+ATuJPY2OmCojZnDY2A6SHiMUmx
ylnsx6jVAA==

`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
XgKClVpS+h3z22aTgNZepCZW5Yffl4m6nNLRjY88G0b6Og6dF7wA3of30X3Vr2BKX5GVSe+jeu6a
q3D7Qa0T3sEnO1qnWdbom/P31G6nS7/pQCPaLh+suxznQX2imRfhfTkmY1B9wExxZtZBbss2GPfs
EFGX8a+efiUiZLAKaSE=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
LYMHL9qwz9VPPAbHAyLFK1YM6t0YBJUbhdak6y3IQta7KscLfLakFo9QXv7rXKj3R5WEjx6Vg+9K
QUgoa/uCYy+n2t004DDpVeDamNuGIrJU3WXV9mo6tEi21Rm+kIG+CFgVuqLY9JSjwI3dhmEqYYtS
wC2GIO6hKaV0keq1ldvsRFBu71kLY+jczboTe6EddpUktWp3UM/RqnrSfHPMlZWhHp1k3YC0SDq9
gvcPn9DB3vIjXgn+xRbyzZOt/j+s8RfjF446i2RalkF5p/den9o/OMG5jmv4rZKHj9S1V3Z2UuL1
c2fxe26sNIvZ7tpz8RHVWRMloPfcPVakam2zhg==

`pragma protect key_keyowner="ATRENTA", key_keyname="ATR-SG-2015-RSA-3", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
BACIRg239ZSAZHpsLobWk7IZyWSAM1rsaZq5LesIgnba07iijhvT5s8WIOIIgHZs1XEDKelSnU1J
+5cyEbU9WgPZsja6FQEw6J0GuN3L/1QyrvmNIJKsNXINx7R+xaY/n0uby2eFsFE9luplvdOyrCEw
eK82BghXwPdasTT1ZUgKiycyGYtNsp5ZaPIWXI9ezN9oHowcWp7Mn6v2jrdDl4lzJuoHgqRtkZvG
7GqevJFheGfXkRPuQGkNK2Pk6XN9woSB1a9C+FUsQBM5MlIE7zrBQAjONIQj/nd82Hlp1H4PRxBW
1mmFP7PskMeNR2hH5xwkvg4Q3IfYBlw8gdzneg==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2017_05", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
vUWbACu3JL9XeVH21XChN1bLnACIM0U/dLRQNf2LGaDFNW9CL0o3SY9pOtV226o71+9Eal6i7P4l
ht62RU2AHTweJsgWkXtQBI0/jHIw4/gxbBebNbqZM6m3qjEE5blPsuzJ1njoX2JWCJElO3p9FfRu
uHpC+4hYoccdFayGku3vk1gwz9lLJ4FcYG9mi1vLIY+tzs0o83THQ8dLrg50Rr/r2n0Xf4hxWe4U
tJ6iUOYBQUYjeOwNQOOxfjv5PKfLIgGA2WC8sJb2GFe9MkTDoMAo40nBLK0Y8+klDIJTyx079Bx0
wdRg2JxUF3+TGlXW98+2/iWy94H1CPEVRm18FQ==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
VX8rVAT0l4oniSvb1X0sblwaqcWh2XE0oCAZbC0SVv8fCy8dLmmtqBzFq3w2V/7nyMmJzWKNP/yV
0GW7ICEfrGaBejU3VpwaHA69xE56Y/8NSHGlZOhr390/5/UqELcFOknZEPJXMLpeKjUn2ijACn/u
O0myDIvGFiUyRGWWYKM=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
dlKAt52rb1rebbUvCxUw/pmWR03F+be3vApC1VuekYTvk7BFt7xopdHrqsvoU8rgaCBc2wuCudx5
nUcu7bKEyHKFc6bcbp6J84c2uG0ZckyqBn/OHRMbmq4Vbar8C3ERI2YmcbL0Q0fBLzMosVarF9eM
+c6VfE9hA5lx9qpwFJhgk5v/yx6kjgu+kEnG+xsdWrpKrj8LIxxh6gkrPOn+jQtKQSX3o7q35Rcv
W3vWLRYdH+pHsfJqCdT0wL4oBTLa7ozdsufX9l6UDgT4ECxLf7R1TtNj7XA1jaaefThL0F1AUCjF
5WuhMqBOotpDZUmvB91yVtbXLMm0r85tK9b/iA==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-PREC-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
C8i09uDTlrCYUCSJeSn96vDxV4vUu6MEfJRSt7qFCywGy8iHQnumQ3nSKNQvZ8xyU6rK8AV0fN2n
4CaEqV00EunilD0BdPkCrMJoyg+dEDF8m+Sd/SPPE9lGcSGn0V77RtvyDn4I7y5v2ETVmhSAXm+J
nf6Px0Yir19H/5SbSIQjcKIxnzOpZufYHAtaTqix84Z9hxx2by4MHvJSH5AvpO8QhJ18KyosA+Ed
R1GMA7h4m+1MoI9/RUGEyQdMSPIED+mkvLfsiMo0exVrUK8+MhBylB+4TAKflNgBsyiFIj9F8y6J
GPN8djEfwr8URNuiPmukg1Gr/urQ4vV7sM+lVw==

`pragma protect key_keyowner="Synplicity", key_keyname="SYNP15_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
VPUA+0TYLaO17Rtdx5rlIorvr9+hCEt2TXVQ/1BbMbez1cdepY4zrzmJmGSSNSpisbVpO9WkYnFt
MxRMtjNp4ijVwYvHoOnWD75JIOjgSJHSHHf8u50i2X8G4lJMYBVOJtcBalrO9+tPWnxh+40ttG3e
OWXxnJ4LwvOe5MbfpcOpMlIRl7ZiM2MIlkw27BQkEFwioLJr0IAn+hSrpRjeLwCbwtSmQErTWi8W
lsMgeszU2q59X4LUa2CaJ0gDdquJsbF302rS84Oci+90O11PxNYNO/qRSL9Ira25wSaUbqs5Jmez
t2tb5ln4qw/lWOzqGjDxGhmRZ5uSG1gaNssWRA==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 4656)
`pragma protect data_block
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
`pragma protect end_protected
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

endmodule
`endif
