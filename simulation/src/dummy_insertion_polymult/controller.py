from typing import List
from memory import PolynomialMemory
from round_block import RoundBlock
from xor_adder import XORAdder

class Controller:
    def __init__(self, normal_mem, sparse_mem, acc_mem, debug_mode: bool = False):
        self.normal_mem = normal_mem
        self.sparse_mem = sparse_mem
        self.acc_mem = acc_mem
        self.word_size = 32
        self.debug_mode = debug_mode
        self.round_block = RoundBlock(debug_mode=debug_mode)
        self.xor_adder = XORAdder(debug_mode=debug_mode)
        self.low_latency = 0
        self.high_latency = 0

    def debug_print(self, message: str) -> None:
        if self.debug_mode:
            print(message)

    def _process_shift_greater_than_5(self, normal_word_zero, acc_start_idx, acc_shift_idx, shift_type: str = "high"):
            """Process shift when shift is >= 5 for both high and low cases"""
            normal_word_551 = self.normal_mem.get_word(len(self.normal_mem.memory) - 2)
            normal_word_552 = self.normal_mem.get_word(len(self.normal_mem.memory) - 1)
            acc_word_first = self.acc_mem.get_word(acc_start_idx - 1)
            
            if self.debug_mode:
                self.debug_print(f"\n=== {shift_type.title()} Shift Processing (>= 5) ===")
                self.debug_print("Input values:")
                self.debug_print(f"normal_word_zero [0]   : {normal_word_zero:032b}")
                self.debug_print(f"normal_word_551 [551]  : {normal_word_551:032b}")
                self.debug_print(f"normal_word_552 [552]  : {normal_word_552:032b}")
                self.debug_print(f"acc_word_first [{acc_start_idx-1}]: {acc_word_first:032b}")
                self.debug_print(f"acc_shift_idx          : {acc_shift_idx}")
            
            # Extract high bits
            high_bits = normal_word_zero & ((1 << acc_shift_idx) - 1)
            if self.debug_mode:
                self.debug_print("\nHigh bits extraction:")
                mask = (1 << acc_shift_idx) - 1
                self.debug_print(f"Source   : {normal_word_zero:032b}")
                self.debug_print(f"Mask     : {mask:032b}")
                self.debug_print(f"Extracted: {high_bits:032b}")
            
            # Extract mid bits
            mid_bits = normal_word_552 & ((1 << 5) - 1)
            if self.debug_mode:
                self.debug_print("\nMid bits extraction:")
                mask = (1 << 5) - 1
                self.debug_print(f"Source   : {normal_word_552:032b}")
                self.debug_print(f"Mask     : {mask:032b}")
                self.debug_print(f"Extracted: {mid_bits:05b}")
            
            # Extract low bits
            remaining_bits = 32 - 5 - acc_shift_idx
            low_bits = (normal_word_551 >> (32 - remaining_bits)) & ((1 << remaining_bits) - 1)
            if self.debug_mode:
                self.debug_print("\nLow bits extraction:")
                self.debug_print(f"Source        : {normal_word_551:032b}")
                self.debug_print(f"Shift amount  : {32 - remaining_bits}")
                self.debug_print(f"Remaining bits: {remaining_bits}")
                self.debug_print(f"Extracted     : {low_bits:b}")
            
            # Combine bits
            combined_word = (high_bits << (32 - acc_shift_idx)) | \
                        (mid_bits << remaining_bits) | \
                        low_bits
            
            if self.debug_mode:
                self.debug_print("\nBit combination:")
                self.debug_print(f"High shifted: {high_bits << (32 - acc_shift_idx):032b}")
                self.debug_print(f"Mid shifted : {mid_bits << remaining_bits:032b}")
                self.debug_print(f"Low bits    : {low_bits:032b}")
                self.debug_print(f"Combined    : {combined_word:032b}")
            
            # XOR operation
            result = acc_word_first ^ combined_word
            if self.debug_mode:
                self.debug_print("\nFinal XOR:")
                self.debug_print(f"Acc word  : {acc_word_first:032b}")
                self.debug_print(f"Combined  : {combined_word:032b}")
                self.debug_print(f"Result    : {result:032b}")
                self.debug_print(f"\n=== {shift_type.title()} Shift Processing End ===\n")
            
            self.acc_mem.set_word(acc_start_idx - 1, result)
            return result
    
    def _process_shift_less_than_5(self, normal_word_zero, normal_word_552, acc_start_idx, 
                                    acc_shift_idx, shift_remainder, shift_type: str = "high"):
            """Process shift when shift is < 5 for both high and low cases"""
            acc_word_first = self.acc_mem.get_word(acc_start_idx - 1)
            
            if self.debug_mode:
                self.debug_print(f"\n=== {shift_type.title()} Shift Processing (< 5) ===")
                self.debug_print("Input values:")
                self.debug_print(f"normal_word_zero [0]   : {normal_word_zero:032b}")
                self.debug_print(f"normal_word_552 [552]  : {normal_word_552:032b}")
                self.debug_print(f"acc_word_first [{acc_start_idx-1}]: {acc_word_first:032b}")
                self.debug_print(f"acc_shift_idx          : {acc_shift_idx}")
                self.debug_print(f"shift_remainder        : {shift_remainder}")
            
            # Extract high bits
            high_bits = normal_word_zero & ((1 << acc_shift_idx) - 1)
            if self.debug_mode:
                self.debug_print("\nHigh bits extraction:")
                mask = (1 << acc_shift_idx) - 1
                self.debug_print(f"Source   : {normal_word_zero:032b}")
                self.debug_print(f"Mask     : {mask:032b}")
                self.debug_print(f"Extracted: {high_bits:032b}")
            
            # Extract low bits
            low_bits = (normal_word_552 >> (5 - shift_remainder)) & ((1 << shift_remainder) - 1)
            if self.debug_mode:
                self.debug_print("\nLow bits extraction:")
                self.debug_print(f"Source   : {normal_word_552:032b}")
                self.debug_print(f"Shift    : {5 - shift_remainder}")
                mask = (1 << shift_remainder) - 1
                self.debug_print(f"Mask     : {mask:032b}")
                self.debug_print(f"Extracted: {low_bits:b}")
            
            # Combine bits
            combined_word = (high_bits << shift_remainder) | low_bits
            if self.debug_mode:
                self.debug_print("\nBit combination:")
                self.debug_print(f"High shifted: {high_bits << shift_remainder:032b}")
                self.debug_print(f"Low bits    : {low_bits:032b}")
                self.debug_print(f"Combined    : {combined_word:032b}")
            
            # XOR operation
            result = acc_word_first ^ combined_word
            if self.debug_mode:
                self.debug_print("\nFinal XOR:")
                self.debug_print(f"Acc word  : {acc_word_first:032b}")
                self.debug_print(f"Combined  : {combined_word:032b}")
                self.debug_print(f"Result    : {result:032b}")
                self.debug_print(f"\n=== {shift_type.title()} Shift Processing End ===\n")
            
            self.acc_mem.set_word(acc_start_idx - 1, result)
            return result

    def _process_initial_shifts(self, normal_word_zero, high_shift, low_shift, 
                                acc_start_idx_high, acc_start_idx_low,
                                acc_shift_idx_high, acc_shift_idx_low,
                                ):
            """Process initial high and low shifts before the main loop"""
            # Process high shift
            normal_word_552 = self.normal_mem.get_word(len(self.normal_mem.memory) - 1)

            if high_shift % 32 >= 5:
                self._process_shift_greater_than_5(normal_word_zero, acc_start_idx_high + 1, acc_shift_idx_high)
            else:
                self._process_shift_less_than_5(normal_word_zero, normal_word_552, 
                                                acc_start_idx_high + 1, acc_shift_idx_high, high_shift % 32)
            
            # Process low shift if needed
            if low_shift % 32 >= 5:
                self._process_shift_greater_than_5(normal_word_zero, acc_start_idx_low + 1, acc_shift_idx_low)
            else:
                self._process_shift_less_than_5(normal_word_zero, normal_word_552,
                                                acc_start_idx_low + 1, acc_shift_idx_low, low_shift % 32)

    def process_word(self, word_idx: int) -> None:
        sparse_word = self.sparse_mem.get_word(word_idx)
        
        # Extract shift amounts
        high_shift = (sparse_word >> 16) & 0xFFFF
        low_shift = sparse_word & 0xFFFF
        
        # Calculate indices and differences
        acc_start_idx_high = (high_shift // 32)
        acc_shift_idx_high = 32 - (high_shift % 32)
        acc_start_idx_low = (low_shift // 32)
        acc_shift_idx_low = 32 - (low_shift % 32)
        high_low_diff = acc_start_idx_low - acc_start_idx_high

        if self.debug_mode:
            self.debug_print("\n=== Processing Word Parameters ===")
            self.debug_print(f"Word Index: {word_idx}")
            self.debug_print(f"Sparse Word: {sparse_word:032b}")
            self.debug_print("\nShift Values:")
            self.debug_print(f"High Shift: {high_shift}")
            self.debug_print(f"Low Shift: {low_shift}")
            self.debug_print("\nCalculated Indices:")
            self.debug_print(f"acc_start_idx_high: {acc_start_idx_high}")
            self.debug_print(f"acc_shift_idx_high: {acc_shift_idx_high}")
            self.debug_print(f"acc_start_idx_low: {acc_start_idx_low}")
            self.debug_print(f"acc_shift_idx_low: {acc_shift_idx_low}")
            self.debug_print(f"high_low_diff: {high_low_diff}")
            self.debug_print("===================================\n")
        
        # Setup round block
        normal_word_zero = self.normal_mem.get_word(0)
        self.round_block.add_normal_poly_word(normal_word_zero, 0)
        self.round_block.normal_sparse_diff = high_low_diff
        self.round_block.mem_len = self.normal_mem.num_words

        # Process initial shifts before the main loop
        self._process_initial_shifts(normal_word_zero, high_shift, low_shift,
                                   acc_start_idx_high, acc_start_idx_low,
                                   acc_shift_idx_high, acc_shift_idx_low,
                                   )

        # Process words
        self.low_latency = self.high_latency = 0
        for word_idx in range(self.normal_mem.num_words + high_low_diff - 1):#self.normal_mem.num_words + high_low_diff - 1
            
            # Process normal words
            self._process_normal_word(word_idx, acc_start_idx_high, acc_shift_idx_high,
                                   acc_shift_idx_low, self.high_latency, self.low_latency)
            
            # Update latency
            acc_shift_idx_high, acc_shift_idx_low = self._update_latency(acc_start_idx_high, word_idx,
                                                           high_shift, low_shift,
                                                           acc_shift_idx_high, acc_shift_idx_low)
            

    def _process_normal_word(self, word_idx, acc_start_idx_high, acc_shift_idx_high,
                           acc_shift_idx_low, high_latency, low_latency):
        """Process a normal word in the multiplication"""
        normal_word_high = self.normal_mem.get_word((word_idx + 1) % self.acc_mem.num_words)
        self.round_block.add_normal_poly_word(normal_word_high, (word_idx + 1) % self.acc_mem.num_words)
        
        acc_word = self.acc_mem.get_word((acc_start_idx_high + 1 + word_idx) % self.acc_mem.num_words)
        self.round_block.set_acc_word(acc_word, (acc_start_idx_high + 1 + word_idx) % self.acc_mem.num_words)
        
        self.round_block.process_round(high_latency, low_latency)

        result = self.xor_adder.process_xor(
            self.round_block.normal_high_word_left,
            self.round_block.normal_high_word_right,
            self.round_block.normal_low_word_left,
            self.round_block.normal_low_word_right,
            self.round_block.acc_word,
            (acc_shift_idx_high, acc_shift_idx_high + 31),
            (acc_shift_idx_low, acc_shift_idx_low + 31)
        )
        
        self.acc_mem.set_word((acc_start_idx_high + 1 + word_idx) % self.acc_mem.num_words, result)

    def _update_latency(self, acc_start_idx_high, word_idx, high_shift, low_shift,
                       acc_shift_idx_high, acc_shift_idx_low):
        """Update latency values based on current state"""
        
        if acc_start_idx_high + 1 + word_idx == (self.acc_mem.num_words - 1):
            
            if high_shift % 32 >= 5:
                self.high_latency = 1
                acc_shift_idx_high += 5
            else:
                self.high_latency = 0
                acc_shift_idx_high = 5 - high_shift % 32
            
            if low_shift % 32 >= 5:
                self.low_latency = 1
                acc_shift_idx_low += 5
            else:
                self.low_latency = 0
                acc_shift_idx_low = 5 - low_shift % 32
                
        return acc_shift_idx_high, acc_shift_idx_low

    def execute(self, iter = None) -> None:
        """Execute the multiplication operation"""
        # if iter is not None:

        # self.round_block.clear_queue()
        # self.process_word(49)


        if iter is None:
            for i in range(self.sparse_mem.num_words):
                self.round_block.clear_queue()
                self.process_word(i)
        else:
            for i in range(iter):
                self.round_block.clear_queue()
                self.process_word(i)