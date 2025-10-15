/*
 * Testbench for Audio Preprocessor
 */

`timescale 1ns/1ps

module tb_audio_preprocessor;

    reg clk;
    reg rst_n;
    reg enable;
    reg signed [15:0] audio_in;
    reg audio_valid;
    wire signed [3:0] audio_out;
    wire audio_out_valid;
    wire frame_ready;
    wire [7:0] frame_count;
    
    // Instantiate DUT
    audio_preprocessor #(
        .AUDIO_WIDTH(16),
        .FRAME_SIZE(256),
        .QUANT_WIDTH(4)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .audio_in(audio_in),
        .audio_valid(audio_valid),
        .audio_out(audio_out),
        .audio_out_valid(audio_out_valid),
        .frame_ready(frame_ready),
        .frame_count(frame_count)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end
    
    integer i;
    real freq, sample_rate, amplitude;
    
    // Test stimulus
    initial begin
        $display("Starting Audio Preprocessor Test");
        
        // Initialize
        rst_n = 0;
        enable = 0;
        audio_in = 0;
        audio_valid = 0;
        
        // Reset
        #20;
        rst_n = 1;
        enable = 1;
        #10;
        
        // Test 1: DC offset removal
        $display("\nTest 1: DC offset removal");
        audio_valid = 1;
        for (i = 0; i < 100; i = i + 1) begin
            audio_in = 16'sd1000; // Constant DC value
            #10;
        end
        audio_in = 16'sd0;
        #10;
        $display("After 100 DC samples, output should be near zero");
        
        // Test 2: Sine wave with DC offset
        $display("\nTest 2: Sine wave processing");
        freq = 1000.0; // 1kHz
        sample_rate = 100000000.0 / 10.0; // 10MHz effective sample rate
        amplitude = 5000.0;
        
        for (i = 0; i < 300; i = i + 1) begin
            audio_in = $rtoi(amplitude * $sin(2.0 * 3.14159 * freq * i / sample_rate) + 500);
            #10;
            if (audio_out_valid)
                $display("Sample %d: in=%d, out=%d", i, audio_in, $signed(audio_out));
        end
        
        // Test 3: Frame buffering
        $display("\nTest 3: Frame buffering");
        audio_valid = 1;
        for (i = 0; i < 512; i = i + 1) begin
            audio_in = i % 1000;
            #10;
            if (frame_ready)
                $display("Frame %d ready at sample %d", frame_count, i);
        end
        
        // Test 4: Noise gate
        $display("\nTest 4: Noise gate");
        for (i = 0; i < 50; i = i + 1) begin
            audio_in = 16'sd50; // Below threshold
            #10;
            if (audio_out_valid)
                $display("Low signal: in=%d, out=%d", audio_in, $signed(audio_out));
        end
        
        for (i = 0; i < 50; i = i + 1) begin
            audio_in = 16'sd500; // Above threshold
            #10;
            if (audio_out_valid)
                $display("High signal: in=%d, out=%d", audio_in, $signed(audio_out));
        end
        
        #100;
        $display("\nAudio Preprocessor Test Completed");
        $finish;
    end

endmodule
