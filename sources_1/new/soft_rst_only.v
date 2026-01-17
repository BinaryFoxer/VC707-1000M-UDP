`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// mdio控制模块
//////////////////////////////////////////////////////////////////////////////////

module soft_rst_only(
    input               clk,
    input               rst_n,

    input               soft_rst_trig,      // 软复位触发信号
    input               op_done,            // 操作完成信号
    input               op_rd_ack,          // 读响应信号
    input       [15:0]  op_rd_data,         // 读出的寄存器数据

    output  reg         op_exec,            // 开始操作
    output  reg         op_rh_wl,           // 操作类型
    output  reg [4:0]   op_addr,
    output  reg [15:0]  op_wr_data,         // 写入数据

    output      [1:0]   led                 // 速度指示led
    );

    // parameter define
    parameter READ_PERIOD = 24'd100_000;    // 10ms读一次状态寄存器值

    // reg define
    reg        rst_trig_0;
    reg        rst_trig_1;
    reg        rst_trig_2;
    reg        start_read;
    reg [23:0] timer_cnt;
    reg [3:0]  flow_cnt;
    reg [1:0]  speed_status;
    reg        rst_trig_flag;
    reg        link_error;

    // wire define
    wire pos_rst_trig;

    assign pos_rst_trig = ~rst_trig_2 & rst_trig_1;

    assign led = link_error ? 2'b00 : speed_status;

    // 对soft_rst_trig打三拍，获取上升沿
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            rst_trig_0 <= 0;
            rst_trig_1 <= 0;
            rst_trig_2 <= 0;
        end
        else begin
            rst_trig_0 <= soft_rst_trig;
            rst_trig_1 <= rst_trig_0;
            rst_trig_2 <= rst_trig_1;
        end
    end

    // 定时读取信号
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            start_read <= 1'b0;
            timer_cnt <= 24'd0;
        end
        else begin
            if(timer_cnt == READ_PERIOD - 1) begin
                start_read <= 1'b1;
                timer_cnt <= 24'd0;
            end
            else begin
                timer_cnt <= timer_cnt + 24'd1;
                start_read <= 1'b0;
            end
        end
    end

    // 使用流计数器完成写控制寄存器和读状态寄存器操作
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            op_exec       <= 1'b0; 
            op_rh_wl      <= 1'b1;
            op_addr       <= 5'h0;
            op_wr_data    <= 16'd0;
            flow_cnt      <= 4'd0;
            speed_status  <= 2'b00;
            rst_trig_flag <= 1'b0;
            link_error    <= 1'b0;
        end
        else begin
            op_exec <= 1'b0;
            if(pos_rst_trig)
                rst_trig_flag <= 1'b1;
            case(flow_cnt)
                4'd0:begin
                    if(rst_trig_flag) begin
                        op_exec <= 1'b1;
                        op_rh_wl <= 1'b0;                          // 写软复位
                        op_addr <= 5'd0;                           // 基本控制寄存器(BSCFR)地址
                        op_wr_data <= 16'b1010_0001_0100_0000;     // 控制寄存器配置: 1010_0001_0100_0000
                        flow_cnt <= 4'd1;       
                    end
                    else if(start_read) begin
                        op_exec <= 1'b1;
                        op_rh_wl <= 1'b1;                          // 读基本状态寄存器
                        op_addr <= 5'd1;                           // 基本状态寄存器(BSCFR)地址
                        flow_cnt <= 4'd2;   
                    end                        
                end

                4'd1:begin
                    if(op_done)                             // 软复位完成，清零软复位标志位
                        flow_cnt <= 4'd0;
                        rst_trig_flag <= 4'd0;
                end

                4'd2:begin
                    if(op_done) begin
                        if(op_rd_ack == 1'b0 && op_rd_data[5] == 1'b1 && op_rd_data[2] == 1'b1) begin  // 读响应和自协商以及连接正常
                            flow_cnt <= 4'd3;
                            link_error <= 1'b0;
                        end
                        else begin
                            flow_cnt <= 4'd0;
                            link_error <= 1'b1;
                        end
                    end
                end

                4'd3:begin
                    op_exec <= 1'b1;
                    op_rh_wl <= 1'b1;                        // 读PHY状态寄存器
                    op_addr <= 5'd2;                        // PHY状态寄存器R17地址，测试读phy_id1
                    flow_cnt <= 4'd4;
                end

                4'd4:begin
                    if(op_done) begin
                        if(op_rd_ack == 1'b0)                // 有读响应，说明读成功数据正常
                            flow_cnt <= 4'd5;
                        else
                            flow_cnt <= 4'd0;
                    end
                end

                4'd5:begin
                    flow_cnt <= 4'd0;
                    case(op_rd_data[15:14])
                        2'b00:speed_status <= 2'b01;    // 10mbps
                        2'b01:speed_status <= 2'b10;    // 100mbps
                        2'b10:speed_status <= 2'b11;    // 1000mbps
                        default:speed_status <= 2'b00;
                    endcase
                end
            endcase
        end
    end



endmodule
