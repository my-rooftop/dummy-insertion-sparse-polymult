import numpy as np

def generate_unique_random_numbers(num=66, low=0, high=17669):
    """
    low부터 high-1까지 범위에서 중복 없는 num개의 랜덤 숫자를 생성하여 오름차순 정렬한 후 반환합니다.
    """
    numbers = np.random.choice(np.arange(low, high), size=num, replace=False)
    numbers = np.sort(numbers)
    return numbers

# 66개의 중복 없는 랜덤 숫자 생성 (0 ~ 17668)
random_numbers = generate_unique_random_numbers(num=66, low=0, high=17669)

# 파일에 저장: 각 숫자를 16비트 이진 문자열로 변환하여 저장
with open("/home/boochoo/hqc/dummy-insertion-sparse-polymult/CW305/poly_mult/jupyter/secret_66_2.mem", "w") as f:
    for number in random_numbers:
        f.write(f"{number:016b}\n")

print("random66.mem 파일에 66개의 숫자가 저장되었습니다.")