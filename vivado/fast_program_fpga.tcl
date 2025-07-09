set proj_dir [pwd]
set src_dir "$proj_dir/src"
set constr_dir "$proj_dir/constr"
set build_dir "$proj_dir/build"

set top [lindex $argv 0]
set jobs [lindex $argv 1]
if {$jobs eq ""} { set jobs 4 }

create_project lisp_machine $build_dir -part xc7a35tcpg236-1 -force
add_files [glob "$src_dir/*.sv"]
add_files -fileset constrs_1 [glob "$constr_dir/*.xdc"]
set_property top $top [current_fileset]

launch_runs synth_1 -jobs $jobs
wait_on_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs $jobs
wait_on_run impl_1

file copy -force $build_dir/lisp_machine.runs/impl_1/$top.bit $build_dir/$top.bit

# Program FPGA immediately after bitstream generation
open_hw_manager
connect_hw_server
open_hw_target
current_hw_device [lindex [get_hw_devices] 0]
refresh_hw_device -update_hw_probes false [current_hw_device]

set_property PROGRAM.FILE $build_dir/$top.bit [current_hw_device]
program_hw_devices [current_hw_device]
