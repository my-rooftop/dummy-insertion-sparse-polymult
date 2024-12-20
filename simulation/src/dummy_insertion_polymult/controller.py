from typing import List
from memory import PolynomialMemory
from round_block import RoundBlock
from xor_adder import XORAdder

class Controller:
    def __init__(self, normal_mem: PolynomialMemory, sparse_mem: PolynomialMemory, acc_mem: PolynomialMemory):
        """
        Initialize controller for polynomial multiplication
        
        Args:
            normal_mem: Memory containing h polynomial bits
            sparse_mem: Memory containing R2 polynomial with shift information
            acc_mem: Memory for accumulating multiplication results
        """
        self.normal_mem = normal_mem #normal
        self.sparse_mem = sparse_mem #sparse
        self.acc_mem = acc_mem
        self.word_size = 32
        
        # Initialize RoundBlock and XORAdder
        self.round_block = RoundBlock(debug_mode=True)
        self.xor_adder = XORAdder(debug_mode=False)
    
    def process_word(self, word_idx: int) -> None:
        """
        Process a single 32-bit word from R2 memory
        
        Args:
            word_idx: Index of the word to process
        """
        # Get the word from R2 memory
        sparse_word = self.sparse_mem.get_word(word_idx)
        
        # Extract high and low 16-bit values (shift amounts)
        high_shift = (sparse_word >> 16) & 0xFFFF
        low_shift = sparse_word & 0xFFFF
        
        acc_start_idx_high = (high_shift // 32)
        acc_shift_idx_high = 32 - (high_shift % 32)

        acc_start_idx_low = (low_shift // 32)
        acc_shift_idx_low = 32 - (low_shift % 32)

        normal_word = self.normal_mem.get_word(0)
        self.round_block.add_normal_poly_word(normal_word)

        self.round_block.normal_sparse_diff = acc_start_idx_low - acc_start_idx_high

        high_latency = 0
        low_latency = 0
        for word_idx in range(550): #self.sparse_mem.num_words

            normal_word_high = self.normal_mem.get_word(word_idx + 1)

            self.round_block.add_normal_poly_word(normal_word_high)

            acc_word = self.acc_mem.get_word((acc_start_idx_high + word_idx) % self.acc_mem.num_words)

            self.round_block.set_acc_word(acc_word)

            self.round_block.process_round(high_latency, low_latency)

            result = self.xor_adder.process_xor(
                self.round_block.normal_high_word_left,
                self.round_block.normal_high_word_right,
                self.round_block.normal_low_word_left,
                self.round_block.normal_low_word_right,
                self.round_block.acc_word,
                (acc_shift_idx_high, acc_shift_idx_high + 31),
                (acc_shift_idx_low, acc_shift_idx_low + 31),
                )

            self.acc_mem.set_word(acc_start_idx_high + word_idx, result)

            if acc_start_idx_high + word_idx == (self.acc_mem.num_words - 1):
                print(f"acc_start_idx_high: {acc_start_idx_high}")
                print(f"acc_shift_idx_high + word_idx: {acc_shift_idx_high + word_idx}")
                acc_shift_idx_high += 5
                print(f"acc_shift_idx_high: {acc_shift_idx_high}")
                if high_shift % 32 >= 5:
                    high_latency = 1
                acc_shift_idx_low += 5
                print(f"acc_shift_idx_low: {acc_shift_idx_low}")
                if low_shift % 32 >= 5:
                    low_latency = 1


            print(f"Result: {result:032b}")

            #for test
            # break    
            
        
        pass
    
    def execute(self) -> None:
        """Execute the multiplication operation for all words in R2 memory"""
        # Process each word in R2 memory
        for word_idx in range(self.sparse_mem.num_words):
            self.process_word(word_idx)
            #for test
            break
    
    def get_result(self) -> List[int]:
        """Get the final multiplication result"""
        return self.acc_mem.get_memory()
