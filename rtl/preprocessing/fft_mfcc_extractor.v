/*
 * Simplified FFT/MFCC Feature Extractor
 * Implements a lightweight feature extraction for audio classification
 * Uses fixed-point arithmetic for power efficiency
 */

module fft_mfcc_extractor #(
    parameter FRAME_SIZE = 256,
    parameter NUM_MFCC = 13,
    parameter DATA_WIDTH = 4
)(
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire frame_valid,
    input wire signed [DATA_WIDTH-1:0] audio_in,
    output reg signed [15:0] mfcc_coeff [0:NUM_MFCC-1],
    output reg mfcc_valid
);

    // State machine
    localparam IDLE = 2'd0;
    localparam COMPUTE = 2'd1;
    localparam OUTPUT = 2'd2;
    
    reg [1:0] state;
    reg [7:0] sample_count;
    reg [7:0] compute_count;
    
    // Frame buffer
    reg signed [DATA_WIDTH-1:0] frame_buffer [0:FRAME_SIZE-1];
    
    // Simplified energy calculation (proxy for FFT bins)
    reg signed [15:0] energy_bins [0:15];
    integer i;
    
    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            sample_count <= 0;
            compute_count <= 0;
            mfcc_valid <= 0;
        end else if (enable) begin
            case (state)
                IDLE: begin
                    mfcc_valid <= 0;
                    if (frame_valid) begin
                        frame_buffer[sample_count] <= audio_in;
                        if (sample_count == FRAME_SIZE - 1) begin
                            state <= COMPUTE;
                            sample_count <= 0;
                            compute_count <= 0;
                        end else begin
                            sample_count <= sample_count + 1;
                        end
                    end
                end
                
                COMPUTE: begin
                    // Compute simplified energy bins (sum of squares in bins)
                    if (compute_count < 16) begin
                        // Each bin covers FRAME_SIZE/16 samples
                        energy_bins[compute_count] <= compute_energy_bin(compute_count);
                        compute_count <= compute_count + 1;
                    end else begin
                        // Compute MFCC-like coefficients (simplified DCT)
                        compute_mfcc_coeffs();
                        state <= OUTPUT;
                    end
                end
                
                OUTPUT: begin
                    mfcc_valid <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
    
    // Function to compute energy in a bin
    function signed [15:0] compute_energy_bin;
        input [7:0] bin_idx;
        reg [7:0] start_idx;
        reg [7:0] j;
        reg signed [15:0] energy;
        begin
            start_idx = bin_idx * 16; // FRAME_SIZE/16 = 16 samples per bin
            energy = 0;
            for (j = 0; j < 16; j = j + 1) begin
                energy = energy + (frame_buffer[start_idx + j] * frame_buffer[start_idx + j]);
            end
            compute_energy_bin = energy;
        end
    endfunction
    
    // Task to compute simplified MFCC coefficients
    task compute_mfcc_coeffs;
        integer k;
        begin
            for (k = 0; k < NUM_MFCC; k = k + 1) begin
                // Simplified: weighted sum of energy bins (like mel filterbank + DCT)
                mfcc_coeff[k] <= energy_bins[k] + (energy_bins[15-k] >>> 1);
            end
        end
    endtask

endmodule
