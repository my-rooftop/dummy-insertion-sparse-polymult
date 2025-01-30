`timescale 1ns / 1ps

module shift_register #(
    parameter WORD_WIDTH = 32,
    parameter MAX_SIZE = 19,
    parameter IDX_WIDTH = 10  // Index width for word_idx
)(
    input wire clk,
    input wire rst_n,
    
    // Input interface
    input wire [WORD_WIDTH-1:0] word_in,
    input wire word_valid,
    
    // Control interface
    input wire clear,
    
    // Word pair retrieval interface
    input wire [4:0] high_right_idx,  // 5 bits for MAX_SIZE=19
    input wire [4:0] high_left_idx,
    input wire [4:0] low_right_idx,
    input wire [4:0] low_left_idx,
    input wire high_right_valid,
    input wire high_left_valid,
    input wire low_right_valid,
    input wire low_left_valid,
    input wire get_pair,
    
    // Output interface
    output reg [WORD_WIDTH-1:0] high_right_word,
    output reg [WORD_WIDTH-1:0] high_left_word,
    output reg [WORD_WIDTH-1:0] low_right_word,
    output reg [WORD_WIDTH-1:0] low_left_word,
    output reg pair_valid,
    output reg word_accepted,
    output wire [4:0] current_size,
    output wire ready
);

    // Internal storage
    reg [WORD_WIDTH-1:0] register [0:MAX_SIZE-1];
    reg [4:0] size;
    
    // State definitions
    localparam IDLE = 2'b00;
    localparam ADDING = 2'b01;
    localparam RETRIEVING = 2'b10;
    
    reg [1:0] state;
    
    // Assign outputs
    assign current_size = size;
    assign ready = (state == IDLE);
    
    // Counter for shifting operations
    integer i;
    
    // Main control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            initialize_registers();
        end
        else begin
            if (clear) begin
                initialize_registers();
            end
            else begin
                case (state)
                    IDLE: begin
                        pair_valid <= 0;
                        word_accepted <= 0;
                        
                        if (word_valid) begin
                            state <= ADDING;
                        end
                        else if (get_pair) begin
                            state <= RETRIEVING;
                        end
                    end
                    
                    ADDING: begin
                        handle_word_addition();
                        state <= IDLE;
                    end
                    
                    RETRIEVING: begin
                        retrieve_word_pairs();
                        state <= IDLE;
                    end
                    
                    default: state <= IDLE;
                endcase
            end
        end
    end
    
    // Task to initialize registers
    task initialize_registers;
        begin
            size <= 0;
            state <= IDLE;
            pair_valid <= 0;
            word_accepted <= 0;
            high_right_word <= 0;
            high_left_word <= 0;
            low_right_word <= 0;
            low_left_word <= 0;
            
            for (i = 0; i < MAX_SIZE; i = i + 1) begin
                register[i] <= 0;
            end
        end
    endtask
    
    // Task to handle word addition
    task handle_word_addition;
        begin
            if (size == MAX_SIZE) begin
                // Shift all elements left
                for (i = 0; i < MAX_SIZE-1; i = i + 1) begin
                    register[i] <= register[i+1];
                end
                // Add new word at the end
                register[MAX_SIZE-1] <= word_in;
            end
            else begin
                // Add new word at current size
                register[size] <= word_in;
                size <= size + 1;
            end
            word_accepted <= 1;
        end
    endtask
    
    // Task to retrieve word pairs
    task retrieve_word_pairs;
        begin
            // High right word
            high_right_word <= high_right_valid ? register[high_right_idx] : 0;
            
            // High left word
            high_left_word <= high_left_valid ? register[high_left_idx] : 0;
            
            // Low right word
            low_right_word <= low_right_valid ? register[low_right_idx] : 0;
            
            // Low left word
            low_left_word <= low_left_valid ? register[low_left_idx] : 0;
            
            pair_valid <= 1;
        end
    endtask

endmodule