import matplotlib.pyplot as plt

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

def plot_all_polynomials(r2_poly, h_poly, result_poly, simulated_result):
    """모든 다항식을 시각화합니다."""
    plot_polynomial_bits(r2_poly, 'r2 Polynomial (first 100 bits)')
    plot_polynomial_bits(h_poly, 'h Polynomial (first 100 bits)')
    plot_polynomial_bits(result_poly, 'Actual Result (first 100 bits)')
    plot_polynomial_bits(simulated_result[:len(result_poly)], 
                        'Simulated Result (first 100 bits)')