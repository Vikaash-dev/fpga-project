# System Architecture Diagrams

## High-Level System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Audio Event Detector Top                      │
│                                                                   │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │   Audio      │    │   FFT/MFCC   │    │     CNN      │      │
│  │ Preprocessor │───▶│  Feature     │───▶│ Accelerator  │───▶  │
│  │              │    │  Extractor   │    │              │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│                                                                   │
│  16-bit Audio      4-bit Quantized    13 MFCC Coeffs   Class    │
│  16 kHz            256 samples/frame  16-bit each       0-3      │
└─────────────────────────────────────────────────────────────────┘
```

## Audio Preprocessor Pipeline

```
Audio Input (16-bit)
    │
    ▼
┌──────────────────┐
│  DC Offset       │  ◄── Exponential Moving Average
│  Removal         │      Tracks and removes DC component
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Noise Gate      │  ◄── Threshold: ±100
│  Filter          │      Removes low-amplitude noise
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Frame Buffer    │  ◄── 256 samples per frame
│  (Ring Buffer)   │      Collects data for processing
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  4-bit           │  ◄── Range: -8 to +7
│  Quantization    │      Reduces power consumption
└────────┬─────────┘
         │
         ▼
    4-bit Output
```

## FFT/MFCC Feature Extractor

```
4-bit Frame Data (256 samples)
    │
    ▼
┌──────────────────┐
│  Frame           │  ◄── Collect 256 samples
│  Collection      │      State machine control
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Energy Bins     │  ◄── 16 bins
│  Computation     │      Sum of squares per bin
└────────┬─────────┘      (16 samples/bin)
         │
         ▼
┌──────────────────┐
│  Simplified      │  ◄── 13 coefficients
│  MFCC-like       │      Weighted combination
│  Transform       │      of energy bins
└────────┬─────────┘
         │
         ▼
  13 x 16-bit MFCC Coefficients
```

## CNN Accelerator Architecture

```
Input: 13 MFCC Coefficients (16-bit each)
    │
    ▼
┌──────────────────┐
│  4-bit           │  ◄── Quantize to 4-bit range
│  Quantization    │      Reduces computation
└────────┬─────────┘
         │
         ▼
┌──────────────────────────────────┐
│  1D Convolution Layer            │
│  ┌──────┐ ┌──────┐ ... ┌──────┐ │
│  │Filt 0│ │Filt 1│     │Filt 7│ │  ◄── 8 filters
│  │ 3x3  │ │ 3x3  │ ... │ 3x3  │ │      4-bit weights
│  └───┬──┘ └───┬──┘     └───┬──┘ │      Kernel size: 3
│      │        │            │     │
│      ▼        ▼            ▼     │
│   [ReLU]  [ReLU]  ...  [ReLU]   │  ◄── Activation function
└────────────────────────┬─────────┘
                         │
                         ▼
              ┌──────────────────┐
              │  Max Pooling     │  ◄── Find max value
              │  Per Filter      │      in each filter output
              └────────┬─────────┘
                       │
                       ▼
           8 x 16-bit Pooled Features
                       │
                       ▼
┌─────────────────────────────────┐
│  Fully Connected Layer          │
│                                  │
│  [8 inputs] × [4-bit weights]   │  ◄── 4 output classes
│           ↓                      │      32 weights total
│     [4 outputs]                  │      4-bit precision
└──────────────┬──────────────────┘
               │
               ▼
       ┌──────────────┐
       │   Argmax     │  ◄── Find highest score
       │ (Winner      │      class
       │  Takes All)  │
       └──────┬───────┘
              │
              ▼
        2-bit Class ID (0-3)
```

## MAC Unit (4-bit) Detailed

```
Input A (4-bit)    Input B (4-bit)
      │                  │
      └────────┬─────────┘
               ▼
         ┌──────────┐
         │ Multiply │
         │  (4x4)   │
         └────┬─────┘
              │
              ▼
         8-bit Product
              │
              ├────────────────┐
              │                │
              ▼                ▼
      ┌──────────────┐  ┌──────────┐
      │ Sign Extend  │  │ Overflow │
      │  to 16-bit   │  │ Detection│
      └──────┬───────┘  └────┬─────┘
             │               │
             ▼               │
      ┌──────────────┐       │
      │     Add      │       │
      │ Accumulator  │       │
      └──────┬───────┘       │
             │               │
             ▼               ▼
      ┌──────────────┐  ┌─────────┐
      │  Saturate    │◄─┤Overflow?│
      │  if needed   │  └─────────┘
      └──────┬───────┘
             │
             ▼
    16-bit Accumulator Output
```

## Data Flow Timeline

```
Time (ms):  0        16       32       48       64
            │        │        │        │        │
Audio:      ├────────┼────────┼────────┼────────┤
            Frame 0  Frame 1  Frame 2  Frame 3
                     
