#!/bin/bash
# Synthesis and simulation script for Audio Event Detector

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Audio Event Detector - Build Script"
echo "=========================================="

# Check for required tools
check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}Error: $1 not found${NC}"
        echo "Please install $1 or add it to PATH"
        return 1
    fi
    echo -e "${GREEN}Found: $1${NC}"
    return 0
}

# Function to run simulation
run_simulation() {
    local testbench=$1
    local module_name=$2
    
    echo -e "\n${YELLOW}Running simulation: $module_name${NC}"
    
    # Using Icarus Verilog for open-source simulation
    iverilog -g2009 -o sim_$module_name \
        -I../rtl/mac \
        -I../rtl/cnn \
        -I../rtl/preprocessing \
        -I../rtl/top \
        ../rtl/mac/*.v \
        ../rtl/cnn/*.v \
        ../rtl/preprocessing/*.v \
        ../rtl/top/*.v \
        $testbench
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Compilation successful${NC}"
        vvp sim_$module_name
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Simulation completed${NC}"
        else
            echo -e "${RED}Simulation failed${NC}"
            return 1
        fi
    else
        echo -e "${RED}Compilation failed${NC}"
        return 1
    fi
}

# Main script
cd "$(dirname "$0")"

# Check for simulation tools
echo -e "\n${YELLOW}Checking for required tools...${NC}"
check_tool iverilog
check_tool vvp

# Run simulations
echo -e "\n${YELLOW}Running testbenches...${NC}"

# MAC Unit test
run_simulation "../tb/mac/tb_audio_mac_4bit.v" "mac_unit"

# Preprocessor test
run_simulation "../tb/preprocessing/tb_audio_preprocessor.v" "preprocessor"

# Integration test
run_simulation "../tb/integration/tb_audio_event_detector_top.v" "integration"

echo -e "\n=========================================="
echo -e "${GREEN}Build and simulation completed!${NC}"
echo "=========================================="

# Generate waveforms (if gtkwave is available)
if command -v gtkwave &> /dev/null; then
    echo -e "\n${YELLOW}Note: You can view waveforms with gtkwave${NC}"
    echo "Example: gtkwave dump.vcd"
fi

# Cleanup
echo -e "\n${YELLOW}Cleaning up temporary files...${NC}"
rm -f sim_*
rm -f *.vcd

exit 0
