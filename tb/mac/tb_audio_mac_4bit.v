/*
 * Testbench for 4-bit MAC Unit
 */

`timescale 1ns/1ps

module tb_audio_mac_4bit;

    reg clk;
    reg rst_n;
    reg enable;
    reg signed [3:0] a;
    reg signed [3:0] b;
    reg clear_accum;
    wire signed [15:0] accum_out;
    wire overflow;
    
    // Instantiate DUT
    audio_mac_4bit #(
        .ACCUM_WIDTH(16)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .a(a),
        .b(b),
        .clear_accum(clear_accum),
        .accum_out(accum_out),
        .overflow(overflow)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end
    
    // Test stimulus
    initial begin
        $display("Starting MAC Unit Test");
        
        // Initialize
        rst_n = 0;
        enable = 0;
        a = 0;
        b = 0;
        clear_accum = 0;
        
        // Reset
        #20;
        rst_n = 1;
        #10;
        
        // Test 1: Basic multiply-accumulate
        $display("\nTest 1: Basic MAC operations");
        enable = 1;
        clear_accum = 1;
        #10;
        clear_accum = 0;
        
        a = 4'sd2; b = 4'sd3; // 2*3 = 6
        #10;
        $display("MAC: %d * %d = %d, Accum = %d", $signed(a), $signed(b), 
                 $signed(a)*$signed(b), $signed(accum_out));
        
        a = 4'sd4; b = 4'sd2; // 4*2 = 8, accum = 6+8 = 14
        #10;
        $display("MAC: %d * %d = %d, Accum = %d", $signed(a), $signed(b), 
                 $signed(a)*$signed(b), $signed(accum_out));
        
        a = -4'sd3; b = 4'sd3; // -3*3 = -9, accum = 14-9 = 5
        #10;
        $display("MAC: %d * %d = %d, Accum = %d", $signed(a), $signed(b), 
                 $signed(a)*$signed(b), $signed(accum_out));
        
        // Test 2: Clear accumulator
        $display("\nTest 2: Clear accumulator");
        clear_accum = 1;
        #10;
        clear_accum = 0;
        $display("After clear: Accum = %d", $signed(accum_out));
        
        // Test 3: Overflow detection
        $display("\nTest 3: Overflow test");
        a = 4'sd7; b = 4'sd7; // Large positive
        repeat(1000) begin
            #10;
            if (overflow)
                $display("Overflow detected at Accum = %d", $signed(accum_out));
        end
        
        // Test 4: Enable/disable
        $display("\nTest 4: Enable control");
        clear_accum = 1;
        #10;
        clear_accum = 0;
        enable = 0;
        a = 4'sd5; b = 4'sd5;
        #10;
        $display("With enable=0: Accum = %d (should be 0)", $signed(accum_out));
        enable = 1;
        #10;
        $display("With enable=1: Accum = %d (should be 25)", $signed(accum_out));
        
        #100;
        $display("\nMAC Unit Test Completed");
        $finish;
    end
    
    // Monitor (simplified for iverilog compatibility)
    always @(posedge clk) begin
        if (enable)
            $display("Time=%0t a=%d b=%d enable=%b clear=%b accum=%d overflow=%b", 
                     $time, a, b, enable, clear_accum, accum_out, overflow);
    end

endmodule
