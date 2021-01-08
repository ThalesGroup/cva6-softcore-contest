# Copyright (c) 2020 Thales.
# 
# Copyright and related rights are licensed under the Apache
# License, Version 2.0 (the "License"); you may not use this file except in
# compliance with the License.  You may obtain a copy of the License at
# https://www.apache.org/licenses/LICENSE-2.0. Unless required by applicable law
# or agreed to in writing, software, hardware and materials distributed under
# this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.
#
# Author: Florian Zaruba, ETH Zurich
# Date: 03/19/2017
#
# Additional contributions by:
#         Sebastien Jacq - sjthales on github.com
#
# Description: Makefile for linting and testing Ariane.
#
# =========================================================================== #
# Revisions  :
# Date        Version  Author       Description
# 2020-10-06  0.1      S.Jacq       modification for CVA6 softcore
# =========================================================================== #

# questa library
library        ?= work
# verilator lib
ver-library    ?= work-ver
# library for DPI
dpi-library    ?= work-dpi
# Top level module to compile
top_level      ?= ariane_tb
# Maximum amount of cycles for a successful simulation run
max_cycles     ?= 1000000000
# Test case to run
test_case      ?= core_test
# QuestaSim Version
questa_version ?= ${QUESTASIM_VERSION}
# verilator version
#verilator      ?= verilator
# traget option
target-options ?=
# additional definess
defines        ?= WT_DCACHE
# test name for torture runs (binary name)
test-location  ?= output/test
# set to either nothing or -log
torture-logs   :=
# custom elf bin to run with sim or sim-verilator
elf-bin        ?= sw/app/benchmarks/coremark.riscv

# Application to simulate
APP            ?= coremark

# root path
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
root-dir := $(dir $(mkfile_path))

# software application path
app_path := $(root-dir)/sw/app


# board name for bitstream generation.
BOARD          := zybo-z7-20
XILINX_PART    := xc7z020clg400-1
XILINX_BOARD   := digilentinc.com:zybo-z7-20:part0:1.0
CLK_PERIOD_NS  := 25
BATCH_MODE ?= 1

# Sources
# Package files -> compile first
ariane_pkg := include/riscv_pkg.sv                          \
              src/riscv-dbg/src/dm_pkg.sv                   \
              include/ariane_pkg.sv                         \
              include/std_cache_pkg.sv                      \
              include/wt_cache_pkg.sv                       \
              src/axi/src/axi_pkg.sv                        \
              src/register_interface/src/reg_intf.sv        \
              src/register_interface/src/reg_intf_pkg.sv    \
              include/axi_intf.sv                           \
              tb/ariane_soc_pkg.sv                          \
              include/ariane_axi_pkg.sv                     \
              src/fpu/src/fpnew_pkg.sv                      \
              src/fpu/src/fpu_div_sqrt_mvp/hdl/defs_div_sqrt_mvp.sv
ariane_pkg := $(addprefix $(root-dir), $(ariane_pkg))

# utility modules
util := include/instr_tracer_pkg.sv                         \
        src/util/instr_tracer_if.sv                         \
        src/util/instr_tracer.sv                            \
        src/tech_cells_generic/src/cluster_clock_gating.sv  \
        tb/common/mock_uart.sv                              \
        src/util/sram.sv


util := $(addprefix $(root-dir), $(util))
# Test packages
test_pkg := $(wildcard tb/test/*/*sequence_pkg.sv*) \
			$(wildcard tb/test/*/*_pkg.sv*)

