from typing import List, Tuple, Dict

class DummyInsertion:
    def __init__(self, word_size: int = 16):
        self.word_size = word_size
        
    def find_pair_gaps(self, positions: List[int], num_dummy_pairs: int) -> List[Tuple[int, int, int]]:
        """Find gaps between consecutive positions within pairs (a0,a1) and (a2,a3)"""
        gaps = []
        for i in range(0, len(positions)-1, 2):
            if i+1 < len(positions):  # Ensure we have a pair
                gap_size = positions[i+1] - positions[i]
                gaps.append((gap_size, i, i+1))
        
        # Sort by gap size in descending order and take top N
        gaps.sort(reverse=True)
        return gaps[:num_dummy_pairs]
    
    def insert_dummies(self, positions: List[int], num_dummy_pairs: int = 12) -> List[int]:
        """Insert dummy pairs at midpoint between positions with largest gaps"""
        positions = sorted(positions)
        largest_gaps = self.find_pair_gaps(positions, num_dummy_pairs)
        
        # Track which positions need dummy insertion
        gap_indices = {gap[1]: gap for gap in largest_gaps}
        
        new_positions = []
        for i in range(len(positions)):
            new_positions.append(positions[i])
            
            if i in gap_indices:
                # Calculate dummy position at midpoint of current pair
                dummy_pos = positions[i] + ((positions[i+1] - positions[i]) // 2)
                # Insert dummy pair (same value twice)
                new_positions.extend([dummy_pos, dummy_pos])
        
        return new_positions
    
    def create_packed_words(self, positions: List[int]) -> List[int]:
        """Pack positions into 32-bit words (16-bit pairs)"""
        words = []
        for i in range(0, len(positions)-1, 2):
            word = ((positions[i] & 0xFFFF) << 16) | (positions[i+1] & 0xFFFF)
            words.append(word)
            
        if len(positions) % 2:
            words.append(positions[-1] << 16)
            
        return words
    
    def process_indices(self, positions: List[int], num_dummy_pairs: int = 12) -> Tuple[List[int], List[int]]:
        """Process indices by inserting dummies and packing into words"""
        positions_with_dummies = self.insert_dummies(positions, num_dummy_pairs)
        packed_words = self.create_packed_words(positions_with_dummies)
        return positions_with_dummies, packed_words

    def create_position_map(self, original_positions: List[int], positions_with_dummies: List[int]) -> Dict[int, str]:
        """Create mapping of positions to their types (Original/Dummy)"""
        original_set = set(original_positions)
        return {
            pos: "Original" if pos in original_set else "Dummy"
            for pos in positions_with_dummies
        }
    
    def print_analysis(self, original_positions: List[int], 
                      positions_with_dummies: List[int], 
                      packed_words: List[int]) -> None:
        """Print analysis of dummy insertion results"""
        print("\nR2 Polynomial Analysis:")
        print(f"Original bit positions: {len(original_positions)}")
        print(f"Positions after dummy insertion: {len(positions_with_dummies)}")
        print(f"Number of 32-bit packed words: {len(packed_words)}")
    
    def print_dummy_details(self, positions_with_dummies: List[int], positions_map: Dict[int, str]) -> None:
        """Print details about inserted dummy pairs"""
        print("\nDummy Insertion Details:")
        for i in range(0, len(positions_with_dummies)-1, 2):
            pos1 = positions_with_dummies[i]
            pos2 = positions_with_dummies[i+1]
            if positions_map[pos1] == "Dummy" and positions_map[pos2] == "Dummy":
                print(f"\nDummy pair between {positions_with_dummies[i-1]} and {positions_with_dummies[i+2]}:")
                print(f"  Gap size: {positions_with_dummies[i+2] - positions_with_dummies[i-1]}")
                print(f"  Dummy value: {pos1}")
    
    def print_word_details(self, word: int, index: int, positions_map: Dict[int, str]) -> None:
        """Print detailed information about a 32-bit word"""
        high_bits = (word >> 16) & 0xFFFF
        low_bits = word & 0xFFFF
        
        high_type = positions_map.get(high_bits, "Unknown")
        low_type = positions_map.get(low_bits, "Unknown")
        
        print(f"\nWord {index}:")
        print(f"  High 16 bits: {high_bits:5d} ({high_bits:016b}) - {high_type}")
        print(f"  Low 16 bits:  {low_bits:5d} ({low_bits:016b}) - {low_type}")
    
    def print_packed_words(self, packed_words: List[int], positions_map: Dict[int, str]) -> None:
        """Print details for all packed words"""
        print("\nPacked Word Details:")
        for i, word in enumerate(packed_words):
            self.print_word_details(word, i, positions_map)