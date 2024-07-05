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
















create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER true [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 2048 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list i_xlnx_clk_gen/inst/clk_out1]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 4 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {dram\\.ar_qos[0]} {dram\\.ar_qos[1]} {dram\\.ar_qos[2]} {dram\\.ar_qos[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 3 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {dram\\.ar_prot[0]} {dram\\.ar_prot[1]} {dram\\.ar_prot[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 4 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {dram\\.ar_len[0]} {dram\\.ar_len[1]} {dram\\.ar_len[2]} {dram\\.ar_len[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 4 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {dram\\.ar_id[0]} {dram\\.ar_id[1]} {dram\\.ar_id[4]} {dram\\.ar_id[5]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 4 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {dram\\.ar_cache[0]} {dram\\.ar_cache[1]} {dram\\.ar_cache[2]} {dram\\.ar_cache[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 2 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {dram\\.ar_burst[0]} {dram\\.ar_burst[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 31 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {dram\\.ar_addr[0]} {dram\\.ar_addr[1]} {dram\\.ar_addr[2]} {dram\\.ar_addr[3]} {dram\\.ar_addr[4]} {dram\\.ar_addr[5]} {dram\\.ar_addr[6]} {dram\\.ar_addr[7]} {dram\\.ar_addr[8]} {dram\\.ar_addr[9]} {dram\\.ar_addr[10]} {dram\\.ar_addr[11]} {dram\\.ar_addr[12]} {dram\\.ar_addr[13]} {dram\\.ar_addr[14]} {dram\\.ar_addr[15]} {dram\\.ar_addr[16]} {dram\\.ar_addr[17]} {dram\\.ar_addr[18]} {dram\\.ar_addr[19]} {dram\\.ar_addr[20]} {dram\\.ar_addr[21]} {dram\\.ar_addr[22]} {dram\\.ar_addr[23]} {dram\\.ar_addr[24]} {dram\\.ar_addr[25]} {dram\\.ar_addr[26]} {dram\\.ar_addr[27]} {dram\\.ar_addr[28]} {dram\\.ar_addr[29]} {dram\\.ar_addr[30]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 3 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {dram\\.ar_size[0]} {dram\\.ar_size[1]} {dram\\.ar_size[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 64 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {dram\\.r_data[0]} {dram\\.r_data[1]} {dram\\.r_data[2]} {dram\\.r_data[3]} {dram\\.r_data[4]} {dram\\.r_data[5]} {dram\\.r_data[6]} {dram\\.r_data[7]} {dram\\.r_data[8]} {dram\\.r_data[9]} {dram\\.r_data[10]} {dram\\.r_data[11]} {dram\\.r_data[12]} {dram\\.r_data[13]} {dram\\.r_data[14]} {dram\\.r_data[15]} {dram\\.r_data[16]} {dram\\.r_data[17]} {dram\\.r_data[18]} {dram\\.r_data[19]} {dram\\.r_data[20]} {dram\\.r_data[21]} {dram\\.r_data[22]} {dram\\.r_data[23]} {dram\\.r_data[24]} {dram\\.r_data[25]} {dram\\.r_data[26]} {dram\\.r_data[27]} {dram\\.r_data[28]} {dram\\.r_data[29]} {dram\\.r_data[30]} {dram\\.r_data[31]} {dram\\.r_data[32]} {dram\\.r_data[33]} {dram\\.r_data[34]} {dram\\.r_data[35]} {dram\\.r_data[36]} {dram\\.r_data[37]} {dram\\.r_data[38]} {dram\\.r_data[39]} {dram\\.r_data[40]} {dram\\.r_data[41]} {dram\\.r_data[42]} {dram\\.r_data[43]} {dram\\.r_data[44]} {dram\\.r_data[45]} {dram\\.r_data[46]} {dram\\.r_data[47]} {dram\\.r_data[48]} {dram\\.r_data[49]} {dram\\.r_data[50]} {dram\\.r_data[51]} {dram\\.r_data[52]} {dram\\.r_data[53]} {dram\\.r_data[54]} {dram\\.r_data[55]} {dram\\.r_data[56]} {dram\\.r_data[57]} {dram\\.r_data[58]} {dram\\.r_data[59]} {dram\\.r_data[60]} {dram\\.r_data[61]} {dram\\.r_data[62]} {dram\\.r_data[63]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 6 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {dram\\.r_id[0]} {dram\\.r_id[1]} {dram\\.r_id[2]} {dram\\.r_id[3]} {dram\\.r_id[4]} {dram\\.r_id[5]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 2 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list {dram\\.r_resp[0]} {dram\\.r_resp[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list {dram\\.ar_ready}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 1 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list {dram\\.ar_valid}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 1 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list {dram\\.r_last}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 1 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list {dram\\.r_ready}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
set_property port_width 1 [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list {dram\\.r_valid}]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]
