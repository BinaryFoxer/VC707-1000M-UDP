`timescale 1ns / 1ps

// ------------------------------------------------------------------
// ARP测试模块,发送测试数据验证链路是否连通
// ------------------------------------------------------------------

module eth_arp_test(
    input               sgmii_clk_n,             // 125m参考时钟
    input               sgmii_clk_p,
    input               sys_rst,
    input               touch_key,               // mdio配置按键
    input               send_key,                // 发送arp请求按键

    input               sgmii_rxn,                      
    input               sgmii_rxp,
    output              sgmii_txn,
    output              sgmii_txp,              
    output              eth_rst_n,               // 以太网模块复位
    output              arp_led,                 // arp测试led

    // ------------------mdio接口-------------------
    input               sys_clk_p,               // 200mhz时钟源
    input               sys_clk_n,

    output              eth_mdc,
    inout               eth_mdio,

    output      [1:0]   led,
    output              id_led,              // 读id正确指示led
    output              test_led,            // 读访问错误指示led
    output              download_sus         // 下载代码成功指示led

    );

    // parameter define
    // 板卡mac和ip
    // parameter BOARD_MAC  = 48'h00_0a_35_01_fe_c0;        // 板卡MAC地址
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

    wire                arp_tx_en;
    wire                arp_tx_type;
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
    
    reg                 clk_v;
    // 添加时钟频率计数器
    reg [31:0] clk_counter;
    reg [31:0] clk_period_counter;
    reg clk_1hz;

    assign eth_rst_n = ~sys_rst;
    assign download_sus = arp_get;

    always @(posedge gmii_tx_clk or posedge sys_rst) begin
        if(sys_rst) begin
            clk_counter <= 32'd0;
            clk_period_counter <= 32'd0;
            clk_1hz <= 1'b0;
        end else begin
            clk_counter <= clk_counter + 32'd1;
            if(clk_counter >= 32'd124999999) begin  // 125MHz -> 1Hz
                clk_counter <= 32'd0;
                clk_1hz <= ~clk_1hz;
            end
        end
    end

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
   
   // -----------------------------------125mhz全局时钟-------------------------------------
//    BUFG确保时钟质量
   BUFG u_bufg_gmii_tx (
       .I(gmii_rx_clk),
       .O(gmii_rx_clk_bufg)
   );
    
    // BUFR #(
    //     .BUFR_DIVIDE("BYPASS"),
    //     .SIM_DEVICE("7SERIES")
    // ) u_bufr_ila (
    //     .I(gmii_rx_clk),
    //     .O(gmii_rx_clk_bufg),
    //     .CE(1'b1),
    //     .CLR(1'b0)
    // );
    
   
    // 例化ila模块
    ila_0 your_instance_name (
        .clk(gmii_tx_clk), // input wire clk
    
    
        .probe0(clk_counter), // input wire [0:0]  probe0  
        .probe1(arp_get), // input wire [0:0]  probe1 
        .probe2(arp_rx_type), // input wire [0:0]  probe2 
        .probe3(gmii_rxd), // input wire [7:0]  probe3 
        .probe4(gmii_rx_dv), // input wire [0:0]  probe4 
        .probe5(arp_rx_done), // input wire [0:0]  probe5 
        .probe6(status_vector), // input wire [15:0]  probe6
        .probe7(cur_state)
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
        .src_ip             (src_ip),
        .arp_led            (arp_led),
        .arp_get            (arp_get),
        .cur_state          (cur_state)  
    );

    // arp控制模块例化
    arp_ctrl u_arp_ctrl(
        .clk                (gmii_tx_clk),        
        .sys_rst            (sys_rst),    
        .touch_key          (send_key),  
        .arp_rx_done        (arp_rx_done),
        .arp_rx_type        (arp_rx_type),
        .arp_tx_en          (arp_tx_en),  
        .arp_tx_type        (arp_tx_type) 
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
