set_global_assignment -entity "soc_system" -library "lib_soc_system" -name IP_TOOL_NAME "Qsys"
set_global_assignment -entity "soc_system" -library "lib_soc_system" -name IP_TOOL_VERSION "18.1"
set_global_assignment -entity "soc_system" -library "lib_soc_system" -name IP_TOOL_ENV "Qsys"
set_global_assignment -library "lib_soc_system" -name SPD_FILE [file join $::quartus(sip_path) "../soc_system.spd"]
set_global_assignment -library "lib_soc_system" -name MISC_FILE [file join $::quartus(sip_path) "../../soc_system.qsys"]

set_global_assignment -library "lib_soc_system" -name MISC_FILE [file join $::quartus(sip_path) "soc_system.v"]
set_global_assignment -library "lib_soc_system" -name MISC_FILE [file join $::quartus(sip_path) "submodules/soc_system_pll.vo"]
set_global_assignment -library "lib_soc_system" -name MISC_FILE [file join $::quartus(sip_path) "submodules/soc_system_ddr3.v"]
set_global_assignment -library "lib_soc_system" -name MISC_FILE [file join $::quartus(sip_path) "submodules/soc_system_ddr3_hps.v"]
set_global_assignment -library "lib_soc_system" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altera_address_span_extender.sv"]
