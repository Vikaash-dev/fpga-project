/*
 * Audio Preprocessing Pipeline
 * Implements noise filtering and feature extraction
 * 
 * Pipeline stages:
 * 1. DC offset removal
 * 2. Simple noise gate
 * 3. Frame buffering for FFT/MFCC
 * 4. 4-bit quantization
 */

module audio_preprocessor #(
    parameter AUDIO_WIDTH = 16,
    parameter FRAME_SIZE = 256,
    parameter QUANT_WIDTH = 4
)(
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire signed [AUDIO_WIDTH-1:0] audio_in,
    input wire audio_valid,
    output reg signed [QUANT_WIDTH-1:0] audio_out,
    output reg audio_out_valid,
    output reg frame_ready,
    output wire [7:0] frame_count
);

    // DC offset removal (running average)
    reg signed [AUDIO_WIDTH-1:0] dc_estimate;
    wire signed [AUDIO_WIDTH-1:0] dc_removed;
    
    // Noise gate threshold
    localparam signed [AUDIO_WIDTH-1:0] NOISE_THRESHOLD = 16'sd100;
    
    // Frame buffer
    reg signed [AUDIO_WIDTH-1:0] frame_buffer [0:FRAME_SIZE-1];
    reg [7:0] write_ptr;
    reg [7:0] read_ptr;
    
    assign frame_count = write_ptr;
    
    // DC offset removal (exponential moving average)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dc_estimate <= 0;
        else if (enable && audio_valid)
            // Simple moving average: dc_estimate = 0.9*dc_estimate + 0.1*audio_in
            dc_estimate <= dc_estimate - (dc_estimate >>> 4) + (audio_in >>> 4);
    end
    
    assign dc_removed = audio_in - dc_estimate;
    
    // Noise gate and frame buffering
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_ptr <= 0;
            frame_ready <= 0;
        end else if (enable && audio_valid) begin
            // Apply noise gate
            if ((dc_removed > NOISE_THRESHOLD) || (dc_removed < -NOISE_THRESHOLD)) begin
                frame_buffer[write_ptr] <= dc_removed;
            end else begin
                frame_buffer[write_ptr] <= 0;
            end
            
            // Update write pointer
            if (write_ptr == FRAME_SIZE - 1) begin
                write_ptr <= 0;
                frame_ready <= 1;
            end else begin
                write_ptr <= write_ptr + 1;
                frame_ready <= 0;
            end
        end else begin
            frame_ready <= 0;
        end
    end
    
    // Quantization to 4-bit
    // Scale factor to map 16-bit to 4-bit range
    wire signed [AUDIO_WIDTH-1:0] scaled_value;
    wire signed [QUANT_WIDTH-1:0] quantized_value;
    
    assign scaled_value = dc_removed >>> (AUDIO_WIDTH - QUANT_WIDTH - 1);
    
    // Saturate to 4-bit range [-8, 7]
    assign quantized_value = (scaled_value > 7) ? 4'sd7 :
                            (scaled_value < -8) ? -4'sd8 :
                            scaled_value[QUANT_WIDTH-1:0];
    
    // Output quantized value
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            audio_out <= 0;
            audio_out_valid <= 0;
        end else if (enable && audio_valid) begin
            audio_out <= quantized_value;
            audio_out_valid <= 1;
        end else begin
            audio_out_valid <= 0;
        end
    end

endmodule
