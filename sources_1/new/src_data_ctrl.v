`timescale 1ns / 1ps

// -------------------------------------------------------------------
// 按键触发FPGA发送UDP报文
// -------------------------------------------------------------------

module src_data_ctrl(
    input               sys_clk_p,               // 200mhz时钟源
    input               sys_clk_n,
    input               sys_rst,

    // --------mdio接口--------
    output              eth_mdc,
    inout               eth_mdio,

    output      [1:0]   led,
    output              id_led,              // 读id正确指示led
    output              test_led,            // 读访问错误指示led
    output              download_sus,        // 下载代码成功指示led
    input               touch_key,           // mdio配置按键                 SW_E

    // --------SGMII接口-------
    input               sgmii_clk_n,             // 125m参考时钟
    input               sgmii_clk_p,
    input               sgmii_rxn,                      
    input               sgmii_rxp,
    output              sgmii_txn,
    output              sgmii_txp,              
    output              eth_rst_n,               // 以太网模块复位

    input               send_key,                // 发送arp请求按键          SW_W
    input               udp_sender_key,          // 发送udp数据报触发按键    SW_N
    output              arp_led                  // arp测试led

    );

    // 板卡mac和ip
    parameter  BOARD_MAC = 48'h00_11_22_33_44_55;        // 板卡MAC地址
    parameter  BOARD_IP  = {8'd192,8'd168,8'd0,8'd2}; 
    // 目标mac和ip
    parameter  DES_MAC   = 48'hff_ff_ff_ff_ff_ff;
    parameter  DES_IP    = {8'd192,8'd168,8'd0,8'd3}; 
    parameter  DATA_LENGTH     = 32'd524_288_000;         // 数据总长度:100MB
    parameter  UDP_SEND_LENGTH = 16'd1472;                // UDP触发发送长度


    // 按键触发数据写入
    localparam  IDLE        = 5'b00001;
    localparam  RESET_FIFO  = 5'b00010;
    localparam  WAIT_RESET  = 5'b00100;
    localparam  WRITE_DATA  = 5'b01000;
    localparam  WRITE_DONE  = 5'b10000;

    // 触发UDP发送
    localparam  TX_IDLE     = 3'b001;
    localparam  TX_TRIGGER  = 3'b010; 
    localparam  TX_WAIT     = 3'b100; 


    // wire define
    wire                gmii_tx_en;
    wire                gmii_tx_er;
    wire        [7:0]   gmii_txd;
    wire                gmii_tx_clk;
    wire                gmii_tx_done;
    wire                gmii_rx_clk;
    wire                gmii_rx_dv;
    wire                gmii_rx_er;
    wire        [7:0]   gmii_rxd;

    wire                arp_gmii_tx_en;
    wire        [7:0]   arp_gmii_txd;
    wire                arp_tx_en;
    wire                arp_tx_type;
    wire                arp_tx_done;
    wire                arp_rx_done;
    wire                arp_rx_type;

    wire                resetdone;
    wire                mmcm_locked_out;
    wire        [47:0]  des_mac;
    wire        [31:0]  des_ip;
    wire        [31:0]  src_ip;
    wire        [47:0]  src_mac;
    wire                sys_clk;

    wire                sgmii_clk_en;
    wire        [15:0]  status_vector;
    wire                arp_get;
    wire        [4:0]   cur_state;  

    // ICMP端口信号
    wire                icmp_tx_start_en;              // ICMP发送模块使能信号（开始组包）
    wire                icmp_tx_done;                  // ICMP单包发送完成
    wire                icmp_gmii_tx_en;               // ICMP使能gmii_txd发送数据
    wire        [7:0]   icmp_gmii_txd;                 // ICMP通过gmii_txd发送的数据
    wire                icmp_rec_en;                   // ICMP接收数据使能信号
    wire        [7:0]   icmp_rec_data;
    wire                icmp_tx_req;                   // ICMP读数据请求信号
    wire        [7:0]   icmp_tx_data;                  // ICMP待发送数据
    wire                icmp_rec_pkt_done;
    wire        [15:0]  icmp_rec_byte_num;             // 接收有效字节数     
    wire        [15:0]  icmp_tx_byte_num;              // 发送有效字节数

    // UDP端口信号
    wire                udp_gmii_tx_en;
    wire        [7:0]   udp_gmii_txd;

    wire                udp_rec_pkt_done;              // 接收数据包完成标志
    wire                udp_rec_en;                    // 接收数据使能
    wire        [7:0]   udp_rec_data;                  // udp接收数据
    wire        [15:0]  udp_rec_byte_num;              // 接收有效字节数
    wire                udp_tx_start_en;               // 开始发送触发信号
    wire        [7:0]   udp_tx_data;                   // udp发送数据        
    wire        [15:0]  udp_tx_byte_num;               // 发送有效字节数
    wire                udp_tx_done;                   // 发送完成信号
    wire                udp_tx_req;                    // 读取发送数据请求信号

    wire        [7:0]   rec_data;
    wire                rec_en;
    wire        [7:0]   tx_data;
    wire                tx_req;

    // udp_sender_key触发按键消抖
    reg                 udp_sender_0;
    reg                 udp_sender_1;
    reg                 udp_sender_2;
    wire                udp_sender_start;

    // fifo输入数据选择
    wire                fifo_wr_en_sel;
    wire        [7:0]   fifo_din_sel;
    wire        [15:0]  wr_data_count;                                  // FIFO写入数据计数
    wire                fifo_full;
    wire                wr_rst_busy;
    wire                rd_rst_busy;
    wire                prog_full;                              // 可编程满标志，65533时拉高

    reg [4:0]   state;                                          // 数据写入状态
    reg [2:0]   tx_state;                                       // UDP发送状态
    reg         fifo_rst;
    reg [7:0]   din_reg;
    reg         wr_en_reg;
    reg [31:0]  byte_cnt;                                       // 写入字节计数
    reg         send_start_pusle;                               // 发送触发脉冲
    reg         wr_data_done;                                   // 写入数据完成

    reg         tx_busy;                                        // UDP发送忙
    reg [15:0]  tx_byte_num;                                    // UDP报文数据段长度
    reg [5:0]   fifo_rst_cnt;                                   // 等待FIFO复位完成
    reg         sys_clk_cnt;
    reg         src_data_clk;
    reg         src_clk_50m;                                    // 50MHz源端时钟

    assign  udp_sender_start = (~udp_sender_2) & udp_sender_1;
    assign  des_ip = src_ip;
    assign  des_mac = src_mac;
    assign  eth_rst_n = ~sys_rst;
    assign  download_sus = arp_get;

    assign  icmp_tx_start_en = icmp_rec_pkt_done;
    assign  icmp_tx_byte_num = icmp_rec_byte_num;

    assign  udp_tx_start_en = send_start_pusle;
    assign  udp_tx_byte_num = tx_byte_num;                           // UDP发送字节长度

    // FIFO输入数据选择
    // assign  fifo_wr_en_sel = (state == WRITE_DATA) ? wr_en_reg : rec_en;
    // assign  fifo_din_sel   = (state == WRITE_DATA) ? din_reg : rec_data;
    assign  fifo_wr_en_sel = wr_en_reg;
    assign  fifo_din_sel   = din_reg;

    // 打三拍采集udp_sender_key的上升沿
    always @(posedge gmii_tx_clk or posedge sys_rst) begin
        if(sys_rst) begin
            udp_sender_0 <= 1'b0;
            udp_sender_1 <= 1'b0;
            udp_sender_2 <= 1'b0;
        end
        else begin
            udp_sender_0 <= udp_sender_key;
            udp_sender_1 <= udp_sender_0;
            udp_sender_2 <= udp_sender_1;
        end
    end
    
     // 50MHz时钟分频
    always @(posedge sys_clk or posedge sys_rst) begin
        if(sys_rst) begin
            src_clk_50m <= 1'b0;
            sys_clk_cnt <= 1'b0;
        end
        else begin
            sys_clk_cnt <= sys_clk_cnt + 1'b1;
            if(sys_clk_cnt)
                src_clk_50m <= ~src_clk_50m;
        end

    end

    // 按键触发数据写入FIFO 时钟可选gmii_tx_clk
    always @(posedge src_clk_50m or posedge sys_rst) begin
        if(sys_rst) begin
            state           <= IDLE;
            fifo_rst        <= 1'b0;
            din_reg         <= 8'd0;
            wr_en_reg       <= 1'b0;
            byte_cnt        <= 32'd0;
            wr_data_done    <= 1'b0;
            fifo_rst_cnt    <= 6'd0;
        end
        else begin
            case(state)
                IDLE:begin
                    // 等待udp_sender按下
                    if(udp_sender_start) begin
                        wr_data_done <= 1'b0;
                        state <= RESET_FIFO;
                        fifo_rst <= 1'b1;
                    end
                end

                RESET_FIFO:begin
                    fifo_rst <= 1'b0;
                    byte_cnt <= 32'd0;
                    din_reg  <= 8'd0;
                    state    <= WAIT_RESET;
                end

                WAIT_RESET:begin
                    if(wr_rst_busy || rd_rst_busy) begin
                        state <= WAIT_RESET;
                    end
                    else begin
                        if(fifo_rst_cnt > 6'd50) begin
                            state <= WRITE_DATA;
                            fifo_rst_cnt <= 6'd0;
                        end
                        else begin
                            fifo_rst_cnt <= fifo_rst_cnt + 6'd1;
                            state <= WAIT_RESET;
                        end

                    end

                end

                WRITE_DATA:begin              // 写入数据部分内容，小于1500-20-8=1472 Bytes
                    if(byte_cnt < DATA_LENGTH) begin
                        if(!prog_full) begin                    // 未达到发送阈值时写入
                            din_reg   <= din_reg + 8'd1;
                            wr_en_reg <= 1'b1;
                            byte_cnt  <= byte_cnt + 32'd1;
                        end
                        else begin
                            wr_en_reg <= 1'b0;
                        end

                    end
                    else begin
                        wr_en_reg <= 1'b0;
                        state     <= WRITE_DONE;
                    end
                end

                WRITE_DONE:begin
                    wr_data_done <= 1'b1;
                    state        <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end

    // always块监听wr_data_count触发发送UDP报文
    always @(posedge gmii_tx_clk or posedge sys_rst) begin
        if(sys_rst) begin
            tx_state <= TX_IDLE;
            tx_busy  <= 1'b0;
            send_start_pusle <= 1'b0;
            tx_byte_num <= UDP_SEND_LENGTH;
        end
        else begin
            send_start_pusle <= 1'b0;
            case(tx_state)
                TX_IDLE:begin
                    if((wr_data_count >= UDP_SEND_LENGTH) && !tx_busy) begin
                        tx_state <= TX_TRIGGER;
                        tx_byte_num <= UDP_SEND_LENGTH;
                    end
                    else if(wr_data_done && (wr_data_count > 0) && !tx_busy) begin
                        tx_byte_num <= wr_data_count;
                        tx_state <= TX_TRIGGER;
                    end
                    else
                        tx_state <= TX_IDLE;

                end

                TX_TRIGGER:begin
                    send_start_pusle <= 1'b1;               // 触发发送
                    tx_state <= TX_WAIT;
                end

                TX_WAIT:begin
                    if(udp_tx_done) begin
                        tx_busy <= 1'b0;
                        tx_state <= TX_IDLE;
                    end
                    else begin
                        tx_busy <= 1'b1;
                    end
                    
                end

                default: tx_state <= TX_IDLE;

            endcase

        end

    end


    // FIFO例化
    fifo_generator_1 unsyc_data_fifo (
      .rst(sys_rst | fifo_rst),            // input wire rst
      .wr_clk(src_clk_50m),                // input wire wr_clk
      .rd_clk(gmii_tx_clk),                // input wire rd_clk
      .din(fifo_din_sel),                      // input wire [7 : 0] din
      .wr_en(fifo_wr_en_sel),                  // input wire wr_en
      .rd_en(tx_req),                  // input wire rd_en
      .dout(tx_data),                    // output wire [7 : 0] dout
      .full(fifo_full),                    // output wire full
      .empty(),                  // output wire empty
      .rd_data_count(),                // output wire [15 : 0] rd_data_count
      .wr_data_count(wr_data_count),  // output wire [15 : 0] wr_data_count
      .prog_full(prog_full),                // output wire prog_full
      .wr_rst_busy(wr_rst_busy),      // output wire wr_rst_busy
      .rd_rst_busy(rd_rst_busy)      // output wire rd_rst_busy
    );
    
//    // 同步FIFO例化
//    fifo_generator_0 data_fifo (
//      .clk(gmii_tx_clk),      // input wire clk
//      .srst(sys_rst | fifo_rst),    // input wire srst
//      .din(fifo_din_sel),      // input wire [7 : 0] din
//      .wr_en(fifo_wr_en_sel),  // input wire wr_en
//      .rd_en(tx_req),  // input wire rd_en
//      .dout(tx_data),    // output wire [7 : 0] dout
//      .full(),    // output wire full
//      .empty()  // output wire empty
//    );



    // ----------------------   ila调试   ------------------------
    ila_1 icmp_ila_test_1 (
        .clk(gmii_tx_clk), // input wire clk
    
        .probe0(udp_sender_start), // input wire [0:0]  probe0  
        .probe1(fifo_rst), // input wire [0:0]  probe1 
        .probe2(fifo_full), // input wire [0:0]  probe2 
        .probe3(gmii_rx_dv), // input wire [0:0]  probe3 
        .probe4(gmii_rxd), // input wire [7:0]  probe4 
        .probe5(gmii_txd), // input wire [7:0]  probe5 
        .probe6(icmp_gmii_txd), // input wire [7:0]  probe6 
        .probe7(icmp_rec_byte_num), // input wire [15:0]  probe7 
        .probe8(send_start_pusle), // input wire [0:0]  probe8 
        .probe9(udp_tx_done), // input wire [0:0]  probe9 
        .probe10(din_reg), // input wire [7:0]  probe10 
        .probe11(tx_data), // input wire [7:0]  probe11
        .probe12(cur_state)
    );

    // ---------------------------------产生200mhz时钟源-------------------------------------
    IBUFDS #(
      .DIFF_TERM("FALSE"),       // Differential Termination
      .IBUF_LOW_PWR("FALSE"),     // Low power="TRUE", Highest performance="FALSE" 
      .IOSTANDARD("LVDS")     // Specify the input I/O standard
   ) IBUFDS_inst (
      .O(sys_clk),  // Buffer output
      .I(sys_clk_p),  // Diff_p buffer input (connect directly to top-level port)
      .IB(sys_clk_n) // Diff_n buffer input (connect directly to top-level port)
   );

    // arp模块例化
    arp #(
        .DES_IP             (DES_IP),
        .DES_MAC            (DES_MAC),
        .BOARD_IP           (BOARD_IP),
        .BOARD_MAC          (BOARD_MAC)
    )u_arp(
        .rst                (sys_rst),          
        .gmii_rx_clk        (gmii_tx_clk),
        .gmii_rx_dv         (gmii_rx_dv), 
        .gmii_rxd           (gmii_rxd),   
        .gmii_tx_clk        (gmii_tx_clk),
        .gmii_tx_en         (arp_gmii_tx_en), 
        .gmii_txd           (arp_gmii_txd),   
        .gmii_tx_done       (arp_tx_done),              

        .arp_tx_en          (arp_tx_en),  
        .arp_tx_type        (arp_tx_type),
        .arp_rx_done        (arp_rx_done),
        .arp_rx_type        (arp_rx_type),
        .des_mac            (des_mac),    
        .des_ip             (des_ip),     
        .src_mac            (src_mac),    
        .src_ip             (src_ip),
        
        .arp_led            (arp_led),
        .arp_get            (arp_get),
        .cur_state          (cur_state)  
    );

    // ICMP模块例化
    icmp #(
        .BOARD_IP(BOARD_IP),
        .BOARD_MAC(BOARD_MAC),
        .DES_IP(DES_IP),
        .DES_MAC(DES_MAC)
    )u_icmp(
        .rst                (sys_rst        ),
        .gmii_rx_clk        (gmii_tx_clk    ),
        .gmii_rx_dv         (gmii_rx_dv     ),
        .gmii_rxd           (gmii_rxd       ),
        .gmii_tx_clk        (gmii_tx_clk    ),
        .gmii_tx_en         (icmp_gmii_tx_en),
        .gmii_txd           (icmp_gmii_txd  ),
        .rec_pkt_done       (icmp_rec_pkt_done),
        .rec_en             (icmp_rec_en    ),
        .rec_data           (icmp_rec_data  ),
        .rec_byte_num       (icmp_rec_byte_num),
        .tx_start_en        (icmp_tx_start_en),
        .tx_data            (icmp_tx_data   ),
        .tx_byte_num        (icmp_tx_byte_num),
        .des_mac            (des_mac        ),
        .des_ip             (des_ip         ),
        .tx_done            (icmp_tx_done   ),
        .tx_req             (icmp_tx_req    )
    );



    eth_ctrl_sw u_eth_ctrl_sw(
        .clk                (gmii_tx_clk),
        .rst                (sys_rst),

        // ARP端口信号
        .arp_rx_done        (arp_rx_done),                   // ARP数据包接收完成信号
        .arp_rx_type        (arp_rx_type),                   // ARP接收类型，0：请求；1：应答
        .arp_tx_en          (arp_tx_en),                     // ARP发送模块使能信号（开始组包）
        .arp_tx_type        (arp_tx_type),                   // ARP发送类型，0：请求；1：应答
        .arp_tx_done        (arp_tx_done),                   // ARP单包发送完成
        .arp_gmii_tx_en     (arp_gmii_tx_en),                // ARP使能gmii_txd发送数据
        .arp_gmii_txd       (arp_gmii_txd),                  // ARP通过gmii_txd发送的数据

        // ICMP端口信号
        .icmp_tx_start_en   (icmp_tx_start_en),              // ICMP发送模块使能信号（开始组包）
        .icmp_tx_done       (icmp_tx_done),                  // ICMP单包发送完成
        .icmp_gmii_tx_en    (icmp_gmii_tx_en),               // ICMP使能gmii_txd发送数据
        .icmp_gmii_txd      (icmp_gmii_txd),                 // ICMP通过gmii_txd发送的数据

        // ICMP fifo接口信号
        .icmp_rec_en        (icmp_rec_en),                   // ICMP接收数据使能信号
        .icmp_rec_data      (icmp_rec_data),
        .icmp_tx_req        (icmp_tx_req),                   // ICMP读数据请求信号
        .icmp_tx_data       (icmp_tx_data),                  // ICMP待发送数据

        // UDP相关端口信号
        .udp_tx_start_en    (udp_tx_start_en),               // UDP发送模块使能信号（开始组包）
        .udp_tx_done        (udp_tx_done),                   // UDP发送完成信号
        .udp_gmii_tx_en     (udp_gmii_tx_en),                // UDP使能gmii_txd发送数据
        .udp_gmii_txd       (udp_gmii_txd),                  // UDP通过gmii_txd发送的数据

        // UDP fifo接口信号
        .udp_rec_en         (udp_rec_en),                   // UDP接收数据使能信号
        .udp_rec_data       (udp_rec_data),
        .udp_tx_req         (udp_tx_req),                   // UDP读数据请求信号
        .udp_tx_data        (udp_tx_data),                  // UDP待发送数据

        // fifo接口信号
        .tx_data            (tx_data),                      // 待发送数据
        .tx_req             (tx_req),
        .rec_en             (rec_en),
        .rec_data           (rec_data),

        // GMII发送引脚
        .gmii_tx_en         (gmii_tx_en),
        .gmii_txd           (gmii_txd)
    );

    udp #(
        .BOARD_IP(BOARD_IP),
        .BOARD_MAC(BOARD_MAC),
        .DES_IP(DES_IP),
        .DES_MAC(DES_MAC)
    )u_udp(
        .rst                    (sys_rst),
        // GMII接口
        .gmii_rx_clk            (gmii_tx_clk),
        .gmii_rx_dv             (gmii_rx_dv),
        .gmii_rxd               (gmii_rxd),
        .gmii_tx_clk            (gmii_tx_clk),
        .gmii_tx_en             (udp_gmii_tx_en),
        .gmii_txd               (udp_gmii_txd),

        // 用户接口
        .rec_pkt_done           (udp_rec_pkt_done),               // 接收数据包完成标志
        .rec_en                 (udp_rec_en),                     // 接收数据使能
        .rec_data               (udp_rec_data),                   // udp接收数据
        .rec_byte_num           (udp_rec_byte_num),               // 接收有效字节数
        .tx_start_en            (udp_tx_start_en),                // 开始发送触发信号
        .tx_data                (udp_tx_data),                    // udp发送数据        
        .tx_byte_num            (udp_tx_byte_num),                // 发送有效字节数
        .des_mac                (des_mac),
        .des_ip                 (des_ip),
        .tx_done                (udp_tx_done),                    // 发送完成信号
        .tx_req                 (udp_tx_req)                      // 读取发送数据请求信号

    );

    // sgmii gmii接口转换例化
    sgmii_to_gmii u_sgmii_gmii(
        .sys_rst                    (sys_rst    ),             
        .sgmii_clk_n                (sgmii_clk_n),   
        .sgmii_clk_p                (sgmii_clk_p),   
        .independent_clock_bufg     (sys_clk    ),
        .sgmii_rx_n                 (sgmii_rxn  ),    
        .sgmii_rx_p                 (sgmii_rxp  ),    
        .gmii_tx_en                 (gmii_tx_en ),    
        .gmii_tx_er                 (),    
        .gmii_txd                   (gmii_txd   ),                            
        .gmii_rx_clk                (gmii_rx_clk),   
        .gmii_rx_dv                 (gmii_rx_dv ),    
        .gmii_rx_er                 (),    
        .gmii_rxd                   (gmii_rxd   ),      
        .gmii_tx_clk                (gmii_tx_clk),   
        .sgmii_tx_n                 (sgmii_txn  ),    
        .sgmii_tx_p                 (sgmii_txp  ),                          
        .resetdone                  (resetdone  ),     
        .mmcm_locked_out            (mmcm_locked_out),
        .sgmii_clk_en               (sgmii_clk_en),
        .status_vector              (status_vector)

    );

    // mdio管理接口例化
    mdio_wr_test u_mdio_wr_test(
        .sys_clk(sys_clk),
        .sys_rst(sys_rst),
        //.eth_rst_n(eth_rst_n),
        .eth_mdc(eth_mdc),
        .eth_mdio(eth_mdio),
        .touch_key(touch_key),
        .led(led),
        .id_led(id_led),
        .test_led(test_led)
    );



endmodule
