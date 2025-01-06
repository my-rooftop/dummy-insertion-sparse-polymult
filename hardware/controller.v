module controller #(
    parameter WORD_WIDTH = 32,
    parameter MEM_SIZE = 553    // Total memory size in words
    parameter MEM_SPARESE_SIZE = 50
)(
    input wire clk,
    input wire rst_n,
    
    // Memory interfaces
    input wire [WORD_WIDTH-1:0] normal_mem_data,
    input wire [WORD_WIDTH-1:0] sparse_mem_data,
    input wire [WORD_WIDTH-1:0] acc_mem_data,
    input wire [9:0] normal_mem_addr_i,
    input wire [9:0] sparse_mem_addr_i,
    input wire [9:0] acc_mem_addr_i,

    output reg [WORD_WIDTH-1:0] acc_mem_write_data,
    output reg acc_mem_write_en,
    output wire [9:0] normal_mem_addr_o,
    output wire [9:0] sparse_mem_addr_o,
    output wire [9:0] acc_mem_addr_o,
    
    // Control signals
    input wire start_process,
    output reg process_done,
    output reg busy
);

    // State definitions
    localparam IDLE = 3'b000;
    localparam READ_SPARSE = 3'b001;
    localparam CALC_INDICES = 3'b010;
    localparam PROCESS_WORD = 3'b011;
    localparam WRITE_RESULT = 3'b100;

    reg [2:0] state;
    
    // Internal registers
    reg [15:0] high_shift, low_shift;
    reg [9:0] acc_start_idx_high, acc_start_idx_low;
    reg [5:0] acc_shift_idx_high, acc_shift_idx_low;
    reg high_latency, low_latency;
    reg [9:0] word_counter;
    
    // Round block interface
    wire [WORD_WIDTH-1:0] normal_high_word_right;
    wire [WORD_WIDTH-1:0] normal_high_word_left;
    wire [WORD_WIDTH-1:0] normal_low_word_right;
    wire [WORD_WIDTH-1:0] normal_low_word_left;
    wire processing_done;
    wire word_accepted;
    wire round_block_ready;
    
    reg round_block_word_valid;
    reg round_block_process_start;
    
    // XOR adder result
    wire [WORD_WIDTH-1:0] xor_result;

    // Instantiate round_block
    round_block #(
        .WORD_WIDTH(WORD_WIDTH)
    ) round_block_inst (
        .clk(clk),
        .rst_n(rst_n),
        .normal_word_in(normal_mem_data),
        .word_valid(round_block_word_valid),
        .process_start(round_block_process_start),
        .normal_sparse_diff(acc_start_idx_low - acc_start_idx_high),
        .high_latency(high_latency),
        .low_latency(low_latency),
        .normal_high_word_right(normal_high_word_right),
        .normal_high_word_left(normal_high_word_left),
        .normal_low_word_right(normal_low_word_right),
        .normal_low_word_left(normal_low_word_left),
        .processing_done(processing_done),
        .word_accepted(word_accepted),
        .ready(round_block_ready)
    );

    // Instantiate xor_adder
    xor_adder #(
        .WORD_WIDTH(WORD_WIDTH)
    ) xor_adder_inst (
        .normal_high_word_left(normal_high_word_left),
        .normal_high_word_right(normal_high_word_right),
        .normal_low_word_left(normal_low_word_left),
        .normal_low_word_right(normal_low_word_right),
        .acc_poly(acc_mem_data),
        .normal_start(acc_shift_idx_high),
        .sparse_start(acc_shift_idx_low),
        .result(xor_result)
    );

    // Main control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            busy <= 0;
            process_done <= 0;
            acc_mem_write_en <= 0;
            round_block_word_valid <= 0;
            round_block_process_start <= 0;
            word_counter <= 0;
            high_latency <= 0;
            low_latency <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    if (start_process) begin
                        state <= READ_SPARSE;
                        busy <= 1;
                        sparse_mem_addr <= 0;
                    end
                end

                READ_SPARSE: begin
                    // Extract shifts from sparse memory word
                    high_shift <= sparse_mem_data[31:16];
                    low_shift <= sparse_mem_data[15:0];
                    state <= CALC_INDICES;
                end

                CALC_INDICES: begin
                    // Calculate indices and shifts
                    acc_start_idx_high <= high_shift[15:5];  // Division by 32
                    acc_shift_idx_high <= 32 - high_shift[4:0];  // Remainder
                    acc_start_idx_low <= low_shift[15:5];
                    acc_shift_idx_low <= 32 - low_shift[4:0];
                    normal_mem_addr <= 0;
                    state <= PROCESS_WORD;
                    round_block_word_valid <= 1;
                end

                PROCESS_WORD: begin
                    round_block_word_valid <= 0;
                    
                    if (word_accepted) begin
                        if (word_counter < MEM_SIZE - 1) begin
                            normal_mem_addr <= normal_mem_addr + 1;
                            word_counter <= word_counter + 1;
                            round_block_word_valid <= 1;
                        end
                        else begin
                            round_block_process_start <= 1;
                            acc_mem_addr <= acc_start_idx_high;
                        end
                    end
                    
                    if (processing_done) begin
                        state <= WRITE_RESULT;
                        acc_mem_write_data <= xor_result;
                        acc_mem_write_en <= 1;
                    end
                end

                WRITE_RESULT: begin
                    acc_mem_write_en <= 0;
                    if (acc_mem_addr == (acc_start_idx_high + word_counter)) begin
                        state <= IDLE;
                        busy <= 0;
                        process_done <= 1;
                        word_counter <= 0;
                    end
                    else begin
                        acc_mem_addr <= acc_mem_addr + 1;
                        round_block_process_start <= 1;
                    end
                end
            endcase
        end
    end

endmodule
