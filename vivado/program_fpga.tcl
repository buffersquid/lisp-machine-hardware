set proj_dir [pwd]
set src_dir "$proj_dir/src"
set constr_dir "$proj_dir/constr"
set build_dir "$proj_dir/build"

open_hw_manager
connect_hw_server
open_hw_target
current_hw_device [lindex [get_hw_devices] 0]
refresh_hw_device -update_hw_probes false [current_hw_device]

set_property PROGRAM.FILE "build/top.bit" [current_hw_device]
program_hw_devices [current_hw_device]
