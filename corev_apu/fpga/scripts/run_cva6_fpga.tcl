# Copyright (c) 2020 Thales.
# 
# Copyright and related rights are licensed under the Solderpad
# License, Version 2.0 (the "License"); you may not use this file except in
# compliance with the License.  You may obtain a copy of the License at
# http://solderpad.org/licenses/SHL-2.0/ Unless required by applicable law
# or agreed to in writing, software, hardware and materials distributed under
# this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.
#
# Author:         Sebastien Jacq - sjthales on github.com

#
# Additional contributions by:
#
#
# script Name:    run_cva6_fpga
# Project Name:   CVA6 softcore
# Language:       tcl
#
# Description:    Script to generate bitstream of CVA6 architecture
#                 in Zybo 7-20 board
#
# =========================================================================== #
# Revisions  :
# Date        Version  Author       Description
# 2020-11-06  0.1      S.Jacq       Created
# =========================================================================== #
set project cva6_fpga

create_project $project . -force -part $::env(XILINX_PART)
set_property board_part $::env(XILINX_BOARD) [current_project]



# set number of threads to 8 (maximum, unfortunately)
set_param general.maxThreads 8

set_msg_config -id {[Synth 8-5858]} -new_severity "info"

set_msg_config -id {[Synth 8-4480]} -limit 1000

add_files -fileset constrs_1 -norecurse constraints/zybo_z7_20.xdc

read_ip { \
      "xilinx/xlnx_axi_clock_converter/xlnx_axi_clock_converter.srcs/sources_1/ip/xlnx_axi_clock_converter/xlnx_axi_clock_converter.xci" \
      "xilinx/xlnx_axi_dwidth_converter_dm_slave/xlnx_axi_dwidth_converter_dm_slave.srcs/sources_1/ip/xlnx_axi_dwidth_converter_dm_slave/xlnx_axi_dwidth_converter_dm_slave.xci" \
      "xilinx/xlnx_axi_dwidth_converter_dm_master/xlnx_axi_dwidth_converter_dm_master.srcs/sources_1/ip/xlnx_axi_dwidth_converter_dm_master/xlnx_axi_dwidth_converter_dm_master.xci" \
      "xilinx/xlnx_processing_system7/xlnx_processing_system7.srcs/sources_1/ip/xlnx_processing_system7/xlnx_processing_system7.xci" \
      "xilinx/xlnx_blk_mem_gen/xlnx_blk_mem_gen.srcs/sources_1/ip/xlnx_blk_mem_gen/xlnx_blk_mem_gen.xci" \
      "xilinx/xlnx_clk_gen/xlnx_clk_gen.srcs/sources_1/ip/xlnx_clk_gen/xlnx_clk_gen.xci" \
}

set_property include_dirs { \
	"src/axi_sd_bridge/include" \
	"../../vendor/pulp-platform/common_cells/include" \
	"../../vendor/pulp-platform/axi/include" \
	"../../core/cache_subsystem/hpdcache/rtl/include" \
	"../register_interface/include" \
} [current_fileset]

source scripts/add_sources.tcl

set_property top cva6_zybo_z7_20 [current_fileset]

read_verilog -sv {src/zybo-z7-20.svh src/zybo-z7-20-ddr.svh ../../vendor/pulp-platform/common_cells/include/common_cells/registers.svh}
#set file "src/zybo-z7-20.svh"
if { $::env(PS7_DDR) == 1 } {
   set file "src/zybo-z7-20-ddr.svh"
} elseif {$::env(BRAM) == 1} {
   set file "src/zybo-z7-20.svh"
} else {
   puts "None of the values is matching"
}

set registers "../../vendor/pulp-platform/common_cells/include/common_cells/registers.svh"

set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file" "$registers"]]
set_property -dict { file_type {Verilog Header} is_global_include 1} -objects $file_obj

update_compile_order -fileset sources_1

add_files -fileset constrs_1 -norecurse constraints/$project.xdc

# synth_design -verilog_define PS7_DDR=$::env(PS7_DDR) -verilog_define BRAM=$::env(BRAM) -rtl -name rtl_1
if { $::env(PS7_DDR) == 1 } {
   synth_design -verilog_define PS7_DDR=PS7_DDR -rtl -name rtl_1
} elseif {$::env(BRAM) == 1} {
   synth_design -verilog_define BRAM=BRAM -rtl -name rtl_1
} else {
   puts "None of the values is matching"
}

set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING true [get_runs synth_1]

launch_runs synth_1
wait_on_run synth_1
open_run synth_1

exec mkdir -p reports_cva6_fpga_synth/
exec rm -rf reports_cva6_fpga_synth/*


check_timing -verbose                                                   -file reports_cva6_fpga_synth/$project.check_timing.rpt
report_timing -max_paths 100 -nworst 100 -delay_type max -sort_by slack -file reports_cva6_fpga_synth/$project.timing_WORST_100.rpt
report_timing -nworst 1 -delay_type max -sort_by group                  -file reports_cva6_fpga_synth/$project.timing.rpt
report_utilization -hierarchical                                        -file reports_cva6_fpga_synth/$project.utilization.rpt
report_cdc                                                              -file reports_cva6_fpga_synth/$project.cdc.rpt
report_clock_interaction                                                -file reports_cva6_fpga_synth/$project.clock_interaction.rpt

# set for RuntimeOptimized implementation
set_property "steps.place_design.args.directive" "RuntimeOptimized" [get_runs impl_1]
set_property "steps.route_design.args.directive" "RuntimeOptimized" [get_runs impl_1]

##create_clock -period $::env(CLK_PERIOD_NS) -name clk_i   [get_ports clk_i]

#set_property HD.CLK_SRC BUFGCTRL_X1Y2 [get_ports clk_i]


launch_runs impl_1
wait_on_run impl_1
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
open_run impl_1

# reports
exec mkdir -p reports_cva6_fpga_impl/
exec rm -rf reports_cva6_fpga_impl/*
check_timing                                                              -file reports_cva6_fpga_impl/${project}.check_timing.rpt
report_timing -max_paths 100 -nworst 100 -delay_type max -sort_by slack   -file reports_cva6_fpga_impl/${project}.timing_WORST_100.rpt
report_timing -nworst 1 -delay_type max -sort_by group                    -file reports_cva6_fpga_impl/${project}.timing.rpt
report_utilization -hierarchical                                          -file reports_cva6_fpga_impl/${project}.utilization.rpt
