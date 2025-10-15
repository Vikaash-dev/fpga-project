# FPGA Constraints for Audio Event Detector
# Target: Xilinx 7-series FPGA (can be adapted for other families)
# Power optimization constraints for <100 μW target

# Clock constraints
create_clock -period 10.000 -name sys_clk [get_ports clk]
set_input_delay -clock sys_clk 2.0 [all_inputs]
set_output_delay -clock sys_clk 2.0 [all_outputs]

# Clock uncertainty
set_clock_uncertainty 0.5 [get_clocks sys_clk]

# Power optimization constraints
set_property POWER_OPT_DESIGN_EFFORT HIGH [current_design]

# Enable clock gating
set_property CLOCK_GATING_STYLE AUTOMATIC [current_design]

# I/O constraints (adjust for specific FPGA board)
# Clock input
set_property PACKAGE_PIN E3 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

# Reset (active low)
set_property PACKAGE_PIN C12 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

# Enable signal
set_property PACKAGE_PIN F16 [get_ports enable]
set_property IOSTANDARD LVCMOS33 [get_ports enable]

# Audio input interface (16-bit parallel or from ADC)
# These would be connected to an ADC chip in real implementation
set_property IOSTANDARD LVCMOS33 [get_ports audio_in[*]]

# Classification output
set_property IOSTANDARD LVCMOS33 [get_ports predicted_class[*]]
set_property IOSTANDARD LVCMOS33 [get_ports classification_valid]

# Status LEDs
set_property IOSTANDARD LVCMOS33 [get_ports processing]
set_property IOSTANDARD LVCMOS33 [get_ports frame_ready]

# Timing exceptions
set_false_path -from [get_ports rst_n]
set_false_path -from [get_ports enable]

# Multi-cycle paths for slow audio processing
set_multicycle_path 4 -setup -from [get_pins -hier *audio_preprocessor*] -to [get_pins -hier *feature_extractor*]
set_multicycle_path 3 -hold -from [get_pins -hier *audio_preprocessor*] -to [get_pins -hier *feature_extractor*]

set_multicycle_path 8 -setup -from [get_pins -hier *feature_extractor*] -to [get_pins -hier *cnn*]
set_multicycle_path 7 -hold -from [get_pins -hier *feature_extractor*] -to [get_pins -hier *cnn*]

# Power analysis constraints
set_operating_conditions -voltage 1.0 -process typical -temperature 25

# Area optimization for power reduction
set_property OPTIMIZATION_EFFORT HIGH [current_design]
