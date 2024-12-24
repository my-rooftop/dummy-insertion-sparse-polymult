# result_verifier.py

class ResultVerifier:
    def __init__(self, acc_mem, result_positions):
        self.acc_mem = acc_mem
        self.result_positions = result_positions
        
    def verify(self):
        """Verify the results and return statistics"""
        matches = 0
        mismatches = 0
        missing = 0
        extra = 0
        
        # Get all 1 bits from acc_mem
        acc_ones = set()
        for pos in range(self.acc_mem.total_bits):
            if self.acc_mem.get_bit(pos) == 1:
                acc_ones.add(pos)
        
        # Convert result positions to set
        result_set = set(self.result_positions)
        
        # Calculate statistics
        matches = len(acc_ones.intersection(result_set))
        missing = len(result_set - acc_ones)
        extra = len(acc_ones - result_set)
        total_expected = len(result_set)
        
        return {
            'matches': matches,
            'missing': missing,
            'extra': extra,
            'total_expected': total_expected,
            'accuracy': (matches / total_expected) * 100 if total_expected > 0 else 0
        }
    
    def print_report(self):
        """Print a detailed verification report"""
        stats = self.verify()
        
        print("\n=== Result Verification Report ===")
        print(f"Total expected 1-bits: {stats['total_expected']}")
        print(f"Matching positions: {stats['matches']}")
        print(f"Missing positions: {stats['missing']}")
        print(f"Extra positions: {stats['extra']}")
        print(f"Accuracy: {stats['accuracy']:.2f}%")
        
        # if stats['missing'] > 0 or stats['extra'] > 0:
        #     print("\nDetailed Analysis:")
        #     acc_ones = set()
        #     for pos in range(self.acc_mem.total_bits):
        #         if self.acc_mem.get_bit(pos) == 1:
        #             acc_ones.add(pos)
            
        #     result_set = set(self.result_positions)
            
        #     if stats['missing'] > 0:
        #         print("\nMissing positions (expected but not found):")
        #         for pos in sorted(result_set - acc_ones):
        #             print(f"Position {pos}")
            
        #     if stats['extra'] > 0:
        #         print("\nExtra positions (found but not expected):")
        #         for pos in sorted(acc_ones - result_set):
        #             print(f"Position {pos}")
