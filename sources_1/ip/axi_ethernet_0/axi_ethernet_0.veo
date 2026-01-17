// (c) Copyright 1995-2025 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
// DO NOT MODIFY THIS FILE.

// IP VLNV: xilinx.com:ip:axi_ethernet:7.1
// IP Revision: 5

// The following must be inserted into your Verilog file for this
// core to be instantiated. Change the instance name and port connections
// (in parentheses) to your own signal names.

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
axi_ethernet_0 your_instance_name (
  .s_axi_lite_resetn(s_axi_lite_resetn),          // input wire s_axi_lite_resetn
  .s_axi_lite_clk(s_axi_lite_clk),                // input wire s_axi_lite_clk
  .mac_irq(mac_irq),                              // output wire mac_irq
  .axis_clk(axis_clk),                            // input wire axis_clk
  .axi_txd_arstn(axi_txd_arstn),                  // input wire axi_txd_arstn
  .axi_txc_arstn(axi_txc_arstn),                  // input wire axi_txc_arstn
  .axi_rxd_arstn(axi_rxd_arstn),                  // input wire axi_rxd_arstn
  .axi_rxs_arstn(axi_rxs_arstn),                  // input wire axi_rxs_arstn
  .interrupt(interrupt),                          // output wire interrupt
  .signal_detect(signal_detect),                  // input wire signal_detect
  .mmcm_locked_out(mmcm_locked_out),              // output wire mmcm_locked_out
  .rxuserclk_out(rxuserclk_out),                  // output wire rxuserclk_out
  .rxuserclk2_out(rxuserclk2_out),                // output wire rxuserclk2_out
  .userclk_out(userclk_out),                      // output wire userclk_out
  .userclk2_out(userclk2_out),                    // output wire userclk2_out
  .pma_reset_out(pma_reset_out),                  // output wire pma_reset_out
  .gt0_qplloutclk_out(gt0_qplloutclk_out),        // output wire gt0_qplloutclk_out
  .gt0_qplloutrefclk_out(gt0_qplloutrefclk_out),  // output wire gt0_qplloutrefclk_out
  .phy_rst_n(phy_rst_n),                          // output wire [0 : 0] phy_rst_n
  .ref_clk(ref_clk),                              // input wire ref_clk
  .gtref_clk_out(gtref_clk_out),                  // output wire gtref_clk_out
  .gtref_clk_buf_out(gtref_clk_buf_out),          // output wire gtref_clk_buf_out
  .s_axi_araddr(s_axi_araddr),                    // input wire [17 : 0] s_axi_araddr
  .s_axi_arready(s_axi_arready),                  // output wire s_axi_arready
  .s_axi_arvalid(s_axi_arvalid),                  // input wire s_axi_arvalid
  .s_axi_awaddr(s_axi_awaddr),                    // input wire [17 : 0] s_axi_awaddr
  .s_axi_awready(s_axi_awready),                  // output wire s_axi_awready
  .s_axi_awvalid(s_axi_awvalid),                  // input wire s_axi_awvalid
  .s_axi_bready(s_axi_bready),                    // input wire s_axi_bready
  .s_axi_bresp(s_axi_bresp),                      // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(s_axi_bvalid),                    // output wire s_axi_bvalid
  .s_axi_rdata(s_axi_rdata),                      // output wire [31 : 0] s_axi_rdata
  .s_axi_rready(s_axi_rready),                    // input wire s_axi_rready
  .s_axi_rresp(s_axi_rresp),                      // output wire [1 : 0] s_axi_rresp
  .s_axi_rvalid(s_axi_rvalid),                    // output wire s_axi_rvalid
  .s_axi_wdata(s_axi_wdata),                      // input wire [31 : 0] s_axi_wdata
  .s_axi_wready(s_axi_wready),                    // output wire s_axi_wready
  .s_axi_wstrb(s_axi_wstrb),                      // input wire [3 : 0] s_axi_wstrb
  .s_axi_wvalid(s_axi_wvalid),                    // input wire s_axi_wvalid
  .s_axis_txc_tdata(s_axis_txc_tdata),            // input wire [31 : 0] s_axis_txc_tdata
  .s_axis_txc_tkeep(s_axis_txc_tkeep),            // input wire [3 : 0] s_axis_txc_tkeep
  .s_axis_txc_tlast(s_axis_txc_tlast),            // input wire s_axis_txc_tlast
  .s_axis_txc_tready(s_axis_txc_tready),          // output wire s_axis_txc_tready
  .s_axis_txc_tvalid(s_axis_txc_tvalid),          // input wire s_axis_txc_tvalid
  .s_axis_txd_tdata(s_axis_txd_tdata),            // input wire [31 : 0] s_axis_txd_tdata
  .s_axis_txd_tkeep(s_axis_txd_tkeep),            // input wire [3 : 0] s_axis_txd_tkeep
  .s_axis_txd_tlast(s_axis_txd_tlast),            // input wire s_axis_txd_tlast
  .s_axis_txd_tready(s_axis_txd_tready),          // output wire s_axis_txd_tready
  .s_axis_txd_tvalid(s_axis_txd_tvalid),          // input wire s_axis_txd_tvalid
  .m_axis_rxd_tdata(m_axis_rxd_tdata),            // output wire [31 : 0] m_axis_rxd_tdata
  .m_axis_rxd_tkeep(m_axis_rxd_tkeep),            // output wire [3 : 0] m_axis_rxd_tkeep
  .m_axis_rxd_tlast(m_axis_rxd_tlast),            // output wire m_axis_rxd_tlast
  .m_axis_rxd_tready(m_axis_rxd_tready),          // input wire m_axis_rxd_tready
  .m_axis_rxd_tvalid(m_axis_rxd_tvalid),          // output wire m_axis_rxd_tvalid
  .m_axis_rxs_tdata(m_axis_rxs_tdata),            // output wire [31 : 0] m_axis_rxs_tdata
  .m_axis_rxs_tkeep(m_axis_rxs_tkeep),            // output wire [3 : 0] m_axis_rxs_tkeep
  .m_axis_rxs_tlast(m_axis_rxs_tlast),            // output wire m_axis_rxs_tlast
  .m_axis_rxs_tready(m_axis_rxs_tready),          // input wire m_axis_rxs_tready
  .m_axis_rxs_tvalid(m_axis_rxs_tvalid),          // output wire m_axis_rxs_tvalid
  .sgmii_rxn(sgmii_rxn),                          // input wire sgmii_rxn
  .sgmii_rxp(sgmii_rxp),                          // input wire sgmii_rxp
  .sgmii_txn(sgmii_txn),                          // output wire sgmii_txn
  .sgmii_txp(sgmii_txp),                          // output wire sgmii_txp
  .mdio_mdc(mdio_mdc),                            // output wire mdio_mdc
  .mdio_mdio_i(mdio_mdio_i),                      // input wire mdio_mdio_i
  .mdio_mdio_o(mdio_mdio_o),                      // output wire mdio_mdio_o
  .mdio_mdio_t(mdio_mdio_t),                      // output wire mdio_mdio_t
  .mgt_clk_clk_n(mgt_clk_clk_n),                  // input wire mgt_clk_clk_n
  .mgt_clk_clk_p(mgt_clk_clk_p)                  // input wire mgt_clk_clk_p
);
// INST_TAG_END ------ End INSTANTIATION Template ---------

// You must compile the wrapper file axi_ethernet_0.v when simulating
// the core, axi_ethernet_0. When compiling the wrapper file, be sure to
// reference the Verilog simulation library.

