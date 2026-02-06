`timescale 1ns / 1ps

// -----------------------------------
// arp顶层模块
// -----------------------------------

module arp(
    input               rst,
    // gmii接口
    input               gmii_rx_clk,                    // gmii接收时钟
    input               gmii_rx_dv,                     // gmii接收数据有效
    input        [7:0]  gmii_rxd,                       // gmii接收数据
    input               gmii_tx_clk,                    // gmii发送时钟
    output              gmii_tx_en,                     // gmii发送使能
    output       [7:0]  gmii_txd,                       // gmii发送数据
    output              gmii_tx_done,                   // 以太网发送完成

    // 用户接口
    input               arp_tx_en,                      // arp发送使能
    input               arp_tx_type,                    // 发送arp的帧类型：0请求；1应答
    output              arp_rx_done,                    // arp接收数据完成
    output              arp_rx_type,                    // 接收arp帧类型：0请求；1应答
    input        [47:0] des_mac,                        // 目标mac地址
    input        [31:0] des_ip,                         // 目标ip
    output       [47:0] src_mac,                        // 源mac地址
    output       [31:0] src_ip,                         // 源ip地址
    output              arp_led,                        // arp测试led
    output              arp_get,
    output       [4:0]  cur_state

    );

    // parameter define
    // 板卡mac和ip
    parameter  BOARD_MAC = 48'h00_11_22_33_44_55;        // 板卡MAC地址
    parameter  BOARD_IP  = {8'd192,8'd168,8'd0,8'd2}; 
    // 目标mac和ip
    parameter  DES_MAC   = 48'hff_ff_ff_ff_ff_ff;
    parameter  DES_IP    = {8'd192,8'd168,8'd0,8'd3};

    // wire define
    wire          crc_en;             // crc开始接收数据使能
    wire          crc_clr;            // crc复位信号
    wire   [7:0]  data;               // 进行校验的8位数据
    wire  [31:0]  crc_data;           // CRC校验数据
    wire  [31:0]  crc_next;           // 下次校验输出的CRC数据

    assign  data = gmii_txd;

    arp_tx #(
        .BOARD_IP(BOARD_IP),
        .BOARD_MAC(BOARD_MAC),
        .DES_IP(DES_IP),
        .DES_MAC(DES_MAC)
    ) u_arp_tx(
        .clk(gmii_tx_clk),        
        .rst(rst),        
        .arp_tx_en(arp_tx_en),  
        .arp_tx_type(arp_tx_type),
        .des_mac(des_mac),                      // ？？？？ 
        .des_ip(des_ip),     
        .crc_data(crc_data),   
        .crc_next(crc_next[31:24]),   
        .crc_en(crc_en),     
        .crc_clr(crc_clr),    
        .gmii_txd(gmii_txd),   
        .gmii_tx_en(gmii_tx_en), 
        .gmii_tx_done(gmii_tx_done),
        .arp_led(arp_led)
    );

    arp_rx #(
        .BOARD_IP(BOARD_IP),
        .BOARD_MAC(BOARD_MAC)
    )u_arp_rx(
        .rst(rst),       
        .clk(gmii_rx_clk),                   
        .gmii_rx_dv(gmii_rx_dv),
        .gmii_rxd(gmii_rxd),           
        .arp_rx_done(arp_rx_done),
        .arp_rx_type(arp_rx_type),
        .src_ip(src_ip),    
        .src_mac(src_mac),
        .arp_get(arp_get),
        .cur_state(cur_state)    

    );

    CRC32_d8 u_crc32_d8(
        .clk(gmii_tx_clk),    
        .rst(rst),    
        .crc_en(crc_en), 
        .crc_clr(crc_clr),
        .data(data),        
        .crc_data(crc_data),
        .crc_next(crc_next)
    );

endmodule
