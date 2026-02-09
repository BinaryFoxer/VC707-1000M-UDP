`timescale 1ns / 1ps

// -------------------------------------------------------------------------
// udp接收模块
// 接收发送方报文以及数据（目前是回环测试）
// -------------------------------------------------------------------------

module udp_rx(
    input                    clk,
    input                    rst,

    input                    gmii_rx_dv,
    input           [7:0]    gmii_rxd,

    output   reg    [15:0]   rec_byte_num,          // 接收到udp数据段字节总长度
    output   reg    [7:0]    rec_data,              // 接收到udp数据段字节数据
    output   reg             rec_en,                // fifo存入接收数据使能
    output   reg             rec_pkt_done           // 接收完成一个数据包
    );

    // parameter define
    parameter   BOARD_MAC = 48'h00_11_22_33_44_55;              // 板卡MAC
    parameter   BOARD_IP  = {8'd192, 8'd168, 8'd0, 8'd2};       // 板卡IP

    localparam  ETH_TYPE = 16'h08_00;                // 以太网类型
    localparam  UDP_TYPE = 8'd17;                   // UDP类型

    localparam  st_idle         = 7'b000_0001;
    localparam  st_preamble     = 7'b000_0010;
    localparam  st_eth_header   = 7'b000_0100;
    localparam  st_ip_header    = 7'b000_1000;
    localparam  st_udp_header   = 7'b001_0000;
    localparam  st_rx_data      = 7'b010_0000;
    localparam  st_rx_end       = 7'b100_0000;

    // reg define
    reg [6:0]   cur_state;
    reg [6:0]   next_state;
    reg         skip_en;
    reg         error_en;
    reg [4:0]   cnt;
    reg [31:0]  des_ip;
    reg [47:0]  des_mac;
    reg [15:0]  eth_type;
    reg [5:0]   ip_head_byte_num;                   // IP首部字节长度（单位：4字节）
    reg [15:0]  udp_byte_num;                       // UDP报文总长度，无需通过IP总长度计算数据段长度
    reg [15:0]  data_byte_num;                      // 数据段字节长度
    reg [15:0]  data_cnt;                           // 数据段字节计数


    // ------------------------------    UDP报文解析状态机   ---------------------------------
    always @(posedge clk or posedge rst) begin
        if(rst)
            cur_state <= st_idle;
        else
            cur_state <= next_state;
    end

    always @(*) begin
        next_state = st_idle;
        case(cur_state)
            st_idle:begin
                if(skip_en)
                    next_state = st_preamble;
                else
                    next_state = st_idle;
            end

            st_preamble:begin
                if(skip_en)
                    next_state = st_eth_header;
                else if(error_en)
                    next_state = st_rx_end;
                else
                    next_state = st_preamble;
            end

            st_eth_header:begin
                if(skip_en)
                    next_state = st_ip_header;
                else if(error_en)
                    next_state = st_rx_end;
                else
                    next_state = st_eth_header;
            end

            st_ip_header:begin
                if(skip_en)
                    next_state = st_udp_header;
                else if(error_en)
                    next_state = st_rx_end;
                else
                    next_state = st_ip_header;
            end

            st_udp_header:begin
                if(skip_en)
                    next_state = st_rx_data;
                else if(error_en)
                    next_state = st_rx_end;
                else
                    next_state = st_udp_header;
            end

            st_rx_data:begin
                if(skip_en)
                    next_state = st_rx_end;
                else
                    next_state = st_rx_data;
            end

            st_rx_end:begin
                if(skip_en)
                    next_state = st_idle;
                else
                    next_state = st_rx_end;
            end

            default:next_state = st_idle;
        endcase

    end

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            rec_byte_num           <=  16'd0;
            rec_data               <=  8'd0;
            rec_en                 <=  1'd0;
            rec_pkt_done           <=  1'd0;
            skip_en                <=  1'd0;
            error_en               <=  1'd0;
            cnt                    <=  5'd0;
            des_ip                 <=  32'd0;
            des_mac                <=  48'd0;
            eth_type               <=  16'd0;
            ip_head_byte_num       <=  6'd0;
            udp_byte_num           <=  16'd0;
            data_byte_num          <=  16'd0;
            data_cnt               <=  16'd0;
        end
        else begin
            skip_en         <= 1'b0;
            error_en        <= 1'b0;
            rec_en          <= 1'b0;
            rec_pkt_done    <= 1'b0;
            case(next_state)
                st_idle:begin
                    if((gmii_rx_dv == 1'b1) && (gmii_rxd == 8'h55))
                        skip_en <= 1'b1;
                    else;
                end

                st_preamble:begin
                    if(gmii_rx_dv) begin
                        cnt <= cnt + 5'd1;
                        if((cnt < 5'd6) && (gmii_rxd != 8'h55))
                            error_en <= 1'b1;
                        else if(cnt == 5'd6) begin
                            cnt <= 5'd0;
                            if(gmii_rxd == 8'hd5)
                                skip_en <= 1'b1;
                            else
                                error_en <= 1'b1;
                        end
                        else;
                    end
                    else;
                end

                st_eth_header:begin
                    if(gmii_rx_dv) begin
                        cnt <= cnt + 5'd1;
                        if(cnt < 5'd6) 
                            des_mac <= {des_mac[39:0], gmii_rxd};
                        else if(cnt == 5'd12)
                            eth_type[15:8] <= gmii_rxd;
                        else if(cnt == 5'd13) begin
                            eth_type[7:0]  <= gmii_rxd;
                            cnt <= 5'd0;
                            if((des_mac == BOARD_MAC) || (des_mac == 48'hff_ff_ff_ff_ff_ff) 
                                && eth_type[15:8] == ETH_TYPE[15:8] && gmii_rxd == ETH_TYPE[7:0])
                                skip_en <= 1'b1;
                            else
                                error_en <= 1'b1;
                        end
                        else;
                    end
                    else;
                end

                st_ip_header:begin
                    if(gmii_rx_dv) begin
                        cnt <= cnt + 5'd1;
                        if(cnt == 5'd0)
                            ip_head_byte_num <= {gmii_rxd[3:0], 2'd0};          // 寄存IP首部长度
                        else if(cnt == 5'd9) begin
                            if(gmii_rxd != UDP_TYPE) begin
                                error_en <= 1'b1;
                                cnt      <= 5'd0;
                            end
                            else;
                        end
                        else if((cnt >= 5'd16) && (cnt <= 5'd18))
                            des_ip <= {des_ip[23:0],gmii_rxd};                  //寄存目的IP地址
                        else if(cnt == 5'd19) begin
                            if(des_ip[23:0] == BOARD_IP[31:8] && gmii_rxd == BOARD_IP[7:0]) begin
                                skip_en <= 1'b1;
                                cnt <= 5'd0;
                            end
                            else begin
                                error_en <= 1'd1;
                                cnt <= 5'd0;
                            end
                        end
                        else;
                    end
                    else;
                end

                st_udp_header:begin
                    if(gmii_rx_dv) begin
                        cnt <= cnt + 5'd1;
                        if(cnt == 5'd4)
                            udp_byte_num[15:8] <= gmii_rxd;
                        else if(cnt == 5'd5)
                            udp_byte_num[7:0]  <= gmii_rxd;
                        else if(cnt == 5'd7) begin
                            // 计算有效字节长度
                            data_byte_num <= udp_byte_num - 16'd8;
                            skip_en <= 1'b1;
                            cnt <= 5'd0;
                        end
                        else;
                    end
                    else;
                end

                st_rx_data:begin
                    if(gmii_rx_dv) begin
                        data_cnt <= data_cnt + 16'd1;
                        rec_data <= gmii_rxd;
                        rec_en   <= 1'b1;

                        if(data_cnt == data_byte_num - 16'd1) begin             // 数据段接收完成
                            skip_en      <= 1'b1;
                            data_cnt     <= 16'd0;
                            rec_pkt_done <= 1'b1;
                            rec_byte_num <= data_byte_num;                      // 接收到数据段字节个数
                        end

                    end
                    else;
                end

                st_rx_end:begin
                    if(gmii_rx_dv == 1'b0 && skip_en == 1'b0)
                        skip_en <= 1'b1;
                end

                default: ;
            endcase
        end
    end


endmodule
