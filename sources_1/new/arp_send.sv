`timescale 1ns / 1ps

module arp_send(
    input rst_n,
    input gmii_clk,
    
    // gmii接口
    output reg gmii_tx_err,
    output reg gmii_tx_en,
    output reg [7:0] gmii_tx_data

    );
    
    // ============参数化设计=================
    reg [24:0] cnt;

    
    // ===========mac_send实例化================
        // 控制信号
    wire tx_go;
    // mac数据载荷
    reg fifo_rdreq;
    reg [7:0] fifo_rddata;
    reg fifo_rdclk;
    
    mac_send ether_send(
    .tx_go(tx_go),
    .rst_n(rst_n),
    .pyd_length(11'd46),   //payload部分数据长度
        
    .src_mac(48'h00_0a_35_01_fe_c0),
    .des_mac(48'hFF_FF_FF_FF_FF_FF),
    .type_length(16'h08_06),
    
    .fifo_rdreq(fifo_rdreq),
    .fifo_rddata(fifo_rddata),
    .fifo_rdclk(fifo_rdclk),
        
    .crc_result(32'h69_1D_7D_96),
        
    .gmii_clk(gmii_clk),
    .gmii_tx_en(gmii_tx_en),
    .gmii_tx_err(gmii_tx_err),
    .gmii_tx_data(gmii_tx_data)
    );
            
    // ===========fifo数据读取==============
    reg [11:0] data_cnt;
    always@(posedge gmii_clk or negedge rst_n) begin
        if(!rst_n)
            data_cnt <= 12'd0;
        else if(fifo_rdreq)
            data_cnt <= data_cnt + 12'd1;
        else 
            data_cnt <= 12'd0;
    end
    
    // 读取arp存储数据字段，这里用查找表进行测试
    always@(*) begin
        case(data_cnt) 
            // 以太网协议
            0:fifo_rddata <= 8'h00;
            1:fifo_rddata <= 8'h01;
            
            // IP协议
            2:fifo_rddata <= 8'h08;
            3:fifo_rddata <= 8'h00;
            
            // MAC地址长度
            4:fifo_rddata <= 8'h06;
            
            // IP地址长度
            5:fifo_rddata <= 8'h04;
            
            // 操作码
            6:fifo_rddata <= 8'h00;
            7:fifo_rddata <= 8'h01;
            
            // 源MAC地址
            8:fifo_rddata <= 8'h00;
            9:fifo_rddata <= 8'h0a;
            10:fifo_rddata <= 8'h35;
            11:fifo_rddata <= 8'h01;
            12:fifo_rddata <= 8'hfe;
            13:fifo_rddata <= 8'hc0;
            // 源IP地址
            14:fifo_rddata <= 8'hC0;
            15:fifo_rddata <= 8'hA8;
            16:fifo_rddata <= 8'h00;
            17:fifo_rddata <= 8'h02;
            // 目标MAC地址
            18:fifo_rddata <= 8'h00;
            19:fifo_rddata <= 8'h00;
            20:fifo_rddata <= 8'h00;
            21:fifo_rddata <= 8'h00;
            22:fifo_rddata <= 8'h00;
            23:fifo_rddata <= 8'h00;
            // 目标IP地址
            24:fifo_rddata <= 8'hC0;
            25:fifo_rddata <= 8'hA8;
            26:fifo_rddata <= 8'h00;
            27:fifo_rddata <= 8'h03;
            // 填充字节
            28:fifo_rddata <= 8'h00;
            29:fifo_rddata <= 8'h00;
            30:fifo_rddata <= 8'hff;
            31:fifo_rddata <= 8'hff;
            32:fifo_rddata <= 8'hff;
            33:fifo_rddata <= 8'hff;
            34:fifo_rddata <= 8'hff;
            35:fifo_rddata <= 8'hff;
            36:fifo_rddata <= 8'h00;
            37:fifo_rddata <= 8'h23;
            38:fifo_rddata <= 8'hcd;
            39:fifo_rddata <= 8'h76;
            40:fifo_rddata <= 8'h63;
            41:fifo_rddata <= 8'h1a;
            42:fifo_rddata <= 8'h08;
            43:fifo_rddata <= 8'h06;
            44:fifo_rddata <= 8'h00;
            45:fifo_rddata <= 8'h01;
            default: fifo_rddata <= 8'h0;

        endcase
    
    end
         
    // ==========数据帧发送间隔================
    always@(posedge gmii_clk or negedge rst_n) begin
        if(!rst_n)
            cnt <= 25'd0;
        else
            cnt <= cnt + 25'd1;
    end
    
    assign tx_go = (cnt==1);
    
endmodule








