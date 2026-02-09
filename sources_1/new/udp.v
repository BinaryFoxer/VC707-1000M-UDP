`timescale 1ns / 1ps

// -----------------------------------------------------------
// udp顶层模块
// -----------------------------------------------------------

module udp(
    input                       rst,
    // GMII接口
    input                       gmii_rx_clk,
    input                       gmii_rx_dv,
    input           [7:0]       gmii_rxd,
    input                       gmii_tx_clk,
    output                      gmii_tx_en,
    output          [7:0]       gmii_txd,

    // 用户接口
    output                      rec_pkt_done,                   // 接收数据包完成标志
    output                      rec_en,                         // 接收数据使能
    output          [7:0]       rec_data,                       // udp接收数据
    output          [15:0]      rec_byte_num,                   // 接收有效字节数
    input                       tx_start_en,                    // 开始发送触发信号
    input           [7:0]       tx_data,                        // udp发送数据        
    input           [15:0]      tx_byte_num,                    // 发送有效字节数
    input           [47:0]      des_mac,
    input           [31:0]      des_ip,
    output                      tx_done,                        // 发送完成信号
    output                      tx_req                          // 读取发送数据请求信号
    );

    // parameter define
    parameter   BOARD_MAC  = 48'h00_11_22_33_44_55;
    parameter   BOARD_IP   = {8'd192, 8'd168, 8'd0, 8'd2};
    parameter   DES_MAC    = 48'hff_ff_ff_ff_ff_ff;
    parameter   DES_IP     = {8'd192,8'd168,8'd0,8'd3}; 

    // wire define
    wire            crc_en;
    wire            crc_clr;
    wire    [7:0]   crc_d8;                                     // 待校验8位数据
    wire    [31:0]  crc_data;                                   // 32位CRC校验数据
    wire    [31:0]  crc_next;

    assign crc_d8 = gmii_txd;

    udp_rx #(
        .BOARD_IP(BOARD_IP),
        .BOARD_MAC(BOARD_MAC)
    )u_udp_rx(
        .clk                (gmii_rx_clk),
        .rst                (rst),
        .gmii_rx_dv         (gmii_rx_dv),
        .gmii_rxd           (gmii_rxd),
        .rec_byte_num       (rec_byte_num),
        .rec_data           (rec_data),
        .rec_en             (rec_en),
        .rec_pkt_done       (rec_pkt_done)
    );

    udp_tx #(
        .BOARD_IP(BOARD_IP),
        .BOARD_MAC(BOARD_MAC),
        .DES_IP(DES_IP),
        .DES_MAC(DES_MAC)
    )u_udp_tx(
        .clk                (gmii_tx_clk),    
        .rst                (rst),
        .tx_start_en        (tx_start_en),
        .tx_byte_num        (tx_byte_num),
        .tx_data            (tx_data),
        .crc_data           (crc_data),
        .crc_next           (crc_next[31:24]),
        .des_ip             (des_ip),
        .des_mac            (des_mac),
        .crc_clr            (crc_clr),
        .crc_en             (crc_en),
        .gmii_tx_en         (gmii_tx_en),
        .gmii_txd           (gmii_txd),
        .tx_done            (tx_done),
        .tx_req             (tx_req)

    );

    // CRC校验模块
    CRC32_d8 u_crc32_d8(
        .clk(gmii_tx_clk),    
        .rst(rst),    
        .crc_en(crc_en), 
        .crc_clr(crc_clr),
        .data(crc_d8),        
        .crc_data(crc_data),
        .crc_next(crc_next)
    );


endmodule
