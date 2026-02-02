`timescale 1ns / 1ps

// -----------------------------------------------------------------
// arp控制模块,通过arp模块发送数据
// -----------------------------------------------------------------


module arp_ctrl(
    input               clk,
    input               sys_rst,

    input               touch_key,                  // 触摸按键触发发送arp请求
    input               arp_rx_done,                // ARP接收数据完成
    input               arp_rx_type,                // ARP接收类型 0:请求  1:应答 
    output   reg        arp_tx_en,                  // ARP发送使能
    output   reg        arp_tx_type                 // ARP发送类型 0:请求  1:应答
    );

    // reg define
    reg             touch_key_d0;
    reg             touch_key_d1;

    // wire define
    wire            pos_touch_key;

    assign pos_touch_key = ~touch_key_d1 & touch_key_d0;

    // 延时打两拍touch_key信号采集上升沿
    always @(posedge clk or posedge sys_rst) begin
        if(sys_rst) begin
            touch_key_d0 <= 1'b0;
            touch_key_d1 <= 1'b0;
        end
        else begin
            touch_key_d0 <= touch_key;
            touch_key_d1 <= touch_key_d0;
        end
    end

    // 赋值给arp发送和arp类型
    always @(posedge clk or posedge sys_rst) begin
        if(sys_rst) begin
            arp_tx_en <= 1'b0;
            arp_tx_type <= 1'b0;
        end
        else begin
            if(pos_touch_key) begin
                arp_tx_en <= 1'b1;                  // 发送arp使能
                arp_tx_type <= 1'b0;                // 发送arp请求
            end
            else if((arp_rx_done == 1'b1) && (arp_rx_type == 1'b0)) begin   // 接收到arp请求,发送arp应答
                arp_tx_en <= 1'b1;
                arp_tx_type <= 1'b1;
            end
            else 
                arp_tx_en <= 1'b0;
        end
    end

endmodule
