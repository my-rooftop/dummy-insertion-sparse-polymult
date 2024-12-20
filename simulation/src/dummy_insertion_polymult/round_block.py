from collections import deque
from typing import List, Optional
from xor_adder import XORAdder

class RoundBlock:
    def __init__(self, debug_mode: bool = False):
        self.normal_poly_queue = deque(maxlen=16)
        self.acc_word: int = 0
        self.sparse_poly_index: int = 0
        self.conunt: int = 0
        self.normal_sparse_diff: int = 0
        self.normal_high_word_left: int = 0
        self.normal_high_word_right: int = 0
        self.normal_low_word_left: int = 0
        self.normal_low_word_right: int = 0
        self.debug_mode = debug_mode
        
    def debug_print(self, message: str) -> None:
        if self.debug_mode:
            print(message)
            
    def visualize_queue(self) -> None:
        if self.debug_mode:
            print("\n=== Queue State ===")
            print(f"Queue size: {len(self.normal_poly_queue)}/16")
            print("Queue contents:")
            for i, word in enumerate(self.normal_poly_queue):
                print(f"[{i:2d}] {word:032b} ({word})")
            
            if self.normal_sparse_diff > 0:
                print("\nSelected words for processing:")
                print(f"High Left  [{0:2d}]: {self.normal_high_word_left:032b}")
                print(f"High Right [{1:2d}]: {self.normal_high_word_right:032b}")
                print(f"Low Left   [{self.normal_sparse_diff:2d}]: {self.normal_low_word_left:032b}")
                print(f"Low Right  [{self.normal_sparse_diff+1:2d}]: {self.normal_low_word_right:032b}")
            print("=================\n")
        
    def set_acc_word(self, word: int) -> None:
        self.acc_word = word & 0xFFFFFFFF
        if self.debug_mode:
            print(f"Set accumulator word: {self.acc_word:032b} ({self.acc_word})")
    
    def get_queue_size(self) -> int:
        return len(self.normal_poly_queue)
    
    def clear_queue(self) -> None:
        self.normal_poly_queue.clear()

    def add_normal_poly_word(self, word: int) -> None:
        self.normal_poly_queue.append(word & 0xFFFFFFFF)
        self.conunt += 1
        if self.debug_mode:
            print(f"\nAdded word to queue: {word:032b} ({word})")
            self.visualize_queue()
        
    def process_round(self, high_latency = 0, low_latency = 0) -> None:
        if self.debug_mode:
            print("\n=== Processing Round ===")
        print("idx", self.get_queue_size() - 2 - high_latency)
        print("idx", self.get_queue_size() - 1 - high_latency)
        print(self.normal_sparse_diff)
        self.normal_high_word_right = self.normal_poly_queue[self.get_queue_size() - 2 - high_latency]
        self.normal_high_word_left = self.normal_poly_queue[self.get_queue_size() - 1 - high_latency]

        if self.get_queue_size() < self.normal_sparse_diff + 2:
            self.normal_low_word_right = 0
            self.normal_low_word_left = 0
        else:
            print("idx", self.get_queue_size() - self.normal_sparse_diff - 2 - low_latency)
            print("idx", self.get_queue_size() - self.normal_sparse_diff - 1 - low_latency)
            self.normal_low_word_right = self.normal_poly_queue[self.get_queue_size() - self.normal_sparse_diff - 2 - low_latency]
            self.normal_low_word_left = self.normal_poly_queue[self.get_queue_size() - self.normal_sparse_diff - 1 - low_latency]

