`timescale 1ns / 1ps

// ----------------------------------------------------------------
// ICMP顶层模块代码
// 可切换ARP与ICMP协议
// ----------------------------------------------------------------

module eth_icmp_test(
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
    input               touch_key,           // mdio配置按键

    // --------SGMII接口-------
    input               sgmii_clk_n,             // 125m参考时钟
    input               sgmii_clk_p,
    input               sgmii_rxn,                      
    input               sgmii_rxp,
    output              sgmii_txn,
    output              sgmii_txp,              
    output              eth_rst_n,               // 以太网模块复位

    input               send_key,                // 发送arp请求按键
    output              arp_led                  // arp测试led
    );

    // 板卡mac和ip
    parameter  BOARD_MAC = 48'h00_11_22_33_44_55;        // 板卡MAC地址
    parameter  BOARD_IP  = {8'd192,8'd168,8'd0,8'd2}; 
    // 目标mac和ip
    parameter  DES_MAC   = 48'hff_ff_ff_ff_ff_ff;
    parameter  DES_IP  = {8'd192,8'd168,8'd0,8'd3}; 

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
    wire                arp_tx_en;
    wire        [7:0]   arp_gmii_txd;
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
    wire                gmii_tx_clk_bufg;
    wire                gmii_rx_clk_bufg;
    wire                sgmii_clk_en;
    wire        [15:0]  status_vector;
    wire                arp_get;
    wire        [4:0]   cur_state;        

    wire                icmp_gmii_tx_en;
    wire        [7:0]   icmp_gmii_txd;
    wire                rec_pkt_done;
    wire                rec_en;
    wire        [7:0]   rec_data;
    wire        [15:0]  rec_byte_num;
    wire        [15:0]  tx_byte_num;
    wire                icmp_tx_done;
    wire                tx_req;
    wire        [7:0]   tx_data;
    wire                icmp_tx_start_en;

    assign icmp_tx_start_en = rec_pkt_done;
    assign tx_byte_num = rec_byte_num;
    assign des_mac = src_mac;
    assign des_ip = src_ip;

    assign eth_rst_n = ~sys_rst;
    assign download_sus = arp_get;
    
    // ila调试
//    ila_0 icmp_ila_test(
//        .clk(gmii_tx_clk), // input wire clk

//        .probe0(icmp_tx_start_en), // input wire [0:0]  probe0  
//        .probe1(rec_pkt_done), // input wire [0:0]  probe1 
//        .probe2(rec_en), // input wire [0:0]  probe2 
//        .probe3(gmii_rxd), // input wire [7:0]  probe3 
//        .probe4(gmii_rx_dv), // input wire [0:0]  probe4 
//        .probe5(arp_rx_done), // input wire [0:0]  probe5 
//        .probe6(rec_byte_num), // input wire [15:0]  probe6
//        .probe7(cur_state)
//    );
    
    ila_1 icmp_ila_test (
        .clk(gmii_tx_clk), // input wire clk
    
        .probe0(icmp_tx_start_en), // input wire [0:0]  probe0  
        .probe1(arp_tx_en), // input wire [0:0]  probe1 
        .probe2(rec_en), // input wire [0:0]  probe2 
        .probe3(gmii_rx_dv), // input wire [0:0]  probe3 
        .probe4(gmii_rxd), // input wire [7:0]  probe4 
        .probe5(gmii_txd), // input wire [7:0]  probe5 
        .probe6(icmp_gmii_txd), // input wire [7:0]  probe6 
        .probe7(rec_byte_num), // input wire [15:0]  probe7 
        .probe8(icmp_tx_done), // input wire [0:0]  probe8 
        .probe9(arp_rx_done), // input wire [0:0]  probe9 
        .probe10(rec_data), // input wire [7:0]  probe10 
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
        .rec_pkt_done       (rec_pkt_done   ),
        .rec_en             (rec_en         ),
        .rec_data           (rec_data       ),
        .rec_byte_num       (rec_byte_num   ),
        .tx_start_en        (icmp_tx_start_en),
        .tx_data            (tx_data        ),
        .tx_byte_num        (tx_byte_num    ),
        .des_mac            (des_mac        ),
        .des_ip             (des_ip         ),
        .tx_done            (icmp_tx_done   ),
        .tx_req             (tx_req         )
    );
    
    
    // 同步FIFO例化
    fifo_generator_0 icmp_data_fifo (
      .clk(gmii_tx_clk),      // input wire clk
      .srst(sys_rst),    // input wire srst
      .din(rec_data),      // input wire [7 : 0] din
      .wr_en(rec_en),  // input wire wr_en
      .rd_en(tx_req),  // input wire rd_en
      .dout(tx_data),    // output wire [7 : 0] dout
      .full(),    // output wire full
      .empty()  // output wire empty
    );

    // // arp控制模块例化
    // arp_ctrl u_arp_ctrl(
    //     .clk                (gmii_tx_clk),        
    //     .sys_rst            (sys_rst),    
    //     .touch_key          (send_key),  
    //     .arp_rx_done        (arp_rx_done),
    //     .arp_rx_type        (arp_rx_type),
    //     .arp_tx_en          (arp_tx_en),  
    //     .arp_tx_type        (arp_tx_type) 
    // );

    // 协议控制模块例化
    eth_ctrl u_eth_ctrl(
        .clk                (gmii_tx_clk     ) ,  
        .rst                (sys_rst         ) ,                  
        .arp_rx_done        (arp_rx_done     ) ,
        .arp_rx_type        (arp_rx_type     ) ,
        .arp_tx_en          (arp_tx_en       ) ,
        .arp_tx_type        (arp_tx_type     ) ,
        .arp_tx_done        (arp_tx_done     ) ,
        .arp_gmii_tx_en     (arp_gmii_tx_en  ) ,
        .arp_gmii_txd       (arp_gmii_txd    ) ,                   
        .icmp_tx_start_en   (icmp_tx_start_en) ,
        .icmp_tx_done       (icmp_tx_done    ) ,
        .icmp_gmii_tx_en    (icmp_gmii_tx_en ) ,
        .icmp_gmii_txd      (icmp_gmii_txd   ) ,                    
        .gmii_tx_en         (gmii_tx_en      ) ,
        .gmii_txd           (gmii_txd        )  
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
        .eth_rst_n(eth_rst_n),
        .eth_mdc(eth_mdc),
        .eth_mdio(eth_mdio),
        .touch_key(touch_key),
        .led(led),
        .id_led(id_led),
        .test_led(test_led)
    );

endmodule
