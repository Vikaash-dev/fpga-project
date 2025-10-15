/*
 * Lightweight CNN Accelerator with 4-bit Quantization
 * Optimized for audio event classification
 * 
 * Architecture:
 * - Single convolution layer
 * - Max pooling
 * - Fully connected layer
 * - All using 4-bit quantized weights and activations
 */

module cnn_accelerator #(
    parameter INPUT_SIZE = 13,     // Number of MFCC coefficients
    parameter CONV_FILTERS = 8,    // Number of convolution filters
    parameter KERNEL_SIZE = 3,     // Convolution kernel size
    parameter FC_OUTPUTS = 4,      // Number of output classes
    parameter WEIGHT_WIDTH = 4     // 4-bit quantized weights
)(
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire signed [15:0] input_features [0:INPUT_SIZE-1],
    input wire input_valid,
    output reg [FC_OUTPUTS-1:0] class_scores,
    output reg classification_valid,
    output reg [1:0] predicted_class
);

    // State machine
    localparam IDLE = 3'd0;
    localparam CONV = 3'd1;
    localparam POOL = 3'd2;
    localparam FC = 3'd3;
    localparam OUTPUT = 3'd4;
    
    reg [2:0] state;
    reg [7:0] compute_idx;
    
    // Quantized feature map (4-bit)
    reg signed [WEIGHT_WIDTH-1:0] input_quant [0:INPUT_SIZE-1];
    
    // Convolution output
    reg signed [15:0] conv_output [0:CONV_FILTERS-1][0:INPUT_SIZE-KERNEL_SIZE];
    
    // Pooled features
    reg signed [15:0] pooled_features [0:CONV_FILTERS-1];
    
    // Pre-trained weights (4-bit quantized) - normally loaded from memory
    // For demonstration, using simple initialization
    reg signed [WEIGHT_WIDTH-1:0] conv_weights [0:CONV_FILTERS-1][0:KERNEL_SIZE-1];
    reg signed [WEIGHT_WIDTH-1:0] fc_weights [0:FC_OUTPUTS-1][0:CONV_FILTERS-1];
    reg signed [7:0] fc_bias [0:FC_OUTPUTS-1];
    
    integer i, j, k;
    
    // Initialize weights (in real design, load from ROM/RAM)
    initial begin
        // Simple pattern weights for demonstration
        for (i = 0; i < CONV_FILTERS; i = i + 1) begin
            for (j = 0; j < KERNEL_SIZE; j = j + 1) begin
                conv_weights[i][j] = (i + j) % 8 - 4; // Range: -4 to 3
            end
        end
        
        for (i = 0; i < FC_OUTPUTS; i = i + 1) begin
            for (j = 0; j < CONV_FILTERS; j = j + 1) begin
                fc_weights[i][j] = (i * j) % 8 - 4;
            end
            fc_bias[i] = i * 10;
        end
    end
    
    // Quantize input features to 4-bit
    always @(*) begin
        for (i = 0; i < INPUT_SIZE; i = i + 1) begin
            // Scale 16-bit to 4-bit range
            if (input_features[i] > 2047)
                input_quant[i] = 4'sd7;
            else if (input_features[i] < -2048)
                input_quant[i] = -4'sd8;
            else
                input_quant[i] = input_features[i][10:7];
        end
    end
    
    // Main state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            compute_idx <= 0;
            classification_valid <= 0;
        end else if (enable) begin
            case (state)
                IDLE: begin
                    classification_valid <= 0;
                    if (input_valid) begin
                        state <= CONV;
                        compute_idx <= 0;
                    end
                end
                
                CONV: begin
                    // Perform 1D convolution
                    if (compute_idx < CONV_FILTERS) begin
                        compute_convolution(compute_idx);
                        compute_idx <= compute_idx + 1;
                    end else begin
                        state <= POOL;
                        compute_idx <= 0;
                    end
                end
                
                POOL: begin
                    // Max pooling across each filter output
                    if (compute_idx < CONV_FILTERS) begin
                        pooled_features[compute_idx] <= max_pool(compute_idx);
                        compute_idx <= compute_idx + 1;
                    end else begin
                        state <= FC;
                        compute_idx <= 0;
                    end
                end
                
                FC: begin
                    // Fully connected layer
                    if (compute_idx < FC_OUTPUTS) begin
                        class_scores[compute_idx] <= compute_fc_output(compute_idx);
                        compute_idx <= compute_idx + 1;
                    end else begin
                        state <= OUTPUT;
                    end
                end
                
                OUTPUT: begin
                    // Find predicted class (argmax)
                    predicted_class <= argmax(class_scores);
                    classification_valid <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
    
    // Task: Perform 1D convolution for one filter
    task compute_convolution;
        input [7:0] filter_idx;
        reg signed [15:0] sum;
        integer pos, k;
        begin
            for (pos = 0; pos <= INPUT_SIZE - KERNEL_SIZE; pos = pos + 1) begin
                sum = 0;
                for (k = 0; k < KERNEL_SIZE; k = k + 1) begin
                    sum = sum + (input_quant[pos + k] * conv_weights[filter_idx][k]);
                end
                // ReLU activation
                conv_output[filter_idx][pos] = (sum > 0) ? sum : 16'd0;
            end
        end
    endtask
    
    // Function: Max pooling over one filter output
    function signed [15:0] max_pool;
        input [7:0] filter_idx;
        reg signed [15:0] max_val;
        integer pos;
        begin
            max_val = conv_output[filter_idx][0];
            for (pos = 1; pos <= INPUT_SIZE - KERNEL_SIZE; pos = pos + 1) begin
                if (conv_output[filter_idx][pos] > max_val)
                    max_val = conv_output[filter_idx][pos];
            end
            max_pool = max_val;
        end
    endfunction
    
    // Function: Compute fully connected layer output for one class
    function signed [7:0] compute_fc_output;
        input [7:0] class_idx;
        reg signed [15:0] sum;
        integer filt;
        begin
            sum = fc_bias[class_idx];
            for (filt = 0; filt < CONV_FILTERS; filt = filt + 1) begin
                sum = sum + ((pooled_features[filt] >>> 8) * fc_weights[class_idx][filt]);
            end
            // Saturate to 8-bit
            if (sum > 127)
                compute_fc_output = 8'd127;
            else if (sum < -128)
                compute_fc_output = -8'd128;
            else
                compute_fc_output = sum[7:0];
        end
    endfunction
    
    // Function: Find argmax of class scores
    function [1:0] argmax;
        input [FC_OUTPUTS-1:0] scores;
        reg [1:0] max_idx;
        reg signed [7:0] max_score;
        integer idx;
        begin
            max_idx = 0;
            max_score = $signed(scores[0]);
            for (idx = 1; idx < FC_OUTPUTS; idx = idx + 1) begin
                if ($signed(scores[idx]) > max_score) begin
                    max_score = $signed(scores[idx]);
                    max_idx = idx;
                end
            end
            argmax = max_idx;
        end
    endfunction

endmodule
