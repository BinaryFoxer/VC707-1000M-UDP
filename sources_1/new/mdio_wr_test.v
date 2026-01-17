`timescale 1ns / 1ps

module mdio_wr_test(
    input               sys_clk_p,
    input               sys_clk_n,
    input               sys_rst,

    output              eth_rst_n,
    output              eth_mdc,
    inout               eth_mdio,

    input               touch_key,
    output      [1:0]   led,
    output              id_led,              // 读id正确指示led
    output              test_led,          // 读访问错误指示led
    output              download_sus         // 下载代码成功指示led

    );

    // parameter define
    parameter READ_PERIOD = 24'd100_000;  // 20ms读取一次寄存器 

    // reg define
    reg [21:0] eth_rst_cnt;               // PHY芯片复位计数器
    reg        eth_rst_n_r;                 // 释放复位

    // wire define
    wire            op_exec;
    wire            op_rh_wl;
    wire  [4:0]     op_addr;
    wire  [15:0]    op_wr_data;
    wire            op_done;
    wire  [15:0]    op_rd_data;
    wire            op_rd_ack;
    wire            dri_clk;
    wire            sys_clk;
    
    IBUFDS #(
      .DIFF_TERM("FALSE"),       // Differential Termination
      .IBUF_LOW_PWR("FALSE"),     // Low power="TRUE", Highest performance="FALSE" 
      .IOSTANDARD("LVDS")     // Specify the input I/O standard
   ) IBUFDS_inst (
      .O(sys_clk),  // Buffer output
      .I(sys_clk_p),  // Diff_p buffer input (connect directly to top-level port)
      .IB(sys_clk_n) // Diff_n buffer input (connect directly to top-level port)
   );

    // 以太网硬复位
    assign eth_rst_n = ~sys_rst;
    // always@(posedge sys_clk or posedge sys_rst) begin
    //     if(sys_rst) begin
    //         eth_rst_cnt <= 22'd0;
    //         eth_rst_n_r <= 1'b0;
    //     end
    //     else begin
    //         if(eth_rst_cnt == 22'd4000_000) begin           // PHY硬件复位20ms
    //             eth_rst_cnt <= 22'd0;
    //             eth_rst_n_r <= 1'b1;
    //         end
    //         else begin
    //             eth_rst_cnt <= eth_rst_cnt + 22'd1;
    //             eth_rst_n_r <= 1'b0;
    //         end
    //     end
    // end
    // assign eth_rst_n = eth_rst_n_r;
    assign download_sus = eth_mdc;

    // 例化以太网驱动模块
    mdio_dri #(
        .CLK_DIV(80),               // 200Mhz时钟源，分频至2.5MHz
        .PHY_ADDR(5'b00111)
    )u_mdio_dri(
        .clk(sys_clk),       
        .rst(sys_rst),     
                   
        .op_exec(op_exec),   
        .op_rh_wl(op_rh_wl),  
        .op_addr(op_addr),   
        .op_wr_data(op_wr_data),
        .op_done(op_done),   
        .op_rd_data(op_rd_data),
        .op_rd_ack(op_rd_ack), 
        .dri_clk(dri_clk),   
                   
                   
        .eth_mdc(eth_mdc),   
        .eth_mdio(eth_mdio)   
    );

    // 例化以太网控制模块
    mdio_ctrl u_mdio_ctrl(
        .clk(dri_clk),          
        .rst(sys_rst),        
                    
        .soft_rst_trig(touch_key),
        .op_done(op_done),      
        .op_rd_ack(op_rd_ack),    
        .op_rd_data(op_rd_data),   
                    
        .op_exec(op_exec),      
        .op_rh_wl(op_rh_wl),     
        .op_addr(op_addr),      
        .op_wr_data(op_wr_data),   
                    
        .led(led),
        .id_led(id_led),
        .test_led(test_led)           
    );

    // // 例化软复位进行测试
    // soft_rst_only #(
    //     .READ_PERIOD(READ_PERIOD)
    // )u_soft_rst_only(
    //     .clk(dri_clk),          
    //     .rst_n(sys_rst_n),        
                    
    //     .soft_rst_trig(touch_key),
    //     .op_done(op_done),      
    //     .op_rd_ack(op_rd_ack),    
    //     .op_rd_data(op_rd_data),   
                    
    //     .op_exec(op_exec),      
    //     .op_rh_wl(op_rh_wl),     
    //     .op_addr(op_addr),      
    //     .op_wr_data(op_wr_data),   
                    
    //     .led(led)           
    // );
endmodule
