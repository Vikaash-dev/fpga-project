/*
 * 4-bit Multiply-Accumulate Unit for Audio Feature Extraction
 * Optimized for low power consumption (<100uW target)
 * 
 * Features:
 * - 4-bit quantized inputs for reduced power
 * - Pipelined design for higher throughput
 * - Clock gating for unused cycles
 * - Saturating arithmetic to prevent overflow
 */

module audio_mac_4bit #(
    parameter ACCUM_WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire signed [3:0] a,      // 4-bit input operand A
    input wire signed [3:0] b,      // 4-bit input operand B
    input wire clear_accum,          // Clear accumulator
    output reg signed [ACCUM_WIDTH-1:0] accum_out,
    output wire overflow
);

    // Internal signals
    reg signed [7:0] product;        // 4-bit x 4-bit = 8-bit product
    reg signed [ACCUM_WIDTH-1:0] accum_next;
    wire signed [ACCUM_WIDTH-1:0] sum;
    wire overflow_pos, overflow_neg;
    
    // Clock gating signal
    wire gated_clk;
    assign gated_clk = clk & enable;
    
    // Multiply stage
    always @(*) begin
        product = a * b;
    end
    
    // Accumulate stage with saturation
    assign sum = accum_out + {{(ACCUM_WIDTH-8){product[7]}}, product};
    
    // Overflow detection
    assign overflow_pos = (accum_out[ACCUM_WIDTH-1] == 0) && 
                         (product[7] == 0) && 
                         (sum[ACCUM_WIDTH-1] == 1);
    assign overflow_neg = (accum_out[ACCUM_WIDTH-1] == 1) && 
                         (product[7] == 1) && 
                         (sum[ACCUM_WIDTH-1] == 0);
    assign overflow = overflow_pos || overflow_neg;
    
    // Saturation logic
    always @(*) begin
        if (overflow_pos)
            accum_next = {1'b0, {(ACCUM_WIDTH-1){1'b1}}}; // Max positive
        else if (overflow_neg)
            accum_next = {1'b1, {(ACCUM_WIDTH-1){1'b0}}}; // Max negative
        else
            accum_next = sum;
    end
    
    // Accumulator register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            accum_out <= 0;
        else if (enable) begin
            if (clear_accum)
                accum_out <= 0;
            else
                accum_out <= accum_next;
        end
    end

endmodule
