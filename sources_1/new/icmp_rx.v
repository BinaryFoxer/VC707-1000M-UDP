`timescale 1ns / 1ps

// --------------------------------------------------------
// icmp数据报文接收逻辑
// 用于回复电脑ping应答命令
// --------------------------------------------------------

module icmp_rx(
    input                       gmii_rx_clk,
    input                       gmii_rx_dv,
    input               [7:0]   gmii_rxd,
    input                       rst,

    output   reg        [15:0]  icmp_id,                    // icmp的id号，相同id表示一组icmp应答
    output   reg        [15:0]  icmp_seq,                   // icmp序列号，标识icmp报文的类型
    output   reg        [15:0]  rec_byte_num,               // 接收icmp报文payload的字节数
    output   reg        [7:0]   rec_data,                   // icmp报文的数据，存入到FIFO中
    output   reg        [31:0]  reply_check_sum,            // 头部校验和
    output   reg                rec_en,                     // 接收icmp数据使能，用于FIFO的输入使能
    output   reg                rec_pkt_done                // 接收数据包完成
    );

    // parameter define
    parameter BOARD_MAC = 48'h00_11_22_33_44_55;
    parameter BOARD_IP  = {8'd192, 8'd168, 8'd0, 8'd2};

    // 状态机定义
    localparam st_idle              = 7'b000_0001;
    localparam st_preamble          = 7'b000_0010;
    localparam st_eth_header        = 7'b000_0100;
    localparam st_ip_header         = 7'b000_1000;
    localparam st_icmp_header       = 7'b001_0000;
    localparam st_rx_data           = 7'b010_0000;
    localparam st_rx_end            = 7'b100_0000;

    // 以太网类型定义
    localparam ETH_TYPE     = 16'h0800;         // 以太网协议类型，IP
    localparam ICMP_TYPE    = 8'd1;             // ICMP协议类型

    // ICMP报文类型
    localparam ECHO_REQUEST = 8'h08;            // ICMP报文类型是回显请求

    // reg define
    reg [6:0]   cur_state;
    reg [6:0]   next_state;
    reg         skip_en;
    reg         error_en;
    reg [4:0]   cnt;
    reg [47:0]  des_mac;                        // ICMP是独立于arp的另一种报文，不存在复用
    reg [31:0]  des_ip;
    reg [15:0]  eth_type;                       // 以太网类型
    reg [5:0]   ip_head_byte_num;               // ip头部数据字节计数
    reg [15:0]  ip_total_length;                // IP报文总长度
    reg [1:0]   rec_en_cnt;                     // 8bit转32bit计数器，这里没有用到
    reg [7:0]   icmp_type;                      // ICMP报文类型：用于标识错误的差错报文或者查询类型的报告报文
    reg [7:0]   icmp_code;                      // ICMP报文代码：根据ICMP差错报文的类型，进一步分析错误的原因

    reg [15:0]  icmp_checksum;                   // 接收数据头部校验和
    reg [15:0]  icmp_data_length;                // ICMP有效数据总长度
    reg [15:0]  icmp_rx_cnt;                     // ICMP接收数据字节计数器
    reg [7:0]   icmp_rx_data_d0;                 // 缓存一拍icmp数据：头部校验和16bit计算一次
    reg [31:0]  reply_checksum_add;              // 头部校验和加法器


// ------------------------------ICMP接收数据处理状态机----------------------------------
    always @(posedge gmii_rx_clk or posedge rst) begin
        if(rst)
            cur_state <= st_idle;
        else
            cur_state <= next_state;
    end

    always @(*) begin
        next_state = st_idle;
        case(cur_state)
            st_idle:begin
                if(skip_en)
                    next_state = st_preamble;
                else
                    next_state = st_idle;
            end

            st_preamble:begin
                if(skip_en)
                    next_state = st_eth_header;
                else if(error_en)
                    next_state = st_rx_end;
                else
                    next_state = st_preamble;
            end

            st_eth_header:begin
                if(skip_en)
                    next_state = st_ip_header;
                else if(error_en)
                    next_state = st_rx_end;
                else
                    next_state = st_eth_header;
            end

            st_ip_header:begin
                if(skip_en)
                    next_state = st_icmp_header;
                else if(error_en)
                    next_state = st_rx_end;
                else
                    next_state = st_ip_header;
            end

            st_icmp_header:begin
                if(skip_en)
                    next_state = st_rx_data;
                else if(error_en)
                    next_state = st_rx_end;
                else
                    next_state = st_icmp_header;
            end

            st_rx_data:begin
                if(skip_en)
                    next_state = st_rx_end;
                else
                    next_state = st_rx_data;
            end

            st_rx_end:begin
                if(skip_en)
                    next_state = st_idle;
                else
                    next_state = st_rx_end;
            end

            default: next_state = st_idle;
        endcase
    end

    always @(posedge gmii_rx_clk or posedge rst) begin
        if(rst) begin
            skip_en                 <= 1'd0;
            error_en                <= 1'd0;
            cnt                     <= 5'd0;
            des_mac                 <= 48'd0;
            des_ip                  <= 32'd0;
            eth_type                <= 16'd0;
            ip_head_byte_num        <= 6'd0;
            ip_total_length         <= 16'd0;
            rec_en_cnt              <= 2'd0;
            icmp_type               <= 8'd0;
            icmp_code               <= 8'd0;
            icmp_checksum           <= 16'd0;
            icmp_data_length        <= 16'd0;
            icmp_rx_cnt             <= 16'd0;
            icmp_rx_data_d0         <= 8'd0;
            reply_checksum_add      <= 32'd0;
            icmp_id                 <= 16'd0;  
            icmp_seq                <= 16'd0;
            rec_byte_num            <= 16'd0;
            rec_data                <= 8'd0;
            reply_check_sum         <= 32'd0;
            rec_en                  <= 1'd0;
            rec_pkt_done            <= 1'd0;
        end
        else begin
            skip_en         <= 1'b0;
            error_en        <= 1'b0;
            rec_pkt_done    <= 1'b0;
            case(next_state)
                st_idle:begin
                    if((gmii_rx_dv == 1'b1) && (gmii_rxd == 8'h55))
                        skip_en <= 1'b1;        
                    else;
                end

                st_preamble:begin
                    if(gmii_rx_dv) begin
                        cnt <= cnt + 5'd1;
                        if((cnt < 5'd6) && (gmii_rxd != 8'h55))
                            error_en <= 1'b1;
                        else if(cnt == 5'd6) begin
                            cnt <= 5'd0;
                            if(gmii_rxd == 8'hd5) 
                                skip_en <= 1'b1;
                            else
                                error_en <= 1'b1;
                        end
                        else;
                    end
                    else;
                end

                st_eth_header:begin
                    if(gmii_rx_dv) begin
                        cnt <= cnt + 5'd1;
                        if(cnt < 5'd6)
                            des_mac <= {des_mac[39:0], gmii_rxd};
                        else if(cnt == 5'd12)
                            eth_type[15:8] <= gmii_rxd;
                        else if(cnt == 5'd13) begin
                            eth_type[7:0] <= gmii_rxd;
                            cnt <= 5'd0;
                            // 判断MAC和以太网类型
                            if((des_mac == BOARD_MAC) || (des_mac == 48'hff_ff_ff_ff_ff_ff)
                            && (eth_type[15:8] == ETH_TYPE[15:8]) && (gmii_rxd == ETH_TYPE[7:0])) begin
                                skip_en <= 1'b1;
                            end
                            else
                                error_en <= 1'b1;
                        end
                        else;
                    end
                    else;
                end

                st_ip_header:begin
                    if(gmii_rx_dv) begin
                        cnt <= cnt + 5'd1;
                        if(cnt == 5'd0) 
                            ip_head_byte_num <= {gmii_rxd[3:0], 2'd0};              // IP报文里的头部长度字段单位是4Bytes
                        else if(cnt == 5'd2) 
                            ip_total_length[15:8] <= gmii_rxd;
                        else if(cnt == 5'd3) 
                            ip_total_length[7:0]  <= gmii_rxd;                      
                        else if(cnt == 5'd4)
                            // 计算有效数据字节长度，IP头20字节，ICMP头8字节
                            icmp_data_length <= ip_total_length - 16'd28;
                        else if(cnt == 5'd9) begin
                            if(gmii_rxd != ICMP_TYPE) begin
                                error_en <= 1'b1;
                                cnt <= 5'd0;
                            end
                        end
                        else if((cnt >= 5'd16) && (cnt <= 5'd18))                  // 前三个字节
                            des_ip <= {des_ip[23:0], gmii_rxd};
                        else if(cnt == 5'd19) begin
                            des_ip <= {des_ip[23:0], gmii_rxd};                    // 最后一个字节
                            if((des_ip[23:0] == BOARD_IP[31:8]) && (gmii_rxd == BOARD_IP[7:0])) begin
                                skip_en <= 1'b1;
                                cnt <= 5'd0;
                            end
                            else begin
                                error_en <= 1'b1;
                                cnt <= 5'd0;
                            end
                        end
                        else;
                    end
                    else;
                end

                st_icmp_header:begin
                    if(gmii_rx_dv) begin
                        cnt <= cnt + 5'd1;
                        if(cnt == 5'd0)
                            icmp_type <= gmii_rxd;
                        else if(cnt == 5'd1)
                            icmp_code <= gmii_rxd;
                        else if(cnt == 5'd2) 
                            icmp_checksum[15:8] <= gmii_rxd;
                        else if(cnt == 5'd3)
                            icmp_checksum[7:0] <= gmii_rxd;
                        else if(cnt == 5'd4)
                            icmp_id[15:8] <= gmii_rxd;
                        else if(cnt == 5'd5)
                            icmp_id[7:0] <= gmii_rxd;
                        else if(cnt == 5'd6)
                            icmp_seq[15:8] <= gmii_rxd;
                        else if(cnt == 5'd7) begin
                            icmp_seq[7:0] <= gmii_rxd;
                            // 判断ICMP的报文类型是不是回显请求
                            if(icmp_type  == ECHO_REQUEST) begin
                                skip_en <= 1'b1;
                                cnt <= 5'd0;
                            end
                            else begin
                                error_en <= 1'b1;                   // ICMP报文类型错误
                                cnt <= 5'd0;
                            end
                        end
                        else;
                    end
                    else;
                end

                st_rx_data:begin
                    if(gmii_rx_dv) begin
                        rec_en_cnt <= rec_en_cnt + 2'd1;
                        icmp_rx_cnt <= icmp_rx_cnt + 16'd1;
                        rec_data <= gmii_rxd;
                        rec_en <= 1'b1;

                        // 判断接收到数据个数的奇偶个数，每16bit进行一次加法计算
                        if(icmp_rx_cnt == icmp_data_length - 16'd1) begin
                            icmp_rx_data_d0 <= 8'h00;
                            if(icmp_data_length[0])
                                reply_checksum_add <= {8'd0, gmii_rxd} + reply_checksum_add;    // 如果是奇数
                            else
                                reply_checksum_add <= {icmp_rx_data_d0, gmii_rxd} + reply_checksum_add;     // 如果是偶数
                        end
                        else if(icmp_rx_cnt < icmp_data_length - 16'd1) begin           
                            icmp_rx_data_d0 <= gmii_rxd;
                            // icmp_rx_cnt <= icmp_rx_cnt + 16'd1;                        
                            if(icmp_rx_cnt[0] == 1'b1)
                                reply_checksum_add <= {icmp_rx_data_d0, gmii_rxd} + reply_checksum_add;
                            else
                                reply_checksum_add <= reply_checksum_add;
                        end
                        else;

                        if(icmp_rx_cnt == icmp_data_length - 16'd1) begin
                            skip_en <= 1'b1;
                            icmp_rx_cnt <= 16'd0;
                            rec_en_cnt <= 2'd0;
                            rec_pkt_done <= 1'b1;
                            rec_byte_num <= icmp_data_length;
                        end
                        else;
                    end
                    else;
                end

                st_rx_end:begin
                    rec_en <= 1'b0;
                    if(gmii_rx_dv == 1'b0 && skip_en == 1'b0) begin
                        reply_check_sum <= reply_checksum_add;
                        skip_en <= 1'b1;
                        reply_checksum_add <= 32'd0;
                    end
                    else;
                end
                
                default: ;
            endcase
        end
    end

endmodule
