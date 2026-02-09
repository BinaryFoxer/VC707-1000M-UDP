`timescale 1ns / 1ps

// -------------------------------------------------------
// 以太网顶层协议控制模块
// 当前支持ARP、ICMP、UDP三种协议切换
// -------------------------------------------------------


module eth_ctrl_sw(
    input                   clk,
    input                   rst,

    // ARP端口信号
    input                   arp_rx_done,                   // ARP数据包接收完成信号
    input                   arp_rx_type,                   // ARP接收类型，0：请求；1：应答
    output  reg             arp_tx_en,                     // ARP发送模块使能信号（开始组包）
    output                  arp_tx_type,                   // ARP发送类型，0：请求；1：应答
    input                   arp_tx_done,                   // ARP单包发送完成
    input                   arp_gmii_tx_en,                // ARP使能gmii_txd发送数据
    input           [7:0]   arp_gmii_txd,                  // ARP通过gmii_txd发送的数据

    // ICMP端口信号
    input                   icmp_tx_start_en,              // ICMP发送模块使能信号（开始组包）
    input                   icmp_tx_done,                  // ICMP单包发送完成
    input                   icmp_gmii_tx_en,               // ICMP使能gmii_txd发送数据
    input           [7:0]   icmp_gmii_txd,                 // ICMP通过gmii_txd发送的数据

    // ICMP fifo接口信号
    input                   icmp_rec_en,                   // ICMP接收数据使能信号
    input           [7:0]   icmp_rec_data,
    input                   icmp_tx_req,                   // ICMP读数据请求信号
    output          [7:0]   icmp_tx_data,                  // ICMP待发送数据

    // UDP相关端口信号
    input                   udp_tx_start_en,               // ICMP发送模块使能信号（开始组包）
    input                   udp_tx_done,                   // UDP发送完成信号
    input                   udp_gmii_tx_en,                // UDP使能gmii_txd发送数据
    input           [7:0]   udp_gmii_txd,                  // UDP通过gmii_txd发送的数据

    // UDP fifo接口信号
    input                   udp_rec_en,                   // ICMP接收数据使能信号
    input           [7:0]   udp_rec_data,
    input                   udp_tx_req,                   // ICMP读数据请求信号
    output          [7:0]   udp_tx_data,                  // ICMP待发送数据

    // fifo接口信号
    input           [7:0]   tx_data,                      // 待发送数据
    output                  tx_req,
    output  reg             rec_en,
    output  reg     [7:0]   rec_data,

    // GMII发送引脚
    output  reg             gmii_tx_en,
    output  reg     [7:0]   gmii_txd
    );

    // define reg
    reg [1:0]   protocol_sw;
    reg         icmp_tx_busy;
    reg         udp_tx_busy;
    reg         arp_rx_flag;
    reg         icmp_tx_req_d0;
    reg         udp_tx_req_d0;

    assign  arp_tx_type = 1'b1;                         // 测试用，只做应答
    assign  tx_req = udp_tx_req ? 1'b1 : icmp_tx_req;
    assign  icmp_tx_data = icmp_tx_req_d0 ? tx_data : 8'd0;
    assign  udp_tx_data = udp_tx_req_d0 ? tx_data : 8'd0;

    // 寄存一拍请求信号，让数据慢请求一拍
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            icmp_tx_req_d0 <= 1'b0;
            udp_tx_req_d0 <= 1'b0;
        end
        else begin
            icmp_tx_req_d0 <= icmp_tx_req;
            udp_tx_req_d0 <= udp_tx_req;
        end
    end

    // 接收使能信号判断接收数据
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            rec_en  <= 1'b0;
            rec_data <= 8'd0;
        end
        else if(icmp_rec_en) begin
            rec_en <= icmp_rec_en;
            rec_data <= icmp_rec_data;
        end
        else if(udp_rec_en) begin
            rec_en <= udp_rec_en;
            rec_data <= udp_rec_data;
        end
        else begin
            rec_en <= 1'b0;
            rec_data <= rec_data;
        end
    end

    // 协议切换
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            gmii_tx_en <= 1'b0;
            gmii_txd <= 8'd0;
        end
        else begin
            case(protocol_sw)
                2'b00:begin
                    gmii_tx_en <= arp_gmii_tx_en;
                    gmii_txd   <= arp_gmii_txd;
                end

                2'b01:begin
                    gmii_tx_en <= icmp_gmii_tx_en;
                    gmii_txd   <= icmp_gmii_txd;
                end

                2'b10:begin
                    gmii_tx_en <= udp_gmii_tx_en;
                    gmii_txd   <= udp_gmii_txd;
                end

                default: ;
            endcase
        end
    end

    // 超时清零机制
    reg [23:0] timeout_cnt;  // 125MHz时钟约0.134秒

    always @(posedge clk or posedge rst) begin
        if (rst)
            timeout_cnt <= 0;
        else if (icmp_tx_start_en)
            timeout_cnt <= 0;
        else if ((icmp_tx_busy && timeout_cnt < 24'hFFFFFF) || (udp_tx_busy && timeout_cnt < 24'hFFFFFF))
            timeout_cnt <= timeout_cnt + 1;
    end


    // 控制ICMP发送忙信号
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            icmp_tx_busy <= 1'b0;
        end
        else if(icmp_tx_start_en) begin
            icmp_tx_busy <= 1'b1;
        end
        else if(icmp_tx_done || timeout_cnt == 24'hFFFFFF) begin
            icmp_tx_busy <= 1'b0;
        end
        else;
    end

    // 控制UDP发送忙信号
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            udp_tx_busy <= 1'b0;
        end
        else if(udp_tx_start_en) begin
            udp_tx_busy <= 1'b1;
        end
        else if(udp_tx_done || timeout_cnt == 24'hFFFFFF) begin
            udp_tx_busy <= 1'b0;
        end
        else;
    end

    // 控制ARP接收请求标志
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            arp_rx_flag <= 1'b0;
        end
        else if(arp_rx_done && (arp_rx_type == 1'b0))
            arp_rx_flag <= 1'b1;
        else 
            arp_rx_flag <= 1'b0;
    end

    // 控制protocol协议切换信号和arp_tx_en信号
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            protocol_sw <= 2'b00;
            arp_tx_en   <= 1'b0;
        end
        else begin
            arp_tx_en <= 1'b0;
            if(udp_tx_start_en)
                protocol_sw <= 2'b10;
            else if(icmp_gmii_tx_en)
                protocol_sw <= 2'b01;
            else if((arp_rx_flag && (udp_tx_busy == 1'b0)) || (arp_rx_flag && (icmp_tx_busy == 1'b0))) begin
                protocol_sw <= 2'b00;
                arp_tx_en <= 1'b1;
            end
            else;
        end
    end


endmodule
