open_hw_manager
connect_hw_server
current_hw_target [get_hw_targets -filter {NAME!~"localhost:3121/xilinx_tcf/Digilent/210249A85F9B"}]
open_hw_target
set_property PROGRAM.FILE {cva6_fpga.runs/impl_1/cva6_zybo_z7_20.bit} [get_hw_devices xc7z020_1]
current_hw_device [get_hw_devices xc7z020_1]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices xc7z020_1] 0]
set_property PROBES.FILE {} [get_hw_devices xc7z020_1]
set_property FULL_PROBES.FILE {} [get_hw_devices xc7z020_1]
set_property PROGRAM.FILE {cva6_fpga.runs/impl_1/cva6_zybo_z7_20.bit} [get_hw_devices xc7z020_1]
program_hw_devices [get_hw_devices xc7z020_1]
refresh_hw_device [lindex [get_hw_devices xc7z020_1] 0]

