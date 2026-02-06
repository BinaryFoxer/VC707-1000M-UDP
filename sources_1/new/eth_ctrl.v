`timescale 1ns / 1ps

// ------------------------------------------------------------
// 以太网控制模块：控制切换不同的协议
// ------------------------------------------------------------


module eth_ctrl(
    input                       clk,
    input                       rst,

    // ARP端口信号
    input                       arp_rx_done         ,       // arp报文接收完成
    input                       arp_rx_type         ,       // arp接收报文类型：0请求；1应答
    output     reg              arp_tx_en           ,       // arp发送使能
    output                      arp_tx_type         ,       // arp发送报文类型：0请求；1应答
    input                       arp_tx_done         ,       // arp发送报文完成
    input                       arp_gmii_tx_en      ,       // arp GMII输出数据有效
    input               [7:0]   arp_gmii_txd        ,       // arp GMII发送数据

    // ICMP端口信号
    input                       icmp_tx_start_en    ,       // icmp开始发送信号
    input                       icmp_tx_done        ,       // icmp发送完成信号
    input                       icmp_gmii_tx_en     ,       // icmp GMII输出数据有效信号
    input               [7:0]   icmp_gmii_txd       ,       // icmp GMII发送数据

    // GMII发送接口
    output                      gmii_tx_en          ,       // GMII输出数据有效
    output              [7:0]   gmii_txd                    // GMII发送数据

    );

    // reg define
    reg         protocol_sw;                // 协议切换信号
    reg         icmp_tx_busy;               // ICMP发送忙状态信号
    reg         arp_rx_flag;                // 接收到ARP请求信号标志

    assign      arp_tx_type = 1'b1;         // 固定arp发送类型为应答
    assign      gmii_tx_en  = protocol_sw ? icmp_gmii_tx_en : arp_gmii_tx_en;       // protocol_sw：0：arp报文；1：icmp报文
    assign      gmii_txd    = protocol_sw ? icmp_gmii_txd : arp_gmii_txd;

    // ICMP忙信号控制
    // always @(posedge clk or posedge rst) begin
    //     if(rst)
    //         icmp_tx_busy <= 1'b0;
    //     else if(icmp_tx_start_en)
    //         icmp_tx_busy <= 1'b1;
    //     else if(icmp_tx_done)
    //         icmp_tx_busy <= 1'b0;
    //     else;
    // end

    reg [23:0] icmp_timeout_cnt;  // 125MHz时钟约0.134秒

    always @(posedge clk or posedge rst) begin
        if (rst)
            icmp_timeout_cnt <= 0;
        else if (icmp_tx_start_en)
            icmp_timeout_cnt <= 0;
        else if (icmp_tx_busy && icmp_timeout_cnt < 24'hFFFFFF)
            icmp_timeout_cnt <= icmp_timeout_cnt + 1;
    end

    // 修改icmp_tx_busy逻辑
    always @(posedge clk or posedge rst) begin
        if (rst)
            icmp_tx_busy <= 1'b0;
        else if (icmp_tx_start_en)
            icmp_tx_busy <= 1'b1;
        else if (icmp_tx_done || icmp_timeout_cnt == 24'hFFFFFF)  // 超时复位
            icmp_tx_busy <= 1'b0;
        else;
    end

    // 控制接收到ARP请求信号标志
    always @(posedge clk or posedge rst) begin
        if(rst)
            arp_rx_flag <= 1'b0;
        else if(arp_rx_done && (arp_rx_type == 1'b0))
            arp_rx_flag <= 1'b1;
        else
            arp_rx_flag <= 1'b0;
    end

    // 控制protocol_sw信号和arp_tx_en信号
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            protocol_sw <= 1'b0;
            arp_tx_en <= 1'b0;
        end
        else begin
            arp_tx_en <= 1'b0;
            if(icmp_tx_start_en) 
                protocol_sw <= 1'b1;
            else if(arp_rx_flag && (icmp_tx_busy == 1'b0)) begin
                protocol_sw <= 1'b0;
                arp_tx_en <= 1'b1;
            end
            else;
        end
    end

endmodule
