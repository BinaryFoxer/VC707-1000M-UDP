`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// mdio驱动模块
//////////////////////////////////////////////////////////////////////////////////

module mdio_dri(
    input               clk,
    input               rst,

    input               op_exec,
    input               op_rh_wl,       // 操作类型，1：读；0：写；
    input      [4:0]    op_addr,        // 操作的寄存器地址
    input      [15:0]   op_wr_data,
    output reg          op_done,
    output reg [15:0]   op_rd_data,
    output reg          op_rd_ack,      // 读操作响应；0：响应
    output reg          dri_clk,        // 驱动模块时钟
    
    // mdio接口
    output reg          eth_mdc,        // 给PHY芯片的mdc时钟
    inout               eth_mdio           
    );

    // parameter define
    parameter CLK_DIV = 80;             // eth_mdc的时钟分频系数(200MHz to 2.5MHz)，eth_mdc相对于clk 
    parameter PHY_ADDR = 5'b00111;      // PHY芯片地址，由板上硬件配置确定
    localparam st_idle  = 6'b00_0001;    // 空闲状态
    localparam st_pre   = 6'b00_0010;    // 发送前导码
    localparam st_start = 6'b00_0100;    // 发送start和op码
    localparam st_addr  = 6'b00_1000;    // 发送PHY地址和reg地址
    localparam st_write = 6'b01_0000;    // 发送TA和写数据
    localparam st_read  = 6'b10_0000;    // 发送TA和读数据

    // reg define
    reg  [5:0]   div_cnt;
    reg  [5:0]   cur_state;
    reg  [5:0]   next_state;
    reg          mdio_dir;         // mdio口方向控制，1：输出; 0：输入
    reg          mdio_out;
    reg          addr_t;           // 临时锁存数据，锁到下一个状态使用
    reg  [15:0]  wr_data_t;
    reg  [1:0]   op_code;
    reg  [6:0]   cnt;
    reg          st_done;
    reg  [15:0]  rd_data_t;

    // wire define
    wire [5:0]   dri_div;               // dri_clk的时钟分频系数(eth_mdc的2倍)，dri_clk相对于clk
    wire         mdio_in;

    assign dri_div = CLK_DIV >> 1;  
    // mdio双向口控制
    assign eth_mdio = mdio_dir ? mdio_out : 1'bz;
    assign mdio_in = eth_mdio;

    // ==============时钟分频================
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            dri_clk <= 1'b0;
            div_cnt <= 1'b0;
        end
        else begin
            if(div_cnt == dri_div[5:1] - 6'd1) begin
                dri_clk <= ~dri_clk;
                div_cnt <= 6'd0;
            end 
            else
                div_cnt <= div_cnt + 6'd1;
        end
    end

    // =============通过cnt产生mdc=============
    always @(posedge dri_clk or posedge rst) begin
        if(rst)
            eth_mdc <= 1'b1;
        else if(cnt[0] == 1'b0)
            eth_mdc <= 1'b1;
        else
            eth_mdc <= 1'b0;
    end
    
    // ==================状态机====================
    // 时序逻辑描述状态转移
    always @(posedge dri_clk or posedge rst) begin
        if(rst) 
            cur_state <= st_idle;
        else 
            cur_state <= next_state;
    end

    // 组合逻辑描述每个状态的转移条件
    always @(*) begin
        next_state = cur_state;    // 出现未定义条件保持状态不变
        case(cur_state)
            st_idle:begin
                if(op_exec)
                    next_state = st_pre;
                else
                    next_state = st_idle;
            end
            
            st_pre:begin
                if(st_done)
                    next_state = st_start;
                else 
                    next_state = st_pre;
            end

            st_start:begin
                if(st_done)
                    next_state = st_addr;
                else
                    next_state = st_start;
            end

            st_addr:begin
                if(st_done) begin
                    if(op_code == 2'b01)
                        next_state = st_write;
                    else 
                        next_state = st_read;
                end 
                else
                    next_state = st_addr;
            end

            st_write:begin
                if(st_done)
                    next_state = st_idle;
                else
                    next_state = st_write;
            end
            
            st_read:begin
                if(st_done)
                    next_state = st_idle;
                else   
                    next_state = st_read;

            end
            default: next_state = st_idle;
        endcase
    end

    // 时序逻辑描述每个状态的输出
    always @(posedge dri_clk or posedge rst) begin
        if(rst) begin
            mdio_dir    <= 1'b0; 
            mdio_out    <= 1'b0;    
            addr_t      <= 5'd0;   
            wr_data_t   <= 15'd0;
            cnt         <= 7'd0;      
            st_done     <= 1'b0;  
            rd_data_t   <= 15'd0;
            op_code     <= 2'd0;
            op_rd_ack   <= 1'b1;
            op_rd_data  <= 16'd0;
            op_done     <= 1'b0;
        end
        else begin
            cnt <= cnt + 7'd1;      // 状态跳转以计数值为依据，所有状态下都是从0开始加
            st_done <= 1'b0;
            case(cur_state)
                st_idle:begin
                    mdio_dir <= 1'b0;
                    mdio_out <= 1'b1;
                    op_done <= 1'b0;
                    cnt <= 7'd0;
                    if(op_exec) begin
                        addr_t <= op_addr;
                        wr_data_t <= op_wr_data;
                        op_code <= {op_rh_wl, ~op_rh_wl};
                        //op_rd_ack <= 1'b1;
                    end
                end
                
                st_pre:begin
                    mdio_dir <= 1'b1;      // mdio输出32个1
                    mdio_out <= 1'b1;
                    if(cnt == 7'd62) 
                        st_done <= 1'b1;
                    else if(cnt == 7'd63) 
                        cnt <= 7'd0;   
                end

                st_start:begin
                    case(cnt)
                        7'd1 :mdio_out <= 1'b0;     // 输出start
                        7'd3 :mdio_out <= 1'b1;
                        7'd5 :mdio_out <= op_code[1];   // 输出操作码
                        7'd6 :st_done <= 1'b1;
                        7'd7 :begin
                            mdio_out <= op_code[0];
                            cnt <= 7'd0;
                        end
                    endcase
                end

                st_addr:begin
                    case(cnt)
                        7'd1 :mdio_out <= PHY_ADDR[4];     // 发送PHY地址
                        7'd3 :mdio_out <= PHY_ADDR[3];     
                        7'd5 :mdio_out <= PHY_ADDR[2];     
                        7'd7 :mdio_out <= PHY_ADDR[1];     
                        7'd9 :mdio_out <= PHY_ADDR[0];     
                        7'd11:mdio_out <= op_addr[4];     // 发送寄存器地址
                        7'd13:mdio_out <= op_addr[3];    
                        7'd15:mdio_out <= op_addr[2];
                        7'd17:mdio_out <= op_addr[1];
                        7'd18:st_done <= 1'b1;
                        7'd19:begin
                            mdio_out <= op_addr[0];
                            cnt <= 7'd0;
                        end
                    endcase
                end

                st_write:begin
                    case(cnt)
                        7'd1 :mdio_out <= 1'b1;     // 发送TA
                        7'd3 :mdio_out <= 1'b0;
                        7'd5 :mdio_out <= op_wr_data[15];     // 发送写数据
                        7'd7 :mdio_out <= op_wr_data[14];     
                        7'd9 :mdio_out <= op_wr_data[13];     
                        7'd11:mdio_out <= op_wr_data[12];     
                        7'd13:mdio_out <= op_wr_data[11];     
                        7'd15:mdio_out <= op_wr_data[10];     
                        7'd17:mdio_out <= op_wr_data[9];     
                        7'd19:mdio_out <= op_wr_data[8];     
                        7'd21:mdio_out <= op_wr_data[7];     
                        7'd23:mdio_out <= op_wr_data[6];     
                        7'd25:mdio_out <= op_wr_data[5];     
                        7'd27:mdio_out <= op_wr_data[4];     
                        7'd29:mdio_out <= op_wr_data[3];     
                        7'd31:mdio_out <= op_wr_data[2];     
                        7'd33:mdio_out <= op_wr_data[1];     
                        7'd35:mdio_out <= op_wr_data[0]; 
                        7'd37:begin
                            mdio_dir <= 1'b0;   // 释放数据总线
                            mdio_out <= 1'b1;
                        end
                        7'd39:st_done <= 1'b1;
                        7'd40:begin
                            cnt <= 7'd0;
                            op_done <= 1'b1;
                        end
                    endcase
                end
                
                st_read:begin
                    case(cnt)
                        7'd1 :begin
                            mdio_dir <= 1'b0;   // 释放总线进行输入
                            mdio_out <= 1'b1;
                        end
                        7'd5 :op_rd_ack <= 1'b0;     // 获取读操作响应 4    ，mdio_in
                        7'd6 :rd_data_t[15] <= mdio_in;     // 获取读数据
                        7'd8 :rd_data_t[14] <= mdio_in;
                        7'd10:rd_data_t[13] <= mdio_in;
                        7'd12:rd_data_t[12] <= mdio_in;
                        7'd14:rd_data_t[11] <= mdio_in;
                        7'd16:rd_data_t[10] <= mdio_in;
                        7'd18:rd_data_t[9] <= mdio_in;
                        7'd20:rd_data_t[8] <= mdio_in;
                        7'd22:rd_data_t[7] <= mdio_in;
                        7'd24:rd_data_t[6] <= mdio_in;
                        7'd26:rd_data_t[5] <= mdio_in;
                        7'd28:rd_data_t[4] <= mdio_in;
                        7'd30:rd_data_t[3] <= mdio_in;
                        7'd32:rd_data_t[2] <= mdio_in;
                        7'd34:rd_data_t[1] <= mdio_in;
                        7'd36:rd_data_t[0] <= mdio_in;
                        7'd39:st_done <= 1'b1;
                        7'd40:begin
                            cnt <= 7'd0;
                            op_done <= 1'b1;
                            op_rd_data <= rd_data_t;
                            rd_data_t <= 16'd0;
                        end
                    endcase
                end
            endcase
        end
    end
endmodule
