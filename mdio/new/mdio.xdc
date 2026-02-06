set_property IOSTANDARD LVDS [get_ports sys_clk_p]
set_property IOSTANDARD LVDS [get_ports sys_clk_n]

set_property IOSTANDARD LVCMOS18 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports touch_key]
set_property IOSTANDARD LVCMOS18 [get_ports id_led]

set_property PACKAGE_PIN AN39 [get_ports {led[1]}]
set_property PACKAGE_PIN E19 [get_ports sys_clk_p]
set_property PACKAGE_PIN E18 [get_ports sys_clk_n]
set_property PACKAGE_PIN AM39 [get_ports {led[0]}]


set_property PACKAGE_PIN AW40 [get_ports send_key]
set_property IOSTANDARD LVCMOS18 [get_ports send_key]

set_property PACKAGE_PIN AU38 [get_ports touch_key]
set_property PACKAGE_PIN AT37 [get_ports id_led]
set_property PACKAGE_PIN AP42 [get_ports arp_led]
set_property IOSTANDARD LVCMOS18 [get_ports arp_led]

set_property IOSTANDARD LVCMOS18 [get_ports eth_mdc]
set_property IOSTANDARD LVCMOS18 [get_ports eth_mdio]
set_property IOSTANDARD LVCMOS18 [get_ports eth_rst_n]

set_property PACKAGE_PIN AJ33 [get_ports eth_rst_n]
set_property PACKAGE_PIN AH31 [get_ports eth_mdc]
set_property PACKAGE_PIN AK33 [get_ports eth_mdio]

set_property IOSTANDARD LVCMOS18 [get_ports download_sus]
set_property PACKAGE_PIN AR35 [get_ports download_sus]


set_property IOSTANDARD LVCMOS18 [get_ports test_led]
set_property PACKAGE_PIN AU39 [get_ports test_led]

set_property IOSTANDARD LVCMOS18 [get_ports sys_rst]
set_property PACKAGE_PIN AP40 [get_ports sys_rst]

set_property PACKAGE_PIN AM8 [get_ports sgmii_rxp]
set_property PACKAGE_PIN AM7 [get_ports sgmii_rxn]
set_property PACKAGE_PIN AN2 [get_ports sgmii_txp]
set_property PACKAGE_PIN AN1 [get_ports sgmii_txn]

set_property PACKAGE_PIN AH8 [get_ports sgmii_clk_p]
set_property PACKAGE_PIN AH7 [get_ports sgmii_clk_n]

