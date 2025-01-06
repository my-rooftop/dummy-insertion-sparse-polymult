`timescale 1ns/1ps

module initial_shift_processor_tb;
    // Parameters
    parameter WORD_WIDTH = 32;
    parameter CLK_PERIOD = 50;

    // Signals
    reg clk;
    reg rst_n;
    reg start_process;
    
    // Input signals
    reg [WORD_WIDTH-1:0] normal_word_zero;
    reg [WORD_WIDTH-1:0] normal_word_551;
    reg [WORD_WIDTH-1:0] normal_word_552;
    reg [WORD_WIDTH-1:0] acc_word_high;
    reg [15:0] high_shift;
    reg [9:0] acc_start_idx_high;
    reg [4:0] acc_shift_idx_high;

    // Output signals
    wire [WORD_WIDTH-1:0] high_result;
    // wire [WORD_WIDTH-1:0] low_result;
    wire processing_done;

    // DUT instantiation
    initial_shift_processor dut (
        .clk(clk),
        .rst_n(rst_n),
        .start_process(start_process),
        .normal_word_zero(normal_word_zero),
        .normal_word_551(normal_word_551),
        .normal_word_552(normal_word_552),
        .acc_word_high(acc_word_high),
        .high_shift(high_shift),
        .acc_start_idx_high(acc_start_idx_high),
        .acc_shift_idx_high(acc_shift_idx_high),
        .high_result(high_result),
        .processing_done(processing_done)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test stimulus
    initial begin
        // Initialize
        rst_n = 0;
        start_process = 0;
        
        // Given test values
        normal_word_zero = 32'b11110110000000010101100010011100;
        normal_word_551 = 32'b00010010011010110010010111010001;
        normal_word_552 = 32'b00000000000000000000000000010101;
        acc_word_high = 32'h0;  // Initial acc word is 0
        // acc_word_low = 32'h0;   // Initial acc word is 0
        
        // High shift test values
        high_shift = 16'd148;
        acc_start_idx_high = 10'd5;
        acc_shift_idx_high = 4'd12;
        
        // // Low shift test values
        // low_shift = 16'd342;
        // acc_start_idx_low = 10'd11;
        // acc_shift_idx_low = 4'd10;

        // Release reset
        #(CLK_PERIOD*2);
        rst_n = 1;
        #CLK_PERIOD;

        // Start processing
        start_process = 1;
        #CLK_PERIOD;
        start_process = 0;

        // Wait for completion
        @(posedge processing_done);
        
        // Verify results
        if (high_result === 32'b10001001110010101000100100110101) begin
            $display("High shift test PASSED");
        end else begin
            $display("High shift test FAILED");
            $display("Expected: 10001001110010101000100100110101");
            $display("Got     : %b", high_result);
        end
        
        // if (low_result === 32'b00100111001010100010010011010110) begin
        //     $display("Low shift test PASSED");
        // end else begin
        //     $display("Low shift test FAILED");
        //     $display("Expected: 00100111001010100010010011010110");
        //     $display("Got     : %b", low_result);
        // end

        #(CLK_PERIOD*5);
        $finish;
    end

    // Monitor changes
    initial begin
        $monitor("Time=%0t rst_n=%b start=%b done=%b", 
                 $time, rst_n, start_process, processing_done);
    end

endmodule
