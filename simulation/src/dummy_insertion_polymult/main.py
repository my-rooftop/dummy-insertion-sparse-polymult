from data_loader import DataLoader
from memory import PolynomialMemory
from dummy_insertion import DummyInsertion

def main():
    # 데이터 로드
    loader = DataLoader()
    r2_positions = loader.read_positions_from_csv('./data/66/y_bits.csv')
    h_positions = loader.read_positions_from_csv('./data/66/h_for_y_bits.csv')
    result_positions = loader.read_positions_from_csv('./data/66/s_bits.csv')
    
    # Create polynomial memory for h
    h_mem = PolynomialMemory(total_bits=17669, word_size=32)
    h_mem.set_bit_positions(h_positions)

    # Process r2 positions with dummy insertion
    dummy_inserter = DummyInsertion()
    r2_positions_with_dummies, r2_packed_words = dummy_inserter.process_indices(r2_positions, num_dummy_pairs=17)

    r2_mem = PolynomialMemory(total_bits=1600, word_size=32)
    r2_mem.set_word_positions(r2_packed_words)

    acc_mem = PolynomialMemory(total_bits=17669, word_size=32)





    # # Print overall analysis
    # dummy_inserter.print_analysis(r2_positions, r2_positions_with_dummies, r2_packed_words)
    
    # # Create and analyze position mapping
    # positions_map = dummy_inserter.create_position_map(r2_positions, r2_positions_with_dummies)
    
    # # Print detailed analysis
    # dummy_inserter.print_dummy_details(r2_positions_with_dummies, positions_map)
    # dummy_inserter.print_packed_words(r2_packed_words, positions_map)

if __name__ == "__main__":
    main()

