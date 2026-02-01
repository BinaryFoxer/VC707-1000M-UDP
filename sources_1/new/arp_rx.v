`timescale 1ns / 1ps

// ----------------------------------------------------------------
// 接收：电脑端发送数据gmii_rxd
// 功能：完成mac帧的接收，依据mac帧结构判断接收是否正确/是否为目的方
// 完成CRC32码的校验？
// ----------------------------------------------------------------

module arp_rx(
    input                   rst,            // 系统复位                
    input                   clk,            // 必须是gmii接收时钟
    
    input                   gmii_rx_dv,     // gmii接收数据有效
    input          [7:0]    gmii_rxd,       // gmii接收数据

    output reg              arp_rx_done,    // arp接收数据处理完毕
    output reg              arp_rx_type,    // arp接收数据类型：请求/应答
    output reg     [31:0]   src_ip,         // 发送方源ip地址
    output reg     [47:0]   src_mac,        // 发送方源mac地址
    output reg              arp_get,
    output reg     [4:0]    cur_state
    );

    // parameter define
    parameter  BOARD_MAC = 48'h00_11_22_33_44_55;        // 板卡MAC地址
    parameter  BOARD_IP  = {8'd192,8'd168,8'd0,8'd2};
    
    localparam ETH_TYPE     = 16'h08_06;                    // 以太网帧类型—ARP帧为0806
    localparam st_idle      = 5'b0_0001;
    localparam st_preamble  = 5'b0_0010;
    localparam st_header    = 5'b0_0100;
    localparam st_arp_data  = 5'b0_1000;
    localparam st_arp_end   = 5'b1_0000;

    // reg define
    // reg [4:0]   cur_state;
    reg [4:0]   next_state;
    reg [4:0]   cnt;                      // 计数接收的字节
    reg         skip_en;                  // 状态跳转使能
    reg         error_en;                 // 错误跳转使能
    reg [47:0]  des_mac_t;                // 寄存接收到的目的mac
    reg [31:0]  des_ip_t;                 // 寄存接收到的目的ip
    reg [15:0]  eth_type_t;               // 寄存接收到的以太帧类型
    reg [15:0]  op_code;                  // 操作码
    reg [47:0]  src_mac_t;                // 寄存接收到的源mac
    reg [31:0]  src_ip_t;                 // 寄存接收到的源ip 
    reg         rx_done_t;                // 寄存arp接收数据处理完成信号                             


    // ----------------------------arp接收帧处理----------------------------
    // 同步时序描述状态转移
    always @(posedge clk or posedge rst) begin
        if(rst) 
            cur_state <= st_idle;
        else
            cur_state <= next_state;
    end

    // 组合逻辑描述状态转移条件
    always @(*) begin
        next_state = cur_state;
        case (cur_state)
            st_idle:begin
                if(skip_en) 
                    next_state = st_preamble;
                else
                    next_state = st_idle;
            end

            st_preamble:begin
                if(skip_en)
                    next_state = st_header;
                else if(error_en)
                    next_state = st_arp_end;
                else
                    next_state = st_preamble;
            end

            st_header:begin
                if(skip_en)
                    next_state = st_arp_data;
                else if(error_en)
                    next_state = st_arp_end;
                else
                    next_state = st_header;
            end

            st_arp_data:begin
                if(skip_en)
                    next_state = st_arp_end;
                else if(error_en)
                    next_state = st_arp_end;
                else   
                    next_state = st_arp_data;
            end

            st_arp_end:begin
                if(skip_en)
                    next_state = st_idle;
                else
                    next_state = st_arp_end;
            end

            default: next_state = st_idle;
        endcase
    end

    // 同步时序描述状态输出
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            cnt         <= 5'd0;
            skip_en     <= 1'd0;
            error_en    <= 1'd0;
            des_mac_t   <= 48'd0;
            des_ip_t    <= 32'd0;
            eth_type_t  <= 16'd0;
            op_code     <= 16'd0;
            src_mac_t   <= 48'd0;
            src_ip_t    <= 32'd0;
            rx_done_t   <= 1'd0;
            arp_rx_type <= 1'd0;
            src_ip      <= 32'd0;
            src_mac     <= 48'd0;
            arp_get     <= 1'b0;
        end
        else begin
            skip_en <= 1'b0;
            error_en <= 1'b0;
            rx_done_t <= 1'b0;
            arp_get   <= 1'b0;
            case(next_state)                                        // 想要cur_state跳转后立刻输出这里必须用next_state
                st_idle:begin
                    if((gmii_rx_dv == 1) && (gmii_rxd == 8'h55)) begin
                        skip_en <= 1'b1;                            // 接收数据有效并且检测到前导码
                    end
                end

                st_preamble:begin
                    if(gmii_rx_dv == 1'b1) begin
                        cnt <= cnt + 5'd1;
                        if((cnt < 5'd6) && (gmii_rxd != 8'h55)) 
                            error_en <= 1'b1;               // 如果前七个字节里已经出现错误
                        else if(cnt == 5'd6) begin
                            cnt <= 5'b0;
                            if(gmii_rxd == 8'hd5)begin           // 第八个字节检测到起始字符
                                skip_en <= 1'b1;
                            end
                            else
                                error_en <= 1'b1;
                        end
                    end
                end

                st_header:begin                            // 判断目的mac，帧类型
                    if(gmii_rx_dv == 1'b1) begin
                        cnt <= cnt + 5'd1;
                        if(cnt < 5'd6) 
                            des_mac_t <= {des_mac_t[39:0], gmii_rxd};   // 接收目的mac
                        else if(cnt == 5'd6) begin
                            if((des_mac_t != BOARD_MAC) && des_mac_t != 48'hff_ff_ff_ff_ff_ff)           
                                error_en <= 1'b1;         // 目的mac不是板卡并且不是广播地址  
                        end
                        else if(cnt == 5'd12) 
                            eth_type_t[15:8] <= gmii_rxd;  // 接收帧类型
                        else if(cnt == 5'd13) begin
                            cnt <= 5'd0;
                            eth_type_t[7:0] <= gmii_rxd;   // 接收帧类型
                            if((eth_type_t[15:8] == ETH_TYPE[15:8]) && 
                                (gmii_rxd == ETH_TYPE[7:0])) begin
                                    skip_en <= 1'b1;
                                    
                                end            // 判断是否是ARP类型 
                            else
                                error_en <= 1'b1;
                        end
                    end
                end

                st_arp_data:begin
                    if(gmii_rx_dv == 1'b1) begin
                        cnt <= cnt + 5'd1;
                        if(cnt == 5'd6)                                 // 操作码
                            op_code[15:8] <= gmii_rxd;
                        else if(cnt == 5'd7)
                            op_code[7:0] <= gmii_rxd;
                        else if(cnt >= 5'd8 && cnt < 5'd14)             // 源mac
                            src_mac_t <= {src_mac_t[39:0], gmii_rxd};
                        else if(cnt >= 5'd14 && cnt < 5'd18)            // 源ip
                            src_ip_t <= {src_ip_t[23:0], gmii_rxd};
                        else if(cnt >= 5'd24 && cnt < 5'd28)            // 目的ip
                            des_ip_t <= {des_ip_t[23:0], gmii_rxd};
                        else if(cnt == 5'd28) begin
                            cnt <= 5'd0;
                            if(des_ip_t == BOARD_IP) begin
                                arp_get <= 1'b1;
                                if(op_code == 16'd1 || op_code == 16'd2) begin
                                    skip_en   <= 1'b1;
                                    rx_done_t <= 1'b1;
                                    src_mac   <= src_mac_t;
                                    src_ip    <= src_ip_t;
                                    src_mac_t <= 48'd0;
                                    src_ip_t  <= 32'd0;
                                    des_mac_t <= 48'd0;
                                    des_ip_t  <= 32'd0;
                                    if(op_code == 16'd1)
                                        arp_rx_type <= 1'b0;            // arp请求
                                    else
                                        arp_rx_type <= 1'b1;            // arp应答
                                end
                                else
                                    error_en <= 1'b1;
                            end
                            else  
                                error_en <= 1'b1;
                        end
                    end
                end

                st_arp_end:begin
                    cnt <= 5'd0;
                    // 单个包数据接收完成
                    if(gmii_rx_dv == 1'b0 && skip_en == 1'b0)
                        skip_en <= 1'b1;    
                end
            default: ;
            endcase
        end
    end

// 输出arp_rx_done信号
always @(posedge clk or posedge rst) begin
    if(rst)
        arp_rx_done <= 1'b0;
    else
        arp_rx_done <= rx_done_t;
end

endmodule
