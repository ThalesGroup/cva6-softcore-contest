# Copyright (c) 2021 Thales.
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
# script Name:    run_cva6_power_analysis
# Project Name:   CVA6 softcore
# Language:       tcl
#
# Description:    Script to run power analysis of the application executed 
#                 on CV32A6 and generation of a power analysis report
#
# =========================================================================== #
# Revisions  :
# Date        Version  Author       Description
# 2021-11-03  0.1      S.Jacq       Created
# =========================================================================== #
set project cva6_sim
set power_report work-sim/power_routed_$::env(APP).txt

open_project $project

open_run impl_1


reset_switching_activity -all
read_saif {work-sim/routed.saif}

report_power -file $power_report -name {power_1}


