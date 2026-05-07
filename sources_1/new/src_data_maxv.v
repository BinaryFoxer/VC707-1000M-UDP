`timescale 1ns / 1ps
//==========================================================================
// 模块名称  : src_data_maxv
// 功能描述  : 基于异步FIFO的200MHz数据源与125MHz以太网链路速率匹配模块
//            : 实现高速数据源(200MHz)到以太网链路(125MHz SGMII)的跨时钟域传输
//            : 集成ARP/ICMP/UDP协议栈，支持按键触发数据发送与回环测试
// 设计平台  : Xilinx VC707 (Virtex-7 XC7VX485T)
// 时钟域    : sys_clk 200MHz (数据写入域)
//            : gmii_tx_clk 125MHz (以太网发送域)
// 复位方式  : 高电平异步复位
// ========================================================================

module src_data_maxv(
    // ======================================================================
    // 系统信号
    // ======================================================================
    input               sys_clk_p,               // 200MHz差分时钟正端
    input               sys_clk_n,               // 200MHz差分时钟负端
    input               sys_rst,                 // 系统复位信号(高有效)

    // ======================================================================
    // MDIO接口 - 以太网PHY管理接口
    // ======================================================================
    output              eth_mdc,                 // PHY管理时钟
    inout               eth_mdio,                // PHY管理数据(双向)

    // ======================================================================
    // 板载LED及按键接口
    // ======================================================================
    output      [1:0]   led,                     // 通用LED指示灯
    output              id_led,                  // ID指示LED
    output              test_led,                // 测试指示LED
    output              download_sus,            // 下载状态指示
    input               touch_key,               // 触摸按键输入

    // ======================================================================
    // SGMII接口 - 千兆以太网串行接口
    // ======================================================================
    input               sgmii_clk_n,             // 125MHz SGMII差分时钟负端
    input               sgmii_clk_p,             // 125MHz SGMII差分时钟正端
    input               sgmii_rxn,               // SGMII接收差分信号负端
    input               sgmii_rxp,               // SGMII接收差分信号正端
    output              sgmii_txn,               // SGMII发送差分信号负端
    output              sgmii_txp,               // SGMII发送差分信号正端
    output              eth_rst_n,               // 以太网PHY复位(低有效)

    // ======================================================================
    // 按键触发接口
    // ======================================================================
    input               send_key,                // 按键触发ARP发送 (SW_W)
    input               udp_sender_key,          // 按键触发UDP数据发送 (SW_N)
    output              arp_led                  // ARP解析成功指示LED

    );

    //==========================================================================
    // 参数定义 - 网络配置
    //==========================================================================
    parameter  BOARD_MAC = 48'h00_11_22_33_44_55;         // 本板MAC地址
    parameter  BOARD_IP  = {8'd192,8'd168,8'd0,8'd2};    // 本板IP地址: 192.168.0.2
    parameter  DES_MAC   = 48'hff_ff_ff_ff_ff_ff;         // 目标MAC地址(广播)
    parameter  DES_IP    = {8'd192,8'd168,8'd0,8'd3};    // 目标IP地址: 192.168.0.3

    //==========================================================================
    // 参数定义 - 数据传输配置
    //==========================================================================
    parameter  DATA_LENGTH     = 32'd524_288_000;         // 总发送数据量: 500MB (500*1024*1024)
    parameter  UDP_SEND_LENGTH = 16'd1472;                // UDP单包数据段长度(最大1472B, 不含IP/UDP头)

    //==========================================================================
    // 状态机定义 - 数据写入FIFO状态 (独热码编码)
    // 状态转移: IDLE -> RESET_FIFO -> WAIT_RESET -> WRITE_DATA -> WRITE_DONE -> IDLE
    //==========================================================================
    localparam  IDLE        = 5'b00001;                   // 空闲状态, 等待按键触发
    localparam  RESET_FIFO  = 5'b00010;                   // 复位异步FIFO
    localparam  WAIT_RESET  = 5'b00100;                   // 等待FIFO复位完成及稳定
    localparam  WRITE_DATA  = 5'b01000;                   // 向FIFO写入数据
    localparam  WRITE_DONE  = 5'b10000;                   // 数据写入完成

    //==========================================================================
    // 状态机定义 - UDP发送触发状态 (独热码编码)
    // 状态转移: TX_IDLE -> TX_TRIGGER -> TX_WAIT -> TX_IDLE
    //==========================================================================
    localparam  TX_IDLE     = 3'b001;                     // 空闲状态, 检测FIFO数据量
    localparam  TX_TRIGGER  = 3'b010;                     // 触发UDP发送脉冲
    localparam  TX_WAIT     = 3'b100;                     // 等待当前UDP包发送完成 


    //==========================================================================
    // 内部信号定义 - GMII接口信号
    //==========================================================================
    wire                gmii_tx_en;               // GMII发送数据使能
    wire                gmii_tx_er;               // GMII发送错误指示
    wire        [7:0]   gmii_txd;                 // GMII发送数据
    wire                gmii_tx_clk;              // GMII发送时钟(125MHz)
    wire                gmii_tx_done;             // GMII发送完成标志
    wire                gmii_rx_clk;              // GMII接收时钟
    wire                gmii_rx_dv;               // GMII接收数据有效
    wire                gmii_rx_er;               // GMII接收错误指示
    wire        [7:0]   gmii_rxd;                 // GMII接收数据

    //==========================================================================
    // 内部信号定义 - ARP协议信号
    //==========================================================================
    wire                arp_gmii_tx_en;           // ARP GMII发送使能
    wire        [7:0]   arp_gmii_txd;             // ARP GMII发送数据
    wire                arp_tx_en;                // ARP发送使能
    wire                arp_tx_type;              // ARP发送类型(0:请求, 1:应答)
    wire                arp_tx_done;              // ARP发送完成
    wire                arp_rx_done;              // ARP接收完成
    wire                arp_rx_type;              // ARP接收类型(0:请求, 1:应答)

    //==========================================================================
    // 内部信号定义 - SGMII及系统信号
    //==========================================================================
    wire                resetdone;                // SGMII复位完成标志
    wire                mmcm_locked_out;          // MMCM锁定输出
    wire        [47:0]  des_mac;                  // 解析得到的目标MAC地址
    wire        [31:0]  des_ip;                   // 解析得到的目标IP地址
    wire        [31:0]  src_ip;                   // 解析得到的源IP地址
    wire        [47:0]  src_mac;                  // 解析得到的源MAC地址
    wire                sys_clk;                  // 200MHz系统时钟(IBUFDS输出)
    wire                sgmii_clk_en;             // SGMII时钟使能
    wire        [15:0]  status_vector;            // SGMII状态向量
    wire                arp_get;                  // ARP地址解析成功标志
    wire        [4:0]   cur_state;                // ARP当前状态(调试用)

    //==========================================================================
    // 内部信号定义 - ICMP协议信号
    //==========================================================================
    wire                icmp_tx_start_en;         // ICMP开始发送使能
    wire                icmp_tx_done;             // ICMP发送完成
    wire                icmp_gmii_tx_en;          // ICMP GMII发送使能
    wire        [7:0]   icmp_gmii_txd;            // ICMP GMII发送数据
    wire                icmp_rec_en;              // ICMP接收数据使能
    wire        [7:0]   icmp_rec_data;            // ICMP接收数据
    wire                icmp_tx_req;              // ICMP读数据请求信号
    wire        [7:0]   icmp_tx_data;             // ICMP待发送数据
    wire                icmp_rec_pkt_done;        // ICMP接收包完成标志
    wire        [15:0]  icmp_rec_byte_num;        // ICMP接收有效字节数
    wire        [15:0]  icmp_tx_byte_num;         // ICMP发送有效字节数

    //==========================================================================
    // 内部信号定义 - UDP协议信号
    //==========================================================================
    wire                udp_gmii_tx_en;           // UDP GMII发送使能
    wire        [7:0]   udp_gmii_txd;             // UDP GMII发送数据
    wire                udp_rec_pkt_done;         // UDP接收数据包完成标志
    wire                udp_rec_en;               // UDP接收数据使能
    wire        [7:0]   udp_rec_data;             // UDP接收数据
    wire        [15:0]  udp_rec_byte_num;         // UDP接收有效字节数
    wire                udp_tx_start_en;          // UDP开始发送触发信号
    wire        [7:0]   udp_tx_data;              // UDP发送数据
    wire        [15:0]  udp_tx_byte_num;          // UDP发送有效字节数
    wire                udp_tx_done;              // UDP发送完成信号
    wire                udp_tx_req;               // UDP读取发送数据请求信号

    //==========================================================================
    // 内部信号定义 - FIFO数据通道信号
    //==========================================================================
    wire        [7:0]   rec_data;                 // 以太网回环接收数据
    wire                rec_en;                   // 以太网回环接收使能
    wire        [7:0]   tx_data;                  // FIFO读出待发送数据
    wire                tx_req;                   // FIFO读数据请求

    //==========================================================================
    // 内部信号定义 - 按键消抖信号
    //==========================================================================
    reg                 udp_sender_0;             // 按键同步第一级寄存器
    reg                 udp_sender_1;             // 按键同步第二级寄存器
    reg                 udp_sender_2;             // 按键同步第三级寄存器(用于边沿检测)
    wire                udp_sender_start;         // 按键上升沿检测脉冲

    //==========================================================================
    // 内部信号定义 - 异步FIFO控制信号
    //==========================================================================
    wire                fifo_wr_en_sel;           // FIFO写入使能(经选择后)
    wire        [7:0]   fifo_din_sel;             // FIFO写入数据(经选择后)
    wire        [15:0]  wr_data_count;            // FIFO已写数据计数
    wire        [15:0]  rd_data_count;            // FIFO读剩余数据计数
    wire                fifo_full;                // FIFO满标志
    wire                wr_rst_busy;              // FIFO写侧复位忙标志
    wire                rd_rst_busy;              // FIFO读侧复位忙标志
    wire                prog_full;                // FIFO可编程满标志(阈值65533)

    //==========================================================================
    // 内部寄存器定义 - 数据写入状态机寄存器
    //==========================================================================
    reg [4:0]   state;                            // 数据写入FIFO当前状态
    reg [2:0]   tx_state;                         // UDP发送触发当前状态
    reg         fifo_rst;                          // FIFO复位控制寄存器
    reg [7:0]   din_reg;                           // FIFO写入数据寄存器
    reg         wr_en_reg;                         // FIFO写入使能寄存器
    reg [31:0]  byte_cnt;                          // 已写入字节计数器
    reg         send_start_pusle;                  // UDP发送触发脉冲
    reg         wr_data_done;                      // FIFO数据写入完成标志

    //==========================================================================
    // 内部寄存器定义 - UDP发送控制寄存器
    //==========================================================================
    reg         tx_busy;                           // UDP发送忙标志
    reg [15:0]  tx_byte_num;                       // UDP报文数据段长度
    reg [7:0]   fifo_rst_cnt;                      // FIFO复位计数器(用于延时)
    reg         sys_clk_cnt;                       // 系统时钟分频计数器
    reg         src_data_clk;                      // 源数据时钟(分频输出)

    //==========================================================================
    // 组合逻辑 - 信号连接与赋值
    //==========================================================================
    assign  udp_sender_start = (~udp_sender_2) & udp_sender_1;  // 检测按键上升沿
    assign  des_ip  = src_ip;                                    // 目标IP = 源IP(回环)
    assign  des_mac = src_mac;                                   // 目标MAC = 源MAC(回环)
    assign  eth_rst_n = ~sys_rst;                                // PHY复位(低有效, 取反系统复位)
    assign  download_sus = arp_get;                              // 下载指示 = ARP解析成功

    assign  icmp_tx_start_en = icmp_rec_pkt_done;                // ICMP收到包后自动触发回复
    assign  icmp_tx_byte_num = icmp_rec_byte_num;                // ICMP回复字节数 = 接收字节数

    assign  udp_tx_start_en = send_start_pusle;                  // UDP发送由触发脉冲启动
    assign  udp_tx_byte_num = tx_byte_num;                       // UDP发送字节长度

    // FIFO写入数据选择: 当前选择内部数据源写入(可切换为回环数据)
    // assign  fifo_wr_en_sel = (state == WRITE_DATA) ? wr_en_reg : rec_en;
    // assign  fifo_din_sel   = (state == WRITE_DATA) ? din_reg : rec_data;
    assign  fifo_wr_en_sel = wr_en_reg;                          // FIFO写入使能选择
    assign  fifo_din_sel   = din_reg;                            // FIFO写入数据选择

    //==========================================================================
    // 时序逻辑 - 按键消抖(三级同步 + 边沿检测)
    // 时钟域: sys_clk (200MHz)
    // 功能: 对udp_sender_key进行同步处理并检测上升沿
    //==========================================================================
    always @(posedge sys_clk or posedge sys_rst) begin
        if(sys_rst) begin
            udp_sender_0 <= 1'b0;
            udp_sender_1 <= 1'b0;
            udp_sender_2 <= 1'b0;
        end
        else begin
            udp_sender_0 <= udp_sender_key;                      // 第一级同步
            udp_sender_1 <= udp_sender_0;                        // 第二级同步
            udp_sender_2 <= udp_sender_1;                        // 第三级同步(边沿检测用)
        end
    end

    //==========================================================================
    // 状态机 - 源端数据写入异步FIFO
    // 时钟域: sys_clk (200MHz)
    // 复位: sys_rst (高有效异步复位)
    // 状态转移:
    //   IDLE --[按键按下]--> RESET_FIFO --[复位计数>=10]--> WAIT_RESET
    //   WAIT_RESET --[FIFO复位完成+延时100周期]--> WRITE_DATA
    //   WRITE_DATA --[数据写完]--> WRITE_DONE --> IDLE
    //==========================================================================
    always @(posedge sys_clk or posedge sys_rst) begin
        if(sys_rst) begin
            state           <= IDLE;
            fifo_rst        <= 1'b0;
            din_reg         <= 8'd0;
            wr_en_reg       <= 1'b0;
            byte_cnt        <= 32'd0;
            wr_data_done    <= 1'b0;
            fifo_rst_cnt    <= 8'd0;
        end
        else begin
            case(state)
                IDLE: begin                                     // 空闲状态: 等待按键触发
                    if(udp_sender_start) begin
                        wr_data_done <= 1'b0;
                        state <= RESET_FIFO;
                        fifo_rst <= 1'b1;
                    end
                end

                RESET_FIFO: begin                               // 复位FIFO: 保持复位信号至少10个时钟周期
                    byte_cnt <= 32'd0;
                    din_reg  <= 8'd0;
                    fifo_rst_cnt <= 8'd0;
                    fifo_rst <= 1'b1;
                    if(fifo_rst_cnt >= 8'd10) begin
                        fifo_rst <= 1'b0;
                        state    <= WAIT_RESET;
                        fifo_rst_cnt <= 8'd0;
                    end
                    else begin
                        state <= RESET_FIFO;
                        fifo_rst_cnt <= fifo_rst_cnt + 8'd1;
                    end
                end

                WAIT_RESET: begin                               // 等待复位: 等待FIFO复位完成并额外延时100周期
                    if(wr_rst_busy || rd_rst_busy) begin
                        state <= WAIT_RESET;
                    end
                    else begin
                        if(fifo_rst_cnt > 8'd100) begin
                            state <= WRITE_DATA;
                            fifo_rst_cnt <= 8'd0;
                        end
                        else begin
                            fifo_rst_cnt <= fifo_rst_cnt + 8'd1;
                            state <= WAIT_RESET;
                        end

                    end

                end

                WRITE_DATA: begin                               // 写入数据: 递增数据写入FIFO, 单包不超过1472B
                    if(byte_cnt < DATA_LENGTH) begin
                        if(!prog_full) begin                    // FIFO未达可编程满阈值时写入
                            din_reg   <= din_reg + 8'd1;
                            wr_en_reg <= 1'b1;
                            byte_cnt  <= byte_cnt + 32'd1;
                        end
                        else begin
                            wr_en_reg <= 1'b0;                 // FIFO接近满, 暂停写入
                        end

                    end
                    else begin
                        wr_en_reg <= 1'b0;                     // 数据写完, 停止写入
                        state     <= WRITE_DONE;
                    end
                end

                WRITE_DONE: begin                               // 写入完成: 置位完成标志, 返回空闲
                    wr_data_done <= 1'b1;
                    state        <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end

    //==========================================================================
    // 状态机 - UDP发送触发控制
    // 时钟域: gmii_tx_clk (125MHz)
    // 复位: sys_rst (高有效异步复位)
    // 功能: 监测FIFO中数据量, 当数据量达到一包UDP长度时触发发送
    //       或在数据写入完成后发送剩余数据
    // 状态转移:
    //   TX_IDLE --[FIFO数据>=UDP_SEND_LENGTH]--> TX_TRIGGER
    //   TX_IDLE --[写入完成且FIFO有剩余]--> TX_TRIGGER
    //   TX_TRIGGER --[发送脉冲]--> TX_WAIT
    //   TX_WAIT --[发送完成]--> TX_IDLE
    //==========================================================================
    always @(posedge gmii_tx_clk or posedge sys_rst) begin
        if(sys_rst) begin
            tx_state <= TX_IDLE;
            tx_busy  <= 1'b0;
            send_start_pusle <= 1'b0;
            tx_byte_num <= UDP_SEND_LENGTH;
        end
        else begin
            send_start_pusle <= 1'b0;                            // 默认拉低, 仅在TX_TRIGGER产生单周期脉冲
            case(tx_state)
                TX_IDLE: begin                                   // 空闲状态: 检测FIFO数据量是否满足发送条件
                    if((rd_data_count >= UDP_SEND_LENGTH) && !tx_busy) begin
                        tx_state <= TX_TRIGGER;                  // FIFO数据量达到一包, 触发发送
                        tx_byte_num <= UDP_SEND_LENGTH;
                    end
                    else if(wr_data_done && (wr_data_count > 0) && !tx_busy) begin
                        tx_byte_num <= wr_data_count;            // 数据写入完成, 发送FIFO中剩余数据
                        tx_state <= TX_TRIGGER;
                    end
                    else
                        tx_state <= TX_IDLE;

                end

                TX_TRIGGER: begin                                // 触发状态: 产生一个时钟周期的发送脉冲
                    send_start_pusle <= 1'b1;
                    tx_state <= TX_WAIT;
                end

                TX_WAIT: begin                                   // 等待状态: 等待当前UDP包发送完成
                    if(udp_tx_done) begin
                        tx_busy <= 1'b0;
                        tx_state <= TX_IDLE;
                    end
                    else begin
                        tx_busy <= 1'b1;                         // 发送进行中, 禁止新的触发
                    end
                    
                end

                default: tx_state <= TX_IDLE;

            endcase

        end

    end


    //==========================================================================
    // 模块例化 - 异步FIFO (Xilinx FIFO Generator IP)
    // 功能: 跨时钟域数据缓冲, 写侧200MHz(sys_clk), 读侧125MHz(gmii_tx_clk)
    // 深度: 65536, 位宽: 8bit, 可编程满阈值: 65533
    //==========================================================================
    fifo_generator_1 unsyc_data_fifo (
      .rst(sys_rst | fifo_rst),                                // 复位: 系统复位 或 FIFO软复位
      .wr_clk(sys_clk),                                        // 写时钟: 200MHz
      .rd_clk(gmii_tx_clk),                                    // 读时钟: 125MHz
      .din(fifo_din_sel),                                      // 写入数据
      .wr_en(fifo_wr_en_sel),                                  // 写入使能
      .rd_en(tx_req),                                          // 读出使能(由UDP发送请求驱动)
      .dout(tx_data),                                          // 读出数据
      .full(fifo_full),                                        // 满标志
      .empty(),                                                // 空标志(未使用)
      .rd_data_count(rd_data_count),                           // 读侧剩余数据计数
      .wr_data_count(wr_data_count),                           // 写侧已写数据计数
      .prog_full(prog_full),                                   // 可编程满标志(阈值65533)
      .wr_rst_busy(wr_rst_busy),                               // 写侧复位忙标志
      .rd_rst_busy(rd_rst_busy)                                // 读侧复位忙标志
    );
    
    // 备用: 同步FIFO例化(当前未使用, 保留供参考)
    // fifo_generator_0 data_fifo (
    //   .clk(gmii_tx_clk),      // input wire clk
    //   .srst(sys_rst | fifo_rst),    // input wire srst
    //   .din(fifo_din_sel),      // input wire [7 : 0] din
    //   .wr_en(fifo_wr_en_sel),  // input wire wr_en
    //   .rd_en(tx_req),  // input wire rd_en
    //   .dout(tx_data),    // output wire [7 : 0] dout
    //   .full(),    // output wire full
    //   .empty()  // output wire empty
    // );



    //==========================================================================
    // 模块例化 - ILA在线逻辑分析仪 (Xilinx ILA IP)
    // 功能: 调试信号抓取, 监测关键状态机与数据通路信号
    //==========================================================================
    ila_1 icmp_ila_test_1 (
        .clk(gmii_tx_clk),                                     // ILA采样时钟: 125MHz
    
        .probe0(udp_sender_start),                              // [0]   按键触发脉冲
        .probe1(fifo_rst),                                      // [0]   FIFO复位信号
        .probe2(wr_rst_busy),                                   // [0]   FIFO写侧复位忙
        .probe3(rd_rst_busy),                                   // [0]   FIFO读侧复位忙
        .probe4(gmii_rxd),                                      // [7:0] GMII接收数据
        .probe5(gmii_txd),                                      // [7:0] GMII发送数据
        .probe6(fifo_rst_cnt),                                  // [7:0] FIFO复位计数器
        .probe7(icmp_rec_byte_num),                             // [15:0] ICMP接收字节数
        .probe8(send_start_pusle),                              // [0]   UDP发送触发脉冲
        .probe9(sys_rst),                                       // [0]   系统复位
        .probe10(din_reg),                                      // [7:0] FIFO写入数据
        .probe11(tx_data),                                      // [7:0] FIFO读出数据
        .probe12(state)                                         // [4:0] 数据写入状态机
    );

    //==========================================================================
    // 模块例化 - 差分时钟输入缓冲 (Xilinx IBUFDS原语)
    // 功能: 将200MHz差分时钟信号转换为单端时钟sys_clk
    //==========================================================================
    IBUFDS #(
      .DIFF_TERM("FALSE"),                                     // 未使能差分终端电阻
      .IBUF_LOW_PWR("FALSE"),                                  // 高性能模式(非低功耗)
      .IOSTANDARD("LVDS")                                      // LVDS电平标准
   ) IBUFDS_inst (
      .O(sys_clk),                                             // 单端时钟输出: 200MHz
      .I(sys_clk_p),                                           // 差分正端输入
      .IB(sys_clk_n)                                           // 差分负端输入
   );

    //==========================================================================
    // 模块例化 - ARP协议处理模块
    // 功能: 实现ARP请求发送与应答解析, 获取目标MAC地址
    //==========================================================================
    arp #(
        .DES_IP             (DES_IP),
        .DES_MAC            (DES_MAC),
        .BOARD_IP           (BOARD_IP),
        .BOARD_MAC          (BOARD_MAC)
    )u_arp(
        .rst                (sys_rst),                   // 系统复位
        .gmii_rx_clk        (gmii_tx_clk),               // GMII接收时钟
        .gmii_rx_dv         (gmii_rx_dv),                // GMII接收数据有效
        .gmii_rxd           (gmii_rxd),                  // GMII接收数据
        .gmii_tx_clk        (gmii_tx_clk),               // GMII发送时钟
        .gmii_tx_en         (arp_gmii_tx_en),            // ARP GMII发送使能
        .gmii_txd           (arp_gmii_txd),              // ARP GMII发送数据
        .gmii_tx_done       (arp_tx_done),               // ARP发送完成

        .arp_tx_en          (arp_tx_en),                 // ARP发送使能
        .arp_tx_type        (arp_tx_type),               // ARP发送类型
        .arp_rx_done        (arp_rx_done),               // ARP接收完成
        .arp_rx_type        (arp_rx_type),               // ARP接收类型
        .des_mac            (des_mac),                   // 解析得到的目标MAC
        .des_ip             (des_ip),                    // 解析得到的目标IP
        .src_mac            (src_mac),                   // 解析得到的源MAC
        .src_ip             (src_ip),                    // 解析得到的源IP
        
        .arp_led            (arp_led),                   // ARP解析指示LED
        .arp_get            (arp_get),                   // ARP地址解析成功标志
        .cur_state          (cur_state)                  // ARP当前状态(调试用)
    );

    //==========================================================================
    // 模块例化 - ICMP协议处理模块
    // 功能: 实现ICMP Echo Reply, 自动响应Ping请求
    //==========================================================================
    icmp #(
        .BOARD_IP(BOARD_IP),
        .BOARD_MAC(BOARD_MAC),
        .DES_IP(DES_IP),
        .DES_MAC(DES_MAC)
    )u_icmp(
        .rst                (sys_rst        ),            // 系统复位
        .gmii_rx_clk        (gmii_tx_clk    ),            // GMII接收时钟
        .gmii_rx_dv         (gmii_rx_dv     ),            // GMII接收数据有效
        .gmii_rxd           (gmii_rxd       ),            // GMII接收数据
        .gmii_tx_clk        (gmii_tx_clk    ),            // GMII发送时钟
        .gmii_tx_en         (icmp_gmii_tx_en),            // ICMP GMII发送使能
        .gmii_txd           (icmp_gmii_txd  ),            // ICMP GMII发送数据
        .rec_pkt_done       (icmp_rec_pkt_done),          // ICMP接收包完成
        .rec_en             (icmp_rec_en    ),            // ICMP接收数据使能
        .rec_data           (icmp_rec_data  ),            // ICMP接收数据
        .rec_byte_num       (icmp_rec_byte_num),          // ICMP接收字节数
        .tx_start_en        (icmp_tx_start_en),           // ICMP发送启动使能
        .tx_data            (icmp_tx_data   ),            // ICMP发送数据
        .tx_byte_num        (icmp_tx_byte_num),           // ICMP发送字节数
        .des_mac            (des_mac        ),            // 目标MAC地址
        .des_ip             (des_ip         ),            // 目标IP地址
        .tx_done            (icmp_tx_done   ),            // ICMP发送完成
        .tx_req             (icmp_tx_req    )             // ICMP读数据请求
    );



    //==========================================================================
    // 模块例化 - 以太网发送仲裁切换模块
    // 功能: 多协议(ARP/ICMP/UDP)GMII发送通道仲裁, 避免总线冲突
    //       同时完成FIFO数据通道与协议栈的连接
    //==========================================================================
    eth_ctrl_sw u_eth_ctrl_sw(
        .clk                (gmii_tx_clk),               // 工作时钟: 125MHz
        .rst                (sys_rst),                   // 系统复位

        // ARP接口
        .arp_rx_done        (arp_rx_done),               // ARP接收完成
        .arp_rx_type        (arp_rx_type),               // ARP接收类型
        .arp_tx_en          (arp_tx_en),                 // ARP发送使能
        .arp_tx_type        (arp_tx_type),               // ARP发送类型
        .arp_tx_done        (arp_tx_done),               // ARP发送完成
        .arp_gmii_tx_en     (arp_gmii_tx_en),            // ARP GMII发送使能
        .arp_gmii_txd       (arp_gmii_txd),              // ARP GMII发送数据

        // ICMP接口
        .icmp_tx_start_en   (icmp_tx_start_en),          // ICMP发送启动
        .icmp_tx_done       (icmp_tx_done),              // ICMP发送完成
        .icmp_gmii_tx_en    (icmp_gmii_tx_en),           // ICMP GMII发送使能
        .icmp_gmii_txd      (icmp_gmii_txd),             // ICMP GMII发送数据

        // ICMP FIFO接口
        .icmp_rec_en        (icmp_rec_en),               // ICMP接收数据使能
        .icmp_rec_data      (icmp_rec_data),             // ICMP接收数据
        .icmp_tx_req        (icmp_tx_req),               // ICMP读数据请求
        .icmp_tx_data       (icmp_tx_data),              // ICMP发送数据

        // UDP接口
        .udp_tx_start_en    (udp_tx_start_en),           // UDP发送启动
        .udp_tx_done        (udp_tx_done),               // UDP发送完成
        .udp_gmii_tx_en     (udp_gmii_tx_en),            // UDP GMII发送使能
        .udp_gmii_txd       (udp_gmii_txd),              // UDP GMII发送数据

        // UDP FIFO接口
        .udp_rec_en         (udp_rec_en),                // UDP接收数据使能
        .udp_rec_data       (udp_rec_data),              // UDP接收数据
        .udp_tx_req         (udp_tx_req),                // UDP读数据请求
        .udp_tx_data        (udp_tx_data),               // UDP发送数据

        // FIFO数据通道
        .tx_data            (tx_data),                   // FIFO读出数据
        .tx_req             (tx_req),                    // FIFO读请求
        .rec_en             (rec_en),                    // 回环接收使能
        .rec_data           (rec_data),                  // 回环接收数据

        // GMII输出
        .gmii_tx_en         (gmii_tx_en),                // GMII发送使能(仲裁后)
        .gmii_txd           (gmii_txd)                   // GMII发送数据(仲裁后)
    );

    //==========================================================================
    // 模块例化 - UDP协议处理模块
    // 功能: 实现UDP数据包的封装发送与接收解析
    //==========================================================================
    udp #(
        .BOARD_IP(BOARD_IP),
        .BOARD_MAC(BOARD_MAC),
        .DES_IP(DES_IP),
        .DES_MAC(DES_MAC)
    )u_udp(
        .rst                    (sys_rst),               // 系统复位
        // GMII接口
        .gmii_rx_clk            (gmii_tx_clk),           // GMII接收时钟
        .gmii_rx_dv             (gmii_rx_dv),            // GMII接收数据有效
        .gmii_rxd               (gmii_rxd),              // GMII接收数据
        .gmii_tx_clk            (gmii_tx_clk),           // GMII发送时钟
        .gmii_tx_en             (udp_gmii_tx_en),        // UDP GMII发送使能
        .gmii_txd               (udp_gmii_txd),          // UDP GMII发送数据

        // UDP接收接口
        .rec_pkt_done           (udp_rec_pkt_done),      // UDP接收包完成
        .rec_en                 (udp_rec_en),            // UDP接收数据使能
        .rec_data               (udp_rec_data),          // UDP接收数据
        .rec_byte_num           (udp_rec_byte_num),      // UDP接收字节数
        // UDP发送接口
        .tx_start_en            (udp_tx_start_en),       // UDP发送启动使能
        .tx_data                (udp_tx_data),           // UDP发送数据
        .tx_byte_num            (udp_tx_byte_num),       // UDP发送字节数
        .des_mac                (des_mac),               // 目标MAC地址
        .des_ip                 (des_ip),                // 目标IP地址
        .tx_done                (udp_tx_done),           // UDP发送完成
        .tx_req                 (udp_tx_req)             // UDP读数据请求

    );

    //==========================================================================
    // 模块例化 - SGMII到GMII接口转换模块
    // 功能: 实现千兆以太网SGMII串行接口与GMII并行接口的协议转换
    //==========================================================================
    sgmii_to_gmii u_sgmii_gmii(
        .sys_rst                    (sys_rst    ),              // 系统复位
        .sgmii_clk_n                (sgmii_clk_n),              // SGMII差分时钟负端
        .sgmii_clk_p                (sgmii_clk_p),              // SGMII差分时钟正端
        .independent_clock_bufg     (sys_clk    ),              // 独立时钟(200MHz, 用于GT恢复)
        .sgmii_rx_n                 (sgmii_rxn  ),              // SGMII差分接收负端
        .sgmii_rx_p                 (sgmii_rxp  ),              // SGMII差分接收正端
        .gmii_tx_en                 (gmii_tx_en ),              // GMII发送使能
        .gmii_tx_er                 (),                         // GMII发送错误(未使用)
        .gmii_txd                   (gmii_txd   ),              // GMII发送数据
        .gmii_rx_clk                (gmii_rx_clk),              // GMII接收时钟
        .gmii_rx_dv                 (gmii_rx_dv ),              // GMII接收数据有效
        .gmii_rx_er                 (),                         // GMII接收错误(未使用)
        .gmii_rxd                   (gmii_rxd   ),              // GMII接收数据
        .gmii_tx_clk                (gmii_tx_clk),              // GMII发送时钟
        .sgmii_tx_n                 (sgmii_txn  ),              // SGMII差分发送负端
        .sgmii_tx_p                 (sgmii_txp  ),              // SGMII差分发送正端
        .resetdone                  (resetdone  ),              // SGMII复位完成标志
        .mmcm_locked_out            (mmcm_locked_out),          // MMCM锁定输出
        .sgmii_clk_en               (sgmii_clk_en),             // SGMII时钟使能
        .status_vector              (status_vector)             // SGMII状态向量

    );

    //==========================================================================
    // 模块例化 - MDIO管理接口模块
    // 功能: 通过MDIO接口配置以太网PHY芯片寄存器
    //==========================================================================
    mdio_wr_test u_mdio_wr_test(
        .sys_clk(sys_clk),                                     // 系统时钟: 200MHz
        .sys_rst(sys_rst),                                     // 系统复位
        .eth_mdc(eth_mdc),                                     // PHY管理时钟输出
        .eth_mdio(eth_mdio),                                   // PHY管理数据(双向)
        .touch_key(touch_key),                                 // 触摸按键输入
        .led(led),                                             // 通用LED输出
        .id_led(id_led),                                       // ID指示LED
        .test_led(test_led)                                    // 测试指示LED
    );



// ==========================================================================
// 模块结束: src_data_maxv
// ==========================================================================
endmodule
