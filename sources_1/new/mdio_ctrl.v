`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// mdio控制模块
//////////////////////////////////////////////////////////////////////////////////

module mdio_ctrl(
    input               clk,
    input               rst,

    input               soft_rst_trig,      // 软复位触发信号
    input               op_done,            // 操作完成信号
    input               op_rd_ack,          // 读响应信号
    input       [15:0]  op_rd_data,         // 读出的寄存器数据

    output  reg         op_exec,            // 开始操作
    output  reg         op_rh_wl,           // 操作类型
    output  reg [4:0]   op_addr,
    output  reg [15:0]  op_wr_data,         // 写入数据

    output      [1:0]   led,                // 速度指示led
    output              id_led,              // 读id正确指示led
    output              test_led           // 读访问错误指示led
    );

    // parameter define
    parameter READ_PERIOD = 24'd100_000;    // 20ms读一次状态寄存器值

    // reg define
    reg        rst_trig_0;
    reg        rst_trig_1;
    reg        rst_trig_2;
    reg        start_read;
    reg [23:0] timer_cnt;
    reg [4:0]  flow_cnt;
    reg [1:0]  speed_status;
    reg        rst_trig_flag;
    reg        link_error;
    reg [15:0] rd_data_t;
    reg [15:0] wr_data_t;
    reg        id_right;
    reg        test_led_v;

    // wire define
    wire pos_rst_trig;

    assign pos_rst_trig = ~rst_trig_2 & rst_trig_1;

    assign led = link_error ? 2'b00 : speed_status;
    assign id_led = id_right;
    // assign test_led = link_error;                         // 读PHY数据失败
    assign test_led = test_led_v;

    // 对soft_rst_trig打三拍，获取上升沿
    always @(posedge clk or posedge rst) begin
        if(rst)begin
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
    always @(posedge clk or posedge rst) begin
        if(rst)begin
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
    always @(posedge clk or posedge rst) begin
        if(rst)begin
            op_exec       <= 1'b0; 
            op_rh_wl      <= 1'b1;
            op_addr       <= 5'h0;
            op_wr_data    <= 16'd0;
            flow_cnt      <= 5'd0;
            speed_status  <= 2'b00;
            rst_trig_flag <= 1'b0;
            link_error    <= 1'b0;
            rd_data_t     <= 16'd0;
            wr_data_t     <= 16'd0;
            id_right      <= 1'b0;
            test_led_v    <= 1'b0;
        end
        else begin
            op_exec <= 1'b0;
            
            if(pos_rst_trig)
                rst_trig_flag <= 1'b1;
            case(flow_cnt)
                5'd0:begin
                    if(rst_trig_flag) begin                        // 使用软复位触发PHY配置，写入寄存器
                        op_exec <= 1'b1;
                        op_rh_wl <= 1'b1;                          // 读R27数据
                        op_addr <= 5'd27;                          // EPSSSR地址
                        flow_cnt <= 5'd1;       
                    end
                    else if(start_read) begin
                        op_exec <= 1'b1;
                        op_rh_wl <= 1'b1;                          // 读基本状态寄存器
                        op_addr <= 5'd1;                           // 基本状态寄存器(BSCFR)地址
                        flow_cnt <= 5'd10;                         // 先读phy id（测试）
                        // test_led_v <= 1'b1;                        // 开始读   
                    end                        
                end

                5'd1:begin
                    if(op_done) begin                              // 等待R27读数据完成
                        if(op_rd_ack == 1'b0) begin
                            rd_data_t <= op_rd_data;               // 寄存R27初始配置数据
                            flow_cnt <= 5'd2;                      
                        end
                        else
                            flow_cnt <= 5'd0;                      // R27访问错误
                                    
                    end
                end

                5'd2:begin
                    wr_data_t <= (rd_data_t & 16'b0111_1111_1111_0000) | 16'b1000_0000_0000_0000;   // 配置成千兆SGMII模式，其它位不变
                    flow_cnt <= 5'd3;
                end

                5'd3:begin
                    op_exec <= 1'b1;
                    op_rh_wl <= 1'b0;                              // 写R27数据配置模式
                    op_addr <= 5'd27;                              // EPSSSR地址
                    op_wr_data <= wr_data_t;                       // R27的配置数据
                    flow_cnt <= 5'd4;
                end
                
                5'd4:begin
                    if(op_done) begin                              // 等待写R27完成
                        flow_cnt <= 5'd5;   
                    end
                end

                5'd5:begin
                    op_exec <= 1'b1;
                    op_rh_wl <= 1'b1;                        // 先读R0的基本配置
                    op_addr <= 5'd0;
                    flow_cnt <= 5'd6;
                end

                5'd6:begin                                   
                    if(op_done) begin                       // 等待读R0完成
                        if(op_rd_ack == 1'b0) begin
                            rd_data_t <= op_rd_data;
                            flow_cnt <= 5'd7;
                        end
                        else
                            flow_cnt <= 5'd0;               // R0访问错误
                                    
                    end
                end

                5'd7:begin
                    wr_data_t <= (rd_data_t & 16'b0000_0000_0011_1111) | 16'b1000_0001_0100_0000;       // bit[6]如果是1为1000M，是0为10M
                    flow_cnt <= 5'd8;
                end

                5'd8:begin
                    op_exec <= 1'b1;
                    op_rh_wl <= 1'b0;                          // 配置完成，开始写软复位
                    op_addr <= 5'd0;                           // 基本控制寄存器(BSCFR)地址
                    op_wr_data <= wr_data_t;     // 控制寄存器配置: 1000_0001_0100_0000
                    flow_cnt <= 5'd9;
                end

                5'd9:begin
                    if(op_done) begin                           // 软复位完成，清零软复位标志位
                        flow_cnt <= 5'd0;
                        rst_trig_flag <= 1'b0;
                    end
                end

                // ------------定时读状态寄存器-----------
                5'd10:begin
                    if(op_done) begin
                        if(op_rd_ack == 1'b0 && op_rd_data[2] == 1) begin  // 读响应以及连接正常 && op_rd_data[2] == 1，op_rd_ack == 1'b0
                            flow_cnt <= 5'd11;
                            link_error <= 1'b0;
                            test_led_v <= 1'b1;
                        end
                        else begin
                            flow_cnt <= 5'd0;
                            link_error <= 1'b1;
                        end
                    end
                    else begin
                        // link_error <= 1'b1;                               // 如果没有读响应，也算作连接失败(测试)
                        // test_led_v <= 1'b1;
                    end
                end

                5'd11:begin
                    op_exec <= 1'b1;
                    op_rh_wl <= 1'b1;                        // 读PHY状态寄存器
                    op_addr <= 5'd17;                        // PHY状态寄存器R17地址
                    flow_cnt <= 5'd12;
                end

                5'd12:begin
                    if(op_done) begin
                        if(op_rd_ack == 1'b0)                // 有读响应，说明读成功数据正常
                            flow_cnt <= 5'd13;
                        else
                            flow_cnt <= 5'd0;
                    end
                end

                5'd13:begin
                    case(op_rd_data[15:14])
                        2'b00:speed_status <= 2'b01;    // 10mbps
                        2'b01:speed_status <= 2'b10;    // 100mbps
                        2'b10:speed_status <= 2'b11;    // 1000mbps
                        default:speed_status <= 2'b00;
                    endcase
                    flow_cnt <= 5'd14;                   
                end

                5'd14:begin
                    op_exec <= 1'b1;                        // 进入读phy ID状态，确保能正常读芯片数据
                    op_rh_wl <= 1'b1;                       // 读PHY ID寄存器
                    op_addr <= 5'd2;                        // 寄存器R2地址
                    flow_cnt <= 5'd15;
                end

                5'd15:begin
                    if(op_done) begin
                        if(op_rd_ack == 1'b0) begin
                            rd_data_t <= op_rd_data;
                            flow_cnt <= 5'd16;
                        end
                        else
                            flow_cnt <= 5'd0;
                    end
                end

                5'd16:begin
                    flow_cnt <= 5'd0;
                    id_right <= (rd_data_t == 16'h0141) ? 1'b1 : 1'b0;
                    // test_led_v <= 1'b1;
                end

            endcase
        end
    end


endmodule
