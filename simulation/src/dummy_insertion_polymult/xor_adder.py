class XORAdder:
    def __init__(self, debug_mode: bool = False):
        self.word_size = 32
        self.debug_mode = debug_mode
        
    def debug_print(self, message: str) -> None:
        if self.debug_mode:
            print(message)
            
    def format_bits_with_highlight(self, value: int, start: int, length: int, total_bits: int) -> str:
        """Format binary string with highlighted extraction range using | |"""
        binary = format(value, f'0{total_bits}b')
        result = list(binary)
        
        # Add highlight markers
        result.insert(len(binary) - start - length, '|')
        result.insert(len(binary) - start + 1, '|')
        
        return ''.join(result)
        
    def concatenate_words(self, word1: int, word2: int) -> int:
        result = ((word1 & 0xFFFFFFFF) << 32) | (word2 & 0xFFFFFFFF)
        if self.debug_mode:
            self.debug_print(f"\nConcatenation:")
            self.debug_print(f"Word1:    {word1:032b} ({word1})")
            self.debug_print(f"Word2:    {word2:032b} ({word2})")
            self.debug_print(f"Combined: {result:064b} ({result})")
        return result
        
    def extract_bits(self, value: int, start: int, length: int) -> int:
        mask = (1 << length) - 1
        result = (value >> start) & mask
        if self.debug_mode:
            self.debug_print(f"\nBit Extraction:")
            self.debug_print(f"Value:    {self.format_bits_with_highlight(value, start, length, 64)}")
            self.debug_print(f"Start:    {start}")
            self.debug_print(f"Length:   {length}")
            self.debug_print(f"Extracted:{result:032b} ({result})")
        return result
        
    def process_xor(self, 
                   normal_high_word_left: int, 
                   normal_high_word_right: int,
                   normal_low_word_left: int,
                   normal_low_word_right: int,
                   acc_poly: int,
                   normal_range: tuple[int, int],
                   sparse_range: tuple[int, int]) -> int:
        if self.debug_mode:
            self.debug_print("\n=== XOR Operation Start ===")
            self.debug_print("Input values:")
            self.debug_print(f"Normal High Left:  {normal_high_word_left:032b}")
            self.debug_print(f"Normal High Right: {normal_high_word_right:032b}")
            self.debug_print(f"Normal Low Left:   {normal_low_word_left:032b}")
            self.debug_print(f"Normal Low Right:  {normal_low_word_right:032b}")
            self.debug_print(f"Acc Poly:         {acc_poly:032b}")
            
        # Concatenate word pairs
        normal_high_concat = self.concatenate_words(normal_high_word_left, normal_high_word_right)
        normal_low_concat = self.concatenate_words(normal_low_word_left, normal_low_word_right)
        
        # Extract relevant bits based on ranges
        normal_start, normal_end = normal_range
        sparse_start, sparse_end = sparse_range
        
        normal_high_bits = self.extract_bits(normal_high_concat, 
                                           normal_start, 
                                           normal_end - normal_start + 1)
        normal_low_bits = self.extract_bits(normal_low_concat, 
                                          sparse_start, 
                                          sparse_end - sparse_start + 1)
        
        # Perform XOR operation
        xor_result = acc_poly ^ normal_high_bits ^ normal_low_bits
        
        if self.debug_mode:
            self.debug_print("\nFinal XOR Operation:")
            self.debug_print(f"Acc Poly:         {acc_poly:032b}")
            self.debug_print(f"Normal High Bits: {normal_high_bits:032b}")
            self.debug_print(f"Normal Low Bits:  {normal_low_bits:032b}")
            self.debug_print(f"XOR Result:       {xor_result:032b}")
            self.debug_print("\n=== XOR Operation End ===\n")
            
        return xor_result
