import csv

def convert_csv_to_mem(csv_filename, mem_filename):
    with open(csv_filename, "r") as csv_file, open(mem_filename, "w") as mem_file:
        csv_reader = csv.reader(csv_file)

        for row in csv_reader:
            # 각 숫자를 15비트 이진수로 변환 (15자리 패딩 유지)
            bin_values = [format(int(value), "015b") for value in row]
            # 한 줄씩 파일에 기록
            for bin_value in bin_values:
                mem_file.write(bin_value + "\n")

    print(f"변환 완료: {mem_filename}")

# 사용 예시
convert_csv_to_mem("./hardware_attack/random_generator_py/y_bits.csv", "./hardware_attack/random_generator_py/y_128.mem")