# DPI
dpi := $(patsubst tb/dpi/%.cc, ${dpi-library}/%.o, $(wildcard tb/dpi/*.cc))


dpi_hdr := $(wildcard tb/dpi/*.h)
dpi_hdr := $(addprefix $(root-dir), $(dpi_hdr))
CFLAGS := -I$(QUESTASIM_HOME)/include         \
          -I$(RISCV)/include                  \
          -std=c++11 -I../tb/dpi

# this list contains the standalone components
src :=  $(filter-out src/ariane_regfile.sv, $(wildcard src/*.sv))              \
        $(filter-out src/fpu/src/fpnew_pkg.sv, $(wildcard src/fpu/src/*.sv))   \
        $(filter-out src/fpu/src/fpu_div_sqrt_mvp/hdl/defs_div_sqrt_mvp.sv,    \
        $(wildcard src/fpu/src/fpu_div_sqrt_mvp/hdl/*.sv))                     \
        $(wildcard src/frontend/*.sv)                                          \
        $(filter-out src/cache_subsystem/std_no_dcache.sv,                     \
        $(wildcard src/cache_subsystem/*.sv))                                  \
        $(wildcard bootrom/*.sv)                                               \
        $(wildcard src/clint/*.sv)                                             \
        $(wildcard fpga/src/axi2apb/src/*.sv)                                  \
        $(wildcard fpga/src/apb_timer/*.sv)                                    \
        $(wildcard fpga/src/axi_slice/src/*.sv)                                \
        $(wildcard src/axi_node/src/*.sv)                                      \
        $(wildcard src/axi_riscv_atomics/src/*.sv)                             \
        $(wildcard src/axi_mem_if/src/*.sv)                                    \
        $(wildcard src/pmp/src/*.sv)                                           \
        src/rv_plic/rtl/rv_plic_target.sv                                      \
        src/rv_plic/rtl/rv_plic_gateway.sv                                     \
        src/rv_plic/rtl/plic_regmap.sv                                         \
        src/rv_plic/rtl/plic_top.sv                                            \
        src/riscv-dbg/src/dmi_cdc.sv                                           \
        src/riscv-dbg/src/dmi_jtag.sv                                          \
        src/riscv-dbg/src/dmi_jtag_tap.sv                                      \
        src/riscv-dbg/src/dm_csrs.sv                                           \
        src/riscv-dbg/src/dm_mem.sv                                            \
        src/riscv-dbg/src/dm_sba.sv                                            \
        src/riscv-dbg/src/dm_top.sv                                            \
        src/riscv-dbg/debug_rom/debug_rom.sv                                   \
        src/register_interface/src/apb_to_reg.sv                               \
        src/axi/src/axi_multicut.sv                                            \
        src/common_cells/src/deprecated/generic_fifo.sv                        \
        src/common_cells/src/deprecated/pulp_sync.sv                           \
        src/common_cells/src/deprecated/find_first_one.sv                      \
        src/common_cells/src/rstgen_bypass.sv                                  \
        src/common_cells/src/rstgen.sv                                         \
        src/common_cells/src/stream_mux.sv                                     \
        src/common_cells/src/stream_demux.sv                                   \
        src/common_cells/src/exp_backoff.sv                                    \
        src/util/axi_master_connect.sv                                         \
        src/util/axi_slave_connect.sv                                          \
        src/util/axi_master_connect_rev.sv                                     \
        src/util/axi_slave_connect_rev.sv                                      \
        src/axi/src/axi_cut.sv                                                 \
        src/axi/src/axi_join.sv                                                \
        src/axi/src/axi_delayer.sv                                             \
        src/axi/src/axi_to_axi_lite.sv                                         \
        src/fpga-support/rtl/SyncSpRamBeNx64.sv                                \
        src/common_cells/src/unread.sv                                         \
        src/common_cells/src/sync.sv                                           \
        src/common_cells/src/cdc_2phase.sv                                     \
        src/common_cells/src/spill_register.sv                                 \
        src/common_cells/src/sync_wedge.sv                                     \
        src/common_cells/src/edge_detect.sv                                    \
        src/common_cells/src/stream_arbiter.sv                                 \
        src/common_cells/src/stream_arbiter_flushable.sv                       \
        src/common_cells/src/deprecated/fifo_v1.sv                             \
        src/common_cells/src/deprecated/fifo_v2.sv                             \
        src/common_cells/src/fifo_v3.sv                                        \
        src/common_cells/src/lzc.sv                                            \
        src/common_cells/src/popcount.sv                                       \
        src/common_cells/src/rr_arb_tree.sv                                    \
        src/common_cells/src/deprecated/rrarbiter.sv                           \
        src/common_cells/src/stream_delay.sv                                   \
        src/common_cells/src/lfsr_8bit.sv                                      \
        src/common_cells/src/lfsr_16bit.sv                                     \
        src/common_cells/src/delta_counter.sv                                  \
        src/common_cells/src/counter.sv                                        \
        src/common_cells/src/shift_reg.sv                                      \
        src/tech_cells_generic/src/pulp_clock_gating.sv                        \
        src/tech_cells_generic/src/cluster_clock_inverter.sv                   \
        src/tech_cells_generic/src/pulp_clock_mux2.sv                          \
        tb/ariane_testharness.sv                                               \
        tb/ariane_peripherals.sv                                               \
        tb/common/uart.sv                                                      \
        tb/common/SimDTM.sv                                                    \
        tb/common/SimJTAG.sv

src := $(addprefix $(root-dir), $(src))

uart_src := $(wildcard fpga/src/apb_uart/src/*.vhd)
uart_src := $(addprefix $(root-dir), $(uart_src))

fpga_src :=  $(wildcard fpga/src/*.sv) $(wildcard fpga/src/bootrom/*.sv) $(wildcard fpga/src/ariane-ethernet/*.sv)
fpga_src := $(addprefix $(root-dir), $(fpga_src))

# look for testbenches
tbs := tb/jtag_pkg.sv tb/ariane_tb.sv tb/ariane_testharness.sv
# RISCV asm tests and benchmark setup (used for CI)
# there is a definesd test-list with selected CI tests
riscv-test-dir            := tmp/riscv-tests/build/isa/
riscv-benchmarks-dir      := tmp/riscv-tests/build/benchmarks/
riscv-benchmarks-list     := ci/riscv-benchmarks.list
riscv-benchmarks          := $(shell xargs printf '\n%s' < $(riscv-benchmarks-list) | cut -b 1-)

# Search here for include files (e.g.: non-standalone components)
incdir := src/common_cells/include/
# Compile and sim flags
compile_flag     += +cover=bcfst+/dut -incr -64 -nologo -quiet -suppress 13262 -permissive +define+$(defines)
uvm-flags        += +UVM_NO_RELNOTES +UVM_VERBOSITY=LOW
questa-flags     += -t 1ns -64 -coverage -classdebug $(gui-sim) $(QUESTASIM_FLAGS)
compile_flag_vhd += -64 -nologo -quiet -2008

# Iterate over all include directories and write them with +incdir+ prefixed
# +incdir+ works for Verilator and QuestaSim
list_incdir := $(foreach dir, ${incdir}, +incdir+$(dir))


# if defined, calls the questa targets in batch mode
ifdef batch-mode
	questa-flags += -c
	questa-cmd   := -do "coverage save -onexit tmp/$@.ucdb; run -a; quit -code [coverage attribute -name TESTSTATUS -concise]"
	questa-cmd   += -do " run -all;"
else
	questa-cmd   := -do "  run -all;"
endif


# Build the TB and module using QuestaSim
build: $(library) $(library)/.build-srcs $(library)/.build-tb
	# Optimize top level
	vopt$(questa_version) $(compile_flag) -work $(library)  $(top_level) -o $(top_level)_optimized +acc -check_synthesis

# src files
$(library)/.build-srcs: $(util) $(library)
	vlog$(questa_version) $(compile_flag) -work $(library) $(filter %.sv,$(ariane_pkg)) $(list_incdir) -suppress 2583
	# vcom$(questa_version) $(compile_flag_vhd) -work $(library) -pedanticerrors $(filter %.vhd,$(ariane_pkg))
	vlog$(questa_version) $(compile_flag) -work $(library) $(filter %.sv,$(util)) $(list_incdir) -suppress 2583
	# Suppress message that always_latch may not be checked thoroughly by QuestaSim.
	vcom$(questa_version) $(compile_flag_vhd) -work $(library) -pedanticerrors $(filter %.vhd,$(uart_src))
	# vcom$(questa_version) $(compile_flag_vhd) -work $(library) -pedanticerrors $(filter %.vhd,$(src))
	vlog$(questa_version) $(compile_flag) -work $(library) -pedanticerrors $(filter %.sv,$(src)) $(list_incdir) -suppress 2583
	touch $(library)/.build-srcs

# build TBs
$(library)/.build-tb:
	# Compile top level
	vlog$(questa_version) $(compile_flag) -sv $(tbs) -work $(library)
	touch $(library)/.build-tb

$(library):
	vlib${questa_version} $(library)


# target used to run simulation, make sim APP=<software application to run on CVA6>
# if you want to run in batch mode, use make <testname> batch-mode=1
sim: build benchmark
	echo $(riscv-benchmarks)
	vsim${questa_version} +permissive $(questa-flags) $(questa-cmd) -lib $(library) +MAX_CYCLES=$(max_cycles) +UVM_TESTNAME=$(test_case) \
	 $(uvm-flags) $(QUESTASIM_FLAGS)  \
	${top_level}_optimized +permissive-off +binary_mem=$(app_path)/$(APP).mem | tee sim.log


run-benchmarks: $(riscv-benchmarks)
	$(MAKE) check-benchmarks

check-benchmarks:
	ci/check-tests.sh tmp/riscv-benchmarks- $(shell wc -l $(riscv-benchmarks-list) | awk -F " " '{ print $1 }')

benchmark:
	cd sw/app && make $(APP).mem

fpga_filter := $(addprefix $(root-dir), bootrom/bootrom.sv)
fpga_filter += $(addprefix $(root-dir), include/instr_tracer_pkg.sv)
fpga_filter += $(addprefix $(root-dir), src/util/ex_trace_item.sv)
fpga_filter += $(addprefix $(root-dir), src/util/instr_trace_item.sv)
fpga_filter += $(addprefix $(root-dir), src/util/instr_tracer_if.sv)
fpga_filter += $(addprefix $(root-dir), src/util/instr_tracer.sv)

# target rused to run synthesis and place and route in out of context mode
# make cva6_ooc CLK_PERIOD_NS=<period of the CVA6 architecture>
cva6_ooc: $(ariane_pkg) $(util) $(src) $(fpga_src)
	@echo "Generate sources for synthesis"
	@echo read_verilog -sv {$(ariane_pkg)} >> fpga/scripts/add_sources.tcl
	@echo read_verilog -sv {$(filter-out $(fpga_filter), $(util))}     >> fpga/scripts/add_sources.tcl
	@echo read_verilog -sv {$(filter-out $(fpga_filter), $(src))} 	   >> fpga/scripts/add_sources.tcl
	@echo read_verilog -sv {$(fpga_src)}   >> fpga/scripts/add_sources.tcl
	cd fpga && make cva6_ooc BOARD=$(BOARD) XILINX_PART=$(XILINX_PART) XILINX_BOARD=$(XILINX_BOARD) CLK_PERIOD_NS=$(CLK_PERIOD_NS) BATCH_MODE=$(BATCH_MODE)

.PHONY:  cva6_ooc cva6_fpga program_cva6_fpga

cva6_fpga: $(ariane_pkg) $(util) $(src) $(fpga_src) $(uart_src)
	@echo "[FPGA] Generate sources"
	@echo read_vhdl        {$(uart_src)}    > fpga/scripts/add_sources.tcl
	@echo read_verilog -sv {$(ariane_pkg)} >> fpga/scripts/add_sources.tcl
	@echo read_verilog -sv {$(filter-out $(fpga_filter), $(util))}     >> fpga/scripts/add_sources.tcl
	@echo read_verilog -sv {$(filter-out $(fpga_filter), $(src))} 	   >> fpga/scripts/add_sources.tcl
	@echo read_verilog -sv {$(fpga_src)}   >> fpga/scripts/add_sources.tcl
	@echo "[FPGA] Generate Bitstream"
	cd fpga && make cva6_fpga BRAM=1 PS7_DDR=0 BOARD=$(BOARD) XILINX_PART=$(XILINX_PART) XILINX_BOARD=$(XILINX_BOARD) CLK_PERIOD_NS=$(CLK_PERIOD_NS) BATCH_MODE=$(BATCH_MODE)

cva6_fpga_ddr: $(ariane_pkg) $(util) $(src) $(fpga_src) $(uart_src)
	@echo "[FPGA] Generate sources"
	@echo read_vhdl        {$(uart_src)}    > fpga/scripts/add_sources.tcl
	@echo read_verilog -sv {$(ariane_pkg)} >> fpga/scripts/add_sources.tcl
	@echo read_verilog -sv {$(filter-out $(fpga_filter), $(util))}     >> fpga/scripts/add_sources.tcl
	@echo read_verilog -sv {$(filter-out $(fpga_filter), $(src))} 	   >> fpga/scripts/add_sources.tcl
	@echo read_verilog -sv {$(fpga_src)}   >> fpga/scripts/add_sources.tcl
	@echo "[FPGA] Generate Bitstream"
	cd fpga && make cva6_fpga PS7_DDR=1 BRAM=0 XILINX_PART=$(XILINX_PART) XILINX_BOARD=$(XILINX_BOARD) CLK_PERIOD_NS=$(CLK_PERIOD_NS) BATCH_MODE=$(BATCH_MODE)


program_cva6_fpga: 
	@echo "[FPGA] Program FPGA"
	cd fpga && make program_cva6_fpga BOARD=$(BOARD) XILINX_PART=$(XILINX_PART) XILINX_BOARD=$(XILINX_BOARD) CLK_PERIOD_NS=$(CLK_PERIOD_NS) BATCH_MODE=$(BATCH_MODE)


clean:
	rm -rf $(riscv-torture-dir)/output/test*
	rm -rf $(library)/ $(dpi-library)/ $(ver-library)/
	rm -f tmp/*.ucdb tmp/*.log *.wlf *vstf wlft* *.ucdb
	cd sw/app && make clean
	cd fpga && make clean

.PHONY:
	build sim benchmark clean   \
	$(riscv-benchmarks)          \
	check-benchmarks                 
                        
