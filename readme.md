# FPGA-Based Gigabit UDP/IP Stack with Lightweight Asynchronous FIFO Rate Matching

基于 FPGA 的千兆 UDP/IP 硬件协议栈 | 轻量级异步 FIFO 速率匹配 | 无 DDR 零丢包高速传输

## 项目简介

本项目基于 **Xilinx VC707 FPGA** 开发完成，实现了一套**全硬件千兆以太网 UDP/IP 协议栈**，支持 ARP 自动应答、ICMP Ping 自动回复、UDP 数据收发与环回测试。

针对**源端数据速率 > 以太网链路速率**导致的丢包、缓存溢出问题，项目提出一种基于异步 FIFO + 可编程满反压（prog_full）的轻量级速率匹配机制，不依赖外部 DDR，即可实现高吞吐、零丢包、高实时性的千兆以太网传输。

## 实验平台

- **FPGA 平台**：Xilinx VC707 (XC7VX485T)

- **开发工具**：Vivado 2018.3

- **物理接口**：SGMII / GMII 千兆以太网

- 时钟

  - 源端写入时钟：200MHz
  - 以太网发送时钟：125MHz

  

- **上位机系统**：Windows 11

## 实现功能

1. ARP 自动应答

   响应上位机 ARP 请求，自动回复 MAC 地址。

2. ICMP Ping 自动回复

   响应 Ping 请求，实现网络连通性测试。

3. UDP 数据收发 / 环回测试

   支持上位机 UDP 数据发送、FPGA 环回、数据校验。

4. 高速数据源生成

   0x01~0xFF 循环递增数据，便于验证丢包 / 错位。

5. 异步 FIFO 跨时钟域缓存

   200MHz 写时钟域 ↔ 125MHz 读时钟域。

6. prog_full 反压速率匹配

   FIFO 满阈值自动反压，暂停源端写入，防止溢出。

7. 双状态机流水传输

   - 源端数据写入状态机（5 状态）
   - UDP 发送控制状态机（3 状态）

   

## 实验结果

- **最高吞吐率**：990 Mbps（接近千兆极限）
- **最大传输数据量**：500MB
- **传输可靠性**：零丢包、零错误、数据连续递增
- **速率自适应**：50MHz / 125MHz / 200MHz 源端均稳定工作
- **对比验证**：无 FIFO 反压 → 严重丢包；有 FIFO 反压 → 稳定零丢包

## 工程文件结构

```
src/
├── src_data_maxv.v            # 工程顶层文件
├── eth_udp_test.v             # UDP连通测试
├── eth_ctrl_sw.v              # 协议切换与仲裁模块
├── arp.v                      # ARP协议模块
├── icmp.v                     # ICMP协议模块
├── udp.v                      # UDP协议模块
├── sgmii_to_gmii.v            # SGMII-GMII接口转换
├── mdio_wr_ctrl.v             # PHY配置 MDIO 接口
├── mdio_wr_dri.v              # PHY配置 MDIO 驱动
└── fifo_generator_1.xci       # 异步FIFO IP核

```

## 使用说明

1. 使用 Vivado 2018.3 新建工程，添加 `src/` 所有文件

2. 锁定 VC707 管脚（SGMII、时钟、LED、按键）

3. 综合、实现、生成比特流下载至 FPGA

4. PC 端设置静态 IP：192.168.0.3

5. FPGA IP：192.168.0.2，MAC：00-11-22-33-44-55

6. 测试指令：

   - ping 192.168.0.2
   - UDP 上位机发送 / 环回测试
   - 按键触发 500MB 高速传输

   

## 适用场景

- 高速图像采集传输
- 工业实时数据传输
- 雷达 / ADC 数据上传
- FPGA → PC 高速无损传输
- 轻量化、低成本千兆以太网传输系统

## 开源协议

MIT License