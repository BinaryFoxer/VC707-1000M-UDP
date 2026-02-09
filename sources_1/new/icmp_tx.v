`timescale 1ns / 1ps

// -----------------------------------------------------------------
// icmp发送报文，包含三个校验：IP头校验、ICMP头校验、CRC校验
// -----------------------------------------------------------------


module icmp_tx(
    input                   gmii_tx_clk,
    input                   rst,
    input         [15:0]    tx_byte_num,                    // 发送的ICMP报文字节数
    input         [7:0]     tx_data,                        // 从FIFO中取出的发送数据
    input                   tx_start_en,                    // 触发开始发送使能信号
    input         [47:0]    des_mac,
    input         [31:0]    des_ip,
    input         [31:0]    crc_data,                       
    input         [7:0]     crc_next,
    input         [15:0]    icmp_id,                        // 此ICMP报文的标识符
    input         [15:0]    icmp_seq,                       // ICMP报文的类型序列号
    input         [31:0]    reply_check_sum,                // RX模块计算出的ICMP数据部分的校验和（没有取反）

    output  reg             crc_clr,                        // CRC清除信号
    output  reg             crc_en,                         // CRC使能信号
    output  reg             gmii_tx_en,                     // gmii发送使能
    output  reg   [7:0]     gmii_txd,
    output  reg             tx_done,                        // 报文发送完成标志
    output  reg             tx_req                          // 向FIFO请求数据信号
    );

    // parameter define
    parameter   BOARD_MAC  = 48'h00_11_22_33_44_55;
    parameter   BOARD_IP   = {8'd192, 8'd168, 8'd0, 8'd2};
    parameter   DES_MAC    = 48'hff_ff_ff_ff_ff_ff;
    parameter   DES_IP     = {8'd192,8'd168,8'd0,8'd3}; 

    localparam  st_idle         = 8'b0000_0001;
    localparam  st_check_ip     = 8'b0000_0010;             // IP头校验和计算：只计算IP头部校验和
    localparam  st_check_icmp   = 8'b0000_0100;             // ICMP头校验和：计算整个 ICMP 报文（首部 + 数据）
    localparam  st_preamble     = 8'b0000_1000;             
    localparam  st_eth_header   = 8'b0001_0000;
    localparam  st_ip_header    = 8'b0010_0000;             // 发送IP头以及ICMP头
    localparam  st_tx_data      = 8'b0100_0000;
    localparam  st_crc          = 8'b1000_0000;

    localparam  ETH_TYPE        = 16'h0800;                 // 上层协议为IP类型
    localparam  MIN_DATA_NUM    = 16'd18;                   // ICMP报文数据部分最小长度：46-20(IP头部长度)-8(ICMP头部长度)  
    parameter  ECHO_REPLY      = 8'h00;                    // ICMP报文类型：回显请求

    // reg define
    reg     [7:0]   cur_state;
    reg     [7:0]   next_state;
    reg     [7:0]   preamble[7:0];                          // 前导码：7+1个字节
    reg     [7:0]   eth_header[13:0];                       // 以太头：14个字节
    reg     [31:0]  ip_header[6:0];                         // ip首部+icmp首部，四个字节为一个单位，4*7=28 bytes
    reg             start_en_d0;
    reg             start_en_d1;
    reg             start_en_d2;
    reg     [15:0]  tx_data_num;                            // 发送ICMP报文有效字节数
    reg     [15:0]  total_num;                              // 总字节数
    reg             trig_tx_en;                             // 打拍后的触发tx发送信号
    reg             skip_en;
    reg     [4:0]   cnt;
    reg     [31:0]  check_buffer;                           // IP头校验和缓存
    reg     [31:0]  check_buffer_icmp;                      // ICMP头校验和缓存
    reg     [1:0]   tx_bit_sel;                             // 发送4字节计数器
    reg     [15:0]  data_cnt;
    reg             tx_done_t;
    reg     [4:0]   real_add_cnt;                           // 以太网实际需要多发出的字节数
    reg             tx_done_delay;

    // wire define
    wire            pos_start_en;                           // tx_start_en的上升沿
    wire    [15:0]  real_tx_data_num;                       // 实际发送的字节数，满足以太网最少字节要求

    assign  pos_start_en = (~start_en_d2) & start_en_d1;
    assign  real_tx_data_num = (tx_data_num >= MIN_DATA_NUM) ? tx_data_num : MIN_DATA_NUM;

    // 打三拍采集tx_start_en的上升沿
    always @(posedge gmii_tx_clk or posedge rst) begin
        if(rst) begin
            start_en_d0 <= 1'b0;
            start_en_d1 <= 1'b0;
            start_en_d2 <= 1'b0;
        end
        else begin
            start_en_d0 <= tx_start_en;
            start_en_d1 <= start_en_d0;
            start_en_d2 <= start_en_d1;
        end
    end
    

    // 寄存ICMP数据段长度
    always @(posedge gmii_tx_clk or posedge rst) begin
        if(rst) begin
            tx_data_num <= 16'd0;
            total_num   <= 16'd0;
        end
        else begin
            if(pos_start_en && (cur_state == st_idle)) begin
                tx_data_num <= tx_byte_num;                     // 从输入中寄存数据字段长度
                total_num   <= tx_byte_num + 16'd28;            // ICMP数据段长度+IP头+ICMP头长度
            end
            else;
        end
    end

    // 寄存一拍触发发送信号
    always @(posedge gmii_tx_clk or posedge rst) begin
        if(rst) begin
            trig_tx_en <= 1'b0;
        end
        else begin
            trig_tx_en <= pos_start_en;
        end
    end

    // --------------------------------状态机发送ICMP报文数据-------------------------------
    always @(posedge gmii_tx_clk or posedge rst) begin
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
                    next_state = st_check_ip;
                else
                    next_state = st_idle;
            end

            st_check_ip:begin
                if(skip_en)
                    next_state = st_check_icmp;
                else
                    next_state = st_check_ip;
            end

            st_check_icmp:begin
                if(skip_en)
                    next_state = st_preamble;
                else
                    next_state = st_check_icmp;
            end

            st_preamble:begin
                if(skip_en)
                    next_state = st_eth_header;
                else
                    next_state = st_preamble;
            end

            st_eth_header:begin
                if(skip_en)
                    next_state = st_ip_header;
                else
                    next_state = st_eth_header;
            end

            st_ip_header:begin
                if(skip_en)
                    next_state = st_tx_data;
                else
                    next_state =st_ip_header;
            end

            st_tx_data:begin
                if(skip_en)
                    next_state = st_crc;
                else    
                    next_state = st_tx_data;
            end

            st_crc:begin
                if(skip_en)
                    next_state = st_idle;
                else
                    next_state = st_crc;
            end

            default:next_state = st_idle;
        endcase
    end

    always @(posedge gmii_tx_clk or posedge rst) begin
        if(rst) begin
            skip_en                 <= 1'd0;
            cnt                     <= 5'd0;
            check_buffer            <= 32'd0;
            check_buffer_icmp       <= 32'd0;
            tx_bit_sel              <= 2'd0;
            data_cnt                <= 16'd0;
            tx_done_t               <= 1'd0;
            real_add_cnt            <= 5'd0;        
            crc_en                  <= 1'd0;
            gmii_tx_en              <= 1'd0;
            gmii_txd                <= 8'd0;
            tx_done                 <= 1'd0;
            tx_req                  <= 1'd0;
            ip_header[1][31:16]     <= 16'd0;
                
            // 寄存器初始化
            //前导码 7个8'h55 + 1个8'hd5 
            preamble[0] <= 8'h55;                
            preamble[1] <= 8'h55;
            preamble[2] <= 8'h55;
            preamble[3] <= 8'h55;
            preamble[4] <= 8'h55;
            preamble[5] <= 8'h55;
            preamble[6] <= 8'h55;
            preamble[7] <= 8'hd5;

            // 以太网帧头
            eth_header[0] <= DES_MAC[47:40];            // 目的mac
            eth_header[1] <= DES_MAC[39:32];
            eth_header[2] <= DES_MAC[31:24];
            eth_header[3] <= DES_MAC[23:16];
            eth_header[4] <= DES_MAC[15:8];
            eth_header[5] <= DES_MAC[7:0];
            eth_header[6] <= BOARD_MAC[47:40];          // 发送方mac
            eth_header[7] <= BOARD_MAC[39:32];
            eth_header[8] <= BOARD_MAC[31:24];
            eth_header[9] <= BOARD_MAC[23:16];
            eth_header[10] <= BOARD_MAC[15:8];
            eth_header[11] <= BOARD_MAC[7:0];
            eth_header[12] <= ETH_TYPE[15:8];           // 以太类型
            eth_header[13] <= ETH_TYPE[7:0];
        end
        else begin
            skip_en     <= 1'b0;
            gmii_tx_en  <= 1'b0;
            crc_en      <= 1'b0;
            tx_done_t   <= 1'b0;
            case(next_state)
                st_idle:begin
                    if(trig_tx_en) begin
                        skip_en <= 1'b1;
                        // 版本号：4；首部长度：5（单位：4bytes，共20字节）,服务类型00，总长度
                        ip_header[0] <= {8'h45, 8'h00, total_num};
                        // 16位报文标识符，同一报文所有分片标识符相同
                        ip_header[1][31:16] <= ip_header[1][31:16] + 16'd1;             // 每发送一次，标识符加1
                        // 标志和片偏移，010不分片；片偏移为0
                        ip_header[1][15:0]  <= 16'h4000;                                // 不使用分片
                        // 生存时间，协议类型：80生存时间128，01协议类型是ICMP，首部校验和先使用0
                        ip_header[2] <= {8'h80, 8'd01, 16'h0000};
                        // 源IP地址
                        ip_header[3] <= BOARD_IP;
                        // 目的IP地址
                        if(des_ip != 32'd0)
                            ip_header[4] <= des_ip;
                        else
                            ip_header[4] <= DES_IP;
                        // ICMP头
                        // 报文类型，校验和计算完成之后再赋值
                        ip_header[5][31:16] <= {ECHO_REPLY, 8'h00};
                        // 标识符和序列号
                        ip_header[6] <= {icmp_id, icmp_seq};
                        // 更新mac地址
                        if(des_mac != 48'd0) begin
                            eth_header[0]  <= des_mac[47:40];
                            eth_header[1]  <= des_mac[39:32];
                            eth_header[2]  <= des_mac[31:24];
                            eth_header[3]  <= des_mac[23:16];
                            eth_header[4]  <= des_mac[15:8] ;
                            eth_header[5]  <= des_mac[7:0]  ;
                        end
                        else;
                    end
                    else;
                end

                st_check_ip:begin
                    cnt <= cnt + 5'd1;
                    if(cnt == 5'd0) begin
                        check_buffer <= ip_header[0][31:16] + ip_header[0][15:0]
                                        + ip_header[1][31:16] + ip_header[1][15:0]
                                        + ip_header[2][31:16] + ip_header[2][15:0]
                                        + ip_header[3][31:16] + ip_header[3][15:0]
                                        + ip_header[4][31:16] + ip_header[4][15:0];
                    end
                    else if(cnt == 5'd1)    // 可能出现进位，累加一次
                        check_buffer <= check_buffer[31:16] + check_buffer[15:0];  
                    else if(cnt == 5'd2)    // 可能再次出现进位，再累加一次
                        check_buffer <= check_buffer[31:16] + check_buffer[15:0];
                    else if(cnt == 5'd3) begin
                        skip_en <= 1'b1;
                        cnt     <= 5'd0;
                        ip_header[2][15:0] <= ~check_buffer[15:0];      // IP头校验和计算完成，重新赋值给字段 
                    end
                    else;
                end

                st_check_icmp:begin
                    cnt <= cnt + 5'd1;
                    if(cnt == 5'd0)             // 计算icmp的头部校验和:IP头校验和先设置为0，需要加上数据段的校验和
                        check_buffer_icmp <= ip_header[5][31:16] 
                                            + ip_header[6][31:16] + ip_header[6][15:0] + reply_check_sum;
                    else if(cnt == 5'd1)
                        check_buffer_icmp <= check_buffer_icmp[31:16] + check_buffer_icmp[15:0];
                    else if(cnt == 5'd2)
                        check_buffer_icmp <= check_buffer_icmp[31:16] + check_buffer_icmp[15:0];
                    else if(cnt == 5'd3) begin
                        skip_en <= 1'b1;
                        cnt <= 5'd0;
                        ip_header[5][15:0] <= ~check_buffer_icmp[15:0];
                    end
                    else;
                end

                st_preamble:begin
                    gmii_tx_en <= 1'b1;
                    gmii_txd <= preamble[cnt];
                    if(cnt == 5'd7) begin
                        skip_en <= 1'b1;
                        cnt <= 5'd0;
                    end
                    else
                        cnt <= cnt + 5'd1;
                end

                st_eth_header:begin
                    gmii_tx_en <= 1'b1;
                    crc_en     <= 1'b1;
                    gmii_txd   <= eth_header[cnt];
                    if(cnt == 5'd13) begin
                        cnt <= 5'd0;
                        skip_en <= 1'b1;
                    end
                    else
                        cnt <= cnt + 5'd1;
                end

                st_ip_header:begin
                    crc_en <= 1'b1;
                    gmii_tx_en <= 1'b1;
                    tx_bit_sel <= tx_bit_sel + 2'b1;            // tx_bit_sel会一直在0~3循环
                    if(tx_bit_sel == 2'd0)
                        gmii_txd <= ip_header[cnt][31:24];
                    else if(tx_bit_sel == 2'd1)
                        gmii_txd <= ip_header[cnt][23:16];
                    else if(tx_bit_sel == 2'd2) begin
                        gmii_txd <= ip_header[cnt][15:8];
                        if(cnt == 5'd6)         // 提前请求发送数据，ICMP的数据段部分
                            tx_req <= 1'b1;
                    end
                    else if(tx_bit_sel == 2'd3) begin
                        gmii_txd <= ip_header[cnt][7:0];
                        if(cnt == 5'd6) begin
                            skip_en <= 1'b1;                    // 28字节的IP头和ICMP头全部发送完
                            cnt <= 5'd0;
                            // tx_req <= 1'b1;
                        end
                        else
                            cnt <= cnt + 5'd1;
                    end
                    else;
                end

                st_tx_data:begin
                    crc_en <= 1'b1;
                    gmii_tx_en <= 1'b1;
                    gmii_txd <= tx_data;
                    tx_bit_sel <= 2'd0;
                    if(data_cnt < tx_data_num - 16'd1)
                        data_cnt <= data_cnt + 16'd1;
                    else if(data_cnt == tx_data_num - 16'd1) begin
                        // 如果发送数据有效位小于18个字节，需要补充位
                        if(data_cnt + real_add_cnt < real_tx_data_num - 16'd1)
                            real_add_cnt <= real_add_cnt + 5'd1;        // 计算需要补多少字节
                        else begin
                            skip_en <= 1'b1;
                            data_cnt <= 16'd0;                          // 发送icmp报文数据段字节指针
                            real_add_cnt <= 5'd0;
                        end
                    end
                    else;
                    // 提前关掉FIFO，保证读出的数据量是对的
                    if(data_cnt == tx_data_num - 16'd2)
                        tx_req <= 1'b0;
                    else;
                end

                st_crc:begin
                    gmii_tx_en <= 1'b1;
                    tx_bit_sel <= tx_bit_sel + 2'b1;
                    tx_req <= 1'b0;
                    if(tx_bit_sel == 2'd0) begin
                        gmii_txd <= {~crc_next[0], ~crc_next[1], ~crc_next[2], ~crc_next[3],
                                    ~crc_next[4], ~crc_next[5], ~crc_next[6], ~crc_next[7]};
                    end
                    else if(tx_bit_sel == 2'd1) begin
                        gmii_txd <= {~crc_data[16], ~crc_data[17], ~crc_data[18], ~crc_data[19],
                                    ~crc_data[20], ~crc_data[21], ~crc_data[22], ~crc_data[23]};
                    end
                    else if(tx_bit_sel == 2'd2) begin
                        gmii_txd <= {~crc_data[8], ~crc_data[9], ~crc_data[10], ~crc_data[11],
                                    ~crc_data[12], ~crc_data[13], ~crc_data[14], ~crc_data[15]};
                        tx_done_t <= 1'b1;
                    end
                    else if(tx_bit_sel == 2'd3) begin
                        gmii_txd <= {~crc_data[0], ~crc_data[1], ~crc_data[2], ~crc_data[3],
                                    ~crc_data[4], ~crc_data[5], ~crc_data[6], ~crc_data[7]};
                        // tx_done_t <= 1'b1;             // 实际上这个周期数据还没有发送完毕，所以延后一个周期
                        skip_en <= 1'b1;
                        tx_bit_sel <= 2'd0;    
                    end
                    else;
                end

            default: ;
            endcase
        end
    end


    // 数据全部发送完成，拉高完成信号以及CRC复位
    always @(posedge gmii_tx_clk or posedge rst) begin
        if(rst) begin
            tx_done <= 1'b0;
            crc_clr <= 1'b0;
            tx_done_delay <= 1'b0;
        end
        else begin
            tx_done_delay <= tx_done_t;

            tx_done <= tx_done_delay;
            crc_clr <= tx_done_delay;
        end
    end

endmodule
