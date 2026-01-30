`timescale 1ns / 1ps

// --------------------------------------
// 接收：sgmii数据 to gmii数据
// 发送：gmii数据 to sgmii数据
// 定位：MAC与PHY间，物理层以及数据链路层
// core: gig_eth_pcs_pma
// --------------------------------------

module sgmii_to_gmii(
    input                   sys_rst,                    

    input                   sgmii_clk_n,                // gtx使用的sgmii参考时钟
    input                   sgmii_clk_p,                // gtx使用的sgmii参考时钟
    input                   sgmii_rx_n,                 // sgmii接收数据
    input                   sgmii_rx_p,                 // sgmii接收数据
    input                   gmii_tx_en,                 // gmii发送使能
    input                   gmii_tx_er,                 // gmii发送数据错误
    input            [7:0]  gmii_txd,                   // gmii发送数据

    output                  gmii_rx_clk,                // gmii接收时钟
    output                  gmii_rx_dv,                 // gmii接收数据有效
    output                  gmii_rx_er,                 // gmii接收数据错误
    output           [7:0]  gmii_rxd,                   // gmii接收数据
    output                  gmii_tx_clk,                // gmii发送时钟
    output                  sgmii_tx_n,                 // sgmii发送数据
    output                  sgmii_tx_p,                 // sgmii发送数据

    output                  resetdone,                  // IP核复位完成信号
    output                  mmcm_locked_out             // IP核内部时钟锁定稳定（时钟稳定后开始传输数据）
    );

    // wire define
    wire                gtrefclk_out;                   // 125M参考时钟输出
    wire                gtrefclk_bufg_out;              // 125M参考时钟全局缓冲输出
    wire                gtrefclk_bufg;                  // 125M参考时钟全局缓冲输入
    wire                sgmii_clk_r;                    // sgmii内部恢复时钟
    wire                sgmii_clk_f;                    // sgmii内部频率时钟
    wire                sgmii_clk_en;                   // sgmii时钟使能信号
    wire        [15:0]  status_vector;                  // PHY寄存器状态向量                
  
    // assign gmii_tx_clk = gmii_rx_clk;
    
    // -------------------------产生125M参考时钟全局缓冲输入----------------------
    // IBUFDS_GTE2 #(
    //   .CLKCM_CFG("TRUE"),   // Refer to Transceiver User Guide
    //   .CLKRCV_TRST("TRUE"), // Refer to Transceiver User Guide
    //   .CLKSWING_CFG(2'b11)  // Refer to Transceiver User Guide
    //    )
    //    GTREFCLK_BUFG (
    //       .O(gtrefclk_bufg),         // 1-bit output: Refer to Transceiver User Guide
    //       .ODIV2(), // 1-bit output: Refer to Transceiver User Guide
    //       .CEB(1'b0),     // 1-bit input: Refer to Transceiver User Guide
    //       .I(sgmii_clk_p),         // 1-bit input: Refer to Transceiver User Guide
    //       .IB(sgmii_clk_n)        // 1-bit input: Refer to Transceiver User Guide
    //    );


    // -------------------------pcs_pma IP例化---------------------------
    gig_ethernet_pcs_pma_0 gig_psc_pma (
      .gtrefclk_p(sgmii_clk_p),                         // input wire gtrefclk_p
      .gtrefclk_n(sgmii_clk_n),                         // input wire gtrefclk_n
      .gtrefclk_out(gtrefclk_out),                      // output wire gtrefclk_out
      .gtrefclk_bufg_out(gtrefclk_bufg_out),            // output wire gtrefclk_bufg_out
      .txn(sgmii_tx_n),                                        // output wire txn
      .txp(sgmii_tx_p),                                        // output wire txp
      .rxn(sgmii_rx_n),                                        // input wire rxn
      .rxp(sgmii_rx_p),                                        // input wire rxp
      .independent_clock_bufg(),           // input wire independent_clock_bufg
      .userclk_out(),                                   // output wire userclk_out
      .userclk2_out(gmii_tx_clk),                       // output wire userclk2_out
      .rxuserclk_out(),                                 // output wire rxuserclk_out
      .rxuserclk2_out(gmii_rx_clk),                     // output wire rxuserclk2_out
      .resetdone(resetdone),                            // output wire resetdone
      .pma_reset_out(),                                 // output wire pma_reset_out
      .mmcm_locked_out(mmcm_locked_out),                // output wire mmcm_locked_out
      .sgmii_clk_r(sgmii_clk_r),                        // output wire sgmii_clk_r
      .sgmii_clk_f(sgmii_clk_f),                        // output wire sgmii_clk_f
      .sgmii_clk_en(sgmii_clk_en),                      // output wire sgmii_clk_en
      .gmii_txd(gmii_txd),                              // input wire [7 : 0] gmii_txd
      .gmii_tx_en(gmii_tx_en),                          // input wire gmii_tx_en
      .gmii_tx_er(gmii_tx_er),                          // input wire gmii_tx_er
      .gmii_rxd(gmii_rxd),                              // output wire [7 : 0] gmii_rxd
      .gmii_rx_dv(gmii_rx_dv),                          // output wire gmii_rx_dv
      .gmii_rx_er(gmii_rx_er),                          // output wire gmii_rx_er
      .gmii_isolate(),                                  // output wire gmii_isolate
      .configuration_vector(5'b00000),                  // input wire [4 : 0] configuration_vector
      .speed_is_10_100(1'b0),                           // input wire speed_is_10_100
      .speed_is_100(1'b0),                              // input wire speed_is_100
      .status_vector(status_vector),                                 // output wire [15 : 0] status_vector
      .reset(sys_rst),                                  // input wire reset
      .signal_detect(1'b1),                             // input wire signal_detect
      .gt0_qplloutclk_out(),                            // output wire gt0_qplloutclk_out
      .gt0_qplloutrefclk_out()                          // output wire gt0_qplloutrefclk_out
    );




endmodule

