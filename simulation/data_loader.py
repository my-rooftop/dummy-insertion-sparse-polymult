import numpy as np

def read_positions_from_csv(filename):
    """CSV 파일에서 1인 비트 위치들을 읽어옵니다."""
    try:
        with open(filename, 'r') as f:
            content = f.read().strip()
            if content:
                return [int(x) for x in content.split(',')]
            return []
    except FileNotFoundError:
        print(f"Error: File {filename} not found")
        return []
    except Exception as e:
        print(f"Error reading file {filename}: {str(e)}")
        return []