from collections import deque
from typing import List, Optional
from xor_adder import XORAdder

class RoundBlock:
    def __init__(self, debug_mode: bool = False):
        self.normal_poly_queue = deque(maxlen=19)
        self.acc_word: int = 0
        self.sparse_poly_index: int = 0
        self.count: int = 0
        self.normal_sparse_diff: int = 0
        self.normal_high_word_left: int = 0
        self.normal_high_word_right: int = 0
        self.normal_low_word_left: int = 0
        self.normal_low_word_right: int = 0
        self.mem_len: int = 0
        self.debug_mode = debug_mode
        
    def debug_print(self, message: str) -> None:
        if self.debug_mode:
            print(message)
            
    def visualize_queue(self) -> None:
        if self.debug_mode:
            print("\n=== Queue State ===")
            print(f"Queue size: {len(self.normal_poly_queue)}/16")
            print("Queue contents:")
            for word, idx in self.normal_poly_queue:
                print(f"[{idx:3d}] {word:032b} ({word})")
            print("=================\n")
        
    def set_acc_word(self, word: int, word_idx: int) -> None:
        """Set accumulator word with its index"""
        self.acc_word = word & 0xFFFFFFFF
        if self.debug_mode:
            print(f"\nSet accumulator word[{word_idx}]: {self.acc_word:032b} ({self.acc_word})")
    
    def get_queue_size(self) -> int:
        return len(self.normal_poly_queue)
    
    def clear_queue(self) -> None:
        self.count = 0
        self.normal_poly_queue.clear()

    def add_normal_poly_word(self, word: int, word_idx: int) -> None:
        """Add a new normal polynomial word to the queue with its index"""
        self.normal_poly_queue.append((word & 0xFFFFFFFF, word_idx))
        if self.debug_mode:
            print(f"\nAdded word[{word_idx}] to queue: {word:032b} ({word})")
            self.visualize_queue()
        
    def process_round(self, high_latency = 0, low_latency = 0) -> None:
        self.count += 1


        
        if self.count >= self.mem_len:
            self.normal_high_word_right = 0
            self.normal_high_word_left = 0

            high_right_idx = "none"
            high_left_idx = "none"
        else:
            high_right_word, high_right_idx = self.normal_poly_queue[self.get_queue_size() - 2 - high_latency]
            high_left_word, high_left_idx = self.normal_poly_queue[self.get_queue_size() - 1 - high_latency]
            
            self.normal_high_word_right = high_right_word
            self.normal_high_word_left = high_left_word

        if self.count < self.normal_sparse_diff + 1:
            self.normal_low_word_right = 0
            self.normal_low_word_left = 0

            low_right_idx = "none"
            low_left_idx = "none"
        else:
            low_right_word, low_right_idx = self.normal_poly_queue[self.get_queue_size() - self.normal_sparse_diff - 2 - low_latency]
            low_left_word, low_left_idx = self.normal_poly_queue[self.get_queue_size() - self.normal_sparse_diff - 1 - low_latency]
            
            self.normal_low_word_right = low_right_word
            self.normal_low_word_left = low_left_word
            
        if self.debug_mode:
            print("\n=== Processing Round ===")
            print(f"Using high words: [{high_left_idx}], [{high_right_idx}]")
            print(f"Using low words: [{low_left_idx}], [{low_right_idx}]")
        # 여기에 만약 high가 일찍 끝난 경우 추가
        