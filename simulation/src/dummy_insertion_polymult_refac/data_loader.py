class DataLoader:
    def __init__(self):
        self.file_pointers = {}  # 파일별 현재 위치를 추적
        self.current_line = {}   # 파일별 현재 라인 번호
        
    def _initialize_file(self, filename: str) -> None:
        """파일 초기화 및 포인터 설정"""
        if filename not in self.file_pointers:
            self.file_pointers[filename] = open(filename, 'r')
            self.current_line[filename] = 0
            
    def read_next_positions(self, filename: str) -> list[int]:
        """CSV 파일에서 다음 라인의 비트 위치들을 읽어옵니다."""
        try:
            self._initialize_file(filename)
            
            # 파일에서 다음 라인 읽기
            line = self.file_pointers[filename].readline().strip()
            self.current_line[filename] += 1
            
            if line:
                return [int(x) for x in line.split(',')]
            return []
            
        except Exception as e:
            print(f"Error reading file {filename}: {str(e)}")
            return []
            
    def reset_file(self, filename: str) -> None:
        """파일 포인터를 처음으로 되돌립니다."""
        if filename in self.file_pointers:
            self.file_pointers[filename].seek(0)
            self.current_line[filename] = 0
            
    def close_files(self) -> None:
        """열린 모든 파일을 닫습니다."""
        for fp in self.file_pointers.values():
            fp.close()
        self.file_pointers.clear()
        self.current_line.clear()