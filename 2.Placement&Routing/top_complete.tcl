#!/usr/bin/openroad
# ===================================================================
# OpenROAD Full Flow - top_complete (Fix Net Types Early)
# ===================================================================

puts "   >>> Starting OpenROAD Full Flow: top_complete <<<"

# --- 1. Thiết lập PDK ---
set ciel_version "0fe599b2afb6708d281543108caf8310912f54af"
set ::env(PDK_ROOT) "/openlane/pdks/$ciel_version"
set ::env(PDK) "sky130A"

read_lef     "/openlane/pdks/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
read_lef     "/openlane/pdks/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"
read_liberty "/openlane/pdks/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

# --- 2. Load Design ---
read_verilog top_complete_synth.v
link_design top_complete

# --- 2.5 FIX NET TYPES NGAY SAU KHI LOAD ---
puts "\n--- Fixing Power Nets IMMEDIATELY after loading ---"
set db_block [[[ord::get_db] getChip] getBlock]

# Liệt kê tất cả nets và fix
set all_nets [$db_block getNets]
foreach net $all_nets {
    set net_name [$net getName]
    set net_type [$net getSigType]
    
    if {[string match "*one_*" $net_name] || [string match "*zero_*" $net_name]} {
        puts "Fixing: $net_name (was $net_type)"
        $net setSigType SIGNAL
    }
}

# --- 3. Floorplan ---
create_clock -name clk -period 25 [get_ports clk]
initialize_floorplan -die_area {0 0 310 310} -core_area {10 10 300 300} -site unithd

make_tracks li1  -x_offset 0.17 -x_pitch 0.46 -y_offset 0.17 -y_pitch 0.34
make_tracks met1 -x_offset 0.17 -x_pitch 0.46 -y_offset 0.17 -y_pitch 0.34
make_tracks met2 -x_offset 0.23 -x_pitch 0.46 -y_offset 0.23 -y_pitch 0.46
make_tracks met3 -x_offset 0.34 -x_pitch 0.68 -y_offset 0.34 -y_pitch 0.68
make_tracks met4 -x_offset 0.46 -x_pitch 0.92 -y_offset 0.46 -y_pitch 0.92

# --- 4. Pins & Placement ---
place_pins -hor_layers {met3} -ver_layers {met4} -corner_avoidance 15 -min_distance 3
tapcell -distance 14 -tapcell_master sky130_fd_sc_hd__tapvpwrvgnd_1
global_placement -density 0.51
set_placement_padding -global -left 2 -right 2
detailed_placement

# --- 5. CTS ---
set_wire_rc -layer met2
clock_tree_synthesis -root_buf sky130_fd_sc_hd__clkbuf_1 -buf_list sky130_fd_sc_hd__clkbuf_1
detailed_placement

# --- 6. Routing ---
puts "\n--- Starting Routing ---"
set_global_routing_layer_adjustment li1 0.2
set_global_routing_layer_adjustment met1 0.3
set_global_routing_layer_adjustment met2 0.5
set_global_routing_layer_adjustment met3 1.0
set_global_routing_layer_adjustment met4 1.5

global_route
detailed_route -output_drc drc_report.rpt -verbose 1

# --- 7. Reports ---
puts "\n=== FINAL REPORTS ==="
report_checks -path_delay min_max
report_design_area
report_power

write_db  top_complete_final.odb
write_def top_complete_final.def
write_verilog top_complete_final.v

puts "✓ Design saved"
exit
