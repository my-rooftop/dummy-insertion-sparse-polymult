from typing import List, Tuple
from memory import PolynomialMemory

class ResultVerifier:
    def __init__(self, acc_mem: PolynomialMemory, expected_positions: List[int]):
        self.acc_mem = acc_mem
        self.expected_positions = expected_positions
        self.total_bits = acc_mem.total_bits
        
    def _get_bit_from_memory(self, position: int) -> int:
        """Get a bit from memory at given position"""
        word_idx = position // 32
        bit_idx = position % 32
        word = self.acc_mem.get_word(word_idx)
        return (word >> bit_idx) & 1
        
    def verify_results(self) -> tuple[bool, List[int], List[int], float]:
        """Verify if the computed results match expected positions"""
        computed_positions = []
        for pos in range(self.total_bits):
            if self._get_bit_from_memory(pos):
                computed_positions.append(pos)
                
        # Find differences
        computed_set = set(computed_positions)
        expected_set = set(self.expected_positions)
        
        missing_positions = sorted(list(expected_set - computed_set))
        extra_positions = sorted(list(computed_set - expected_set))
        
        # Calculate error rate
        total_errors = len(missing_positions) + len(extra_positions)
        total_ones = len(expected_set | computed_set)  # Union of both sets
        error_rate = (total_errors / total_ones * 100) if total_ones > 0 else 0
        
        return len(missing_positions) == 0 and len(extra_positions) == 0, missing_positions, extra_positions, error_rate
    
    def print_report(self):
        """Print detailed verification report"""
        is_correct, missing, extra, error_rate = self.verify_results()
        
        print("\n=== Multiplication Verification Report ===")
        print(f"Total bits checked: {self.total_bits}")
        print(f"Expected 1-bits: {len(self.expected_positions)}")
        print(f"Error rate: {error_rate:.2f}%")
        
        if is_correct:
            print("\nVERIFICATION PASSED ✓")
            print("All bit positions match exactly!")
        else:
            print("\nVERIFICATION FAILED ✗")
            if missing:
                print(f"\nMissing 1-bits: {len(missing)} positions")
            if extra:
                print(f"\nExtra 1-bits: {len(extra)} positions")
                    
        print("\n=====================================")