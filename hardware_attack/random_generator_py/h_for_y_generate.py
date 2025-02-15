import math
import pandas as pd
from typing import List

class PolynomialMemory:
    def __init__(self, total_bits: int, word_size: int = 128):
        self.total_bits = total_bits
        self.word_size = word_size
        self.num_words = math.ceil(total_bits / word_size)
        self.memory = [0] * self.num_words  # word_size 단위 워드 초기화

    def set_bit_positions(self, positions: List[int]) -> None:
        """주어진 위치에 해당하는 비트를 1로 설정 (LSB부터)"""
        for pos in positions:
            if pos < self.total_bits:
                word_idx = pos // self.word_size
                bit_idx = pos % self.word_size
                self.memory[word_idx] |= (1 << bit_idx)  # LSB부터 설정

    def get_memory(self) -> List[int]:
        """현재 메모리 값 반환"""
        return self.memory.copy()

    def get_word_binary(self, word_idx: int) -> str:
        """주어진 인덱스의 word_size 비트 워드를 이진 문자열로 반환"""
        if word_idx >= self.num_words:
            return format(0, f'0{self.word_size}b')
        return format(self.memory[word_idx], f'0{self.word_size}b')

def read_s_bits(csv_filename: str) -> List[int]:
    """CSV 파일에서 1이 있는 비트 위치 읽기"""
    df = pd.read_csv(csv_filename, header=None)
    return df.values.flatten().tolist()

def save_to_mem(words: List[str], mem_filename: str) -> None:
    """.mem 파일로 변환된 word_size 비트 워드 저장"""
    with open(mem_filename, 'w') as f:
        for word in words:
            f.write(word + "\n")

def main():
    word_size = 32  # 여기서 64 또는 128로 설정 가능
    
    csv_filename = "./hardware_attack/random_generator_py/s_bits.csv"
    mem_filename = f"./hardware_attack/random_generator_py/s_{word_size}.mem"  # 64비트 사용 시 변경

    # CSV에서 계수가 1인 비트 위치 읽기
    bit_positions = read_s_bits(csv_filename)
    
    # PolynomialMemory 객체 생성 및 비트 설정
    max_bit = max(bit_positions) if bit_positions else 0
    memory = PolynomialMemory(total_bits=max_bit + 1, word_size=word_size)
    memory.set_bit_positions(bit_positions)

    # word_size 비트 워드를 이진 문자열로 변환하여 저장
    words = [memory.get_word_binary(i) for i in range(memory.num_words)]
    save_to_mem(words, mem_filename)

    print(f"{len(words)}개의 {word_size}비트 워드가 {mem_filename}에 저장되었습니다.")

if __name__ == "__main__":
    main()