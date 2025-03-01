import numpy as np

def generate_bit_words(num_sets=100):
    """
    17669비트를 무작위로 생성 후,
    32비트씩 끊어 총 553개의 워드로 만들고,
    이를 여러 세트(기본 num_sets 세트) 생성하는 함수.
    
    마지막 청크가 32비트보다 짧을 경우, valid 비트를 오른쪽(LSB) 정렬하도록
    왼쪽에 0으로 패딩합니다.
    """
    all_results = []

    for _ in range(num_sets):
        # 1) 17669개의 비트를 각 1/2 확률로 생성 (0 또는 1)
        bits = np.random.randint(0, 2, size=17669, dtype=np.uint8)

        # 2) 32비트씩 끊어서 총 553개 워드로 변환
        words = []
        for i in range(553):
            start = i * 32
            end = start + 32
            chunk = bits[start:end]

            # 만약 마지막 chunk가 32비트보다 짧다면,
            # valid 비트들을 오른쪽에 두기 위해 왼쪽에 pad_size 만큼 0을 붙임
            if len(chunk) < 32:
                pad_size = 32 - len(chunk)
                chunk = np.concatenate([np.zeros(pad_size, dtype=np.uint8), chunk])

            # chunk(길이 32인 비트 배열)를 정수로 변환
            val = 0
            for b in chunk:
                val = (val << 1) | b
            words.append(val)

        all_results.append(words)

    return all_results

num_sets = 1
bit_word_sets = generate_bit_words(num_sets=num_sets)

# 파일 저장: 모든 세트의 워드를 32비트 이진 문자열로 저장
with open(f"/home/boochoo/hqc/dummy-insertion-sparse-polymult/CW305/poly_mult/jupyter/plaintext_{num_sets}.mem", "w") as f:
    for set_words in bit_word_sets:
        for word in set_words:
            f.write(f"{word:032b}\n")

print(f"파일에 {num_sets}개의 세트(총 553*{num_sets} 워드)가 누적되어 저장되었습니다.")