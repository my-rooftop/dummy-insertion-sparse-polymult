from typing import Tuple, List

class ShiftRegister:
    def __init__(self, max_size: int = 19, debug_mode: bool = False):
        """
        ShiftRegister 초기화
        
        Args:
            max_size: 최대 레지스터 크기
            debug_mode: 디버그 모드 활성화 여부
        """
        self.max_size = max_size
        self.register: List[Tuple[int, int]] = []  # (word, idx) 튜플의 리스트
        self.debug_mode = debug_mode
        
    def debug_print(self, message: str) -> None:
        """디버그 메시지 출력"""
        if self.debug_mode:
            print(message)
            
    def visualize(self) -> None:
        """레지스터의 현재 상태를 시각화"""
        if self.debug_mode:
            print("\n=== Register State ===")
            print(f"Register size: {len(self.register)}/{self.max_size}")
            print("Register contents:")
            for i, (word, idx) in enumerate(self.register):
                print(f"Position {i:2d}: [{idx:3d}] {word:032b} ({word:08X})")
            print("===================\n")
    
    def clear(self) -> None:
        """레지스터 초기화"""
        self.register.clear()
        
    def size(self) -> int:
        """현재 레지스터 크기 반환"""
        return len(self.register)
        
    def add_word(self, word: int, word_idx: int) -> None:
        """
        워드 추가
        
        Args:
            word: 추가할 워드 값
            word_idx: 워드의 인덱스
        """
        if len(self.register) >= self.max_size:
            removed_word, removed_idx = self.register.pop(0)
            if self.debug_mode:
                print(f"\nRemoved oldest word[{removed_idx}]: {removed_word:08X}")
            
        self.register.append((word & 0xFFFFFFFF, word_idx))
        
        if self.debug_mode:
            print(f"\nAdded word[{word_idx}]: {word:08X}")
            self.visualize()
            
    def get_word_pair(self, high_left_idx: int, high_right_idx: int, 
                     low_left_idx: int, low_right_idx: int) -> Tuple[int, int, 
                                                                    int, int]:
        """
        지정된 인덱스의 워드 쌍들을 가져오기
        순서: high_right -> high_left -> low_right -> low_left
        
        Args:
            high_right_idx: 상위 오른쪽 워드의 인덱스
            high_left_idx: 상위 왼쪽 워드의 인덱스
            low_right_idx: 하위 오른쪽 워드의 인덱스
            low_left_idx: 하위 왼쪽 워드의 인덱스
            
        Returns:
            ((high_right_word, high_right_idx), (high_left_word, high_left_idx),
             (low_right_word, low_right_idx), (low_left_word, low_left_idx))
        """
            
        if high_right_idx is None:
            high_right = 0
        else:
            high_right = self.register[high_right_idx][0]

        if high_left_idx is None:
            high_left = 0
        else:
            high_left = self.register[high_left_idx][0]
        
        if low_right_idx is None:
            low_right = 0
        else:
            low_right = self.register[low_right_idx][0]
        
        if low_left_idx is None:
            low_left = 0
        else:
            low_left = self.register[low_left_idx][0]
        
        if self.debug_mode:
            print("\n=== Word Pair Retrieval ===")
            print(f"High Right  {high_right:08X}")
            print(f"High Left   {high_left:08X}")
            print(f"Low Right   {low_right:08X}")
            print(f"Low Left    {low_left:08X}")
            print("=========================\n")
        
        return (high_left, high_right, low_left, low_right)


def run_tests():
    """ShiftRegister 테스트 실행"""
    print("\n=== Starting ShiftRegister Test ===")
    
    # 테스트 데이터 생성 (23개 워드)
    test_words = [
        0xF0F0F0F0, 0x0F0F0F0F, 0xAAAAAAAA, 0x55555555,  # 0-3
        0x12345678, 0x87654321, 0xFEDCBA98, 0x89ABCDEF,  # 4-7
        0x11111111, 0x22222222, 0x33333333, 0x44444444,  # 8-11
        0xFFFF0000, 0x0000FFFF, 0xF0F0F0F0, 0x0F0F0F0F,  # 12-15
        0xDEADBEEF, 0xBEEFDEAD, 0xCAFEBABE, 0xBABECAFE,  # 16-19
        0x01234567, 0x89ABCDEF, 0x99999999                # 20-22
    ]
    
    # ShiftRegister 인스턴스 생성 (max_size=19, 디버그 모드 활성화)
    shift_reg = ShiftRegister(max_size=19, debug_mode=True)
    
    print("\nAdding 23 words to register with max_size=19...")
    print("Notice how the oldest words are removed when size exceeds 19\n")
    
    # 23개 워드 순차적으로 추가
    for i, word in enumerate(test_words):
        print(f"\n--- Adding Word #{i} ---")
        shift_reg.add_word(word, i)
        
    print("\n=== Testing Word Pair Retrieval ===")
    # 존재하는 인덱스로 테스트
    print("\nTest 1: Existing indices")
    shift_reg.get_word_pair(15, 16, 17, 18)
    
    # 일부 존재하지 않는 인덱스로 테스트
    print("\nTest 2: Some non-existing indices")
    shift_reg.get_word_pair(1, 16, 3, 18)
    
    # 모두 존재하지 않는 인덱스로 테스트
    print("\nTest 3: All non-existing indices")
    shift_reg.get_word_pair(0, 1, 2, 3)
    
    print("\n=== ShiftRegister Test Complete ===")


if __name__ == "__main__":
    run_tests()