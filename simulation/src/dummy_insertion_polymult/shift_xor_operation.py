class ShiftXorOperations:
    def __init__(self, total_bits=17669):
        self.total_bits = total_bits
        self.bits = [0] * total_bits
        self.r2_mem = None
        self.acc_mem = None
        self.accumulated_result = [0] * total_bits
        
    def set_r2_memory(self, r2_mem):
        """Set r2 memory reference"""
        self.r2_mem = r2_mem
        
    def set_acc_memory(self, acc_mem):
        """Set accumulator memory reference"""
        self.acc_mem = acc_mem

    def set_bits(self, positions):
        """Set bits to 1 at given positions"""
        for pos in positions:
            if 0 <= pos < self.total_bits:
                self.bits[pos] = 1
                
    def shift_bits(self, positions, shift_amount):
        """Shift given positions by shift_amount with wraparound"""
        shifted = [0] * self.total_bits
        for pos in positions:
            new_pos = (pos + shift_amount) % self.total_bits
            shifted[new_pos] = 1
        return shifted
        
    def xor_arrays(self, arr1, arr2, arr3=None):
        """3항 XOR 연산 (arr3이 None이면 2항 XOR)"""
        result = []
        if arr3 is None:
            for i in range(len(arr1)):
                result.append(arr1[i] ^ arr2[i])
        else:
            for i in range(len(arr1)):
                result.append(arr1[i] ^ arr2[i] ^ arr3[i])
        return result
        
    def get_word(self, word_idx):
        """Get 32-bit word at given index"""
        start_bit = word_idx * 32
        end_bit = min(start_bit + 32, self.total_bits)
        word_bits = self.accumulated_result[start_bit:end_bit]
        
        return sum(1 << i for i in range(len(word_bits)) if word_bits[i])
        
    def print_word(self, word_idx):
        """Print word in binary and decimal format"""
        word_value = self.get_word(word_idx)
        print(f"Word {word_idx}: {word_value:032b} ({word_value})")

    def process_r2_word(self, word_idx):
        """Process shifts from r2_mem word at given index
        Args:
            word_idx: Index of word in r2_mem to process
        """
        if not self.r2_mem:
            raise ValueError("r2_mem not set. Call set_r2_memory first.")
            
        # Get shifts from r2_mem word
        r2_word = self.r2_mem.get_word(word_idx)
        shift1 = (r2_word >> 16) & 0xFFFF  # High 16 bits
        shift2 = r2_word & 0xFFFF          # Low 16 bits
        
        # Perform shifts
        shifted1 = self.shift_bits(self.get_one_positions(), shift1)
        shifted2 = self.shift_bits(self.get_one_positions(), shift2)
        
        # 3항 XOR 연산으로 누적 결과에 반영
        self.accumulated_result = self.xor_arrays(shifted1, shifted2, self.accumulated_result)

    def process_r2_word_accumulated(self, word_idx):
        for i in range(word_idx):
            self.process_r2_word(i)

    def get_one_positions(self):
        """Get positions of all 1 bits"""
        return [i for i, bit in enumerate(self.bits) if bit == 1]

    def compare_with_acc_mem(self):
        """Compare accumulated results with acc_mem"""
        if not self.acc_mem:
            raise ValueError("acc_mem not set. Call set_acc_memory first.")
            
        matches = 0
        differences = []
        total_words = self.total_bits // 32
        
        print("\n🔍 VERIFICATION RESULT 🔍")
        print("=" * 50)
        
        for word_idx in range(total_words):
            acc_word = self.acc_mem.get_word(word_idx)
            shift_word = self.get_word(word_idx)
            
            if acc_word == shift_word:
                matches += 1
            else:
                differences.append(word_idx)
        
        if differences:
            print("\n❌ CRITICAL ERROR: MISMATCH DETECTED! ❌")
            print(f"Found {len(differences)} mismatched words!")
            print("\nMismatched word indices:")
            for idx in differences:
                print(f"\n[Word {idx}]")
                print(f"Expected : {self.acc_mem.get_word(idx):032b}")
                print(f"Actual   : {self.get_word(idx):032b}")
                print(f"Diff     : {self.acc_mem.get_word(idx) ^ self.get_word(idx):032b}")
                print("-" * 50)
        else:
            print("\n✅ VERIFICATION SUCCESSFUL!")
            print("All words match perfectly!")
        
        print("\nSummary:")
        print(f"Total words checked: {total_words}")
        print(f"Matching words: {matches}")
        print(f"Different words: {len(differences)}")
        print("=" * 50)
