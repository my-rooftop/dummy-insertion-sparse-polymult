module initial_shift_processor #(
    parameter WORD_WIDTH = 32
)(
    input wire clk,
    input wire rst_n,
    
    // Input data
    input wire [WORD_WIDTH-1:0] normal_word_zero,
    input wire [WORD_WIDTH-1:0] normal_word_551,
    input wire [WORD_WIDTH-1:0] normal_word_552,
    input wire [WORD_WIDTH-1:0] acc_word_high,
    input wire [WORD_WIDTH-1:0] acc_word_low,
    
    // Control signals
    input wire [15:0] high_shift,
    input wire [15:0] low_shift,
    input wire [9:0] acc_start_idx_high,
    input wire [9:0] acc_start_idx_low,
    input wire [4:0] acc_shift_idx_high,
    input wire [4:0] acc_shift_idx_low,
    input wire start_process,
    
    // Output interface
    output reg [WORD_WIDTH-1:0] high_result,
    output reg [WORD_WIDTH-1:0] low_result,
    output reg processing_done
);

    // State definitions
    localparam IDLE         = 3'b000;
    localparam EXTRACT_HIGH = 3'b001;
    localparam COMBINE_HIGH = 3'b010;
    localparam EXTRACT_LOW  = 3'b011;
    localparam COMBINE_LOW  = 3'b100;
    
    reg [2:0] state;
    reg [WORD_WIDTH-1:0] combined_word;

    // Function to extract bits based on shifting logic
    function [WORD_WIDTH-1:0] extract_bits(
        input [WORD_WIDTH-1:0] word_zero,
        input [WORD_WIDTH-1:0] word_551,
        input [WORD_WIDTH-1:0] word_552,
        input [4:0] shift_idx,
        input [15:0] shift
    );
        reg [WORD_WIDTH-1:0] high_bits_local;
        reg [4:0] mid_bits_local;
        reg [WORD_WIDTH-1:0] low_bits_local;
    begin
        if (shift[4:0] >= 5) begin
            high_bits_local = word_zero & ((1 << shift_idx) - 1);
            mid_bits_local = word_552[4:0];
            low_bits_local = (word_551 >> (32 - (32 - 5 - shift_idx))) & 
                            ((1 << (32 - 5 - shift_idx)) - 1);
            extract_bits = (high_bits_local << (32 - shift_idx)) |
                           (mid_bits_local << (32 - 5 - shift_idx)) |
                           low_bits_local;
        end
        else begin
            high_bits_local = word_zero & ((1 << shift_idx) - 1);
            low_bits_local = (word_552 >> (5 - shift[4:0])) & 
                            ((1 << shift[4:0]) - 1);
            extract_bits = (high_bits_local << shift[4:0]) | low_bits_local;
        end
    end
    endfunction

    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            processing_done <= 0;
            high_result <= 0;
            low_result <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    if (start_process) begin
                        state <= EXTRACT_HIGH;
                        processing_done <= 0;
                    end
                end
                
                EXTRACT_HIGH: begin
                    combined_word <= extract_bits(normal_word_zero, normal_word_551, normal_word_552, acc_shift_idx_high, high_shift);
                    state <= COMBINE_HIGH;
                end
                
                COMBINE_HIGH: begin
                    high_result <= acc_word_high ^ combined_word;
                    state <= EXTRACT_LOW;
                end
                
                EXTRACT_LOW: begin
                    combined_word <= extract_bits(normal_word_zero, normal_word_551, normal_word_552, acc_shift_idx_low, low_shift);
                    state <= COMBINE_LOW;
                end
                
                COMBINE_LOW: begin
                    low_result <= acc_word_low ^ combined_word;
                    state <= IDLE;
                    processing_done <= 1;
                end
            endcase
        end
    end

endmodule