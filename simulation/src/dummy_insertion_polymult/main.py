from data_loader import DataLoader
from memory import PolynomialMemory
from dummy_insertion import DummyInsertion
from controller import Controller
from shift_xor_operation import ShiftXorOperations
from result_verifier import ResultVerifier

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

    acc_mem = PolynomialMemory(total_bits=17669, word_size=32, debug_mode=False)

    # # Print overall analysis
    # dummy_inserter.print_analysis(r2_positions, r2_positions_with_dummies, r2_packed_words)
    
    # # Create and analyze position mapping
    # positions_map = dummy_inserter.create_position_map(r2_positions, r2_positions_with_dummies)
    
    # # Print detailed analysis
    # dummy_inserter.print_dummy_details(r2_positions_with_dummies, positions_map)
    # dummy_inserter.print_packed_words(r2_packed_words, positions_map)

    # Create controller for polynomial multiplication
    num = 50

    controller = Controller(normal_mem=h_mem, sparse_mem=r2_mem, acc_mem=acc_mem, debug_mode=False)
    controller.execute(num)

    verifier = ResultVerifier(acc_mem, result_positions)
    verifier.print_report()

    # ops = ShiftXorOperations()
    # ops.set_r2_memory(r2_mem)
    # ops.set_acc_memory(acc_mem)  # acc_mem 설정
    # ops.set_bits(h_positions)
    
    # # r2_mem의 특정 word를 처리
    # ops.process_r2_word_accumulated(num)  # 첫 번째 word (148, 342) 처리
    
    # # 결과 비교
    # ops.compare_with_acc_mem()

    #이거 밑에 전부 비트표현으로 변경해줘

    # print("[541]:", h_mem.get_word_binary(541))
    # print("[542]:", h_mem.get_word_binary(542))
    # print("[543]:", h_mem.get_word_binary(543))
    # print("[544]:", h_mem.get_word_binary(544))
    # print("[545]:", h_mem.get_word_binary(545))
    # print("[546]:", h_mem.get_word_binary(546))
    # print("[547]:", h_mem.get_word_binary(547))
    # print("[548]:", h_mem.get_word_binary(548))
    # print("[549]:", h_mem.get_word_binary(549))
    # print("[550]:", h_mem.get_word_binary(550))
    # print("[551]:", h_mem.get_word_binary(551))
    # print("[552]:", h_mem.get_word_binary(552))
    # print("[0] :", h_mem.get_word_binary(0))
    # print("[1] :", h_mem.get_word_binary(1))
    # print("[2] :", h_mem.get_word_binary(2))
    # print("[3] :", h_mem.get_word_binary(3))


if __name__ == "__main__":
    main()

