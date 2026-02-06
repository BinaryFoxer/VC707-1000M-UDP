`timescale 1ns / 1ps

module tb_icmp;

parameter   T = 8;
parameter   OP_CYCLE = 100;

parameter   BOARD_MAC  = 48'h00_11_22_33_44_55;
parameter   BOARD_IP   = {8'd192, 8'd168, 8'd0, 8'd2};
parameter   DES_MAC    = 48'hff_ff_ff_ff_ff_ff;
parameter   DES_IP     = {8'd192, 8'd168, 8'd0, 8'd2}; 

defparam    u_icmp.u_icmp_tx.ECHO_REPLY = 8'h08;

// reg define
reg         gmii_clk;
reg         sys_rst;
reg         tx_start_en;
reg [31:0]  tx_data;
reg [15:0]  tx_byte_num;
reg [47:0]  des_mac;
reg [31:0]  des_ip;
reg [3:0]   flow_cnt;
reg [13:0]  delay_cnt;

// wire define
wire        gmii_rx_clk;
wire        gmii_rx_dv;
wire [7:0]  gmii_rxd;
wire        gmii_tx_clk;
wire        gmii_tx_en;
wire [7:0]  gmii_txd;
wire        tx_done;
wire        tx_req;

assign  gmii_rx_clk = gmii_clk;
assign  gmii_tx_clk = gmii_clk;
assign  gmii_rx_dv  = gmii_tx_en;
assign  gmii_rxd    = gmii_txd;

// 初始化输入信号
initial begin
    gmii_clk        = 1'b0;
    sys_rst         = 1'b1;
    #(T+1) sys_rst  = 1'b0;
end

always #(T/2) gmii_clk = ~gmii_clk;

always @(posedge gmii_clk or posedge sys_rst) begin
    if(sys_rst) begin
        tx_start_en    <= 1'd0;
        tx_data        <= 32'd0;
        tx_byte_num    <= 16'd0;
        des_mac        <= 48'd0;
        des_ip         <= 32'd0;
        flow_cnt       <= 4'd0;
        delay_cnt      <= 14'd0;
    end
    else begin
        case(flow_cnt)
            4'd0: flow_cnt <= flow_cnt + 4'd1;

            4'd1: begin
                tx_start_en <= 1'b1;
                tx_byte_num <= 16'd20;              // ICMP要发送的报文字节数
                flow_cnt    <= flow_cnt + 4'd1;
            end

            4'd2: begin
                tx_start_en <= 1'b0;
                flow_cnt    <= flow_cnt + 4'd1; 
            end

            4'd3: begin
                if(tx_req)
                    tx_data <= tx_data + 1;
                if(tx_done) begin
                    flow_cnt <= flow_cnt + 4'd1; 
                    tx_data <= 32'd0;
                end
            end

            4'd4: begin
                delay_cnt <= delay_cnt + 1'b1;
                if(delay_cnt == OP_CYCLE - 1)
                    flow_cnt <= flow_cnt + 4'd1;
            end

            4'd5: begin
                tx_start_en <= 1'b1;
                tx_byte_num <= 16'd28;
                flow_cnt <= flow_cnt + 4'd1;
            end

            4'd6: begin
                tx_start_en <= 1'b0;
                flow_cnt <= flow_cnt + 4'd1;
            end

            4'd7: begin
                if(tx_req)
                    tx_data <= tx_data + 1;
                if(tx_done) begin
                    flow_cnt <= flow_cnt + 4'd1;
                    tx_data <= 32'd0;
                end
            end
        endcase
    end
end


icmp #(
    .DES_IP(DES_IP),
    .DES_MAC(DES_MAC),
    .BOARD_IP(BOARD_IP),
    .BOARD_MAC(BOARD_MAC)
)u_icmp(
    .rst                    (sys_rst),     
    .gmii_rx_clk            (gmii_clk),
    .gmii_rx_dv             (gmii_rx_dv),
    .gmii_rxd               (gmii_rxd),
    .gmii_tx_clk            (gmii_clk),
    .gmii_tx_en             (gmii_tx_en),
    .gmii_txd               (gmii_txd),
    .rec_pkt_done           (),
    .rec_en                 (),
    .rec_data               (),
    .rec_byte_num           (),
    .tx_start_en            (tx_start_en),
    .tx_data                (tx_data),
    .tx_byte_num            (tx_byte_num),
    .des_mac                (des_mac),
    .des_ip                 (des_ip),
    .tx_done                (tx_done),
    .tx_req                 (tx_req)

);



endmodule
