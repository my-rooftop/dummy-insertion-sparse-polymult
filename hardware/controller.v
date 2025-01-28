`timescale 1ns / 1ps

module controller #(
    parameter WORD_WIDTH = 32,
    parameter MEM_SIZE = 553,    // Total memory size in words
    parameter MEM_SPARSE_SIZE = 50
)(
    input wire clk,
    input wire rst_n,
    
    // Memory interfaces
    input wire [WORD_WIDTH-1:0] normal_mem_data,
    input wire [WORD_WIDTH-1:0] sparse_mem_data,
    input wire [WORD_WIDTH-1:0] acc_mem_data,
    input wire [9:0] sparse_mem_addr_i,

    output reg [WORD_WIDTH-1:0] acc_mem_write_data,
    output reg acc_mem_write_en,
    output reg [9:0] normal_mem_addr_o,
    output reg [9:0] sparse_mem_addr_o,
    output reg [9:0] acc_mem_addr_o,
    
    // Control signals
    input wire start_process,
    output reg process_done,
    output reg busy
);

    // State definitions
    localparam IDLE = 4'b0000;
    localparam READ_SPARSE = 4'b0001;
    localparam READ_NORMAL_ZERO = 4'b0010;
    localparam READ_NORMAL_551 = 4'b0011;
    localparam READ_NORMAL_552 = 4'b0100;
    localparam READ_ACC_HIGH = 4'b0101;
    localparam PROCESS_HIGH = 4'b0110;
    localparam READ_ACC_LOW = 4'b0111;
    localparam PROCESS_LOW = 4'b1000;
    localparam WRITE_HIGH = 4'b1001;
    localparam WRITE_LOW = 4'b1010;
    localparam START_ROUND = 4'b1011;
    localparam LOAD_NEXT_WORD = 4'b1100;
    localparam PROCESS_ROUND = 4'b1101;
    
    reg [3:0] state;
    
    // Storage registers
    reg [15:0] high_shift, low_shift;
    reg [9:0] acc_start_idx_high, acc_start_idx_low;
    reg [4:0] acc_shift_idx_high, acc_shift_idx_low;
    reg [WORD_WIDTH-1:0] normal_word_zero, normal_word_551, normal_word_552;
    reg [WORD_WIDTH-1:0] acc_word_high, acc_word_low;
    
    // Initial shift processor interface
    wire high_processing_done;
    wire [WORD_WIDTH-1:0] high_result;
    reg start_high_process;
    
    wire low_processing_done;
    wire [WORD_WIDTH-1:0] low_result;
    reg start_low_process;

    // Additional registers
    reg [2:0] word_counter;
    reg [9:0] round_counter;  // Counter for ~500 rounds
    reg round_in_progress;

    reg [WORD_WIDTH-1:0] normal_word_in;
    reg round_word_valid;
    reg only_add;
    reg [5:0] normal_sparse_diff;
    reg high_latency;
    reg low_latency;
    
    // Wires for xor_adder
    wire [WORD_WIDTH-1:0] xor_adder_result;
    wire [WORD_WIDTH-1:0] normal_high_word_right_o; // Wire for direct connection
    wire [WORD_WIDTH-1:0] normal_high_word_left_o; // Wire for direct connection
    wire [WORD_WIDTH-1:0] normal_low_word_right_o; // Wire for direct connection
    wire [WORD_WIDTH-1:0] normal_low_word_left_o; // Wire for direct connection

    reg [WORD_WIDTH-1:0] acc_poly;  // Assuming you have this value or need to define it
    reg [5:0] high_start, low_start;  // Assuming you have these values or need to define them

    // Declare wires for xor_adder inputs
    wire [WORD_WIDTH-1:0] normal_high_word_right_i;
    wire [WORD_WIDTH-1:0] normal_high_word_left_i;
    wire [WORD_WIDTH-1:0] normal_low_word_right_i;
    wire [WORD_WIDTH-1:0] normal_low_word_left_i;

    // Instantiate initial_shift_processor for high shift
    initial_shift_processor high_processor (
        .clk(clk),
        .rst_n(rst_n),
        .normal_word_zero(normal_word_zero),
        .normal_word_551(normal_word_551),
        .normal_word_552(normal_word_552),
        .acc_word_high(acc_word_high),
        .high_shift(high_shift),
        .acc_start_idx_high(acc_start_idx_high),
        .acc_shift_idx_high(acc_shift_idx_high),
        .start_process(start_high_process),
        .high_result(high_result),
        .processing_done(high_processing_done)
    );

    // Instantiate low_shift_processor
    initial_shift_processor low_processor (
        .clk(clk),
        .rst_n(rst_n),
        .normal_word_zero(normal_word_zero),
        .normal_word_551(normal_word_551),
        .normal_word_552(normal_word_552),
        .acc_word_high(acc_word_low),
        .high_shift(low_shift),
        .acc_start_idx_high(acc_start_idx_low),
        .acc_shift_idx_high(acc_shift_idx_low),
        .start_process(start_low_process),
        .high_result(low_result),
        .processing_done(low_processing_done)
    );

    // Instantiate round_block
    round_block #(
        .WORD_WIDTH(WORD_WIDTH),
        .QUEUE_SIZE(19),
        .NORMAL_WORD_COUNT(553)
    ) round_inst (
        .clk(clk),
        .rst_n(rst_n),
        .normal_word_in(normal_word_in),
        .word_valid(round_word_valid),
        .only_add(only_add),
        .normal_sparse_diff(normal_sparse_diff),
        .high_latency(high_latency),
        .low_latency(low_latency),
        .normal_high_word_right(normal_high_word_right_o), // Connect to wire
        .normal_high_word_left(normal_high_word_left_o),
        .normal_low_word_right(normal_low_word_right_o),
        .normal_low_word_left(normal_low_word_left_o),
        .processing_done(round_processing_done),
        .word_accepted(round_word_accepted),
        .output_valid(round_output_valid),
        .ready(round_ready)
    );

    // Assign the wire to the xor_adder input
    assign normal_high_word_right_i = normal_high_word_right_o;
    assign normal_high_word_left_i = normal_high_word_left_o;
    assign normal_low_word_right_i = normal_low_word_right_o;
    assign normal_low_word_left_i = normal_low_word_left_o;

    // Instantiate xor_adder
    xor_adder #(
        .WORD_WIDTH(WORD_WIDTH)
    ) xor_adder_inst (
        .normal_high_word_left(normal_high_word_left_i),
        .normal_high_word_right(normal_high_word_right_i),
        .normal_low_word_left(normal_low_word_left_i),
        .normal_low_word_right(normal_low_word_right_i),
        .acc_poly(acc_mem_data),
        .high_start(high_start),
        .low_start(low_start),
        .result(xor_adder_result)
    );

    // Main control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            busy <= 0;
            process_done <= 0;
            acc_mem_write_en <= 0;
            start_high_process <= 0;
            start_low_process <= 0;
            normal_mem_addr_o <= 0;
            sparse_mem_addr_o <= 0;
            acc_mem_addr_o <= 0;
            round_counter <= 0;
            word_counter <= 0;
            round_in_progress <= 0;
            round_word_valid <= 0;  // Ensure this is reset
            only_add <= 0;          // Ensure this is reset
            high_latency <= 0;
            low_latency <= 0;
        end
        else begin
            // Default values
            round_word_valid <= 0;
            
            case (state)
                IDLE: begin
                    if (start_process) begin
                        state <= READ_SPARSE;
                        busy <= 1;
                        sparse_mem_addr_o <= sparse_mem_addr_i;
                    end
                end

                READ_SPARSE: begin
                    // Extract shifts and calculate indices
                    high_shift <= sparse_mem_data[31:16];
                    low_shift <= sparse_mem_data[15:0];
                    acc_start_idx_high <= sparse_mem_data[31:16] >> 5; // Divide by 32
                    acc_start_idx_low <= sparse_mem_data[15:0] >> 5;
                    acc_shift_idx_high <= 32 - (sparse_mem_data[31:16] & 5'h1F);
                    acc_shift_idx_low <= 32 - (sparse_mem_data[15:0] & 5'h1F);
                    normal_sparse_diff <= (sparse_mem_data[15:0] >> 5) - (sparse_mem_data[31:16] >> 5);
                    state <= READ_NORMAL_ZERO;
                    normal_mem_addr_o <= 0;
                end

                READ_NORMAL_ZERO: begin
                    normal_word_zero <= normal_mem_data;
                    state <= READ_NORMAL_551;
                    normal_mem_addr_o <= 551;
                end

                READ_NORMAL_551: begin
                    normal_word_551 <= normal_mem_data;
                    state <= READ_NORMAL_552;
                    normal_mem_addr_o <= 552;
                end

                READ_NORMAL_552: begin
                    normal_word_552 <= normal_mem_data;
                    state <= READ_ACC_HIGH;
                    acc_mem_addr_o <= acc_start_idx_high;
                end

                READ_ACC_HIGH: begin
                    acc_word_high <= acc_mem_data;
                    state <= PROCESS_HIGH;
                    start_high_process <= 1;
                end

                PROCESS_HIGH: begin
                    start_high_process <= 0;
                    if (high_processing_done) begin
                        state <= WRITE_HIGH;
                        acc_mem_write_data <= high_result;
                        acc_mem_write_en <= 1;
                    end
                end

                WRITE_HIGH: begin
                    acc_mem_write_en <= 0;
                    state <= READ_ACC_LOW;
                    acc_mem_addr_o <= acc_start_idx_low;
                end

                READ_ACC_LOW: begin
                    acc_word_low <= acc_mem_data;
                    state <= PROCESS_LOW;
                    start_low_process <= 1;
                end

                PROCESS_LOW: begin
                    start_low_process <= 0;
                    if (low_processing_done) begin
                        state <= WRITE_LOW;
                        acc_mem_write_data <= low_result;
                        acc_mem_write_en <= 1;
                    end
                end

                WRITE_LOW: begin
                    acc_mem_write_en <= 0;
                    state <= START_ROUND;
                    round_counter <= 0;
                end

                START_ROUND: begin
                    
                    state <= LOAD_NEXT_WORD;
                    word_counter <= 0;
                    round_word_valid <= 1;
                    only_add <= 1;
                    normal_word_in <= normal_word_zero;  // First word is zero
                    round_counter <= round_counter + 1;
                    high_start <= acc_shift_idx_high;
                    low_start <= acc_shift_idx_low;

                end

                LOAD_NEXT_WORD: begin
                    if(round_processing_done) begin
                        normal_mem_addr_o <= round_counter;

                        acc_mem_addr_o <= (acc_start_idx_high + round_counter - 1) % MEM_SIZE;
                        state <= PROCESS_ROUND;

                        if(round_counter > 1) begin
                            acc_mem_write_en <= 1;
                            acc_mem_write_data <= xor_adder_result;
                        end

                        if(round_counter + 1 == MEM_SIZE - 3) begin
                            if(high_shift % 32 >= 5) begin
                                high_latency <= 1;
                                high_start <= acc_shift_idx_high + 5;
                            end else begin
                                high_latency <= 0;
                                high_start <= 5 - high_shift % 32;
                            end 

                            if(low_shift % 32 >= 5) begin
                                low_latency <= 1;
                                low_start <= acc_shift_idx_low + 5;
                            end else begin
                                low_latency <= 0;
                                low_start <= 5 - low_shift % 32;
                            end
                        end

                        
                        
                    end
                end

                PROCESS_ROUND: begin
                    if(round_counter == MEM_SIZE - 1 + acc_start_idx_high) begin
                            process_done <= 1;
                    end
                    if (round_ready) begin
                        round_word_valid <= 1;
                        only_add <= 0;

                        normal_word_in <= normal_mem_data;
                        round_counter <= round_counter + 1;
                        state <= LOAD_NEXT_WORD;
                    end
                end
            endcase
        end
    end

endmodule
