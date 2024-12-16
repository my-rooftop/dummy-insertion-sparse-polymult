import numpy as np

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

def print_analysis(analysis_results):
    """분석 결과를 출력합니다."""
    print("\n검증 결과:")
    print(f"시뮬레이션된 결과의 1인 비트 개수: {analysis_results['simulated_count']}")
    print(f"실제 결과의 1인 비트 개수: {analysis_results['actual_count']}")
    print(f"일치하는 비트 위치 개수: {analysis_results['matching_count']}")
    print(f"정확도: {analysis_results['accuracy']:.2f}%")