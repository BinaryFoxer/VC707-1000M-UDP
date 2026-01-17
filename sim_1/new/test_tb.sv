`timescale 1ns / 1ps
`define CLK_PERIOD_R 8
`define CLK_PERIOD_S 5

module test_tb;

reg sys_clk_p;     // 200MHz系统时钟
reg sys_clk_n;
reg sys_clk;

// 125MHz GTX参考时钟 
reg gtrefclk_p;          // 连接到AH8
reg gtrefclk_n;          // 连接到AH7
reg gtrefclk;

reg sys_rst_n;  

// sgmii接口
wire txp;
wire txn;
wire rxp;
wire rxn;

// 状态指示
wire led_link;

test_top top(
    .sys_clk_p(sys_clk_p),     // 200MHz系统时钟
    .sys_clk_n(sys_clk_n),
    
    
    .gtrefclk_p(gtrefclk_p),          // 连接到AH8
    .gtrefclk_n(gtrefclk_n),          // 连接到AH7
    
    .sys_rst_n(sys_rst_n),  
    

    .txp(txp),
    .txn(txn),
    .rxp(rxp),
    .rxn(rxn),
    
    .led_link(led_link)
);

initial sys_clk = 0;
always #2.5 sys_clk = ~sys_clk;
assign sys_clk_p = sys_clk;
assign sys_clk_n = ~sys_clk;

initial gtrefclk = 0;
always #(`CLK_PERIOD_R / 2) gtrefclk = ~gtrefclk;
assign gtrefclk_p = gtrefclk;
assign gtrefclk_n = ~gtrefclk;

initial begin
    sys_rst_n = 0;
    #50
    sys_rst_n = 1;
    #1000000
    $stop;

end

endmodule
