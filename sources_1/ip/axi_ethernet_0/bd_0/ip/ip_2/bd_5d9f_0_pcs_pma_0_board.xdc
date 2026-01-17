#--------------------Physical Constraints-----------------
set_property LOC GTXE2_CHANNEL_X1Y1 [get_cells -hi -regexp {.*transceiver_inst/gtwizard_inst/.*GTWIZARD_i/gt.e2_i}] 

set_property BOARD_PIN {sgmii_mgt_clkp} [get_ports gtrefclk_p]
set_property BOARD_PIN {sgmii_mgt_clkn} [get_ports gtrefclk_n]
set_property BOARD_PIN {mdc} [get_ports ext_mdc]
set_property BOARD_PIN {mdio_i} [get_ports ext_mdio_o]

