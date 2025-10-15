# Makefile for Audio Event Detector Project

# Tools
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave
PYTHON = python3

# Directories
RTL_DIR = rtl
TB_DIR = tb
BUILD_DIR = build
PYTHON_DIR = python

# Source files
MAC_SRC = $(RTL_DIR)/mac/audio_mac_4bit.v
PREP_SRC = $(RTL_DIR)/preprocessing/audio_preprocessor.v \
           $(RTL_DIR)/preprocessing/fft_mfcc_extractor.v
CNN_SRC = $(RTL_DIR)/cnn/cnn_accelerator.v
TOP_SRC = $(RTL_DIR)/top/audio_event_detector_top.v
ALL_SRC = $(MAC_SRC) $(PREP_SRC) $(CNN_SRC) $(TOP_SRC)

# Testbenches
TB_MAC = $(TB_DIR)/mac/tb_audio_mac_4bit.v
TB_PREP = $(TB_DIR)/preprocessing/tb_audio_preprocessor.v
TB_TOP = $(TB_DIR)/integration/tb_audio_event_detector_top.v

# Simulation outputs
SIM_MAC = $(BUILD_DIR)/sim_mac
SIM_PREP = $(BUILD_DIR)/sim_prep
SIM_TOP = $(BUILD_DIR)/sim_top

# VCD files
VCD_MAC = $(BUILD_DIR)/mac_wave.vcd
VCD_PREP = $(BUILD_DIR)/prep_wave.vcd
VCD_TOP = $(BUILD_DIR)/top_wave.vcd

.PHONY: all clean sim sim_mac sim_prep sim_top gen_model gen_audio help

all: $(BUILD_DIR) sim

help:
	@echo "Audio Event Detector - Makefile Targets"
	@echo "========================================"
	@echo "  make all        - Build directory and run all simulations"
	@echo "  make sim        - Run all testbench simulations"
	@echo "  make sim_mac    - Run MAC unit testbench"
	@echo "  make sim_prep   - Run preprocessor testbench"
	@echo "  make sim_top    - Run top-level integration testbench"
	@echo "  make gen_model  - Generate quantized CNN model weights"
	@echo "  make gen_audio  - Generate test audio samples"
	@echo "  make wave_mac   - View MAC unit waveforms (requires gtkwave)"
	@echo "  make wave_prep  - View preprocessor waveforms"
	@echo "  make wave_top   - View top-level waveforms"
	@echo "  make clean      - Clean build artifacts"
	@echo ""

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Compile and run MAC testbench
$(SIM_MAC): $(MAC_SRC) $(TB_MAC) | $(BUILD_DIR)
	@echo "Compiling MAC testbench..."
	$(IVERILOG) -g2009 -o $(SIM_MAC) $(MAC_SRC) $(TB_MAC)

sim_mac: $(SIM_MAC)
	@echo "Running MAC simulation..."
	cd $(BUILD_DIR) && $(VVP) ../$(SIM_MAC)

# Compile and run Preprocessor testbench
$(SIM_PREP): $(MAC_SRC) $(PREP_SRC) $(TB_PREP) | $(BUILD_DIR)
	@echo "Compiling Preprocessor testbench..."
	$(IVERILOG) -g2009 -o $(SIM_PREP) $(MAC_SRC) $(PREP_SRC) $(TB_PREP)

sim_prep: $(SIM_PREP)
	@echo "Running Preprocessor simulation..."
	cd $(BUILD_DIR) && $(VVP) ../$(SIM_PREP)

# Compile and run Top-level testbench
$(SIM_TOP): $(ALL_SRC) $(TB_TOP) | $(BUILD_DIR)
	@echo "Compiling Top-level testbench..."
	$(IVERILOG) -g2009 -o $(SIM_TOP) $(ALL_SRC) $(TB_TOP)

sim_top: $(SIM_TOP)
	@echo "Running Top-level simulation..."
	cd $(BUILD_DIR) && $(VVP) ../$(SIM_TOP)

# Run all simulations
sim: sim_mac sim_prep sim_top
	@echo ""
	@echo "All simulations completed!"
	@echo ""

# View waveforms
wave_mac: $(VCD_MAC)
	$(GTKWAVE) $(VCD_MAC) &

wave_prep: $(VCD_PREP)
	$(GTKWAVE) $(VCD_PREP) &

wave_top: $(VCD_TOP)
	$(GTKWAVE) $(VCD_TOP) &

# Generate model weights
gen_model:
	@echo "Generating quantized model weights..."
	cd $(PYTHON_DIR)/model_gen && $(PYTHON) generate_model.py

# Generate audio samples
gen_audio:
	@echo "Generating test audio samples..."
	cd $(PYTHON_DIR)/utils && $(PYTHON) generate_audio_samples.py

# Lint RTL code (if verilator is available)
lint:
	@echo "Linting RTL code..."
	@if command -v verilator >/dev/null 2>&1; then \
		verilator --lint-only -Wall $(ALL_SRC); \
	else \
		echo "Verilator not found. Skipping lint."; \
	fi

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)
	rm -f *.vcd
	rm -f *.out
	rm -f $(PYTHON_DIR)/model_gen/*.json
	rm -f $(PYTHON_DIR)/model_gen/*.v
	rm -f $(PYTHON_DIR)/utils/*.wav
	rm -f $(PYTHON_DIR)/utils/*.vh
	@echo "Clean complete!"

# Synthesize for FPGA (requires Vivado in PATH)
synth:
	@echo "Running FPGA synthesis..."
	@if command -v vivado >/dev/null 2>&1; then \
		vivado -mode batch -source scripts/synthesize.tcl; \
	else \
		echo "Vivado not found. Please install Xilinx Vivado."; \
	fi
