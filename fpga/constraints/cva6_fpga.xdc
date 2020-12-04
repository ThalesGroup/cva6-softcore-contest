## Common Ariane XDCs

create_clock -period 100.000 -name tck -waveform {0.000 50.000} [get_ports tck]
set_input_jitter tck 1.000
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets tck_IBUF]

# minimize routing delay
set_input_delay -clock tck -clock_fall 5.000 [get_ports tdi]
set_input_delay -clock tck -clock_fall 5.000 [get_ports tms]
set_output_delay -clock tck 5.000 [get_ports tdo]
set_false_path -from [get_ports trst_n]


set_max_delay -datapath_only -from [get_pins i_dmi_jtag/i_dmi_cdc/i_cdc_resp/i_src/data_src_q_reg*/C] -to [get_pins i_dmi_jtag/i_dmi_cdc/i_cdc_resp/i_dst/data_dst_q_reg*/D] 20.000
set_max_delay -datapath_only -from [get_pins i_dmi_jtag/i_dmi_cdc/i_cdc_resp/i_src/req_src_q_reg/C] -to [get_pins i_dmi_jtag/i_dmi_cdc/i_cdc_resp/i_dst/req_dst_q_reg/D] 20.000
set_max_delay -datapath_only -from [get_pins i_dmi_jtag/i_dmi_cdc/i_cdc_req/i_dst/ack_dst_q_reg/C] -to [get_pins i_dmi_jtag/i_dmi_cdc/i_cdc_req/i_src/ack_src_q_reg/D] 20.000

# set multicycle path on reset, on the FPGA we do not care about the reset anyway
set_multicycle_path -from [get_pins {i_rstgen_main/i_rstgen_bypass/synch_regs_q_reg[3]/C}] 4
set_multicycle_path -hold -from [get_pins {i_rstgen_main/i_rstgen_bypass/synch_regs_q_reg[3]/C}] 3

set_property MARK_DEBUG false [get_nets {debug_req[data][7]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][4]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][0]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][1]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][2]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][3]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][5]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][6]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][8]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][11]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][13]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][15]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][17]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][19]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][21]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][23]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][25]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][27]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][29]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][31]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][30]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][28]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][26]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][24]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][22]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][20]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][18]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][16]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][14]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][12]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][9]}]
set_property MARK_DEBUG false [get_nets {debug_req[data][10]}]
