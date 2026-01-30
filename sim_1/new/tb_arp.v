`timescale 1ns / 1ns

// -------------------------------------------------------
// arp testbench
// 通过自回环测试arp收发
// -------------------------------------------------------

module tb_arp;

parameter T = 8;                                // 时钟周期8ns
parameter OP_CYCLE = 100;                       // 操作周期

// 板卡mac和ip
parameter BOARD_MAC = 48'h00_0a_35_01_fe_c0;        // 板卡MAC地址
parameter BOARD_IP  = 32'hC0_A8_00_02;              // 板卡IP地址
// 目标mac和ip
parameter   DES_MAC   = 48'hFF_FF_FF_FF_FF_FF;      // PC mac
parameter   DES_IP    = 32'hC0_A8_00_03;            // PC ip

// reg define
reg                 gmii_clk;
reg                 sys_rst;
reg                 arp_tx_en;
reg                 arp_tx_type;
reg     [3:0]       flow_cnt;
reg     [13:0]      delay_cnt;

// wire define
wire                gmii_rx_clk;
wire                gmii_rx_dv;
wire    [7:0]       gmii_rxd   ; //GMII接收数据
wire                gmii_tx_clk; //GMII发送时钟
wire                gmii_tx_en ; //GMII发送数据使能信号
wire    [7:0]       gmii_txd   ; //GMII发送数据

wire                arp_rx_done; //ARP接收完成信号
wire                arp_rx_type; //ARP接收类型 0:请求  1:应答
wire        [47:0]  src_mac    ; //接收到目的MAC地址
wire        [31:0]  src_ip     ; //接收到目的IP地址    
wire        [47:0]  des_mac    ; //发送的目标MAC地址
wire        [31:0]  des_ip     ; //发送的目标IP地址
wire                gmii_tx_done;


assign  gmii_rx_clk = gmii_clk;
assign  gmii_tx_clk = gmii_clk;
assign  gmii_rx_dv  = gmii_tx_en;
assign  gmii_rxd    = gmii_txd;

assign  des_mac     = src_mac;
assign  des_ip      = src_ip;

initial begin
    gmii_clk        = 1'b0;
    sys_rst         = 1'b1;         // 初始复位
    #(T+1) sys_rst = 1'b0;
end

always #(T/2) gmii_clk = ~gmii_clk;

always @(posedge gmii_clk or posedge sys_rst) begin
    if(sys_rst) begin
        arp_tx_en <= 1'b0;
        arp_tx_type <= 1'b0;
        delay_cnt <= 1'b0;
        flow_cnt <= 1'b0;
    end
    else begin
        case (flow_cnt)
            4'd0 : flow_cnt <= flow_cnt + 4'd1;
            4'd1 : begin
                arp_tx_en <= 1'b1;
                arp_tx_type <= 1'b0;        // 发送arp请求
                flow_cnt <= flow_cnt + 4'd1;
            end
            4'd2 : begin
                arp_tx_en <= 1'b0;
                flow_cnt <= flow_cnt + 4'd1; 
            end
            4'd3 : begin
                if(gmii_tx_done) begin
                    flow_cnt <= flow_cnt + 4'd1;
                end
            end 
            4'd4 : begin
                delay_cnt <= delay_cnt + 14'd1;
                if(delay_cnt == OP_CYCLE - 1) begin
                    flow_cnt <= flow_cnt + 4'd1;
                end
            end
            4'd5 : begin
                arp_tx_en <= 1'b1;
                arp_tx_type <= 1'b1;        // arp应答
                flow_cnt <= flow_cnt + 4'd1;
            end
            4'd6 : begin
                arp_tx_en <= 1'b0;
                flow_cnt <= flow_cnt + 4'd1;
            end
            4'd7 : begin
                if(gmii_tx_done)
                    flow_cnt <= flow_cnt + 4'd1;
            end
            default:; 
        endcase
    end
end


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


endmodule
