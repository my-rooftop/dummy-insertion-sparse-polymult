from typing import List
from memory import PolynomialMemory
from xor_adder import XORAdder
from shift_register import ShiftRegister

class Controller:
    def __init__(self, normal_mem, sparse_mem, acc_mem, debug_mode: bool = False):
        self.normal_mem = normal_mem
        self.sparse_mem = sparse_mem
        self.acc_mem = acc_mem
        self.word_size = 32
        self.debug_mode = debug_mode
        self.xor_adder = XORAdder(debug_mode=debug_mode)
        self.shift_register = ShiftRegister(debug_mode=debug_mode)
        self.low_latency = 0
        self.high_latency = 0
        self.high_low_diff = 0

    def debug_print(self, message: str) -> None:
        if self.debug_mode:
            print(message)

    def _process_initial_acc(self, normal_word_zero, acc_start_idx, acc_shift_idx, high_shift):
            """Process shift when shift is >= 5 for both high and low cases"""
            normal_word_551 = self.normal_mem.get_word(len(self.normal_mem.memory) - 2)
            normal_word_552 = self.normal_mem.get_word(len(self.normal_mem.memory) - 1)
            acc_word_first = self.acc_mem.get_word(acc_start_idx - 1)

            if high_shift % 32 >= 5:
                # Extract high bits
                high_bits = normal_word_zero & ((1 << acc_shift_idx) - 1)
                
                # Extract mid bits
                mid_bits = normal_word_552 & ((1 << 5) - 1)
                
                # Extract low bits
                remaining_bits = 32 - 5 - acc_shift_idx
                low_bits = (normal_word_551 >> (32 - remaining_bits)) & ((1 << remaining_bits) - 1)
                
                # Combine bits
                combined_word = (high_bits << (32 - acc_shift_idx)) | \
                            (mid_bits << remaining_bits) | \
                            low_bits
                
                # XOR operation
                result = acc_word_first ^ combined_word
            else:
                shift_remainder = high_shift % 32
                high_bits = normal_word_zero & ((1 << acc_shift_idx) - 1)
                
                # Extract low bits
                low_bits = (normal_word_552 >> (5 - shift_remainder)) & ((1 << shift_remainder) - 1)

                combined_word = (high_bits << shift_remainder) | low_bits

                result = acc_word_first ^ combined_word
            
            # print(f"Result: {result:032b}")
            self.acc_mem.set_word(acc_start_idx - 1, result)
            return result
              
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
        self.high_low_diff = acc_start_idx_low - acc_start_idx_high

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
            self.debug_print(f"high_low_diff: {self.high_low_diff}")
            self.debug_print("===================================\n")
        
        # Setup round block
        normal_word_zero = self.normal_mem.get_word(0)
        self.shift_register.add_word(normal_word_zero, 0)

        self._process_initial_acc(normal_word_zero, acc_start_idx_high + 1, acc_shift_idx_high, high_shift)

        self._process_initial_acc(normal_word_zero, acc_start_idx_low + 1, acc_shift_idx_low, low_shift)  

        # Process words
        self.low_latency = self.high_latency = 0

        for load_word_idx in range(1, 30):#self.normal_mem.num_words + self.high_low_diff
            
            normal_word_high = self.normal_mem.get_word(load_word_idx % self.acc_mem.num_words)
            acc_word = self.acc_mem.get_word((load_word_idx + acc_start_idx_high) % self.acc_mem.num_words)
            
            self.shift_register.add_word(normal_word_high, load_word_idx % self.acc_mem.num_words)
            shift_register_size = self.shift_register.size()
                        
            high_left_idx, high_right_idx, low_left_idx, low_right_idx = self._get_index(load_word_idx, shift_register_size)        

            high_right, high_left, low_right, low_left = self.shift_register.get_word_pair(
                high_right_idx, high_left_idx, low_right_idx, low_left_idx)
            
            xor_result = self.xor_adder.process_xor(
                high_left, high_right, low_left, low_right,
                acc_word, (acc_shift_idx_high, acc_shift_idx_high + 31), (acc_shift_idx_low, acc_shift_idx_low + 31))
            
            self.acc_mem.set_word((load_word_idx + acc_start_idx_high) % self.acc_mem.num_words, xor_result)

            # Update latency
            acc_shift_idx_high, acc_shift_idx_low = self._update_latency(acc_start_idx_high, word_idx,
                                                           high_shift, low_shift,
                                                           acc_shift_idx_high, acc_shift_idx_low)

    def _get_index(self, load_word_idx, shift_register_size):
        """Get the index of the word to load"""

        high_left_idx = 0
        high_right_idx = 0
        low_left_idx = 0
        low_right_idx = 0

        print("shift_register_size: ", shift_register_size)
        print("self.high_latency: ", self.high_low_diff)
        if load_word_idx >= self.normal_mem.num_words:
            high_left_idx = None
            high_right_idx = None
        else:
            high_left_idx = shift_register_size - 1 - self.high_latency
            high_right_idx = shift_register_size - 2 - self.high_latency

        if load_word_idx < self.high_low_diff + 1:
            low_left_idx = None
            low_right_idx = None
        else:
            low_left_idx = shift_register_size - self.high_low_diff - 1 - self.low_latency
            low_right_idx = shift_register_size - self.high_low_diff - 2 - self.low_latency

        if self.debug_mode:
            print("\n=== Processing Round ===")
            print(f"Using high words: [{high_left_idx}], [{high_right_idx}]")
            print(f"Using low words: [{low_left_idx}], [{low_right_idx}]")

        return high_left_idx, high_right_idx, low_left_idx, low_right_idx

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

        self.shift_register.clear()
        self.process_word(0)

        # if iter is None:
        #     for i in range(self.sparse_mem.num_words):
        #         self.shift_register.clear()
        #         self.process_word(i)
        # else:
        #     for i in range(iter):
        #         self.shift_register.clear()
        #         self.process_word(i)