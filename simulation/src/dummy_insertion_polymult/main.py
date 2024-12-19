from data_loader import DataLoader


def main():
    # 데이터 로드
    loader = DataLoader()
    r2_positions = loader.read_positions_from_csv('./data/r2_bits.csv')
    h_positions = loader.read_positions_from_csv('./data/h_bits.csv')
    result_positions = loader.read_positions_from_csv('./data/r2h_result_bits.csv')
    
    

if __name__ == "__main__":
    main()