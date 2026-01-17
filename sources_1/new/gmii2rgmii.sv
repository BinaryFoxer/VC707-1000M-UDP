`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/12 17:16:14
// Design Name: 
// Module Name: gmii2rgmii
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module gmii2rgmii(
    input rst_n, 
    input gmii_clk,
    input gmii_tx_en,
    input gmii_tx_err,
    input [7:0] gmii_tx_data,
    
    output rgmii_clk,
    output rgmii_tx_ctl,
    output [3:0] rgmii_tx_data
    
    );
    wire rgmii_err_xor;
    
    genvar i;
    
    // tx_data
    generate
        for(i=0;i<4;i=i+1) begin:rgmii_data
               ODDR #(
              .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
              .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
              .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
           ) to_rgmii_data (
              .Q(rgmii_tx_data[i]),   // 1-bit DDR output
              .C(gmii_clk),   // 1-bit clock input
              .CE(1'd1), // 1-bit clock enable input
              .D1(gmii_tx_data[i]), // 1-bit data input (positive edge)
              .D2(gmii_tx_data[i+4]), // 1-bit data input (negative edge)
              .R(!rst_n),   // 1-bit reset
              .S(1'd0)    // 1-bit set
           );
        
        end 
    
    endgenerate
    
    assign rgmii_tx_ctl = gmii_tx_en ^ rgmii_err_xor;
    // tx_ctl
       ODDR #(
      .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
      .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) ODDR_ctl (
      .Q(rgmii_tx_ctl),   // 1-bit DDR output
      .C(gmii_clk),   // 1-bit clock input
      .CE(1'd1), // 1-bit clock enable input
      .D1(gmii_tx_en), // 1-bit data input (positive edge)
      .D2(rgmii_err_xor), // 1-bit data input (negative edge)
      .R(!rst_n),   // 1-bit reset
      .S(1'd0)    // 1-bit set
   );
   
   // Ê±ÖÓ
   ODDR #(
      .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
      .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) ODDR_clk (
      .Q(rgmii_clk),   // 1-bit DDR output
      .C(gmii_clk),   // 1-bit clock input
      .CE(1'd1), // 1-bit clock enable input
      .D1(1'b1), // 1-bit data input (positive edge)
      .D2(1'b0), // 1-bit data input (negative edge)
      .R(!rst_n),   // 1-bit reset
      .S(1'd0)    // 1-bit set
     );
    
endmodule
