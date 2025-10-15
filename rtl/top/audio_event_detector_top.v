/*
 * Audio Event Detection System - Top Level
 * Integrates preprocessing, feature extraction, and CNN classification
 * 
 * Target: <100 μW power consumption
 * Uses clock gating and power optimization techniques
 */

module audio_event_detector_top #(
    parameter AUDIO_WIDTH = 16,
    parameter FRAME_SIZE = 256,
    parameter NUM_MFCC = 13,
    parameter NUM_CLASSES = 4
)(
    // Clock and reset
    input wire clk,
    input wire rst_n,
    
    // System control
    input wire enable,
    input wire low_power_mode,
    
    // Audio input interface
    input wire signed [AUDIO_WIDTH-1:0] audio_in,
    input wire audio_valid,
    
    // Classification output
    output wire [1:0] predicted_class,
    output wire classification_valid,
    output wire [NUM_CLASSES-1:0] class_scores,
    
    // Status signals
    output wire processing,
    output wire frame_ready
);

    // Internal signals
    wire signed [3:0] preprocessed_audio;
    wire preprocessed_valid;
    wire [7:0] frame_count;
    
    wire signed [15:0] mfcc_coeffs [0:NUM_MFCC-1];
    wire mfcc_valid;
    
    // Power-gated clocks
    wire preprocess_clk, feature_clk, cnn_clk;
    
    // Clock gating for power optimization
    assign preprocess_clk = clk & (enable & audio_valid);
    assign feature_clk = clk & (enable & frame_ready);
    assign cnn_clk = clk & (enable & mfcc_valid);
    
    // Processing status
    assign processing = preprocessed_valid | mfcc_valid | classification_valid;
    
    // Audio Preprocessing Module
    audio_preprocessor #(
        .AUDIO_WIDTH(AUDIO_WIDTH),
        .FRAME_SIZE(FRAME_SIZE),
        .QUANT_WIDTH(4)
    ) preprocessor (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .audio_in(audio_in),
        .audio_valid(audio_valid),
        .audio_out(preprocessed_audio),
        .audio_out_valid(preprocessed_valid),
        .frame_ready(frame_ready),
        .frame_count(frame_count)
    );
    
    // FFT/MFCC Feature Extractor
    fft_mfcc_extractor #(
        .FRAME_SIZE(FRAME_SIZE),
        .NUM_MFCC(NUM_MFCC),
        .DATA_WIDTH(4)
    ) feature_extractor (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .frame_valid(frame_ready),
        .audio_in(preprocessed_audio),
        .mfcc_coeff(mfcc_coeffs),
        .mfcc_valid(mfcc_valid)
    );
    
    // CNN Accelerator
    cnn_accelerator #(
        .INPUT_SIZE(NUM_MFCC),
        .CONV_FILTERS(8),
        .KERNEL_SIZE(3),
        .FC_OUTPUTS(NUM_CLASSES),
        .WEIGHT_WIDTH(4)
    ) cnn (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .input_features(mfcc_coeffs),
        .input_valid(mfcc_valid),
        .class_scores(class_scores),
        .classification_valid(classification_valid),
        .predicted_class(predicted_class)
    );

endmodule
