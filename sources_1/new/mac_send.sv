`timescale 1ns / 1ps

module mac_send(
    // 控制信号
    input tx_go,
    input rst_n,
    input [10:0] pyd_length,   //payload部分数据长度
    
    // mac帧头
    input [47:0] src_mac,
    input [47:0] des_mac,
    input [15:0] type_length,
    
    // mac数据载荷
    output reg fifo_rdreq,
    input [7:0] fifo_rddata,
    input fifo_rdclk,
    
    // CRC校验码
    input [31:0] crc_result,
    
    // gmii数据传输接口
    input gmii_clk,
    output reg gmii_tx_en,
    output reg gmii_tx_err,
    output reg [7:0] gmii_tx_data
    
    );
    
    // ====================寄存器设计==================
    reg [5:0] cnt;  // 发送字节计数逻辑
    reg en_cnt; // 状态计数使能信号，用于在23读取FIFO时让计数停止下来
    reg [10:0] pyd_data_num;    // payload字节计数
    reg en_tx;
    
    parameter CRC32 = 32'h967D1D69;
    assign crc_result = {CRC32[7:0], CRC32[15:8], CRC32[23:16], CRC32[31:24]};
    
    // =================序列化发送逻辑==================
    always@(posedge gmii_clk or negedge rst_n) begin
        if(!rst_n) begin
            gmii_tx_data <= 8'd0;
        end else begin
            case(cnt)
                1, 2, 3, 4, 5, 6, 7:
                     gmii_tx_data <= 8'h55;     // 前导码
                     
                8: gmii_tx_data <= 8'hd5;       // 分隔符
                // 目标mac
                9: gmii_tx_data <= des_mac[47:40];
                10: gmii_tx_data <= des_mac[39:32];
                11: gmii_tx_data <= des_mac[31:24];
                12: gmii_tx_data <= des_mac[23:16];
                13: gmii_tx_data <= des_mac[15:8];
                14: gmii_tx_data <= des_mac[7:0];
                // 源mac
                15: gmii_tx_data <= src_mac[47:40];
                16: gmii_tx_data <= src_mac[39:32];
                17: gmii_tx_data <= src_mac[31:24];
                18: gmii_tx_data <= src_mac[23:16];
                19: gmii_tx_data <= src_mac[15:8];
                20: gmii_tx_data <= src_mac[7:0];
                // 类型长度
                21: gmii_tx_data <= type_length[15:8];
                22: gmii_tx_data <= type_length[7:0];
                // 从fifo中读取payload
                23: gmii_tx_data <= fifo_rddata;
                
                24: gmii_tx_data <= crc_result[31:24];
                25: gmii_tx_data <= crc_result[23:16];
                26: gmii_tx_data <= crc_result[15:8];
                27: gmii_tx_data <= crc_result[7:0];
                
                // 发送帧间间隔
                28: gmii_tx_data <= 8'd0;
                default: gmii_tx_data <= 8'd0;
         
            endcase
        
        end
        
    end
    
    // ================计数值23时向FIFO请求数据==============
    // en_cnt没有延时一拍，立刻就拉下来
    assign en_cnt = !((cnt==23) && (pyd_data_num>1));  //计数停止，读取fifo数据的条件
    assign fifo_rdreq = !en_cnt;
    
//    // fifo_rdreq延了一拍
//    always@(posedge gmii_clk or negedge rst_n) begin
//        if(!rst_n) begin
//            fifo_rdreq <= 1'd0;     
//        end else if(!en_cnt) begin
//                fifo_rdreq <= 1'd1;   
//        end else begin
//            fifo_rdreq <= 1'd0;
//        end
        
//    end
    
    // 用读取数据长度控制读取fifo时间
    always@(posedge gmii_clk or negedge rst_n) begin
        if(!rst_n) begin
            pyd_data_num <= 11'd0;
        end else if(tx_go) begin    // tx_go是一个脉冲信号，只在开始发送时输出1次高电平
            pyd_data_num <= pyd_length;      
        end else if(!en_cnt) begin
                pyd_data_num <= pyd_data_num - 11'd1;   
        end else begin
            pyd_data_num <= pyd_data_num;
        end
     
    end
    
    // =================cnt计数逻辑==================
    // 内部发送使能，实际发送时间不会有发送间隔那么长
    always@(posedge gmii_clk or negedge rst_n) begin
        if(!rst_n)
            en_tx <= 1'b0;
        else if(tx_go) 
            en_tx <= 1'b1;
        else if(cnt >= 6'd27)
            en_tx <= 1'b0;
        else 
            en_tx <= en_tx;
       
    end
    
    always@(posedge gmii_clk or negedge rst_n) begin
        if(!rst_n)
            cnt <= 5'd0;
        else if(en_tx) begin
            if(!en_cnt) 
                cnt <= cnt;
            else 
                cnt <= cnt + 6'd1;
        end else begin
            cnt <= 6'd0;
        end
    
    end
    
    // =====================gmii转sgmii高速串行接口========================
    // VC707评估板仅支持sgmii接口传输
    

    
    
   
endmodule



