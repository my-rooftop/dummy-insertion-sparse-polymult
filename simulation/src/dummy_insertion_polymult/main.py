from data_loader import DataLoader
from memory import PolynomialMemory
from dummy_insertion import DummyInsertion
from controller import Controller
from result_verifier import ResultVerifier

def test_dataset(dataset_num: int, loader: DataLoader, debug_mode: bool = False) -> tuple[bool, float]:
    """Test a single dataset and return success status and error rate"""
    # Load next dataset from files
    r2_positions = loader.read_next_positions('./data/66/y_bits.csv')
    h_positions = loader.read_next_positions('./data/66/h_for_y_bits.csv')
    result_positions = loader.read_next_positions('./data/66/s_bits.csv')
    
    if not r2_positions or not h_positions or not result_positions:
        print(f"\nError: Failed to load dataset {dataset_num}")
        return False, 100.0

    # Initialize memories
    h_mem = PolynomialMemory(total_bits=17669, word_size=32)
    h_mem.set_bit_positions(h_positions)
    

    # for i in range(553):
    #     print(f'normal_words[{i}] = 32\'b{h_mem.get_word(i):032b};')

    # Process r2 positions with dummy insertion
    dummy_inserter = DummyInsertion()
    r2_positions_with_dummies, r2_packed_words = dummy_inserter.process_indices(r2_positions, num_dummy_pairs=17)

    r2_mem = PolynomialMemory(total_bits=1600, word_size=32)
    r2_mem.set_word_positions(r2_packed_words)


    acc_mem = PolynomialMemory(total_bits=17669, word_size=32, debug_mode=debug_mode)

    # Execute multiplication
    controller = Controller(normal_mem=h_mem, sparse_mem=r2_mem, acc_mem=acc_mem, debug_mode=debug_mode)
    controller.execute()

    # Verify results
    verifier = ResultVerifier(acc_mem, result_positions)
    success, missing, extra, error_rate = verifier.verify_results()
    
    if not success:
        print(f"\n⚠️ WARNING: Dataset {dataset_num} failed verification!")
        print(f"Missing positions: {len(missing)}")
        print(f"Extra positions: {len(extra)}")
        print(f"Error rate: {error_rate:.2f}%")
        
    return success, error_rate

def main():
    print("\n=== Starting Multiple Dataset Test ===")
    
    total_datasets = 1
    successful_tests = 0
    failed_tests = []
    total_error_rate = 0.0
    
    # Initialize data loader
    loader = DataLoader()
    
    try:
        for dataset_num in range(total_datasets):
            print(f"\nTesting dataset {dataset_num}...")
            success, error_rate = test_dataset(dataset_num, loader, debug_mode=True)
            
            if success:
                successful_tests += 1
                print(f"✓ Dataset {dataset_num} passed")
            else:
                failed_tests.append(dataset_num)
            
            total_error_rate += error_rate
        
        # Print summary
        print("\n=== Test Summary ===")
        print(f"Total datasets tested: {total_datasets}")
        print(f"Successful tests: {successful_tests}")
        print(f"Failed tests: {len(failed_tests)}")
        if failed_tests:
            print(f"Failed dataset numbers: {failed_tests}")
        print(f"Average error rate: {total_error_rate/total_datasets:.2f}%")
        print("=====================")
        
    finally:
        # 파일들을 확실하게 닫아줍니다
        loader.close_files()

if __name__ == "__main__":
    main()