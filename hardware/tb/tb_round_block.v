`timescale 1ns/1ps

module round_block_tb;
    // Parameters
    parameter WORD_WIDTH = 32;
    parameter CLK_PERIOD = 10;

    // Test data - Normal words array
    reg [WORD_WIDTH-1:0] normal_words [0:10];

    // Signals
    reg clk;
    reg rst_n;
    reg [WORD_WIDTH-1:0] normal_word_in;
    reg word_valid;
    reg only_add;
    reg [5:0] normal_sparse_diff;
    reg high_latency;
    reg low_latency;

    // Output signals
    wire [WORD_WIDTH-1:0] normal_high_word_right;
    wire [WORD_WIDTH-1:0] normal_high_word_left;
    wire [WORD_WIDTH-1:0] normal_low_word_right;
    wire [WORD_WIDTH-1:0] normal_low_word_left;
    wire processing_done;
    wire word_accepted;
    wire ready;

    integer i;

    // DUT instantiation
    round_block dut (
        .clk(clk),
        .rst_n(rst_n),
        .normal_word_in(normal_word_in),
        .word_valid(word_valid),
        .only_add(only_add),
        .normal_sparse_diff(normal_sparse_diff),
        .high_latency(high_latency),
        .low_latency(low_latency),
        .normal_high_word_right(normal_high_word_right),
        .normal_high_word_left(normal_high_word_left),
        .normal_low_word_right(normal_low_word_right),
        .normal_low_word_left(normal_low_word_left),
        .processing_done(processing_done),
        .word_accepted(word_accepted),
        .ready(ready)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Initialize test data
    initial begin
        // Normal Word Zero and subsequent words
        normal_words[0] = 32'b11110110000000010101100010011100;  // Word Zero
        normal_words[1] = 32'b00110011111110101100111000011011;  // Word 1
        normal_words[2] = 32'b00100011001100100011100011101001;  // Word 2
        normal_words[3] = 32'b00011010000010100001000101100000;  // Word 3
        normal_words[4] = 32'b11111101011111011010010100110110;  // Word 4
        normal_words[5] = 32'b10001101011010101100111010101101;  // Word 5
        normal_words[6] = 32'b10111111100000000101011110000111;  // Word 6
        normal_words[7] = 32'b11001001100110011011011100100101;  // Word 7
        normal_words[8] = 32'b01000000110100010011110111011011;  // Word 8
        normal_words[9] = 32'b00100101101110010000010101100110;  // Word 9
        normal_words[10] = 32'b00100111100111111100110001001100; // Word 10
        normal_words[11] = 32'b10111010100110010001101000111101;
        normal_words[12] = 32'b10010000111100111001000001111001;
        normal_words[13] = 32'b01001110011110100110110001101101;
        normal_words[14] = 32'b11101011000000110011101100010000;
        normal_words[15] = 32'b01100110101010000101100111111101;
        normal_words[16] = 32'b00011110101100110011001000110110;
        normal_words[17] = 32'b01011101100000011010110010101010;
        normal_words[18] = 32'b01000000001110011011111010000100;
        normal_words[19] = 32'b01011011010110101000001100010110;
        normal_words[20] = 32'b00110100000101100010110101011001;
        normal_words[21] = 32'b11011000011110001110011101001110;
        normal_words[22] = 32'b01011101001011011010101101001001;
    end

    // Test stimulus
    initial begin
        // Initialize
        rst_n = 0;
        word_valid = 0;
        only_add = 0;
        normal_sparse_diff = 6;
        high_latency = 0;
        low_latency = 0;
        normal_word_in = 0;

        // Release reset
        #(CLK_PERIOD*2);
        rst_n = 1;
        #CLK_PERIOD;

        // Test Case 1: Add Normal Word Zero
        $display("\n=== Test Case 1: Adding Normal Word Zero ===");
        normal_word_in = normal_words[0];
        only_add = 1;  // Only add mode
        word_valid = 1;
        
        @(posedge clk);
        wait(word_accepted);
        word_valid = 0;
        @(posedge clk);
        
        // Test Case 2: Process subsequent words
        for (i = 1; i <= 22; i = i + 1) begin
            $display("\n=== Processing Normal Word %0d ===", i);
            normal_word_in = normal_words[i];
            only_add = 0;  // Process mode
            word_valid = 1;
            
            @(posedge clk);
            wait(word_accepted);
            word_valid = 0;
            
            // Wait for processing to complete
            wait(processing_done);
            
            // Display results for each word
            $display("Results for Word %0d:", i);
            $display("Normal High Word Left : %b", normal_high_word_left);
            $display("Normal High Word Right: %b", normal_high_word_right);
            $display("Normal Low Word Left  : %b", normal_low_word_left);
            $display("Normal Low Word Right : %b", normal_low_word_right);
            
            @(posedge clk);
        end

        #(CLK_PERIOD*5);
        $finish;
    end

    // Dump waveforms
    initial begin
        $dumpfile("round_block.vcd");
        $dumpvars(0, round_block_tb);
    end

    // Monitor state changes
    initial begin
        $monitor("Time=%0t rst_n=%b valid=%b only_add=%b state=%0d done=%b", 
                 $time, rst_n, word_valid, only_add, dut.state, processing_done);
    end

endmodule
