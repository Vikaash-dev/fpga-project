/*
 * Testbench for Complete Audio Event Detector
 */

`timescale 1ns/1ps

module tb_audio_event_detector_top;

    reg clk;
    reg rst_n;
    reg enable;
    reg low_power_mode;
    reg signed [15:0] audio_in;
    reg audio_valid;
    wire [1:0] predicted_class;
    wire classification_valid;
    wire [3:0] class_scores;
    wire processing;
    wire frame_ready;
    
    // Instantiate DUT
    audio_event_detector_top #(
        .AUDIO_WIDTH(16),
        .FRAME_SIZE(256),
        .NUM_MFCC(13),
        .NUM_CLASSES(4)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .low_power_mode(low_power_mode),
        .audio_in(audio_in),
        .audio_valid(audio_valid),
        .predicted_class(predicted_class),
        .classification_valid(classification_valid),
        .class_scores(class_scores),
        .processing(processing),
        .frame_ready(frame_ready)
    );
    
    // Clock generation - 100MHz
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    integer i, j;
    real freq, sample_rate, amplitude, phase;
    integer frame_count;
    
    // Test stimulus
    initial begin
        $display("========================================");
        $display("Audio Event Detector System Test");
        $display("========================================");
        
        // Initialize
        rst_n = 0;
        enable = 0;
        low_power_mode = 0;
        audio_in = 0;
        audio_valid = 0;
        frame_count = 0;
        
        // Reset
        #20;
        rst_n = 1;
        enable = 1;
        #10;
        
        // Test 1: Quiet/Background noise
        $display("\n--- Test 1: Background Noise (Class 0) ---");
        audio_valid = 1;
        sample_rate = 10000000.0; // 10MHz
        
        for (i = 0; i < 300; i = i + 1) begin
            // Low amplitude random noise
            audio_in = $random % 200;
            #10;
        end
        #1000;
        
        // Test 2: Low frequency tone (e.g., door slam)
        $display("\n--- Test 2: Low Frequency Event (Class 1) ---");
        freq = 100.0; // 100Hz
        amplitude = 3000.0;
        
        for (i = 0; i < 300; i = i + 1) begin
            audio_in = $rtoi(amplitude * $sin(2.0 * 3.14159 * freq * i / sample_rate));
            #10;
        end
        #1000;
        
        // Test 3: Mid frequency tone (e.g., alarm)
        $display("\n--- Test 3: Mid Frequency Event (Class 2) ---");
        freq = 1000.0; // 1kHz
        amplitude = 4000.0;
        
        for (i = 0; i < 300; i = i + 1) begin
            audio_in = $rtoi(amplitude * $sin(2.0 * 3.14159 * freq * i / sample_rate));
            #10;
        end
        #1000;
        
        // Test 4: High frequency tone (e.g., whistle)
        $display("\n--- Test 4: High Frequency Event (Class 3) ---");
        freq = 3000.0; // 3kHz
        amplitude = 3500.0;
        
        for (i = 0; i < 300; i = i + 1) begin
            audio_in = $rtoi(amplitude * $sin(2.0 * 3.14159 * freq * i / sample_rate));
            #10;
        end
        #1000;
        
        // Test 5: Complex signal (multiple frequencies)
        $display("\n--- Test 5: Complex Signal ---");
        for (i = 0; i < 300; i = i + 1) begin
            audio_in = $rtoi(2000.0 * $sin(2.0 * 3.14159 * 500.0 * i / sample_rate) +
                           1000.0 * $sin(2.0 * 3.14159 * 2000.0 * i / sample_rate));
            #10;
        end
        #1000;
        
        // Test 6: Power saving mode
        $display("\n--- Test 6: Low Power Mode ---");
        low_power_mode = 1;
        for (i = 0; i < 300; i = i + 1) begin
            audio_in = $random % 1000;
            #10;
        end
        #1000;
        
        $display("\n========================================");
        $display("Audio Event Detector Test Completed");
        $display("========================================");
        #100;
        $finish;
    end
    
    // Monitor classifications
    always @(posedge clk) begin
        if (classification_valid) begin
            $display("Time=%0t: Classification Result - Class=%d, Scores=%b", 
                     $time, predicted_class, class_scores);
        end
        if (frame_ready) begin
            frame_count = frame_count + 1;
            $display("Time=%0t: Frame %d ready for processing", $time, frame_count);
        end
    end

endmodule
