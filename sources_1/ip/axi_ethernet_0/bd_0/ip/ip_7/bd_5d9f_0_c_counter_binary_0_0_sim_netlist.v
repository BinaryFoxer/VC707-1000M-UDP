// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
// Date        : Wed Dec 17 15:19:55 2025
// Host        : BinaryFoxer running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               d:/Allprojects/vivado/test_vc707/test_vc707.srcs/sources_1/ip/axi_ethernet_0/bd_0/ip/ip_7/bd_5d9f_0_c_counter_binary_0_0_sim_netlist.v
// Design      : bd_5d9f_0_c_counter_binary_0_0
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7vx485tffg1761-2
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "bd_5d9f_0_c_counter_binary_0_0,c_counter_binary_v12_0_12,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "c_counter_binary_v12_0_12,Vivado 2018.3" *) 
(* NotValidForBitStream *)
module bd_5d9f_0_c_counter_binary_0_0
   (CLK,
    SCLR,
    THRESH0,
    Q);
  (* x_interface_info = "xilinx.com:signal:clock:1.0 clk_intf CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME clk_intf, ASSOCIATED_BUSIF q_intf:thresh0_intf:l_intf:load_intf:up_intf:sinit_intf:sset_intf, ASSOCIATED_RESET SCLR, ASSOCIATED_CLKEN CE, FREQ_HZ 100000000, PHASE 0.000, INSERT_VIP 0" *) input CLK;
  (* x_interface_info = "xilinx.com:signal:reset:1.0 sclr_intf RST" *) (* x_interface_parameter = "XIL_INTERFACENAME sclr_intf, POLARITY ACTIVE_HIGH, INSERT_VIP 0" *) input SCLR;
  (* x_interface_info = "xilinx.com:signal:data:1.0 thresh0_intf DATA" *) (* x_interface_parameter = "XIL_INTERFACENAME thresh0_intf, LAYERED_METADATA undef" *) output THRESH0;
  (* x_interface_info = "xilinx.com:signal:data:1.0 q_intf DATA" *) (* x_interface_parameter = "XIL_INTERFACENAME q_intf, LAYERED_METADATA xilinx.com:interface:datatypes:1.0 {DATA {datatype {name {attribs {resolve_type immediate dependency {} format string minimum {} maximum {}} value data} bitwidth {attribs {resolve_type generated dependency bitwidth format long minimum {} maximum {}} value 24} bitoffset {attribs {resolve_type immediate dependency {} format long minimum {} maximum {}} value 0} integer {signed {attribs {resolve_type immediate dependency {} format bool minimum {} maximum {}} value false}}}} DATA_WIDTH 24}" *) output [23:0]Q;

  wire CLK;
  wire [23:0]Q;
  wire SCLR;
  wire THRESH0;

  (* C_AINIT_VAL = "0" *) 
  (* C_CE_OVERRIDES_SYNC = "0" *) 
  (* C_FB_LATENCY = "0" *) 
  (* C_HAS_CE = "0" *) 
  (* C_HAS_SCLR = "1" *) 
  (* C_HAS_SINIT = "0" *) 
  (* C_HAS_SSET = "0" *) 
  (* C_IMPLEMENTATION = "0" *) 
  (* C_SCLR_OVERRIDES_SSET = "1" *) 
  (* C_SINIT_VAL = "0" *) 
  (* C_VERBOSITY = "0" *) 
  (* C_WIDTH = "24" *) 
  (* C_XDEVICEFAMILY = "virtex7" *) 
  (* c_count_by = "1" *) 
  (* c_count_mode = "0" *) 
  (* c_count_to = "1100000000000000000000" *) 
  (* c_has_load = "0" *) 
  (* c_has_thresh0 = "1" *) 
  (* c_latency = "1" *) 
  (* c_load_low = "0" *) 
  (* c_restrict_count = "1" *) 
  (* c_thresh0_value = "1100000000000000000000" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  bd_5d9f_0_c_counter_binary_0_0_c_counter_binary_v12_0_12 U0
       (.CE(1'b1),
        .CLK(CLK),
        .L({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .LOAD(1'b0),
        .Q(Q),
        .SCLR(SCLR),
        .SINIT(1'b0),
        .SSET(1'b0),
        .THRESH0(THRESH0),
        .UP(1'b1));
endmodule

(* C_AINIT_VAL = "0" *) (* C_CE_OVERRIDES_SYNC = "0" *) (* C_COUNT_BY = "1" *) 
(* C_COUNT_MODE = "0" *) (* C_COUNT_TO = "1100000000000000000000" *) (* C_FB_LATENCY = "0" *) 
(* C_HAS_CE = "0" *) (* C_HAS_LOAD = "0" *) (* C_HAS_SCLR = "1" *) 
(* C_HAS_SINIT = "0" *) (* C_HAS_SSET = "0" *) (* C_HAS_THRESH0 = "1" *) 
(* C_IMPLEMENTATION = "0" *) (* C_LATENCY = "1" *) (* C_LOAD_LOW = "0" *) 
(* C_RESTRICT_COUNT = "1" *) (* C_SCLR_OVERRIDES_SSET = "1" *) (* C_SINIT_VAL = "0" *) 
(* C_THRESH0_VALUE = "1100000000000000000000" *) (* C_VERBOSITY = "0" *) (* C_WIDTH = "24" *) 
(* C_XDEVICEFAMILY = "virtex7" *) (* ORIG_REF_NAME = "c_counter_binary_v12_0_12" *) (* downgradeipidentifiedwarnings = "yes" *) 
module bd_5d9f_0_c_counter_binary_0_0_c_counter_binary_v12_0_12
   (CLK,
    CE,
    SCLR,
    SSET,
    SINIT,
    UP,
    LOAD,
    L,
    THRESH0,
    Q);
  input CLK;
  input CE;
  input SCLR;
  input SSET;
  input SINIT;
  input UP;
  input LOAD;
  input [23:0]L;
  output THRESH0;
  output [23:0]Q;

  wire CLK;
  wire [23:0]Q;
  wire SCLR;
  wire THRESH0;

  (* C_AINIT_VAL = "0" *) 
  (* C_CE_OVERRIDES_SYNC = "0" *) 
  (* C_FB_LATENCY = "0" *) 
  (* C_HAS_CE = "0" *) 
  (* C_HAS_SCLR = "1" *) 
  (* C_HAS_SINIT = "0" *) 
  (* C_HAS_SSET = "0" *) 
  (* C_IMPLEMENTATION = "0" *) 
  (* C_SCLR_OVERRIDES_SSET = "1" *) 
  (* C_SINIT_VAL = "0" *) 
  (* C_VERBOSITY = "0" *) 
  (* C_WIDTH = "24" *) 
  (* C_XDEVICEFAMILY = "virtex7" *) 
  (* c_count_by = "1" *) 
  (* c_count_mode = "0" *) 
  (* c_count_to = "1100000000000000000000" *) 
  (* c_has_load = "0" *) 
  (* c_has_thresh0 = "1" *) 
  (* c_latency = "1" *) 
  (* c_load_low = "0" *) 
  (* c_restrict_count = "1" *) 
  (* c_thresh0_value = "1100000000000000000000" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  bd_5d9f_0_c_counter_binary_0_0_c_counter_binary_v12_0_12_viv i_synth
       (.CE(1'b0),
        .CLK(CLK),
        .L({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .LOAD(1'b0),
        .Q(Q),
        .SCLR(SCLR),
        .SINIT(1'b0),
        .SSET(1'b0),
        .THRESH0(THRESH0),
        .UP(1'b0));
endmodule
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2015"
`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="cds_rsa_key", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=64)
`pragma protect key_block
INaBf8vh5mCmDzf2yp77pxZAxQdyEQiT/vG2dEgvrFjseUnGc6ldwH4JvdnpZSpdf/ihioPyMNjl
u6ooyzv5TA==

`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
S5XIZZtuFR/MZffuhwdnvE3H9oRWM4uXoaGZTa/Dyk62O+Wa0v41pjmZELCiR7uodZPFQfykZ6K9
2ZDMu8dB3afQRMs5lnd/53M1b9ke+MNEeZ/wzjUcsJghubnEAwzdWeW/0tlqST1WD9B/KCxYqwH5
Gj6IZTTFHAXcaVhnCT8=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
CM6IcdzP0PbD6yMSqylmi4JE2qpmxiNeI+prjGwJiD8e3Xsynu3PbGKJAOpOxtR1hT/3mpBcx1Rz
Fkz0QBh4wtE8fiziv1i+xi8T6cqC8ClamjrpZ//sn6dh7NvwSYik14MlwVuei4DZoZJZF63aoPUn
RXkQ13wtK+MkYKBcPVSZMFZmaCU6jMMBYclXzvRG1JqqZoa7mWFTeFZePUTXG7Wo12QaZ8GUi0AV
UIshoN25yn5e2Xr3FyuEtm5AvsZb+iLsgLeHBtKBnsVaHQphicgqwgwv6MQQF6ZNBgU/aACfibDS
3+n/mMMm8k1cj2bW6VCi7a+c8LmCf81NlJuLww==

`pragma protect key_keyowner="ATRENTA", key_keyname="ATR-SG-2015-RSA-3", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
ehl0CusS7+JNGq6HfhyaBMy68nccIdIGqixoEztEZfkCpXuUYsdqw6G9MIJdWdu0Ck2acV7K6IVg
rzb8/bNaDDVWp48kupToegTkOdwDkCejEqppido4BkJ+iEkjPniz+aJHlOlOwmauETy2hCMuuC57
oWDprzGWlsqbCjqzKrXmPYm6fNdcOa2DiOYstQaMFNbPU2ccrbLJAiYMHNDqtPNqWxKBsD67kiGf
2eOneDOmdmy7YkNsL+cx8MJc3BVUsYBrpAEsGyFMkmX8a8nYz8R/wlFQFGQAd/t5XrfxFNI58mj1
AHXbcAMhGKVq9YdKeU/vSXY/NwMqp12xJ1nUaw==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2017_05", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
h/qRAwiPuqY/Zg/QWqbaYm8xWTi9SshYuPzyL0UME9ZDDF+C2CyGAugh9HzMdD0kZmT94TKmBgLR
dKP28nlE8VCCU5rvbjKxfn/wNtNKHCvZ1hns8CF7+pGuelhxGvXNmYKFw5co8+4grYFaDXeoZZR6
S5sjvhqtSVD3+qq4vYWRjT2Y/yes7L9dRsLq2D3iZ4xjgVHuIbOQLT/EUKW+9iYudT9Uy6YTwB+5
mSb0QK3YfZdGwZyXB4S3mdF9vNQHdW/rnACq3yngF+lprNkh3ooQKdGqtxtz8KSQxNZOAFE+koOw
h00o7AKpvDAp3uNguLvnNJH3rugOhh95b8Jatw==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
TsA04vIYHDZne2CBj5bWCBFH4MtNoFDCn/3DNEi0BwutuUf+X+lD9kAO3kl352WHjQbF79Ssm+PT
fCYpODgWdxSVbzaHFpITxCQ4HcIJhUeW5PC5tw09Tand68D6eg84qRguH+llbb5jdGJkJeTCf+Mx
pupkkLiDvNyTYWe+nqw=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
rx9hgQkvaJJTJJcTjGFW1DrrWiT+xanrcMvFn0Z3KRXlZvf+SE7IQgGCiP7ZDA6T5z1Zv5nzS4h5
cVi+CvwC9UMZRWmLDAjzASJ2nx1g9BjbYe2vHAUmyurIiR6LSigTeM/9TlMv+fFwJbqwuH6FJ3/z
Vl4tIMk4NrqkMn/riOG87SjhesepM6kcQOBgDGzLTG14z3qeZG8OPzxgApfyubmX4qdD1oTgGm2u
Q4mQfFxEye6Jqkn4Rzjhifs/ieNYomHlK7R2/72QJj5j0WyYBIhvO+09izz299Z54ZP2ZXaRMfDT
lU4lQNqQU14PX9Yk9p7sy2PnK4vTwwF0CFIgSQ==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-PREC-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
a4T9GvJp6ZHO6B2fG5MAAa4KZXDtYOuMCZtmjASYwkrzngRuC72RNDRpgk2JNPqDewvMoSDca/Qt
SwV8lJdZM4UqV4m5a9+EDAGEAQyElAvXS5UpuzVLW/TmOgz8RJ0SSW6JZ5NYyvTP+gVvSMHiI+DX
KY7rwGS0zI9kzw0n/TjQLODuyh4Ku8VjpxVn6bxIdONIUZNbCLUl5dMTdtKlq1yMvB1mZPsQWtFZ
ehUUFFd5eCJKCiFoIeLXFuo6jYNwTDnYfjRH5ApOmKT2peac/sAxjc0E5D2Av5HY8XGSvkR6FKNu
KzGOW5Y1einzJP23+B7kiqGIDcOo5KLGPUMktg==

`pragma protect key_keyowner="Synplicity", key_keyname="SYNP15_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
KVhX1SM1Ikm9BkAQ7xAqRbJHNjlJtfv/UHz9VuW53YOP9kcefRBv5fPjMSPequJKajRFVU13aegM
OXl8g3ydXqNF2lclAnPlGW7V4ygmgJOoB5AuihT9mSaN997jubp4BKStIMlQpDbgp8uW140PUBo6
60iMVV0PmIGt8sxjXRYE+k2+FMZ25IZkAKMBZ8OnhVN/llumXhG4LSHc6CCUbTGJQXcH70IHptst
CCSqImmBVQfweIu+Ursdh2Fqk+epJGPE05xYitZOo9QiHe9WW8H+zIi+7SGUt2yxQdYWEWKoD9Lx
mZrm8z7/dxVYJY+xTlruyfwazeGNqgpz9e0q4Q==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 12640)
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
