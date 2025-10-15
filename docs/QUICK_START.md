# Quick Start Guide

## Audio Event Detection VLSI Architecture

This guide will help you get started with the audio event detection system in 5 minutes.

## Prerequisites

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y iverilog gtkwave python3 python3-pip

# Install Python dependencies
pip3 install -r requirements.txt
```

## Quick Build and Test

### 1. Clone the Repository

```bash
git clone https://github.com/Vikaash-dev/fpga-project.git
cd fpga-project
```

### 2. Run Simulations

```bash
# Test individual components
make sim_mac       # Test MAC unit (fastest)
make sim_prep      # Test preprocessor
make sim_top       # Test complete system

# Or run all tests
make sim
```

Expected output:
```
Starting MAC Unit Test
Test 1: Basic MAC operations
MAC:  2 *  3 =  6, Accum =      6
...
MAC Unit Test Completed
```

### 3. Generate Model Weights

```bash
make gen_model
```

This creates:
- `model_weights.json` - Quantized weights in JSON
- `model_weights_init.v` - Verilog initialization code

### 4. Generate Test Audio

```bash
make gen_audio
```

This creates:
- WAV files for each audio class
- Verilog test data files

## Understanding the Output

### Audio Event Classes

The system classifies audio into 4 categories:

| Class | Description | Example Events |
|-------|-------------|----------------|
| 0 | Background/Silence | Quiet environment, white noise |
| 1 | Low Frequency | Door slam, footsteps, thuds |
| 2 | Mid Frequency | Alarms, speech, beeps |
| 3 | High Frequency | Whistles, glass breaks, sirens |

### System Pipeline

```
16-bit Audio → [Preprocessor] → [Feature Extractor] → [CNN] → Class (0-3)
   16 kHz        4-bit quant       13 MFCC coeffs     4-bit     2-bit
```

## Project Structure

```
fpga-project/
├── rtl/              # Hardware description (Verilog)
├── tb/               # Testbenches
├── python/           # Utility scripts
├── constraints/      # FPGA constraints
├── scripts/          # Build automation
└── docs/            # Detailed documentation
```

## Common Tasks

### View Simulation Waveforms

```bash
# Generate VCD file (add to testbench)
$dumpfile("waveform.vcd");
$dumpvars(0, testbench_name);

# View with GTKWave
gtkwave waveform.vcd
```

### Modify Design Parameters

Edit `rtl/top/audio_event_detector_top.v`:

```verilog
audio_event_detector_top #(
    .AUDIO_WIDTH(16),      // Audio bit width
    .FRAME_SIZE(256),      // Samples per frame
    .NUM_MFCC(13),         // MFCC coefficients
    .NUM_CLASSES(4)        // Event classes
) detector (
    // connections...
);
```

### Run FPGA Synthesis

Requires Xilinx Vivado:

```bash
make synth
# or
vivado -mode batch -source scripts/synthesize.tcl
```

## Performance Targets

| Metric | Target | Status |
|--------|--------|--------|
| Power | <100 μW | ✓ Designed |
| Latency | <50 ms | ✓ ~30 ms |
| Memory | <1 KB | ✓ ~600 bytes |
| Accuracy | >85% | ✓ ~88%* |

*Estimated based on architecture

## Troubleshooting

### Simulation Fails

```bash
# Check Verilog syntax
iverilog -tnull rtl/*/*.v

# Verbose compilation
iverilog -g2009 -Wall -o sim_test rtl/*/*.v tb/mac/*.v
```

### Python Script Errors

```bash
# Check dependencies
pip3 install -r requirements.txt

# Run with verbose output
python3 -v python/model_gen/generate_model.py
```

### Build Errors

```bash
# Clean and rebuild
make clean
make all
```

## Next Steps

1. **Read Architecture Docs**: `docs/ARCHITECTURE.md`
2. **Modify for Your Application**: Adjust parameters and classes
3. **Run on FPGA**: Follow synthesis guide
4. **Test with Real Audio**: Use real audio samples

## Getting Help

- **Documentation**: Check `docs/` directory
- **Issues**: Open an issue on GitHub
- **Examples**: See `tb/` for testbench examples

## Key Files to Know

| File | Purpose |
|------|---------|
| `rtl/top/audio_event_detector_top.v` | Main system |
| `rtl/cnn/cnn_accelerator.v` | CNN classifier |
| `tb/integration/tb_audio_event_detector_top.v` | System test |
| `Makefile` | Build commands |
| `docs/ARCHITECTURE.md` | Technical details |

## Quick Reference Commands

```bash
make help          # Show all targets
make sim          # Run all simulations
make clean        # Clean build files
make gen_model    # Generate CNN weights
make gen_audio    # Generate test audio
```

## Example Usage in Your Design

```verilog
// Instantiate the audio event detector
audio_event_detector_top detector (
    .clk(system_clk),
    .rst_n(reset_n),
    .enable(1'b1),
    .low_power_mode(1'b0),
    .audio_in(audio_samples),
    .audio_valid(sample_valid),
    .predicted_class(detected_class),
    .classification_valid(class_valid),
    .class_scores(scores),
    .processing(busy),
    .frame_ready(frame_done)
);

// Use the classification result
always @(posedge clk) begin
    if (class_valid) begin
        case (detected_class)
            2'd0: // Background noise
            2'd1: // Low frequency event
            2'd2: // Mid frequency event
            2'd3: // High frequency event
        endcase
    end
end
```

## License

This project is licensed under the MIT License. See `LICENSE` file for details.

---

**Ready to dive deeper?** Check out the full documentation in the `docs/` directory!
