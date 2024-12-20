import numpy as np
import matplotlib.pyplot as plt
from data_loader import DataLoader

class PolynomialOperations:
    @staticmethod
    def create_polynomial_from_positions(positions, size=17669):
        """비트 위치들로부터 다항식(비트 벡터)을 생성합니다."""
        poly = np.zeros(size, dtype=np.int8)
        for pos in positions:
            if pos < size:
                poly[pos] = 1
        return poly

    @staticmethod
    def polynomial_multiply_gf2(poly1, poly2):
        """GF(2) 상에서 두 다항식을 곱합니다."""
        result = np.zeros(len(poly1) + len(poly2) - 1, dtype=np.int8)
        
        for i in range(len(poly1)):
            if poly1[i] == 1:
                for j in range(len(poly2)):
                    if poly2[j] == 1:
                        result[i + j] ^= 1  # XOR 연산 (GF(2)에서의 덧셈)
        
        return result
    
    @staticmethod
    def reduce_polynomial(poly, n):
        """다항식의 크기를 n으로 줄입니다."""
        result = np.copy(poly[:n])
        
        # n+1부터 2n-1까지의 항들을 처리
        for i in range(n, len(poly)):
            if poly[i] == 1:
                # x^i = x^(i-n) (mod x^n + 1) 관계를 적용
                result[i - n] ^= 1
                
        return result

class Visualizer:
    @staticmethod
    def plot_polynomial_bits(poly, title, max_bits=100):
        """다항식의 처음 max_bits개의 비트를 시각화합니다."""
        plt.figure(figsize=(15, 3))
        plt.plot(poly[:max_bits], 'b.')
        plt.grid(True)
        plt.title(title)
        plt.xlabel('Bit Position')
        plt.ylabel('Bit Value')
        plt.ylim(-0.1, 1.1)
        plt.show()

    @staticmethod
    def plot_all_polynomials(r2_poly, h_poly, result_poly, simulated_result):
        """모든 다항식을 시각화합니다."""
        Visualizer.plot_polynomial_bits(r2_poly, 'r2 Polynomial (first 100 bits)')
        Visualizer.plot_polynomial_bits(h_poly, 'h Polynomial (first 100 bits)')
        Visualizer.plot_polynomial_bits(result_poly, 'Actual Result (first 100 bits)')
        Visualizer.plot_polynomial_bits(simulated_result[:len(result_poly)], 
                                      'Simulated Result (first 100 bits)')

class ResultAnalyzer:
    @staticmethod
    def analyze_results(simulated_positions, result_positions):
        """시뮬레이션 결과를 분석합니다."""
        matching_positions = set(simulated_positions) & set(result_positions)
        accuracy = len(matching_positions) / len(result_positions) * 100
        
        return {
            'simulated_count': len(simulated_positions),
            'actual_count': len(result_positions),
            'matching_count': len(matching_positions),
            'accuracy': accuracy
        }

    @staticmethod
    def print_analysis(analysis_results):
        """분석 결과를 출력합니다."""
        print("\n검증 결과:")
        print(f"시뮬레이션된 결과의 1인 비트 개수: {analysis_results['simulated_count']}")
        print(f"실제 결과의 1인 비트 개수: {analysis_results['actual_count']}")
        print(f"일치하는 비트 위치 개수: {analysis_results['matching_count']}")
        print(f"정확도: {analysis_results['accuracy']:.2f}%")

def main():
    # 데이터 로드
    loader = DataLoader()
    r2_positions = loader.read_positions_from_csv('./data/66/y_bits.csv')
    h_positions = loader.read_positions_from_csv('./data/66/h_for_y_bits.csv')
    result_positions = loader.read_positions_from_csv('./data/66/s_bits.csv')

    # 초기 데이터 정보 출력
    print(f"r2의 1인 비트 개수: {len(r2_positions)}")
    print(f"h의 1인 비트 개수: {len(h_positions)}")
    print(f"결과의 1인 비트 개수: {len(result_positions)}")

    # 다항식 연산
    poly_ops = PolynomialOperations()
    r2_poly = poly_ops.create_polynomial_from_positions(r2_positions)
    h_poly = poly_ops.create_polynomial_from_positions(h_positions)
    result_poly = poly_ops.create_polynomial_from_positions(result_positions)

    # 시뮬레이션된 곱셈 수행
    raw_result = poly_ops.polynomial_multiply_gf2(r2_poly, h_poly)
    
    # 다항식 크기 축소 적용
    n = len(r2_poly)  # 원래 다항식의 크기
    simulated_result = poly_ops.reduce_polynomial(raw_result, n)

    # 결과 분석
    simulated_positions = np.where(simulated_result[:len(result_poly)] == 1)[0]
    analyzer = ResultAnalyzer()
    analysis_results = analyzer.analyze_results(simulated_positions, result_positions)
    analyzer.print_analysis(analysis_results)

    # 시각화
    visualizer = Visualizer()
    visualizer.plot_all_polynomials(r2_poly, h_poly, result_poly, simulated_result)

if __name__ == "__main__":
    main()