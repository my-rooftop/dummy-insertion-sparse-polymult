import math
from typing import List

class PolynomialMemory:
    def __init__(self, total_bits: int, word_size: int = 32):
        self.total_bits = total_bits
        self.word_size = word_size
        self.num_words = math.ceil(total_bits / word_size)
        self.memory = [0] * self.num_words
        self.current_word_position = 0
        
    def set_bit_positions(self, positions: List[int]) -> None:
        """Set bits to 1 at given positions"""
        for pos in positions:
            if pos < self.total_bits:
                word_idx = pos // self.word_size
                bit_idx = pos % self.word_size
                self.memory[word_idx] |= (1 << bit_idx)
    
    def set_word_positions(self, words: List[int], start_position: int = None) -> None:
        """Store a list of 32-bit words starting from a specific position"""
        if start_position is not None:
            self.current_word_position = start_position
            
        for word in words:
            if self.current_word_position >= self.num_words:
                break
            self.memory[self.current_word_position] = word
            self.current_word_position += 1
    
    def get_bit(self, position: int) -> int:
        """Get bit value at given position"""
        if position >= self.total_bits:
            return 0
        
        word_idx = position // self.word_size
        bit_idx = position % self.word_size
        return (self.memory[word_idx] >> bit_idx) & 1
    
    def get_word(self, word_idx: int) -> int:
        """Get word at given index"""
        if word_idx >= self.num_words:
            return 0
        return self.memory[word_idx]
    
    def set_word(self, word_idx: int, value: int) -> None:
        """Set word at given index"""
        if word_idx < self.num_words:
            self.memory[word_idx] = value
    
    def get_memory(self) -> List[int]:
        """Get entire memory contents"""
        return self.memory.copy()
    
    def __str__(self) -> str:
        """String representation showing memory contents in binary"""
        result = []
        for i, word in enumerate(self.memory):
            if i == self.num_words - 1:
                remaining_bits = self.total_bits - (i * self.word_size)
                mask = (1 << remaining_bits) - 1
                word &= mask
            
            binary = format(word, f'0{self.word_size}b')
            result.append(f"Word {i}: {binary}")
        return "\n".join(result)