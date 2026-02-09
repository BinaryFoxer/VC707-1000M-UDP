`timescale 1ns / 1ps

// ---------------------------------------------------------------------
// UDP发送模块 
// ---------------------------------------------------------------------


module udp_tx(
    input                   clk,
    input                   rst,

    input                   tx_start_en,                // 发送UDP报文使能信号
    input           [15:0]  tx_byte_num,                // 发送UDP报文数据段字节数
    input           [7:0]   tx_data,                    // UDP数据段数据字节
    input           [31:0]  crc_data,
    input           [7:0]   crc_next,
    input           [31:0]  des_ip,
    input           [47:0]  des_mac,

    output  reg             crc_clr,
    output  reg             crc_en,
    output  reg             gmii_tx_en,                 // 发送gmii数据使能信号
    output  reg     [7:0]   gmii_txd,
    output  reg             tx_done,                    // 发送UDP数据报文完成信号s
    output  reg             tx_req 
    );

    // parameter define
    parameter   BOARD_MAC  = 48'h00_11_22_33_44_55;
    parameter   BOARD_IP   = {8'd192, 8'd168, 8'd0, 8'd2};
    parameter   DES_MAC    = 48'hff_ff_ff_ff_ff_ff;
    parameter   DES_IP     = {8'd192,8'd168,8'd0,8'd3}; 

    localparam  ETH_TYPE        = 16'h0800;                 // 上层协议为IP类型
    localparam  MIN_DATA_NUM    = 16'd18;                   // UDP报文数据部分最小长度：46-20(IP头部长度)-8(UDP头部长度)
    localparam  UDP_TYPE        = 8'd17;                    // UDP协议号17

    localparam  st_idle         = 7'b000_0001;
    localparam  st_check_ip     = 7'b000_0010;              // 计算IP头部校验和
    localparam  st_preamble     = 7'b000_0100;
    localparam  st_eth_header   = 7'b000_1000;
    localparam  st_ip_header    = 7'b001_0000;              // 发送20字节IP头和8字节UDP头
    localparam  st_tx_data      = 7'b010_0000;
    localparam  st_crc          = 7'b100_0000;

    // reg define
    reg [6:0]   cur_state;
    reg [6:0]   next_state;
    reg [7:0]   preamble[7:0];
    reg [7:0]   eth_header[13:0];
    reg [31:0]  ip_header[6:0];                             // IP头+UDP头共28个
    reg         start_en_d0;
    reg         start_en_d1;
    reg         start_en_d2;                                // 对tx_start_en信号打三拍
    reg         trig_tx_en;                                 // 触发开始发送信号
    reg [15:0]  tx_data_num;                                // 寄存数据段字节数
    reg [15:0]  total_num;                                  // IP报文的总字节数
    reg [15:0]  udp_num;                                    // UDP报文的总字节数
    reg         skip_en;
    reg [4:0]   cnt;
    reg [31:0]  check_buffer;                               // IP头校验和计算缓存
    reg [1:0]   tx_byte_sel;                                 // 4字节发送计数器
    reg [15:0]  data_cnt;                                   // 数据段字节计数指针
    reg         tx_done_t;
    reg [15:0]  real_add_cnt;                               // 实际需要填充的字节数（报文长度小于48字节时）

    // wire define
    wire            pos_start_en;                           // tx_start_en的上升沿
    wire    [15:0]  real_tx_data_num;                       // 实际发送的字节数，满足以太网最少字节要求

    assign  pos_start_en = ~start_en_d2 & start_en_d1;
    assign  real_tx_data_num = (tx_data_num >= MIN_DATA_NUM) ? tx_data_num : MIN_DATA_NUM;

    // 打三拍采集tx_start_en的上升沿
    always @(posedge clk or posedge rst) begin
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

    // 寄存UDP数据段长度
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            tx_data_num <= 16'd0;
            total_num   <= 16'd0;
            udp_num     <= 16'd0;
        end
        else begin
            if(pos_start_en && (cur_state == st_idle)) begin
                tx_data_num <= tx_byte_num;                     // 寄存UDP数据字段长度
                udp_num     <= tx_byte_num + 16'd8;
                total_num   <= tx_byte_num + 16'd28;            // 总长度：UDP数据段长度+IP头(20)+UDP头长度(8)
            end
        end
    end

    // 寄存一拍触发发送信号，为了先完成数据段长度和总长度的寄存
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            trig_tx_en <= 1'b0;
        end
        else begin
            trig_tx_en <= pos_start_en;
        end
    end

    // ---------------------------  发送UDP报文状态机   ----------------------------
    always @(posedge clk or posedge rst) begin
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
                    next_state = st_preamble;
                else
                    next_state = st_check_ip;
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

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            // 寄存器初始化
            skip_en                 <= 1'b0; 
            cnt                     <= 5'd0;
            check_buffer            <= 32'd0;
            ip_header[1][31:16]     <= 16'd0;
            tx_byte_sel             <= 2'd0;
            crc_en                  <= 1'b0;
            gmii_tx_en              <= 1'b0;
            gmii_txd                <= 8'd0;
            tx_req                  <= 1'b0;
            tx_done_t               <= 1'b0; 
            data_cnt                <= 16'd0;
            real_add_cnt            <= 5'd0;

            //前导码 7个8'h55 + 1个8'hd5 
            preamble[0] <= 8'h55;                
            preamble[1] <= 8'h55;
            preamble[2] <= 8'h55;
            preamble[3] <= 8'h55;
            preamble[4] <= 8'h55;
            preamble[5] <= 8'h55;
            preamble[6] <= 8'h55;
            preamble[7] <= 8'hd5;

            // 以太头
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
            skip_en <= 1'b0;
            tx_done_t <= 1'b0;
            gmii_tx_en <= 1'b0;
            crc_en <= 1'b0;
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
                        // 生存时间，协议类型：80生存时间128，协议类型17：UDP，首部校验和先使用0
                        ip_header[2] <= {8'h80, UDP_TYPE, 16'h0000};
                        // 源IP地址
                        ip_header[3] <= BOARD_IP;
                        // 目的IP地址
                        if(des_ip != 32'd0)
                            ip_header[4] <= des_ip;
                        else
                            ip_header[4] <= DES_IP;
                        // UDP头
                        // 源端口与目的端口
                        ip_header[5] <= {16'd1234, 16'd1234};                           // 源端口和目的端口均为1234
                        // UDP长度和校验和（不使用，默认为0）
                        ip_header[6] <= {udp_num, 16'd0};
                        
                        // 更新以太头中的目的mac
                        if(des_mac != 48'd0) begin
                            eth_header[0]  <= des_mac[47:40];
                            eth_header[1]  <= des_mac[39:32];
                            eth_header[2]  <= des_mac[31:24];
                            eth_header[3]  <= des_mac[23:16];
                            eth_header[4]  <= des_mac[15:8] ;
                            eth_header[5]  <= des_mac[7:0]  ;
                        end
                    end
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
                    else if(cnt == 5'd1) begin
                        check_buffer <= check_buffer[31:16] + check_buffer[15:0];       // check_buffer是32位的
                    end
                    else if(cnt == 5'd2) begin
                        check_buffer <= check_buffer[31:16] + check_buffer[15:0];       //可能再次出现进位，加一次
                    end             
                    else if(cnt == 5'd3) begin
                        skip_en <= 1'b1;
                        cnt <= 5'd0;
                        ip_header[2][15:0] <= ~check_buffer[15:0];
                    end
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
                    crc_en <= 1'b1;
                    gmii_txd <= eth_header[cnt];
                    if(cnt == 5'd13) begin
                        skip_en <= 1'b1;
                        cnt <= 5'd0;
                    end
                    else
                        cnt <= cnt + 5'd1;
                end

                st_ip_header:begin
                    gmii_tx_en <= 1'b1;
                    crc_en <= 1'b1;
                    tx_byte_sel <= tx_byte_sel + 2'd1;
                    // 双重循环发送
                    if(tx_byte_sel == 2'd0)
                        gmii_txd <= ip_header[cnt][31:24];
                    else if(tx_byte_sel == 2'd1)
                        gmii_txd <= ip_header[cnt][23:16];
                    else if(tx_byte_sel == 2'd2) begin
                        gmii_txd <= ip_header[cnt][15:8];
                        if(cnt == 5'd6) 
                            // 提前请求数据，等待有效信号到达时直接发送
                            tx_req <= 1'b1;
                    end
                    else if(tx_byte_sel == 2'd3) begin
                        gmii_txd <= ip_header[cnt][7:0];
                        if(cnt == 5'd6) begin
                            skip_en <= 1'b1;
                            cnt <= 5'd0;
                            
                        end
                        else
                            cnt <= cnt + 5'd1;
                    end
                end

                st_tx_data:begin
                    gmii_tx_en <= 1'b1;
                    crc_en <= 1'b1;
                    tx_byte_sel <= 2'd0;
                    gmii_txd <= tx_data;

                    if(data_cnt < tx_data_num - 16'd1)
                        data_cnt <= data_cnt + 16'd1;
                    else if(data_cnt == tx_data_num - 16'd1) begin
                        if(data_cnt + real_add_cnt < real_tx_data_num - 16'd1)
                            real_add_cnt <= real_add_cnt + 16'd1;       // 计算需要填充多少字节
                        else begin
                            skip_en <= 1'b1;
                            data_cnt <= 16'd0;
                            real_add_cnt <= 16'd0;
                        end
                    end

                    if(data_cnt == tx_data_num - 16'd2) 
                        tx_req <= 1'b0;

                end

                st_crc:begin
                    gmii_tx_en <= 1'b1;
                    tx_byte_sel <= tx_byte_sel + 2'd1;

                    if(tx_byte_sel == 2'd0)
                        gmii_txd <= {~crc_next[0], ~crc_next[1], ~crc_next[2],~crc_next[3],
                                    ~crc_next[4], ~crc_next[5], ~crc_next[6],~crc_next[7]};
                    else if(tx_byte_sel == 2'd1)
                        gmii_txd <= {~crc_data[16], ~crc_data[17], ~crc_data[18],~crc_data[19],
                                    ~crc_data[20], ~crc_data[21], ~crc_data[22],~crc_data[23]};
                    else if(tx_byte_sel == 2'd2) begin
                        gmii_txd <= {~crc_data[8], ~crc_data[9], ~crc_data[10],~crc_data[11],
                                    ~crc_data[12], ~crc_data[13], ~crc_data[14],~crc_data[15]};                              
                    end
                    else if(tx_byte_sel == 2'd3) begin
                        gmii_txd <= {~crc_data[0], ~crc_data[1], ~crc_data[2],~crc_data[3],
                                    ~crc_data[4], ~crc_data[5], ~crc_data[6],~crc_data[7]};  
                        tx_done_t <= 1'b1;
                        skip_en <= 1'b1;
                    end     
                end

                default: ;
            endcase
        end
    end

    //发送完成信号及crc值复位信号
    always @(posedge clk or negedge rst) begin
        if(rst) begin
            tx_done <= 1'b0;
            crc_clr <= 1'b0;
        end
        else begin
            tx_done <= tx_done_t;
            crc_clr <= tx_done_t;
        end
    end


endmodule
