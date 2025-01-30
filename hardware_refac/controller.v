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
    input wire [WORD_WIDTH-1:0] sparse_mem_data_i,
    input wire [WORD_WIDTH-1:0] acc_mem_data_i,
    input wire [9:0] sparse_mem_addr_i,

    output reg [WORD_WIDTH-1:0] acc_mem_write_data_o,
    output reg acc_mem_write_en,
    output reg [9:0] normal_mem_addr_o,
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

    reg [3:0] state;
    reg [15:0] high_shift, low_shift;
    reg [9:0] acc_start_idx_high, acc_start_idx_low;
    reg [4:0] acc_shift_idx_high, acc_shift_idx_low;
    reg [5:0] normal_sparse_diff;

    reg [WORD_WIDTH-1:0] normal_word_zero, normal_word_551, normal_word_552;


    reg [WORD_WIDTH - 1:0] initial_acc_word_i;
    reg [15:0] initial_shift;
    reg [4:0] initial_acc_shift_idx;
    reg initial_start_process;
    wire [WORD_WIDTH - 1:0] initial_result;
    wire initial_processing_done;

    // Instantiate initial_shift_processor for high shift
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

    // Reset and initialization
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            busy <= 0;
            process_done <= 0;
            acc_mem_write_en <= 0;
            
            normal_mem_addr_o <= 0;
            acc_mem_addr_o <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    if (start_process) begin
                        state <= READ_SPARSE;
                        busy <= 1'b1;
                        
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
                    state <= IDLE;
                    process_done <= 1;
                    busy <= 0;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule