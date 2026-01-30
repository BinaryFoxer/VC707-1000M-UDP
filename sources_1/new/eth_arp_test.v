`timescale 1ns / 1ps

// ------------------------------------------------------------------
// ARP测试模块,发送测试数据验证链路是否连通
// ------------------------------------------------------------------

module eth_arp_test(
    input               sgmii_clk_n,             // 125m参考时钟
    input               sgmii_clk_p,
    input               sys_rst,
    input               touch_key,

    input               sgmii_rxn,                      
    input               sgmii_rxp,
    output              sgmii_txn,
    output              sgmii_txp,              
    output              eth_rst_n               // 以太网模块复位
    );

    // parameter define
    // 板卡mac和ip
    // parameter BOARD_MAC  = 48'h00_0a_35_01_fe_c0;        // 板卡MAC地址
    parameter  BOARD_MAC = 48'h00_11_22_33_44_55;        // 板卡MAC地址
    parameter  BOARD_IP  = 32'hC0_A8_00_02;              // 板卡IP地址
    // 目标mac和ip
    parameter  DES_MAC   = 48'hff_ff_ff_ff_ff_ff;
    parameter  DES_IP    = 32'hC0_A8_00_03;            // PC ip

    // wire define
    wire                gmii_tx_en;
    wire                gmii_tx_er;
    wire        [7:0]   gmii_txd;
    wire                gmii_tx_clk;
    wire                gmii_tx_done;
    wire                gmii_rx_clk;
    wire                gmii_rx_dv;
    wire                gmii_rx_er;
    wire        [7:0]   gmii_rxd;

    wire                arp_tx_en;
    wire                arp_tx_type;
    wire                arp_rx_done;
    wire                arp_rx_type;
    wire                resetdone;
    wire                mmcm_locked_out;
    wire                des_mac;
    wire                des_ip;
    wire                src_ip;
    wire                src_mac;

    assign eth_rst_n = ~sys_rst;

    // arp模块例化
    arp #(
        .DES_IP             (DES_IP),
        .DES_MAC            (DES_MAC),
        .BOARD_IP           (BOARD_IP),
        .BOARD_MAC          (BOARD_MAC)
    )u_arp(
        .rst                (sys_rst),          
        .gmii_rx_clk        (gmii_rx_clk),
        .gmii_rx_dv         (gmii_rx_dv), 
        .gmii_rxd           (gmii_rxd),   
        .gmii_tx_clk        (gmii_tx_clk),
        .gmii_tx_en         (gmii_tx_en), 
        .gmii_txd           (gmii_txd),   
        .gmii_tx_done       (gmii_tx_done),          
        .arp_tx_en          (arp_tx_en),  
        .arp_tx_type        (arp_tx_type),
        .arp_rx_done        (arp_rx_done),
        .arp_rx_type        (arp_rx_type),
        .des_mac            (des_mac),    
        .des_ip             (des_ip),     
        .src_mac            (src_mac),    
        .src_ip             (src_ip)  
    );

    // arp控制模块例化
    arp_ctrl u_arp_ctrl(
        .clk                (gmii_rx_clk),        
        .sys_rst            (sys_rst),    
        .touch_key          (touch_key),  
        .arp_rx_done        (arp_rx_done),
        .arp_rx_type        (arp_rx_type),
        .arp_tx_en          (arp_tx_en),  
        .arp_tx_type        (arp_tx_type) 
    );
 
    // sgmii gmii接口转换例化
    sgmii_to_gmii u_sgmii_gmii(
        .sys_rst            (sys_rst),             
        .sgmii_clk_n        (sgmii_clk_n),   
        .sgmii_clk_p        (sgmii_clk_p),   
        .sgmii_rx_n         (sgmii_rxn),    
        .sgmii_rx_p         (sgmii_rxp),    
        .gmii_tx_en         (gmii_tx_en),    
        .gmii_tx_er         (),    
        .gmii_txd           (gmii_txd),                            
        .gmii_rx_clk        (gmii_rx_clk),   
        .gmii_rx_dv         (gmii_rx_dv),    
        .gmii_rx_er         (),    
        .gmii_rxd           (gmii_rxd),      
        .gmii_tx_clk        (gmii_tx_clk),   
        .sgmii_tx_n         (sgmii_txn),    
        .sgmii_tx_p         (sgmii_txp),                          
        .resetdone          (resetdone),     
        .mmcm_locked_out    (mmcm_locked_out)

    );


endmodule
