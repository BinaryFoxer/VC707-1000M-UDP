`timescale 1ns / 1ps
 
module test_top(
    input sys_clk_p,     // 200MHz系统时钟
    input sys_clk_n,
    
    // 125MHz GTX参考时钟，由板上时钟芯片产生
    input gtrefclk_p,          // 连接到AH8
    input gtrefclk_n,          // 连接到AH7
    
    input sys_rst_n,  
    output reg phy_rst_n,
    
    // sgmii接口
    output txp,
    output txn,
    input rxp,
    input rxn,
    
    // 状态指示
    output led_link,

    output wire [7:0] test_gmii_tx_data,
    output wire test_gmii_tx_en,
    output wire test_gmii_tx_err
    );
    
    // ======================内部信号=========================
    wire userclk;
    wire userclk2;
    wire sys_clk_200m;     // 200MHz系统时钟
    wire refclk_125m;     // 125MHz参考时钟
    
    // ARP模块到PCS/PMA的GMII接口
    wire gmii_tx_err;     
    wire gmii_tx_en;      
    wire [7:0] gmii_tx_data;
    
    wire [7:0] gmii_rxd;
    wire gmii_rx_dv;
    wire gmii_rx_er;
    
    wire gmii_isolate;
    
    // 添加测试信号输出
    assign test_gmii_tx_data = gmii_tx_data;
    assign test_gmii_tx_en = gmii_tx_en;
    assign test_gmii_tx_err = gmii_tx_err;
    
    // PCS控制mdio接口
    wire mdc;
    wire mdio_o; 
    wire mdio_t;

    // 外部mdio控制接口
    wire ext_mdc;
    wire ext_mdio_o;
    wire ext_mdio_t;
    
    wire resetdone;
    wire [15:0] status_vector;
    
    wire mmcm_locked_out;

    // SGMII接口
    wire sgmii_clk_f;   // Differential clock for GMII transmit data
    wire sgmii_clk_r;
    wire sgmii_clk_en;  // clock for GMII transmit data
        
    // ======================复位逻辑============================
    reg pcs_pma_rst = 1'b1;         // IP核复位
    reg arp_reset_n = 1'b0;         // arp发送模块复位
    reg [23:0] rst_counter = 24'd0;
    always@(posedge sys_clk_200m) begin
        if(!sys_rst_n) begin
            rst_counter <= 24'd0;
            pcs_pma_rst <= 1'b1;
            arp_reset_n <= 1'b0;
            phy_rst_n <= 1'b0;
        end else begin
            // PHY 硬件复位
            // if(rst_counter < 24'd200_000) begin
            if(rst_counter < 24'd200_000) begin

                rst_counter <= rst_counter + 24'd1;
                pcs_pma_rst <= 1'b1;          // IP核复位保持高
                arp_reset_n <= 1'b0;          // ARP模块复位保持
                phy_rst_n <= 1'b0;            // 保持PHY芯片复位状态
                // 等待PHY初始化
             end else if(rst_counter < 24'd2_200_000) begin
                rst_counter <= rst_counter + 24'd1;
                phy_rst_n <= 1'b1;  // 释放PHY复位

                pcs_pma_rst <= 1'b1;  // IP核复位保持高
                arp_reset_n <= 1'b0;    // ARP模块复位保持
                // 等待PCS/PMA复位完成
             end else begin
                rst_counter <= rst_counter;
                pcs_pma_rst <= 1'b0;    // 释放IP模块复位
                if(resetdone) begin
                    arp_reset_n <= 1'b1;  // 释放ARP模块复位
                end
                
             end
               
        end
        
    end
    // =============================时钟处理===========================
    
    // 系统时钟输入
    IBUFDS sys_clk_ibufgds (
      .I(sys_clk_p),
      .IB(sys_clk_n),
      .O(sys_clk_200m)
    );
    
    // 参考时钟输入
    IBUFDS refclk_ibufgds (
      .I(gtrefclk_p),
      .IB(gtrefclk_n),
      .O(refclk_125m)
    );
    
   // =====================例化ARP协议栈========================
   arp_send arp_mac_send(
    .rst_n(arp_reset_n),
    .gmii_clk(userclk2),
    
    .gmii_tx_err(gmii_tx_err),
    .gmii_tx_en(gmii_tx_en),
    .gmii_tx_data(gmii_tx_data)

    );
    
    // =====================状态指示========================
    // 使用status_vector来驱动LED
    // status_vector[0]通常表示链路状态
    // status_vector[1]通常表示链路速度
    assign led_link = status_vector[0];  // 链路状态
        
   // =====================例化PCS/PMA IP核=====================
    gig_ethernet_pcs_pma_1 pcs_pma_v (
      .gtrefclk_p(gtrefclk_p),                          // input wire gtrefclk_p
      .gtrefclk_n(gtrefclk_n),                          // input wire gtrefclk_n
      
      .gtrefclk_out(),                      // output wire gtrefclk_out
      .gtrefclk_bufg_out(),            // output wire gtrefclk_bufg_out
      
      .txn(txn),                                        // output wire txn
      .txp(txp),                                        // output wire txp
      .rxn(rxn),                                        // input wire rxn
      .rxp(rxp),                                        // input wire rxp
      
      .independent_clock_bufg(sys_clk_200m),  // input wire independent_clock_bufg
      .userclk_out(userclk),                        // output wire userclk_out
      .userclk2_out(userclk2),                      // output wire userclk2_out
      .rxuserclk_out(),                    // output wire rxuserclk_out
      .rxuserclk2_out(),                  // output wire rxuserclk2_out
      
      .resetdone(resetdone),                            // output wire resetdone
      .pma_reset_out(),                    // output wire pma_reset_out
      .mmcm_locked_out(mmcm_locked_out),                // output wire mmcm_locked_out
      
      .sgmii_clk_r(sgmii_clk_r),                        // output wire sgmii_clk_r
      .sgmii_clk_f(sgmii_clk_f),                        // output wire sgmii_clk_f
      .sgmii_clk_en(sgmii_clk_en),                      // output wire sgmii_clk_en

      .gmii_txd(gmii_tx_data),                              // input wire [7 : 0] gmii_txd
      .gmii_tx_en(gmii_tx_en),                          // input wire gmii_tx_en
      .gmii_tx_er(gmii_tx_err),                          // input wire gmii_tx_er
      .gmii_rxd(gmii_rxd),                              // output wire [7 : 0] gmii_rxd
      .gmii_rx_dv(gmii_rx_dv),                          // output wire gmii_rx_dv
      .gmii_rx_er(gmii_rx_er),                          // output wire gmii_rx_er
      .gmii_isolate(),                      // output wire gmii_isolate
      
      // 控制PCS的管理寄存器，是否使用？
      .mdc(),                                        // input wire mdc
      .mdio_i(1'b1),                                  // input wire mdio_i
      .mdio_o(),                                  // output wire mdio_o
      .mdio_t(),                                  // output wire mdio_t
          
      // 控制外部PHY的mdio接口，是否使用？
      .ext_mdc(ext_mdc),                                // output wire ext_mdc
      .ext_mdio_i(1'b0),                          // input wire ext_mdio_i
      .mdio_t_in(1'b1),                            // input wire mdio_t_in
      .ext_mdio_o(ext_mdio_o),                          // output wire ext_mdio_o
      .ext_mdio_t(ext_mdio_t),                          // output wire ext_mdio_t
      
      .phyaddr(5'b00111),                                // input wire [4 : 0] phyaddr
      
      .configuration_vector(5'b10000),      // input wire [4 : 0] configuration_vector
      .configuration_valid(1'b1),        // input wire configuration_valid
      .an_interrupt(),                      // output wire an_interrupt
      
      .an_adv_config_vector(16'b0001_0011_0000_0001),      // input wire [15 : 0] an_adv_config_vector
      .an_adv_config_val(1'b1),            // input wire an_adv_config_val
      .an_restart_config(1'b0),            // input wire an_restart_config
      .speed_is_10_100(1'b0),                // input wire speed_is_10_100
      .speed_is_100(1'b0),                      // input wire speed_is_100
      .status_vector(status_vector),                    // output wire [15 : 0] status_vector
      
      .reset(pcs_pma_rst),                                    // input wire reset
      .signal_detect(1'b1),                    // input wire signal_detect
      .gt0_qplloutclk_out(),          // output wire gt0_qplloutclk_out
      .gt0_qplloutrefclk_out()    // output wire gt0_qplloutrefclk_out
    );
    
        
endmodule
