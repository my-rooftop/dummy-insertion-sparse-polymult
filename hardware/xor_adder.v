module xor_adder #( //slice LUTs 247
   parameter WORD_WIDTH = 32
)(
   // Input words
   input wire [WORD_WIDTH-1:0] normal_high_word_left,
   input wire [WORD_WIDTH-1:0] normal_high_word_right,
   input wire [WORD_WIDTH-1:0] normal_low_word_left,
   input wire [WORD_WIDTH-1:0] normal_low_word_right,
   input wire [WORD_WIDTH-1:0] acc_poly,
    
   // Start positions
   input wire [5:0] high_start,
   input wire [5:0] low_start,
    
   // Output
   output wire [WORD_WIDTH-1:0] result
);

   // Internal wires
   wire [63:0] normal_high_concat;
   wire [63:0] normal_low_concat;
   wire [WORD_WIDTH-1:0] normal_high_bits;
   wire [WORD_WIDTH-1:0] normal_low_bits;
    
   // Concatenate words
   assign normal_high_concat = {normal_high_word_left, normal_high_word_right};
   assign normal_low_concat = {normal_low_word_left, normal_low_word_right};
    
   // Extract 32 bits from start positions
   assign normal_high_bits = normal_high_concat[high_start +: WORD_WIDTH];
   assign normal_low_bits = normal_low_concat[low_start +: WORD_WIDTH];
    
   // Final XOR
   assign result = acc_poly ^ normal_high_bits ^ normal_low_bits;

endmodule
