from typing import List
from memory import PolynomialMemory
from round_block import RoundBlock
from xor_adder import XORAdder

class Controller:
    def __init__(self, normal_mem, sparse_mem, acc_mem):
        self.normal_mem = normal_mem
        self.sparse_mem = sparse_mem
        self.acc_mem = acc_mem
        self.word_size = 32
        self.round_block = RoundBlock(debug_mode=True)
        self.xor_adder = XORAdder(debug_mode=True)
        self.low_latency = 0
        self.high_latency = 0

    def process_high_shift_greater_than_5(self, normal_word_zero, acc_start_idx_high, acc_shift_idx_high):
        """Process high shift when shift is >= 5"""
        normal_word_551 = self.normal_mem.get_word(len(self.normal_mem.memory) - 2)
        normal_word_552 = self.normal_mem.get_word(len(self.normal_mem.memory) - 1)
        acc_word_first = self.acc_mem.get_word(acc_start_idx_high - 1)
        
        # Extract bits
        high_bits = normal_word_zero & ((1 << acc_shift_idx_high) - 1)
        mid_bits = normal_word_552 & ((1 << 5) - 1)
        remaining_bits = 32 - 5 - acc_shift_idx_high
        low_bits = (normal_word_551 >> (32 - remaining_bits)) & ((1 << remaining_bits) - 1)
        
        # Combine bits
        combined_word = (high_bits << (32 - acc_shift_idx_high)) | \
                       (mid_bits << remaining_bits) | \
                       low_bits
        
        # XOR and store result
        result = acc_word_first ^ combined_word
        self.acc_mem.set_word(acc_start_idx_high - 1, result)
        
        return result

    def process_high_shift_less_than_5(self, normal_word_zero, normal_word_552, acc_start_idx_high, 
                                     acc_shift_idx_high, shift_remainder):
        """Process high shift when shift is < 5"""
        acc_word_first = self.acc_mem.get_word(acc_start_idx_high - 1)
        
        # Extract and combine bits
        high_bits = normal_word_zero & ((1 << acc_shift_idx_high) - 1)
        low_bits = (normal_word_552 >> (5 - shift_remainder)) & ((1 << shift_remainder) - 1)
        combined_word = (high_bits << shift_remainder) | low_bits
        
        # XOR and store result
        result = acc_word_first ^ combined_word
        self.acc_mem.set_word(acc_start_idx_high - 1, result)
        
        return result

    def process_low_shift_greater_than_5(self, normal_word_zero, acc_start_idx_low, acc_shift_idx_low):
        """Process low shift when shift is >= 5"""
        normal_word_551 = self.normal_mem.get_word(len(self.normal_mem.memory) - 2)
        normal_word_552 = self.normal_mem.get_word(len(self.normal_mem.memory) - 1)
        acc_word_first = self.acc_mem.get_word(acc_start_idx_low - 1)
        
        # Extract bits
        high_bits = normal_word_zero & ((1 << acc_shift_idx_low) - 1)
        mid_bits = normal_word_552 & ((1 << 5) - 1)
        remaining_bits = 32 - 5 - acc_shift_idx_low
        low_bits = (normal_word_551 >> (32 - remaining_bits)) & ((1 << remaining_bits) - 1)
        
        # Combine bits
        combined_word = (high_bits << (32 - acc_shift_idx_low)) | \
                       (mid_bits << remaining_bits) | \
                       low_bits
        
        # XOR and store result
        result = acc_word_first ^ combined_word
        self.acc_mem.set_word(acc_start_idx_low - 1, result)
        
        return result

    def process_low_shift_less_than_5(self, normal_word_zero, normal_word_552, acc_start_idx_low, 
                                    acc_shift_idx_low, shift_remainder):
        """Process low shift when shift is < 5"""
        acc_word_first = self.acc_mem.get_word(acc_start_idx_low - 1)
        
        # Extract and combine bits
        high_bits = normal_word_zero & ((1 << acc_shift_idx_low) - 1)
        low_bits = (normal_word_552 >> (5 - shift_remainder)) & ((1 << shift_remainder) - 1)
        combined_word = (high_bits << shift_remainder) | low_bits
        
        # XOR and store result
        result = acc_word_first ^ combined_word
        self.acc_mem.set_word(acc_start_idx_low - 1, result)
        
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
        high_low_diff = acc_start_idx_low - acc_start_idx_high
        
        # Setup round block
        normal_word_zero = self.normal_mem.get_word(0)
        self.round_block.add_normal_poly_word(normal_word_zero, 0)
        self.round_block.normal_sparse_diff = high_low_diff
        self.round_block.mem_len = self.normal_mem.num_words
        
        # Process words
        self.low_latency = self.high_latency = 0
        for word_idx in range(self.normal_mem.num_words + high_low_diff - 1):#self.normal_mem.num_words + high_low_diff - 1
            # Process initial word
            if word_idx == 0:
                if high_shift % 32 >= 5:
                    self.process_high_shift_greater_than_5(normal_word_zero, acc_start_idx_high, acc_shift_idx_high)
                else:
                    normal_word_552 = self.normal_mem.get_word(len(self.normal_mem.memory) - 1)
                    self.process_high_shift_less_than_5(normal_word_zero, normal_word_552, 
                                                      acc_start_idx_high, acc_shift_idx_high, high_shift % 5)
            
            # Process word at difference point
            if word_idx == high_low_diff:
                if low_shift % 32 >= 5:
                    self.process_low_shift_greater_than_5(normal_word_zero, acc_start_idx_low, acc_shift_idx_low)
                else:
                    normal_word_552 = self.normal_mem.get_word(len(self.normal_mem.memory) - 1)
                    self.process_low_shift_less_than_5(normal_word_zero, normal_word_552,
                                                     acc_start_idx_low, acc_shift_idx_low, low_shift % 5)
            
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
        
        acc_word = self.acc_mem.get_word((acc_start_idx_high + word_idx) % self.acc_mem.num_words)
        self.round_block.set_acc_word(acc_word, (acc_start_idx_high + word_idx) % self.acc_mem.num_words)
        
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
        
        self.acc_mem.set_word((acc_start_idx_high + word_idx) % self.acc_mem.num_words, result)

    def _update_latency(self, acc_start_idx_high, word_idx, high_shift, low_shift,
                       acc_shift_idx_high, acc_shift_idx_low):
        """Update latency values based on current state"""
        
        if acc_start_idx_high + word_idx == (self.acc_mem.num_words - 1):
            acc_shift_idx_high += 5
            if high_shift % 32 >= 5:
                self.high_latency = 1
            acc_shift_idx_low += 5
            if low_shift % 32 >= 5:
                self.low_latency = 1
                
        return acc_shift_idx_high, acc_shift_idx_low

    def execute(self) -> None:
        """Execute the multiplication operation"""
        for word_idx in range(self.sparse_mem.num_words):
            self.round_block.clear_queue()
            self.process_word(word_idx)
            break  # For testing
