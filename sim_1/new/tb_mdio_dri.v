`timescale  1ns/1ns                     

module  tb_mdio_dri;

//parameter  define
parameter  PHY_ADDR = 5'b00111;            //PHY地址

//reg define
reg          sys_clk;                   
reg          sys_rst_n;
reg          touch_key;                
     
//wire define
wire         eth_rst_n ;
wire         eth_mdc   ;
wire         eth_mdio  ;
wire   [1:0] led       ;

//*****************************************************
//**                    main code
//*****************************************************

initial begin
    sys_clk            = 1'b1;
    sys_rst_n          <= 1'b0;    
    touch_key          <= 1'b0;
    #200
    sys_rst_n          <= 1'b1;
    #1202
    touch_key          <= 1'b1;
    #400
    touch_key          <= 1'b0;    
end

//产生时钟，这里以50Mhz为例
always #10 sys_clk = ~sys_clk;

pullup(eth_mdio);      //MDIO输出高阻态

// 设置PHY寄存器初始值
reg         we_i;
reg         strobe_i;
reg  [7:0]  address_i;
reg  [7:0]  data_i;

initial begin
    we_i           = 1'b0;
    strobe_i       = 1'b0;     
    address_i      = 8'd0;
    data_i         = 8'd0;
    #300        
    we_i           = 1'b1;         
    strobe_i       = 1'b1; 
    address_i      = 8'h02;       // R1的高8位
    data_i         = 8'h80;
    #20             
    address_i      = 8'h03;
    data_i         = 8'h26;
    #20             
    address_i      = 8'h22;       // R17的高8位
    data_i         = 8'h80;
    #20             
    address_i      = 8'h23;
    data_i         = 8'h00;
    #20             
    address_i      = 8'h36;       // R27的高8位
    data_i         = 8'hFF;
    #20             
    address_i      = 8'h37;
    data_i         = 8'hFF;

    #20             
    address_i      = 8'h40;        // 配置PHY地址
    data_i         = PHY_ADDR;            
    #20
    we_i           = 1'b0;         // 结束配置
    strobe_i       = 1'b0;    
    address_i      = 8'd0;
    data_i         = 8'd0;    
end

mdio_wr_test #(
    .READ_PERIOD(160)
    )mdio_wr_test_inst(
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),

    .eth_rst_n(eth_rst_n),
    .eth_mdc(eth_mdc),
    .eth_mdio(eth_mdio),

    .touch_key(touch_key),
    .led(led)
    );

mdio_slave_interface u_mdio_slave_interface(
		.rst_n_i    (sys_rst_n),
		.mdc_i      (eth_mdc),
		.mdio       (eth_mdio),

		//wishbone interface 
		.clk_i      (sys_clk),
		.rst_i      (~sys_rst_n),
		.address_i  (address_i),
  		.data_i     (data_i),
  		.data_o     (),
  		.strobe_i   (strobe_i),
  		.we_i		(we_i),
  		.ack_o      ()
    );

endmodule
