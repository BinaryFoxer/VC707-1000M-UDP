`timescale 1ns / 1ps

// ------------------------------------------------------------
// 发送包括arp报文的完整mac帧
// CRC校验从header开始，直到填充
// ------------------------------------------------------------

module arp_tx(
    input                   clk,                // gmii发送时钟
    input                   rst,                // 系统复位
    input                   arp_tx_en,          // arp发送使能
    input                   arp_tx_type,        // arp类型，0：请求；1：应答
    input           [47:0]  des_mac,            // 目的mac
    input           [31:0]  des_ip,             // 目的ip
    input           [31:0]  crc_data,           // CRC校验数据
    input           [7:0]   crc_next,           // 下一字节CRC的高八位

    output reg              crc_en,             // crc使能
    output reg              crc_clr,            // crc复位
    output reg      [7:0]   gmii_txd,           // gmii发送数据
    output reg              gmii_tx_en,         // gmii发送使能
    output reg              gmii_tx_done,       // gmii发送完成
    output reg              arp_led

    );

    // parameter define
    parameter  BOARD_MAC = 48'h00_11_22_33_44_55;        // 板卡MAC地址
    parameter  BOARD_IP  = {8'd192,8'd168,8'd0,8'd2}; 
    // 目标mac和ip
    parameter  DES_MAC   = 48'hff_ff_ff_ff_ff_ff;
    parameter  DES_IP    = {8'd192,8'd168,8'd0,8'd3};

    localparam  st_idle         = 5'b0_0001;            // 空闲状态
    localparam  st_preamble     = 5'b0_0010;            // 发送前导码
    localparam  st_header       = 5'b0_0100;            // 发送以太网帧头
    localparam  st_arp_data     = 5'b0_1000;            // 发送arp报文
    localparam  st_crc          = 5'b1_0000;            // 发送crc校验值
    localparam  ETH_TYPE        = 16'h08_06;            // 以太帧类型为arp
    localparam  HW_TYPE         = 16'h00_01;            // 硬件协议类型: ethernet
    localparam  PROTOCOL_TYPE   = 16'h08_00;            // 上层协议类型: IP
    localparam  MIN_BYTE_NUM    = 16'd46;               // 以太帧payload最少46字节

    // reg define
    reg [4:0]   cur_state;
    reg [4:0]   next_state;
    reg [5:0]   cnt;
    reg         skip_en;
    reg [4:0]   data_cnt;                   // 发送数据计数器
    reg         tx_done_t;

    reg [7:0]   preamble [7:0]      ;       // 前导码+SFD
    reg [7:0]   eth_header [13:0]   ;       // 以太头
    reg [7:0]   arp_data [27:0]     ;       // arp数据

    reg         tx_en_d0;                   // arp_tx_en延时
    reg         tx_en_d1;                   // arp_tx_en延时

    // wire define
    wire        pos_tx_en;

    // -----------------------------对arp_tx_en延时打三拍---------------------------------
    assign pos_tx_en = (~tx_en_d1) & tx_en_d0;
    // 延时两拍采上升沿
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            tx_en_d0 <= 1'b0;
            tx_en_d1 <= 1'b0;
        end
        else begin
            tx_en_d0 <= arp_tx_en;
            tx_en_d1 <= tx_en_d0;
        end
    end

    // -----------------------------通过gmii接口发送指定数据-------------------------------
    // 同步时序描述状态转移
    always @(posedge  clk or posedge rst) begin
        if(rst)
            cur_state <= st_idle;
        else
            cur_state <= next_state;
    end

    // 组合逻辑描述状态转移条件
    always @(*) begin
        next_state = cur_state;
        case(cur_state)
            st_idle:begin
                if(skip_en)
                    next_state = st_preamble;
                else
                    next_state = st_idle;
            end

            st_preamble:begin
                if(skip_en)
                    next_state = st_header;
                else
                    next_state = st_preamble;
            end

            st_header:begin
                if(skip_en)
                    next_state = st_arp_data;
                else
                    next_state = st_header;
            end

            st_arp_data:begin
                if(skip_en)
                    next_state = st_crc;
                else
                    next_state = st_arp_data;
            end

            st_crc:begin
                if(skip_en)
                    next_state = st_idle;
                else
                    next_state = st_crc;
            end
            default:next_state = cur_state;
        endcase
    end

    // 同步时序描述状态输出
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            cnt         <= 6'd0;
            skip_en     <= 1'b0;
            data_cnt    <= 5'b0;
            tx_done_t   <= 1'b0;
            gmii_txd    <= 8'd0;
            gmii_tx_en  <= 1'b0;
            crc_en      <= 1'b0;
            arp_led     <= 1'b0;
            
            // 初始化数组
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

            // arp内容
            arp_data[0]  <= HW_TYPE[15:8];              // 硬件协议类型
            arp_data[1]  <= HW_TYPE[7:0];
            arp_data[2]  <= PROTOCOL_TYPE[15:8];        // 上层协议类型
            arp_data[3]  <= PROTOCOL_TYPE[7:0];        
            arp_data[4]  <= 8'h06;                      // mac地址长度：6个字节
            arp_data[5]  <= 8'h04;                      // ip地址长度：4个字节        
            arp_data[6]  <= 8'h00;                               
            arp_data[7]  <= 8'h01;                      // 操作码 8'h01：ARP请求 8'h02:ARP应答                               
            arp_data[8]  <= BOARD_MAC[47:40];           // 发送方mac
            arp_data[9]  <= BOARD_MAC[39:32];
            arp_data[10] <= BOARD_MAC[31:24];
            arp_data[11] <= BOARD_MAC[23:16];
            arp_data[12] <= BOARD_MAC[15:8];
            arp_data[13] <= BOARD_MAC[7:0];
            arp_data[14] <= BOARD_IP[31:24];            // 发送方ip
            arp_data[15] <= BOARD_IP[23:16];
            arp_data[16] <= BOARD_IP[15:8];
            arp_data[17] <= BOARD_IP[7:0];
            arp_data[18] <= 8'h00;                      //接收端(目的)MAC地址(请求帧全为0?)
            arp_data[19] <= 8'h00;
            arp_data[20] <= 8'h00;
            arp_data[21] <= 8'h00;
            arp_data[22] <= 8'h00;
            arp_data[23] <= 8'h00;  
            arp_data[24] <= DES_IP[31:24];              //接收端(目的)IP地址
            arp_data[25] <= DES_IP[23:16];
            arp_data[26] <= DES_IP[15:8];
            arp_data[27] <= DES_IP[7:0];
        end
        else begin
            skip_en    <= 1'b0;
            tx_done_t  <= 1'b0;
            crc_en     <= 1'b0;
            gmii_tx_en <= 1'b0;
            case(next_state)                            // 想要cur_state跳转后立刻输出这里必须用next_state
                st_idle:begin
                    cnt <= 6'd0;
                    gmii_txd <= 8'd0;
                    if(pos_tx_en) begin                 // arp_tx_en信号触发发送
                        skip_en <= 1'b1;
                        if(des_mac != 48'b0 || des_ip != 32'b0) begin   // 如果上层模块更新了目的mac和目的ip
                            eth_header[0]  <= des_mac[47:40];
                            eth_header[1]  <= des_mac[39:32];
                            eth_header[2]  <= des_mac[31:24];
                            eth_header[3]  <= des_mac[23:16];
                            eth_header[4]  <= des_mac[15:8];
                            eth_header[5]  <= des_mac[7:0];
                            arp_data[18]   <= des_mac[47:40]; 
                            arp_data[19]   <= des_mac[39:32];
                            arp_data[20]   <= des_mac[31:24];
                            arp_data[21]   <= des_mac[23:16];
                            arp_data[22]   <= des_mac[15:8]; 
                            arp_data[23]   <= des_mac[7:0];  
                            arp_data[24]   <= des_ip[31:24];
                            arp_data[25]   <= des_ip[23:16];
                            arp_data[26]   <= des_ip[15:8];
                            arp_data[27]   <= des_ip[7:0];
                        end
                        if(arp_tx_type == 1'b0)
                            arp_data[7] <= 8'h01;      // arp 请求
                        else
                            arp_data[7] <= 8'h02;      // arp 应答
                    end
                end

                st_preamble:begin
                    gmii_tx_en <= 1'b1;                // 打开gmii发送，开始发送前导码和SFD
                    gmii_txd <= preamble[cnt];         // 通过gmii数据接口把数据发送出去
                    if(cnt == 6'd7) begin
                        cnt <= 6'd0;
                        skip_en <= 1'b1;               // 发送完进入下一个状态
                    end
                    else
                        cnt <= cnt + 6'd1;
                end

                st_header:begin
                    gmii_tx_en <= 1'b1;                // 继续拉高gmii发送使能发送头部
                    crc_en <= 1'b1;                    // 打开crc校验，从首部开始计算crc校验码
                    gmii_txd <= eth_header[cnt];       
                    if(cnt == 6'd13) begin
                        skip_en <= 1'b1;
                        cnt <= 6'd0;
                    end
                    else
                        cnt <= cnt + 6'd1;
                end

                st_arp_data:begin
                    gmii_tx_en <= 1'b1;
                    crc_en <= 1'b1;
                    if(cnt == MIN_BYTE_NUM - 1) begin
                        skip_en <= 1'b1;
                        cnt <= 6'd0;
                        data_cnt <= 5'd0;
                    end
                    else
                        cnt <= cnt + 6'd1;
                    
                    if(data_cnt <= 5'd27) begin
                        data_cnt <= data_cnt + 5'd1;
                        gmii_txd <= arp_data[data_cnt];
                    end
                    else 
                        gmii_txd <= 8'd0;              // 不足46字节的用0来填充 
                end

                st_crc:begin
                    gmii_tx_en <= 1'b1;                // 保持gmii发送，关闭crc生成
                    cnt <= cnt + 6'd1;
                    if(cnt == 6'd0) begin
                        gmii_txd <= {~crc_next[0], ~crc_next[1], ~crc_next[2], ~crc_next[3],
                                    ~crc_next[4], ~crc_next[5], ~crc_next[6], ~crc_next[7]};
                    end
                    else if(cnt == 6'd1) begin
                        gmii_txd <= {~crc_data[16], ~crc_data[17], ~crc_data[18], ~crc_data[19],
                                    ~crc_data[20], ~crc_data[21], ~crc_data[22], ~crc_data[23]};
                    end
                    else if(cnt == 6'd2) begin
                        gmii_txd <= {~crc_data[8], ~crc_data[9], ~crc_data[10], ~crc_data[11],
                                    ~crc_data[12], ~crc_data[13], ~crc_data[14], ~crc_data[15]};
                    end
                    else if(cnt == 6'd3) begin
                        gmii_txd <= {~crc_data[0], ~crc_data[1], ~crc_data[2], ~crc_data[3],
                                    ~crc_data[4], ~crc_data[5], ~crc_data[6], ~crc_data[7]};
                        tx_done_t <= 1'b1;             // 实际上这个周期数据还没有发送完毕，所以延后一个周期
                        arp_led <= 1'b1;
                        skip_en <= 1'b1;
                        cnt <= 6'd0;    
                    end
                end
                default: ;
            endcase
        end
    end

// crc_clr和tx_done赋值
always @(posedge clk or posedge rst) begin
    if(rst) begin
        crc_clr <= 1'b0;
        gmii_tx_done <= 1'b0;
    end
    else begin
        crc_clr <= tx_done_t;
        gmii_tx_done <= tx_done_t;
    end
end

endmodule
