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
# script Name:    run_cva6_ooc
# Project Name:   CVA6 softcore
# Language:       tcl
#
# Description:    Script to synthesize/place and route CVA6 architecture
#                 in out of context mode
#
# =========================================================================== #
# Revisions  :
# Date        Version  Author       Description
# 2020-10-06  0.1      S.Jacq       Created
# =========================================================================== #
set project cva6_ooc

create_project $project . -force -part $::env(XILINX_PART)
set_property board_part $::env(XILINX_BOARD) [current_project]



# set number of threads to 8 (maximum, unfortunately)
set_param general.maxThreads 8

set_msg_config -id {[Synth 8-5858]} -new_severity "info"

set_msg_config -id {[Synth 8-4480]} -limit 1000

set_property include_dirs { \
	"src/axi_sd_bridge/include" \
	"../../vendor/pulp-platform/common_cells/include" \
	"../../vendor/pulp-platform/axi/include" \
	"../../core/cache_subsystem/hpdcache/rtl/include" \
	"../register_interface/include" \
} [current_fileset]

source scripts/add_sources.tcl

set_property top cva6 [current_fileset]

read_verilog -sv {src/zybo-z7-20.svh ../../vendor/pulp-platform/common_cells/include/common_cells/registers.svh}
set file "src/zybo-z7-20.svh"
set registers "../../vendor/pulp-platform/common_cells/include/common_cells/registers.svh"

set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file" "$registers"]]
set_property -dict { file_type {Verilog Header} is_global_include 1} -objects $file_obj

update_compile_order -fileset sources_1


set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING true [get_runs synth_1]

launch_runs synth_1
wait_on_run synth_1
open_run synth_1

exec mkdir -p reports_cva6_ooc_synth/
exec rm -rf reports_cva6_ooc_synth/*


check_timing -verbose                                                   -file reports_cva6_ooc_synth/$project.check_timing.rpt
report_timing -max_paths 100 -nworst 100 -delay_type max -sort_by slack -file reports_cva6_ooc_synth/$project.timing_WORST_100.rpt
report_timing -nworst 1 -delay_type max -sort_by group                  -file reports_cva6_ooc_synth/$project.timing.rpt
report_utilization -hierarchical                                        -file reports_cva6_ooc_synth/$project.utilization.rpt
report_cdc                                                              -file reports_cva6_ooc_synth/$project.cdc.rpt
report_clock_interaction                                                -file reports_cva6_ooc_synth/$project.clock_interaction.rpt

# set for RuntimeOptimized implementation
set_property "steps.place_design.args.directive" "RuntimeOptimized" [get_runs impl_1]
set_property "steps.route_design.args.directive" "RuntimeOptimized" [get_runs impl_1]

create_clock -period $::env(CLK_PERIOD_NS) -name clk_i   [get_ports clk_i]

#set_property HD.CLK_SRC BUFGCTRL_X1Y2 [get_ports clk_i]


launch_runs impl_1
wait_on_run impl_1

# reports
exec mkdir -p reports_cva6_ooc_impl/
exec rm -rf reports_cva6_ooc_impl/*
check_timing                                                              -file reports_cva6_ooc_impl/${project}.check_timing.rpt
report_timing -max_paths 100 -nworst 100 -delay_type max -sort_by slack   -file reports_cva6_ooc_impl/${project}.timing_WORST_100.rpt
report_timing -nworst 1 -delay_type max -sort_by group                    -file reports_cva6_ooc_impl/${project}.timing.rpt
report_utilization -hierarchical                                          -file reports_cva6_ooc_impl/${project}.utilization.rpt
