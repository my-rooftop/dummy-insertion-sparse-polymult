`timescale 1ns/1ps

module poly_mult_tb;

  // 신호 선언
  reg         clk;
  reg         load_i;
  reg [127:0] key_i;
  reg [127:0] data_i;
  wire [127:0] data_o;
  wire        busy_o;

  // DUT 인스턴스화
  poly_mult uut (
    .clk(clk),
    .load_i(load_i),
    .key_i(key_i),
    .data_i(data_i),
    .data_o(data_o),
    .busy_o(busy_o)
  );

  // 클럭 생성 (주기 10 ns)
  always #5 clk = ~clk;

  initial begin
    // 초기화
    clk     = 0;
    load_i  = 0;
    key_i   = 128'hDEADBEEF_12345678_DEADBEEF_12345678;  // 임의의 key 값
    data_i  = 128'h8888_7777_6666_5555_4444_3333_2222_1111; // 16비트 단위로 나눈 128비트 데이터
    
    // 초기 대기
    #20;
    
    // load_i를 한 번만 펄스하여 알고리즘 시작
    $display("Time %0t: Assert load_i", $time);
    load_i = 1;
    @(posedge clk);
    @(posedge clk);
    load_i = 0;

    // 알고리즘 실행 동안 busy_o가 1로 유지됨을 확인
    wait (busy_o == 1);
    $display("Time %0t: busy_o is HIGH, algorithm started.", $time);

    // busy_o가 0이 될 때까지 대기
    wait (busy_o == 0);
    #10;

    // 최종 data_o 확인
    $display("Time %0t: busy_o is LOW, algorithm finished.", $time);
    $display("Time %0t: data_o = %h", $time, data_o);

    // 결과 비교
    if (data_o === data_i)
      $display("TEST PASSED: data_o matches data_i");
    else
      $display("TEST FAILED: data_o does not match data_i");
      
    #20;
    $finish;
  end

endmodule