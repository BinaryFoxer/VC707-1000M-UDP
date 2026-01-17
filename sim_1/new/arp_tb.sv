`timescale 1ns / 1ps
`define CLK_PERIOD 8

module arp_tb;

reg rst_n;
reg gmii_clk;

arp_send arp_test(
    .rst_n(rst_n),
    .gmii_clk(gmii_clk)
);

initial gmii_clk = 0;
always #(`CLK_PERIOD / 2) gmii_clk = ~gmii_clk;

initial begin
    rst_n = 0;
    #10
    rst_n = 1;
    #5000
    $stop;

end

endmodule
