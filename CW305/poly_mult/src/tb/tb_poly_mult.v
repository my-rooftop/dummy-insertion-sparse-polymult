`timescale 1ns/1ps

module poly_mult_tb;

    // Parameters
    parameter LOGW = 8; // LOGW 값은 실제 크기에 맞게 설정 필요
    parameter LOG_WEIGHT = 7; // LOG_WEIGHT 값은 실제 크기에 맞게 설정 필요

    // Testbench Signals
    reg clk;
    reg load_i;
    reg [127:0] key_i;
    reg [127:0] data_i;
    wire [127:0] data_o;
    wire busy_o;

    // Instantiate the DUT (Device Under Test)
    poly_mult uut (
        .clk(clk),
        .load_i(load_i),
        .key_i(key_i),
        .data_i(data_i),
        .data_o(data_o),
        .busy_o(busy_o)
    );

    // Clock Generation
    always #5 clk = ~clk; // 10ns 주기의 클럭 생성 (100MHz)

    initial begin
        // 초기화
        clk = 0;
        load_i = 0;
        key_i = 0;
        data_i = 0;
        
        // 파워온 리셋 대기
        #20;

        // 첫 번째 데이터 로드
        load_i = 1;
        key_i = 128'h00000000000000000000000000000001; // 주소 1
        data_i = 128'hDEADBEEFCAFEBABE1122334455667788; // 저장할 데이터
        #10;
        load_i = 0;
        #20;

        // 두 번째 데이터 로드
        load_i = 1;
        key_i = 128'h00000000000000000000000000000002; // 주소 2
        data_i = 128'hAABBCCDDEEFF00112233445566778899; // 저장할 데이터
        #10;
        load_i = 0;
        #20;

        // 데이터 읽기 테스트 (주소 1에서 읽기)
        key_i = 128'h00000000000000000000000000000001; // 주소 1을 설정
        #10;
        $display("Read Data at Address 1: %h", data_o);
        
        // 데이터 읽기 테스트 (주소 2에서 읽기)
        key_i = 128'h00000000000000000000000000000002; // 주소 2를 설정
        #10;
        $display("Read Data at Address 2: %h", data_o);

        // 시뮬레이션 종료
        #50;
        $finish;
    end

endmodule