`timescale 1ns / 1ps

module tb_shift_register;
    // Parameters
    parameter WORD_WIDTH = 32;
    parameter MAX_SIZE = 19;
    parameter CLK_PERIOD = 10;
    
    // Test signals
    reg clk;
    reg rst_n;
    reg [WORD_WIDTH-1:0] word_in;
    reg word_valid;
    reg clear;
    reg [4:0] high_right_idx;
    reg [4:0] high_left_idx;
    reg [4:0] low_right_idx;
    reg [4:0] low_left_idx;
    reg high_right_valid;
    reg high_left_valid;
    reg low_right_valid;
    reg low_left_valid;
    reg get_pair;
    
    // Output signals
    wire [WORD_WIDTH-1:0] high_right_word;
    wire [WORD_WIDTH-1:0] high_left_word;
    wire [WORD_WIDTH-1:0] low_right_word;
    wire [WORD_WIDTH-1:0] low_left_word;
    wire pair_valid;
    wire word_accepted;
    wire [4:0] current_size;
    wire ready;
    
    // Test data
    reg [WORD_WIDTH-1:0] test_words [0:22];
    integer i;
    
    // DUT instantiation
    shift_register #(
        .WORD_WIDTH(WORD_WIDTH),
        .MAX_SIZE(MAX_SIZE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .word_in(word_in),
        .word_valid(word_valid),
        .clear(clear),
        .high_right_idx(high_right_idx),
        .high_left_idx(high_left_idx),
        .low_right_idx(low_right_idx),
        .low_left_idx(low_left_idx),
        .high_right_valid(high_right_valid),
        .high_left_valid(high_left_valid),
        .low_right_valid(low_right_valid),
        .low_left_valid(low_left_valid),
        .get_pair(get_pair),
        .high_right_word(high_right_word),
        .high_left_word(high_left_word),
        .low_right_word(low_right_word),
        .low_left_word(low_left_word),
        .pair_valid(pair_valid),
        .word_accepted(word_accepted),
        .current_size(current_size),
        .ready(ready)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Initialize test data
    initial begin
        test_words[0]  = 32'hF0F0F0F0;
        test_words[1]  = 32'h0F0F0F0F;
        test_words[2]  = 32'hAAAAAAAA;
        test_words[3]  = 32'h55555555;
        test_words[4]  = 32'h12345678;
        test_words[5]  = 32'h87654321;
        test_words[6]  = 32'hFEDCBA98;
        test_words[7]  = 32'h89ABCDEF;
        test_words[8]  = 32'h11111111;
        test_words[9]  = 32'h22222222;
        test_words[10] = 32'h33333333;
        test_words[11] = 32'h44444444;
        test_words[12] = 32'hFFFF0000;
        test_words[13] = 32'h0000FFFF;
        test_words[14] = 32'hF0F0F0F0;
        test_words[15] = 32'h0F0F0F0F;
        test_words[16] = 32'hDEADBEEF;
        test_words[17] = 32'hBEEFDEAD;
        test_words[18] = 32'hCAFEBABE;
        test_words[19] = 32'hBABECAFE;
        test_words[20] = 32'h01234567;
        test_words[21] = 32'h89ABCDEF;
        test_words[22] = 32'h99999999;
    end
    
    // Test stimulus
    initial begin
        // Initialize
        initialize_signals();
        
        // Reset
        apply_reset();
        
        // Test 1: Add words and verify size
        $display("\n=== Test 1: Adding Words and Size Check ===");
        for (i = 0; i < 23; i = i + 1) begin
            add_word(test_words[i]);
            $display("Added word %0d: %h, Current size: %0d", i, test_words[i], current_size);
        end
        
        // Test 2: Retrieve word pairs - all valid
        $display("\n=== Test 2: Retrieve All Valid Word Pairs ===");
        retrieve_pairs(16, 17, 14, 15, 1, 1, 1, 1);
        verify_outputs(test_words[16], test_words[17], test_words[14], test_words[15]);
        
        // Test 3: Retrieve word pairs - partially valid
        $display("\n=== Test 3: Retrieve Partially Valid Word Pairs ===");
        retrieve_pairs(16, 17, 14, 15, 1, 0, 1, 0);
        verify_outputs(test_words[16], 0, test_words[14], 0);
        
        // Test 4: Clear and verify
        $display("\n=== Test 4: Clear Register ===");
        clear_register();
        if (current_size == 0)
            $display("Register cleared successfully");
        else
            $display("Clear failed! Size = %0d", current_size);
        
        // End simulation
        #(CLK_PERIOD*5);
        $finish;
    end
    
    // Tasks for test control
    task initialize_signals;
        begin
            rst_n = 1;
            word_valid = 0;
            clear = 0;
            get_pair = 0;
            high_right_valid = 0;
            high_left_valid = 0;
            low_right_valid = 0;
            low_left_valid = 0;
        end
    endtask
    
    task apply_reset;
        begin
            #(CLK_PERIOD*2);
            rst_n = 0;
            #(CLK_PERIOD*2);
            rst_n = 1;
            #CLK_PERIOD;
        end
    endtask
    
    task add_word;
        input [WORD_WIDTH-1:0] word;
        begin
            @(posedge clk);
            word_in = word;
            word_valid = 1;
            @(posedge clk);
            while (!word_accepted) @(posedge clk);
            word_valid = 0;
            @(posedge clk);
        end
    endtask
    
    task retrieve_pairs;
        input [4:0] hr_idx, hl_idx, lr_idx, ll_idx;
        input hr_valid, hl_valid, lr_valid, ll_valid;
        begin
            @(posedge clk);
            high_right_idx = hr_idx;
            high_left_idx = hl_idx;
            low_right_idx = lr_idx;
            low_left_idx = ll_idx;
            high_right_valid = hr_valid;
            high_left_valid = hl_valid;
            low_right_valid = lr_valid;
            low_left_valid = ll_valid;
            get_pair = 1;
            @(posedge clk);
            while (!pair_valid) @(posedge clk);
            get_pair = 0;
            @(posedge clk);
        end
    endtask
    
    task verify_outputs;
        input [WORD_WIDTH-1:0] exp_high_right;
        input [WORD_WIDTH-1:0] exp_high_left;
        input [WORD_WIDTH-1:0] exp_low_right;
        input [WORD_WIDTH-1:0] exp_low_left;
        begin
            $display("\nVerifying outputs:");
            $display("High Right - Expected: %h, Got: %h %s", 
                    exp_high_right, high_right_word, 
                    (exp_high_right === high_right_word) ? "✓" : "✗");
            $display("High Left  - Expected: %h, Got: %h %s", 
                    exp_high_left, high_left_word,
                    (exp_high_left === high_left_word) ? "✓" : "✗");
            $display("Low Right  - Expected: %h, Got: %h %s", 
                    exp_low_right, low_right_word,
                    (exp_low_right === low_right_word) ? "✓" : "✗");
            $display("Low Left   - Expected: %h, Got: %h %s", 
                    exp_low_left, low_left_word,
                    (exp_low_left === low_left_word) ? "✓" : "✗");
        end
    endtask
    
    task clear_register;
        begin
            @(posedge clk);
            clear = 1;
            @(posedge clk);
            clear = 0;
            @(posedge clk);
        end
    endtask
    
    // Monitor changes
    initial begin
        $monitor("Time=%0t rst_n=%b size=%0d ready=%b", 
                 $time, rst_n, current_size, ready);
    end
    
    // Generate VCD file
    initial begin
        $dumpfile("shift_register.vcd");
        $dumpvars(0, shift_register_tb);
    end

endmodule