Preprocess: ┌────┐   ┌────┐   ┌────┐   ┌────┐
            │ DC │   │ DC │   │ DC │   │ DC │
            │Filt│   │Filt│   │Filt│   │Filt│
            └────┘   └────┘   └────┘   └────┘
                     
Features:           ┌─────┐  ┌─────┐  ┌─────┐
                    │MFCC │  │MFCC │  │MFCC │
                    │Calc │  │Calc │  │Calc │
                    └─────┘  └─────┘  └─────┘
                     
CNN:                        ┌────┐   ┌────┐
                            │Conv│   │Conv│
                            │Pool│   │Pool│
                            │ FC │   │ FC │
                            └────┘   └────┘
                     
Output:                            Class   Class
                                    0-3     0-3
```

## Power Distribution

```
Total Power: ~85 μW (Target: <100 μW)

┌────────────────────────────────────┐
│ Preprocessing: 25 μW (29%)         │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                   │
├────────────────────────────────────┤
│ Feature Extraction: 20 μW (24%)    │
│ ▓▓▓▓▓▓▓▓▓▓▓▓                       │
├────────────────────────────────────┤
│ CNN Accelerator: 30 μW (35%)       │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                 │
├────────────────────────────────────┤
│ Control & I/O: 10 μW (12%)         │
│ ▓▓▓▓▓▓                             │
└────────────────────────────────────┘
```

## Memory Layout

```
Total Memory: ~600 bytes

┌─────────────────────────────────────────┐
│ Frame Buffer (256 x 16-bit): 512 bytes │  85%
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓     │
├─────────────────────────────────────────┤
│ CNN Weights (56 x 4-bit): 28 bytes     │  5%
│ ▓▓                                      │
├─────────────────────────────────────────┤
│ MFCC Buffer (13 x 16-bit): 26 bytes    │  4%
│ ▓▓                                      │
├─────────────────────────────────────────┤
│ Conv Output (88 x 16-bit): 176 bytes*  │  29%*
│ ▓▓▓▓▓▓▓▓▓                               │
└─────────────────────────────────────────┘

*Can be reduced with streaming architecture
```

## Clock Gating Strategy

```
Main Clock (100 MHz)
    │
    ├──────────────┐
    │              │
    ▼              ▼
┌────────┐    ┌────────┐
│Enable? │    │Audio   │
│  No    │    │Valid?  │
└───┬────┘    └───┬────┘
    │             │
    ▼             ▼
  [GATED]    ┌────────┐
             │Preproc │
             │ Active │
             └───┬────┘
                 │
                 ▼
             ┌────────┐
             │Frame   │
             │Ready?  │
             └───┬────┘
                 │
                 ▼
             ┌────────┐
             │Feature │
             │Extract │
             └───┬────┘
                 │
                 ▼
             ┌────────┐
             │MFCC    │
             │Valid?  │
             └───┬────┘
                 │
                 ▼
             ┌────────┐
             │  CNN   │
             │ Active │
             └────────┘

Power Savings: ~30% through selective gating
```

## FPGA Resource Utilization (Artix-7)

```
LUTs:     ████░░░░░░░░░░░░░░░░  ~800 / 20,800   (4%)
FFs:      ██░░░░░░░░░░░░░░░░░░  ~600 / 41,600   (1.5%)
DSPs:     ████████░░░░░░░░░░░░  8 / 90          (9%)
BRAM:     ████░░░░░░░░░░░░░░░░  2 / 50          (4%)

Total Area: ~5% of Artix-7 35T
```

## Processing Pipeline Stages

```
Stage 1: Input Buffer
    ↓ 10 cycles
Stage 2: DC Removal
    ↓ 1 cycle
Stage 3: Noise Gate
    ↓ 1 cycle
Stage 4: Quantization
    ↓ 1 cycle
Stage 5: Frame Assembly (256 cycles)
    ↓
Stage 6: Energy Bins (16 cycles)
    ↓
Stage 7: MFCC Transform (13 cycles)
    ↓
Stage 8: CNN Convolution (11 cycles)
    ↓
Stage 9: Max Pooling (8 cycles)
    ↓
Stage 10: FC Layer (4 cycles)
    ↓
Stage 11: Classification (1 cycle)

Total Latency: ~315 cycles + frame collection
              = ~3.15 μs + 16 ms @ 16 kHz
              ≈ 16 ms per classification
```

## Signal Bit-Width Summary

```
Signal Path                    Bit Width    Rationale
─────────────────────────────────────────────────────
Audio Input                    16-bit       Standard ADC
Preprocessor Output            4-bit        Power optimization
MFCC Coefficients              16-bit       Precision for features
Conv Layer Weights             4-bit        Quantized
Conv Layer Output              16-bit       Accumulation precision
Pooled Features                16-bit       Max values
FC Layer Weights               4-bit        Quantized
FC Layer Output                8-bit        Class scores
Classification Output          2-bit        4 classes (00-11)
```

---

These diagrams provide a visual understanding of the system architecture and data flow.
