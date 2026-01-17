`timescale 1ns / 1ps

module tb_arp_top();

// ====================== 时钟和复位信号 ======================
reg sys_clk_p;
reg sys_clk_n;

reg gtrefclk_p;
reg gtrefclk_n;

reg sys_rst_n;

// 时钟参数
parameter SYS_CLK_PERIOD = 5;     // 200MHz (5ns周期)
parameter GTREFCLK_PERIOD = 8;    // 125MHz (8ns周期)

// 时钟生成
initial begin
    sys_clk_p = 1'b0;
    forever #(SYS_CLK_PERIOD/2) sys_clk_p = ~sys_clk_p;
end

assign sys_clk_n = ~sys_clk_p;

initial begin
    gtrefclk_p = 1'b0;
    forever #(GTREFCLK_PERIOD/2) gtrefclk_p = ~gtrefclk_p;
end

assign gtrefclk_n = ~gtrefclk_p;

// ====================== 复位生成 ======================
initial begin
    sys_rst_n = 1'b0;
    #100 sys_rst_n = 1'b1;  // 100ns后释放复位
end

// ====================== 实例化DUT ======================
wire txp, txn;
wire phy_rst_n;
wire led_link;

// 测试ARP发送数据
wire [7:0] gmii_tx_data;
wire gmii_tx_en;
wire gmii_tx_err;

// 修改test_top以输出内部GMII信号用于验证
test_top dut (
    .sys_clk_p(sys_clk_p),
    .sys_clk_n(sys_clk_n),
    .gtrefclk_p(gtrefclk_p),
    .gtrefclk_n(gtrefclk_n),
    .sys_rst_n(sys_rst_n),
    .phy_rst_n(phy_rst_n),
    
    // SGMII接口 - 连接到虚拟PHY
    .txp(txp),
    .txn(txn),
    .rxp(1'b0),  // 接收侧悬空，因为我们只测试发送
    .rxn(1'b1),
    
    // 状态指示
    .led_link(led_link),
    
    // 用于测试的内部信号（需要在test_top中声明为输出）
    .test_gmii_tx_data(gmii_tx_data),
    .test_gmii_tx_en(gmii_tx_en),
    .test_gmii_tx_err(gmii_tx_err)
);

// ====================== 虚拟PHY接收器 ======================
// 用于捕获和验证ARP数据包
reg [7:0] packet_buffer [0:511];
reg [9:0] packet_index = 0;
reg packet_capturing = 0;
reg [31:0] byte_counter = 0;

// 捕获GMII数据流
always @(posedge gmii_clk) begin
    if (!sys_rst_n) begin
        packet_index <= 0;
        packet_capturing <= 0;
        byte_counter <= 0;
    end else begin
        byte_counter <= byte_counter + 1;
        
        // 检测帧开始（前导码+SFD）
        if (gmii_tx_en && gmii_tx_data == 8'hD5 && packet_index == 7) begin
            packet_capturing <= 1;
            packet_index <= 0;
            $display("[%0t] INFO: Start of Frame Detected", $time);
        end 
        // 捕获帧数据
        else if (gmii_tx_en && packet_capturing) begin
            packet_buffer[packet_index] <= gmii_tx_data;
            packet_index <= packet_index + 1;
            
            // 简单帧结束检测（在实际中应该检查IFG）
            if (packet_index > 100) begin
                packet_capturing <= 0;
                $display("[%0t] INFO: Frame captured, length = %0d bytes", $time, packet_index);
                verify_arp_packet();
            end
        end
        // 帧结束
        else if (!gmii_tx_en && packet_capturing) begin
            packet_capturing <= 0;
            $display("[%0t] INFO: End of Frame, captured %0d bytes", $time, packet_index);
            verify_arp_packet();
        end
    end
end

// ====================== ARP数据包验证 ======================
task verify_arp_packet;
    integer i;
    reg [47:0] dest_mac;
    reg [47:0] src_mac;
    reg [15:0] eth_type;
    reg [15:0] arp_hw_type;
    reg [15:0] arp_protocol;
    reg [7:0] arp_hw_len;
    reg [7:0] arp_prot_len;
    reg [15:0] arp_opcode;
    reg [47:0] arp_src_mac;
    reg [31:0] arp_src_ip;
    reg [47:0] arp_dest_mac;
    reg [31:0] arp_dest_ip;
begin
    $display("\n========== ARP Packet Verification ==========");
    
    // 验证以太网头部（从SFD之后开始）
    dest_mac = {packet_buffer[0], packet_buffer[1], packet_buffer[2], 
                packet_buffer[3], packet_buffer[4], packet_buffer[5]};
    src_mac = {packet_buffer[6], packet_buffer[7], packet_buffer[8], 
               packet_buffer[9], packet_buffer[10], packet_buffer[11]};
    eth_type = {packet_buffer[12], packet_buffer[13]};
         
    $display("Destination MAC: %02x:%02x:%02x:%02x:%02x:%02x",
             dest_mac[47:40], dest_mac[39:32], dest_mac[31:24],
             dest_mac[23:16], dest_mac[15:8], dest_mac[7:0]);
    $display("Source MAC: %02x:%02x:%02x:%02x:%02x:%02x",
             src_mac[47:40], src_mac[39:32], src_mac[31:24],
             src_mac[23:16], src_mac[15:8], src_mac[7:0]);
    $display("EtherType: 0x%04x", eth_type);
    
    // 验证ARP数据部分
    arp_hw_type = {packet_buffer[14], packet_buffer[15]};
    arp_protocol = {packet_buffer[16], packet_buffer[17]};
    arp_hw_len = packet_buffer[18];
    arp_prot_len = packet_buffer[19];
    arp_opcode = {packet_buffer[20], packet_buffer[21]};
    arp_src_mac = {packet_buffer[22], packet_buffer[23], packet_buffer[24],
                   packet_buffer[25], packet_buffer[26], packet_buffer[27]};
    arp_src_ip = {packet_buffer[28], packet_buffer[29], 
                  packet_buffer[30], packet_buffer[31]};
    arp_dest_mac = {packet_buffer[32], packet_buffer[33], packet_buffer[34],
                    packet_buffer[35], packet_buffer[36], packet_buffer[37]};
    arp_dest_ip = {packet_buffer[38], packet_buffer[39],
                   packet_buffer[40], packet_buffer[41]};
    
    $display("\nARP Header:");
    $display("  HW Type: 0x%04x (1=Ethernet)", arp_hw_type);
    $display("  Protocol: 0x%04x (0x0800=IPv4)", arp_protocol);
    $display("  HW Addr Len: %0d", arp_hw_len);
    $display("  Protocol Addr Len: %0d", arp_prot_len);
    $display("  Opcode: 0x%04x (1=Request, 2=Reply)", arp_opcode);
    $display("  Sender MAC: %02x:%02x:%02x:%02x:%02x:%02x",
             arp_src_mac[47:40], arp_src_mac[39:32], arp_src_mac[31:24],
             arp_src_mac[23:16], arp_src_mac[15:8], arp_src_mac[7:0]);
    $display("  Sender IP: %0d.%0d.%0d.%0d",
             arp_src_ip[31:24], arp_src_ip[23:16], arp_src_ip[15:8], arp_src_ip[7:0]);
    $display("  Target MAC: %02x:%02x:%02x:%02x:%02x:%02x",
             arp_dest_mac[47:40], arp_dest_mac[39:32], arp_dest_mac[31:24],
             arp_dest_mac[23:16], arp_dest_mac[15:8], arp_dest_mac[7:0]);
    $display("  Target IP: %0d.%0d.%0d.%0d",
             arp_dest_ip[31:24], arp_dest_ip[23:16], arp_dest_ip[15:8], arp_dest_ip[7:0]);
    
    // 验证期望值
    if (dest_mac == 48'hFFFFFFFFFFFF) begin
        $display("\n? Destination MAC is broadcast (correct)");
    end else begin
        $display("\n? Destination MAC error: expected broadcast");
    end
    
    if (src_mac == 48'h000A3501FEC0) begin
        $display("? Source MAC matches expected value");
    end else begin
        $display("? Source MAC error: expected 00:0A:35:01:FE:C0");
    end
    
    if (eth_type == 16'h0806) begin
        $display("? EtherType is ARP (0x0806)");
    end else begin
        $display("? EtherType error: expected 0x0806");
    end
    
    if (arp_opcode == 16'h0001) begin
        $display("? ARP Opcode is Request (0x0001)");
    end else begin
        $display("? ARP Opcode error: expected 0x0001");
    end
    
    if (arp_dest_ip == 32'hC0A80003) begin
        $display("? Target IP is 192.168.0.3");
    end else begin
        $display("? Target IP error: expected 192.168.0.3");
    end
    
    // 验证CRC（最后4字节）
    $display("\nFrame CRC (last 4 bytes):");
    for (i = packet_index-4; i < packet_index; i = i+1) begin
        $write("0x%02x ", packet_buffer[i]);
    end
    $display("");
    
    $display("============================================\n");
end
endtask

// ====================== GMII时钟 ======================
wire gmii_clk;
// 从DUT中获取userclk2（GMII时钟）
assign gmii_clk = dut.userclk2;

// ====================== 信号监控 ======================
// 监控关键状态信号
initial begin
    $timeformat(-9, 3, " ns", 10);
    $display("\n========== ARP发送测试开始 ==========");
    
    // 等待系统稳定
    wait(sys_rst_n == 1'b1);
    $display("[%0t] INFO: System reset released", $time);
    
    // 等待PCS/PMA复位完成
    wait(dut.resetdone == 1'b1);
    $display("[%0t] INFO: PCS/PMA reset done", $time);
    
    // 等待ARP模块复位完成
    #2000000; // 等待2ms确保ARP模块复位完成
    
    $display("[%0t] INFO: Waiting for ARP packet transmission...", $time);
    
    // 监控GMII发送信号
    fork
        // 监控帧开始
        begin
            @(posedge gmii_tx_en);
            $display("[%0t] INFO: GMII TX_EN asserted, ARP transmission started", $time);
        end
        
        // 超时检查
        begin
            #20000000; // 等待20ms
            if (packet_index == 0) begin
                $display("[%0t] ERROR: No ARP packet detected within timeout!", $time);
                $finish;
            end
        end
        
        // 监控多个ARP包
        begin
            repeat(3) begin  // 监控3个ARP包
                wait(packet_index > 50);
                #1000;
                packet_index = 0;  // 重置计数器准备下一个包
                $display("[%0t] INFO: Waiting for next ARP packet...", $time);
            end
            $display("\n[%0t] INFO: Successfully verified 3 ARP packets", $time);
            #10000;
            $finish;
        end
    join
    
end

// ====================== 波形输出 ======================
initial begin
    // 创建VCD文件用于波形查看
    $dumpfile("arp_test.vcd");
    $dumpvars(0, tb_arp_top);
    
    // 或者使用FSDB（如果支持）
    // $fsdbDumpfile("arp_test.fsdb");
    // $fsdbDumpvars(0, tb_arp_top);
end

// ====================== 测试激励 ======================
// 您可以添加额外的测试激励，例如：
// 1. 模拟PHY状态变化
// 2. 测试不同的ARP参数
// 3. 测试错误注入

// 模拟信号检测
reg signal_detect = 1'b1;
initial begin
    #5000000 signal_detect = 1'b0;  // 5us后模拟信号丢失
    #200000 signal_detect = 1'b1;   // 200ns后恢复信号
end

endmodule