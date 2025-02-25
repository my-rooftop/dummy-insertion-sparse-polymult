`include "clog2.v"

module poly_mult #(
    parameter MAX_WEIGHT = 75,
    parameter WEIGHT = 66,
    parameter N = 17_669,
    parameter M = 15,
    parameter RAMWIDTH = 32,
    parameter TWO_N = 2*N,
    parameter W_RAMWIDTH = TWO_N + (RAMWIDTH-TWO_N%RAMWIDTH)%RAMWIDTH, 
    parameter W = W_RAMWIDTH + RAMWIDTH*((W_RAMWIDTH/RAMWIDTH)%2),
    parameter X = W/RAMWIDTH,
    parameter LOGX = `CLOG2(X), 
    parameter Y = X/2,
    parameter LOGW = `CLOG2(W),
    parameter W_BY_X = W/X, 
    parameter W_BY_Y = W/Y, 
    parameter RAMSIZE = X + X%2,
    parameter ADDR_WIDTH = `CLOG2(RAMSIZE),
    parameter LOG_WEIGHT = `CLOG2(WEIGHT),
    parameter LOG_MAX_WEIGHT = `CLOG2(MAX_WEIGHT),
    parameter MEM_WIDTH = RAMWIDTH,    
    parameter N_MEM = N + (MEM_WIDTH - N%MEM_WIDTH)%MEM_WIDTH, 
    parameter N_B = N + (8-N%8)%8, 
    parameter N_Bd = N_B - N, 
    parameter N_MEMd = N_MEM - N_B                 
)(
    input wire clk,
    input wire load_i,
    input wire [9:0] key_i,   // ✅ 메모리 주소 (0 ~ 66+553)
    input wire [127:0] data_i,  // ✅ 저장할 데이터
    output reg [127:0] data_o,
    output reg busy_o
);

    // 내부 신호 정의
    reg [LOGW-1:0] loc_in;
    reg [LOG_WEIGHT-1:0] loc_addr;
    wire [LOGW-1:0] loc_out; // ✅ POSITION_RAM에서 읽은 데이터

    reg [W_BY_X-1:0] din;
    reg [ADDR_WIDTH-1:0] addr_0_reg;
    wire [W_BY_X-1:0] dout_0; // ✅ RANDOM_BITS_MEM에서 읽은 데이터

    reg wr_en_pos;
    reg wr_en_dual;

    // ✅ POSITION_RAM (16비트 저장 및 읽기)
    mem_single #(.WIDTH(LOGW), .DEPTH(WEIGHT)) POSITION_RAM (
        .clock(clk),
        .data(loc_in),
        .address(loc_addr),
        .wr_en(wr_en_pos),
        .q(loc_out)  // ✅ 읽기 데이터
    );

    // ✅ RANDOM_BITS_MEM (32비트 저장 및 읽기)
    mem_dual #(.WIDTH(W_BY_X), .DEPTH(Y)) RANDOM_BITS_MEM (
        .clock(clk),
        .data_0(din),
        .data_1(0),
        .address_0(addr_0_reg),
        .address_1(0),
        .wren_0(wr_en_dual),
        .wren_1(0),
        .q_0(dout_0), // ✅ 읽기 데이터
        .q_1()
    );

    always @(posedge clk) begin
        if (load_i) begin
            busy_o <= 1;

            if (data_i != 0) begin // ✅ `data_i`가 0이 아니면 저장
                if (key_i < WEIGHT) begin  // ✅ key_i < 66 → POSITION_RAM에 16비트 저장
                    wr_en_pos <= 1;
                    wr_en_dual <= 0;
                    loc_addr <= key_i;
                    loc_in   <= data_i[15:0];  // ✅ 16비트 저장
                    data_o <= data_i;  // ✅ 즉시 data_o 업데이트
                end
                else if (key_i >= WEIGHT && key_i < (WEIGHT + 553)) begin  // ✅ key_i 66~(66+553) → RANDOM_BITS_MEM에 32비트 저장
                    wr_en_pos <= 0;
                    wr_en_dual <= 1;
                    addr_0_reg <= key_i - WEIGHT;
                    din <= data_i[31:0];  // ✅ 32비트 저장
                    data_o <= data_i;  // ✅ 즉시 data_o 업데이트
                end
                else begin
                    wr_en_pos <= 0;
                    wr_en_dual <= 0;
                end
            end
            else begin // ✅ `data_i == 0`이면 key_i에 해당하는 메모리 값 읽기
                wr_en_pos <= 0;
                wr_en_dual <= 0;

                if (key_i < WEIGHT) begin
                    loc_addr <= key_i; // ✅ POSITION_RAM에서 데이터 읽기
                    data_o <= { 112'b0, loc_out};  // ✅ 데이터는 상위 16비트에 배치, 나머지는 0
                end
                else if (key_i >= WEIGHT && key_i < (WEIGHT + 553)) begin
                    addr_0_reg <= key_i - WEIGHT; // ✅ RANDOM_BITS_MEM에서 데이터 읽기
                    data_o <= {96'b0, dout_0};  // ✅ 데이터는 상위 32비트에 배치, 나머지는 0
                end
                else begin
                    data_o <= 128'b1;  // ✅ 유효하지 않은 key 값일 때
                end
            end
        end
        else begin
            busy_o <= 0;
            wr_en_pos <= 0;
            wr_en_dual <= 0;
        end
    end
endmodule