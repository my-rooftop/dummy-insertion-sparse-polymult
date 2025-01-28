`timescale 1ns / 1ps

module round_block #(
    parameter WORD_WIDTH = 32,
    parameter QUEUE_SIZE = 19,
    parameter NORMAL_WORD_COUNT = 553
)(
    input wire clk,
    input wire rst_n,
    
    // Normal polynomial word input interface
    input wire [WORD_WIDTH-1:0] normal_word_in,
    input wire word_valid,
    input wire only_add,         // New signal to control operation mode
    
    // Control signals
    input wire [5:0] normal_sparse_diff,
    input wire high_latency,
    input wire low_latency,
    
    // Output interface
    output reg [WORD_WIDTH-1:0] normal_high_word_right,
    output reg [WORD_WIDTH-1:0] normal_high_word_left,
    output reg [WORD_WIDTH-1:0] normal_low_word_right,
    output reg [WORD_WIDTH-1:0] normal_low_word_left,
    output reg processing_done,
    output reg word_accepted,
    output reg output_valid,
    output reg ready
);

    // State definitions
    localparam IDLE = 2'b00;
    localparam ADDING = 2'b01;
    localparam PROCESSING = 2'b10;
    
    reg [1:0] state;
    reg [WORD_WIDTH-1:0] word_queue [0:QUEUE_SIZE-1];
    reg [5:0] queue_count;
    reg [9:0] process_count;
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            queue_count <= 0;
            process_count <= 0;
            processing_done <= 0;
            word_accepted <= 0;
            ready <= 1;
        end
        else begin
            // Clear single-cycle signals
            word_accepted <= 0;
            processing_done <= 0;
            
            case (state)
                IDLE: begin
                    ready <= 1;
                    if (word_valid) begin
                        state <= ADDING;
                        ready <= 0;
                    end
                end

                ADDING: begin
                    // Shift all elements one position to the left (0th element gets removed)
                    if (queue_count == QUEUE_SIZE) begin
                        for (i = 0; i < QUEUE_SIZE-1; i = i + 1) begin
                            word_queue[i] <= word_queue[i+1];
                        end
                        word_queue[QUEUE_SIZE-1] <= normal_word_in;
                    end
                    else begin
                        word_queue[queue_count] <= normal_word_in;
                    end
                    
                    if (queue_count < QUEUE_SIZE)
                        queue_count <= queue_count + 1;
                        
                    word_accepted <= 1;
                    
                    // If only_add is not set, proceed to processing
                    if (!only_add) begin
                        process_count <= process_count + 1;
                        state <= PROCESSING;
                    end else begin
                        state <= IDLE;
                        normal_high_word_right <= 0;
                        normal_high_word_left <= 0;
                        normal_low_word_right <= 0;
                        normal_low_word_left <= 0;
                        output_valid <= 0;
                        processing_done <= 1;
                    end
                end


                PROCESSING: begin
                    if (queue_count >= 2) begin
                        // Process high words
                        if (process_count >= NORMAL_WORD_COUNT) begin
                            normal_high_word_right <= 0;
                            normal_high_word_left <= 0;
                        end else begin
                            normal_high_word_right <= word_queue[queue_count - 2 - high_latency];
                            normal_high_word_left <= word_queue[queue_count - 1 - high_latency];
                        end

                        // Process low words
                        if (process_count < normal_sparse_diff + 1) begin
                            normal_low_word_right <= 0;
                            normal_low_word_left <= 0;
                        end else begin
                            normal_low_word_right <= word_queue[queue_count - normal_sparse_diff - 2 - low_latency];
                            normal_low_word_left <= word_queue[queue_count - normal_sparse_diff - 1 - low_latency];
                        end

                        processing_done <= 1;
                        output_valid <= 1;
                    end
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
