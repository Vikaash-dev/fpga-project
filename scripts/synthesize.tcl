# Vivado TCL Script for FPGA Synthesis
# Audio Event Detector - Xilinx Artix-7 Target

# Set project parameters
set project_name "audio_event_detector"
set top_module "audio_event_detector_top"
set part "xc7a35tcpg236-1"
set build_dir "build"

# Create build directory
file mkdir $build_dir

# Create project
puts "Creating project: $project_name"
create_project $project_name $build_dir/$project_name -part $part -force

# Add RTL source files
puts "Adding RTL source files..."
add_files [glob rtl/mac/*.v]
add_files [glob rtl/cnn/*.v]
add_files [glob rtl/preprocessing/*.v]
add_files [glob rtl/top/*.v]

# Add constraints
puts "Adding constraints..."
add_files -fileset constrs_1 constraints/audio_detector.xdc

# Set top module
set_property top $top_module [current_fileset]

# Update compile order
update_compile_order -fileset sources_1

# Set synthesis options
puts "Configuring synthesis settings..."
set_property strategy "Flow_PerfOptimized_high" [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE AlternateRoutability [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING true [get_runs synth_1]

# Power optimization
set_property STEPS.SYNTH_DESIGN.ARGS.FANOUT_LIMIT 400 [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS true [get_runs synth_1]

# Run synthesis
puts "Running synthesis..."
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Check synthesis status
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "ERROR: Synthesis failed!"
    exit 1
}

puts "Synthesis completed successfully"

# Open synthesized design
open_run synth_1

# Generate synthesis reports
puts "Generating synthesis reports..."
report_utilization -file $build_dir/synth_utilization.txt
report_timing_summary -file $build_dir/synth_timing.txt
report_power -file $build_dir/synth_power.txt

# Set implementation options
puts "Configuring implementation settings..."
set_property strategy "Performance_ExplorePostRoutePhysOpt" [get_runs impl_1]

# Run implementation
puts "Running implementation..."
launch_runs impl_1 -jobs 4
wait_on_run impl_1

# Check implementation status
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "ERROR: Implementation failed!"
    exit 1
}

puts "Implementation completed successfully"

# Open implemented design
open_run impl_1

# Generate implementation reports
puts "Generating implementation reports..."
report_utilization -hierarchical -file $build_dir/impl_utilization_hierarchical.txt
report_utilization -file $build_dir/impl_utilization.txt
report_timing_summary -max_paths 10 -file $build_dir/impl_timing.txt
report_timing -sort_by group -max_paths 10 -path_type summary -file $build_dir/impl_timing_paths.txt
report_clock_utilization -file $build_dir/impl_clock_util.txt
report_power -file $build_dir/impl_power.txt
report_drc -file $build_dir/impl_drc.txt

# Generate bitstream
puts "Generating bitstream..."
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# Print summary
puts "\n=========================================="
puts "FPGA Synthesis and Implementation Complete"
puts "=========================================="
puts "Project: $project_name"
puts "Part: $part"
puts "Top Module: $top_module"
puts ""
puts "Reports generated in: $build_dir/"
puts "  - synth_utilization.txt"
puts "  - synth_timing.txt"
puts "  - synth_power.txt"
puts "  - impl_utilization.txt"
puts "  - impl_timing.txt"
puts "  - impl_power.txt"
puts ""

# Print key metrics
set util [report_utilization -return_string]
puts "Resource Utilization Summary:"
puts $util
puts ""

set power [report_power -return_string]
puts "Power Summary:"
puts $power
puts ""

puts "Bitstream location: $build_dir/$project_name/$project_name.runs/impl_1/${top_module}.bit"
puts "=========================================="

# Close project
close_project

puts "Done!"
exit 0
