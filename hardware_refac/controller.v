`timescale 1ns / 1ps

module controller #(
    parameter WORD_WIDTH = 32,
    parameter MEM_SIZE = 553,    // Total memory size in words
    parameter MEM_SPARSE_SIZE = 50
)(
    input wire clk,
    input wire rst_n,
    
    // Memory interfaces
    input wire [WORD_WIDTH-1:0] normal_mem_data_i,
    input wire [9:0] normal_mem_addr_i,
    input wire [WORD_WIDTH-1:0] sparse_mem_data_i,
    input wire [WORD_WIDTH-1:0] acc_mem_data_i,
    input wire [9:0] sparse_mem_addr_i,

    output reg [WORD_WIDTH-1:0] acc_mem_write_data_o,
    output reg acc_mem_write_en,
    output reg [9:0] normal_mem_addr_o,
    output reg [9:0] acc_mem_addr_o,
    
    // Control signals
    input wire start_process,
    input wire word_ready,
    output reg process_done,
    output reg busy
);

    // State definitions
    localparam IDLE = 5'b00000;
    localparam READ_SPARSE = 5'b00001;
    localparam READ_NORMAL_ZERO = 5'b00010;
    localparam READ_NORMAL_551 = 5'b00011;
    localparam READ_NORMAL_552 = 5'b00100;
    localparam READ_ACC_HIGH = 5'b00101;
    localparam PROCESS_HIGH = 5'b00110;
    localparam READ_ACC_LOW = 5'b00111;
    localparam PROCESS_LOW = 5'b01000;
    localparam WRITE_HIGH = 5'b01001;
    localparam WRITE_LOW = 5'b01010;
    localparam ROUND_LOAD_ZERO = 5'b01011;
    localparam ROUND_LOAD = 5'b01100;
    localparam ROUND_ADD = 5'b01101;
    localparam ROUND_GET_INDEX = 5'b01110;
    localparam ROUND_GET_PAIR = 5'b01111;
    localparam ROUND_UPDATE_LATENCY = 5'b10000;
    localparam ROUND_END = 5'b10001;
    localparam ROUND_LOAD_WAIT = 5'b10010;

    reg [4:0] state;
    reg [15:0] high_shift, low_shift;
    reg [9:0] acc_start_idx_high, acc_start_idx_low;
    reg [4:0] acc_shift_idx_high, acc_shift_idx_low;
    reg [5:0] normal_sparse_diff;

    reg [WORD_WIDTH-1:0] normal_word_zero, normal_word_551, normal_word_552;
    reg [WORD_WIDTH-1:0] acc_mem;

    // Shift Register related signals
    reg [WORD_WIDTH-1:0] shift_reg_word_in;
    reg shift_reg_word_valid;
    reg shift_reg_clear;
    reg [4:0] high_right_idx, high_left_idx;
    reg [4:0] low_right_idx, low_left_idx;
    reg high_right_valid, high_left_valid;
    reg low_right_valid, low_left_valid;
    reg get_pair;
    
    wire [WORD_WIDTH-1:0] high_right_word;
    wire [WORD_WIDTH-1:0] high_left_word;
    wire [WORD_WIDTH-1:0] low_right_word;
    wire [WORD_WIDTH-1:0] low_left_word;
    wire pair_valid;
    wire word_accepted;
    
    // shift_register 인스턴스화 부분의 wire/reg 선언 수정
    wire [4:0] shift_reg_size;  // current_size를 shift_reg_size로 이름 변경
    reg [4:0] current_size;     // current_size는 reg로 선언

    wire shift_reg_ready;

    reg [9:0] load_word_idx;
    reg high_latency, low_latency;

    reg [WORD_WIDTH-1:0] initial_acc_word_i;
    reg [15:0] initial_shift;
    reg [4:0] initial_acc_shift_idx;
    reg initial_start_process;
    wire [WORD_WIDTH-1:0] initial_result;
    wire initial_processing_done;
    
    wire [WORD_WIDTH-1:0] xor_result;

    // Instantiate initial_shift_processor
    initial_shift_processor initial_processor (
        .clk(clk),
        .rst_n(rst_n),
        .normal_word_zero(normal_word_zero),
        .normal_word_551(normal_word_551),
        .normal_word_552(normal_word_552),
        .acc_word_i(initial_acc_word_i),
        .shift(initial_shift),
        .acc_shift_idx(initial_acc_shift_idx),
        .start_process(initial_start_process),
        .result(initial_result),
        .processing_done(initial_processing_done)
    );

    // shift_register 인스턴스 수정
    shift_register #(
        .WORD_WIDTH(WORD_WIDTH),
        .MAX_SIZE(19)
    ) shift_reg (
        .clk(clk),
        .rst_n(rst_n),
        .word_in(shift_reg_word_in),
        .word_valid(shift_reg_word_valid),
        .clear(shift_reg_clear),
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
        .current_size(shift_reg_size),  // 이름 변경
        .ready(shift_reg_ready)
    );

    xor_adder xor_adder_inst (
        .normal_high_word_left(high_left_word),
        .normal_high_word_right(high_right_word),
        .normal_low_word_left(low_left_word),
        .normal_low_word_right(low_right_word),
        .acc_poly(acc_mem),
        .high_start(acc_shift_idx_high),
        .low_start(acc_shift_idx_low),
        .result(xor_result)
    );


    // Reset and initialization
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // State and control signals
            state <= IDLE;
            busy <= 0;
            process_done <= 0;
            acc_mem_write_en <= 0;
            
            // Memory addresses
            normal_mem_addr_o <= 0;
            acc_mem_addr_o <= 0;
            
            // Shift and index variables
            high_shift <= 0;
            low_shift <= 0;
            acc_start_idx_high <= 0;
            acc_start_idx_low <= 0;
            acc_shift_idx_high <= 0;
            acc_shift_idx_low <= 0;
            normal_sparse_diff <= 0;
            
            // Memory data registers
            normal_word_zero <= 0;
            normal_word_551 <= 0;
            normal_word_552 <= 0;
            acc_mem <= 0;
            
            // Shift register control signals
            shift_reg_word_in <= 0;
            shift_reg_word_valid <= 0;
            shift_reg_clear <= 1;  // Clear shift register on reset
            high_right_idx <= 0;
            high_left_idx <= 0;
            low_right_idx <= 0;
            low_left_idx <= 0;
            high_right_valid <= 0;
            high_left_valid <= 0;
            low_right_valid <= 0;
            low_left_valid <= 0;
            get_pair <= 0;
            
            // Processing control
            load_word_idx <= 0;
            high_latency <= 0;
            low_latency <= 0;
            
            // Initial processor control
            initial_acc_word_i <= 0;
            initial_shift <= 0;
            initial_acc_shift_idx <= 0;
            initial_start_process <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    if (start_process) begin
                        state <= READ_SPARSE;
                        busy <= 1'b1;
                        shift_reg_clear <= 0;
                    end
                end

                READ_SPARSE: begin
                    state <= READ_NORMAL_ZERO;
                    high_shift <= sparse_mem_data_i[31:16];
                    low_shift <= sparse_mem_data_i[15:0];
                    acc_start_idx_high <= sparse_mem_data_i[31:16] >> 5; // Divide by 32
                    acc_start_idx_low <= sparse_mem_data_i[15:0] >> 5;
                    acc_shift_idx_high <= 32 - (sparse_mem_data_i[31:16] & 5'h1F);
                    acc_shift_idx_low <= 32 - (sparse_mem_data_i[15:0] & 5'h1F);
                    normal_sparse_diff <= (sparse_mem_data_i[15:0] >> 5) - (sparse_mem_data_i[31:16] >> 5);
                    normal_mem_addr_o <= 0;
                    high_latency <= 0;
                    low_latency <= 0;
                end

                READ_NORMAL_ZERO: begin
                    normal_word_zero <= normal_mem_data_i;
                    normal_mem_addr_o <= 551;
                    state <= READ_NORMAL_551;
                end

                READ_NORMAL_551: begin
                    normal_word_551 <= normal_mem_data_i;
                    normal_mem_addr_o <= 552;
                    state <= READ_NORMAL_552;
                end

                READ_NORMAL_552: begin
                    normal_word_552 <= normal_mem_data_i;
                    acc_mem_addr_o <= acc_start_idx_high;
                    state <= READ_ACC_HIGH;
                end
                
                READ_ACC_HIGH: begin
                    state <= PROCESS_HIGH;
                    initial_acc_word_i <= acc_mem_data_i;
                    initial_shift <= high_shift;
                    initial_acc_shift_idx <= acc_shift_idx_high;
                    initial_start_process <= 1;
                end
                
                PROCESS_HIGH: begin
                    initial_start_process <= 0;
                    if (initial_processing_done) begin
                        state <= WRITE_HIGH;
                        acc_mem_write_data_o <= initial_result;
                        acc_mem_write_en <= 1;
                    end
                end

                WRITE_HIGH: begin
                    acc_mem_write_en <= 0;
                    state <= READ_ACC_LOW;
                    acc_mem_addr_o <= acc_start_idx_low;
                end

                READ_ACC_LOW: begin
                    state <= PROCESS_LOW;
                    initial_acc_word_i <= acc_mem_data_i;
                    initial_shift <= low_shift;
                    initial_acc_shift_idx <= acc_shift_idx_low;
                    initial_start_process <= 1;
                end

                PROCESS_LOW: begin
                    initial_start_process <= 0;
                    if (initial_processing_done) begin
                        state <= WRITE_LOW;
                        acc_mem_write_data_o <= initial_result;
                        acc_mem_write_en <= 1;
                    end
                end

                WRITE_LOW: begin
                    acc_mem_write_en <= 0;
                    load_word_idx <= 0;
                    shift_reg_word_in <= normal_word_zero;
                    shift_reg_word_valid <= 1;
                    high_right_idx <= 0;
                    high_left_idx <= 0;
                    low_right_idx <= 0;
                    low_left_idx <= 0;
                    high_right_valid <= 0;
                    high_left_valid <= 0;
                    low_right_valid <= 0;
                    low_left_valid <= 0;
                    get_pair <= 0;
                    state <= ROUND_LOAD_ZERO;

                end

                ROUND_LOAD_ZERO: begin
                    shift_reg_word_valid <= 0;
                    if(word_accepted) begin
                        state <= ROUND_LOAD;
                    end
                end

                ROUND_LOAD: begin
                    load_word_idx <= load_word_idx + 1;
                    if (load_word_idx == MEM_SIZE + normal_sparse_diff) begin
                        state <= ROUND_END;
                    end
                    else begin
                        normal_mem_addr_o <= load_word_idx % MEM_SIZE;
                        acc_mem_addr_o <= (load_word_idx + acc_start_idx_high) % MEM_SIZE;
                        state <= ROUND_LOAD_WAIT;
                    end
                end

                ROUND_LOAD_WAIT: begin
                    state <= ROUND_ADD;
                end

                ROUND_ADD: begin
                    if (normal_mem_addr_i == load_word_idx % MEM_SIZE) begin
                        shift_reg_word_in <= normal_mem_data_i;
                        acc_mem <= acc_mem_data_i;
                        shift_reg_word_valid <= 1;
                        high_right_idx <= 0;
                        high_left_idx <= 0;
                        low_right_idx <= 0;
                        low_left_idx <= 0;
                        high_right_valid <= 0;
                        high_left_valid <= 0;
                        low_right_valid <= 0;
                        low_left_valid <= 0;
                        get_pair <= 0;
                        state <= ROUND_GET_INDEX;
                    end
                end

                ROUND_GET_INDEX: begin
                    if (word_accepted) begin
                        current_size <= shift_reg_size;  // shift_register의 size를 current_size에 저장
                        shift_reg_word_in <= 0;
                        shift_reg_word_valid <= 0;
                        high_left_idx <= 0;
                        high_right_idx <= 0;
                        low_left_idx <= 0;
                        low_right_idx <= 0;
                        if(load_word_idx >= MEM_SIZE) begin
                            high_left_valid <= 0;
                            high_right_valid <= 0;
                        end
                        else begin
                            high_left_valid <= 1;
                            high_right_valid <= 1;
                            high_left_idx <= current_size - 1 - high_latency;
                            high_right_idx <= current_size - 2 - high_latency;
                        end

                        if (load_word_idx < normal_sparse_diff + 1) begin
                            low_left_valid <= 0;
                            low_right_valid <= 0;
                        end
                        else begin
                            low_left_valid <= 1;
                            low_right_valid <= 1;
                            low_left_idx <= current_size - normal_sparse_diff - 1 - low_latency;
                            low_right_idx <= current_size - normal_sparse_diff - 2 - low_latency;
                        end
                        get_pair <= 1;
                        state <= ROUND_GET_PAIR;
                    end
                end

                ROUND_GET_PAIR: begin
                    if (pair_valid) begin
                        acc_mem_write_data_o <= xor_result;
                        acc_mem_write_en <= 1;
                        acc_mem_addr_o <= (load_word_idx + acc_start_idx_high) % MEM_SIZE;
                        if (acc_start_idx_high + load_word_idx == MEM_SIZE - 1) begin
                            state <= ROUND_UPDATE_LATENCY;
                        end
                        else begin
                            state <= ROUND_LOAD;
                        end
                    end
                end

                ROUND_UPDATE_LATENCY: begin
                    if(high_shift % 32 >= 5) begin
                        high_latency <= 1;
                        acc_shift_idx_high <= acc_shift_idx_high + 5;
                    end
                    else begin
                        high_latency <= 0;
                        acc_shift_idx_high <= 5 - high_shift % 32;
                    end

                    if(low_shift % 32 >= 5) begin
                        low_latency <= 1;
                        acc_shift_idx_low <= acc_shift_idx_low + 5;
                    end
                    else begin
                        low_latency <= 0;
                        acc_shift_idx_low <= 5 - low_shift % 32;
                    end
                end

                ROUND_END: begin
                    process_done <= 1;
                    busy <= 0;
                    acc_mem_write_en <= 0;
                    shift_reg_clear <= 1;
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule