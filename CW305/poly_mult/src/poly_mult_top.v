`include "clog2.v"

module poly_mult_top #(
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
    input wire rst,
    input wire load_i,
    input wire [9:0] key_i,   // ✅ 메모리 주소 (0 ~ 66+553)
    input wire [127:0] data_i,  // ✅ 저장할 데이터
    output reg [127:0] data_o,
    output reg busy_o
);

    // 내부 신호 정의
    wire [LOGW-1:0] loc_in;
    reg [LOGW-1:0] data_write;
    reg [LOG_WEIGHT-1:0] loc_addr_write;
    reg [LOG_WEIGHT-1:0] loc_addr_read;

    reg [W_BY_X-1:0] din;
    wire [ADDR_WIDTH-1:0]addr_0;
    wire [ADDR_WIDTH-1:0]addr_1;
    reg [ADDR_WIDTH-1:0] addr_0_reg;
    reg [ADDR_WIDTH-1:0] addr_1_reg;
    wire [W_BY_X-1:0] dout_0; // ✅ RANDOM_BITS_MEM에서 읽은 데이터
    wire [W_BY_X-1:0] dout_1; // ✅ RANDOM_BITS_MEM에서 읽은 데이터
    reg [ADDR_WIDTH-1:0]addr_result;
    wire [W_BY_X-1:0]dout;
    wire valid;
    reg rd_dout;
    reg wr_en_pos;
    reg wr_en_dual;

    reg start;
    wire [LOG_WEIGHT-1:0] loc_addr;
    wire [ADDR_WIDTH-1:0] addr_0_mux;
    wire [ADDR_WIDTH-1:0] addr_1_mux;

    assign addr_0_mux = (load_i) ? addr_0_reg : (start ? addr_0_reg : addr_result);
    assign addr_1_mux = (load_i) ? addr_1_reg : (start ? addr_1_reg : addr_result);
    assign loc_addr = (load_i) ? loc_addr_read : (start ? loc_addr_read : loc_addr_write);

    assign mux_word_0 = (addr_0_reg> RAMSIZE/2 - 1)? 0: dout_0;
    assign mux_word_1 = (addr_1_reg> RAMSIZE/2 - 1)? 0: dout_1;  

    assign addr_0 = addr_0_reg;
    assign addr_1 = addr_1_reg;

    mem_dual #(.WIDTH(LOGW), .DEPTH(WEIGHT)) POSITION_RAM (
        .clock(clk),
        .data_0(data_write),
        .data_1(0),
        .address_0(loc_addr_write),
        .address_1(loc_addr_read),
        .wren_0(wr_en_pos),
        .wren_1(0),
        .q_0(), 
        .q_1(loc_in) // ✅ 읽기 데이터
    );

    // ✅ RANDOM_BITS_MEM (32비트 저장 및 읽기)
    mem_dual #(.WIDTH(W_BY_X), .DEPTH(Y)) RANDOM_BITS_MEM (
        .clock(clk),
        .data_0(din),
        .data_1(0),
        .address_0(addr_0_reg),
        .address_1(addr_1_reg),
        .wren_0(wr_en_dual),
        .wren_1(0),
        .q_0(dout_0), // ✅ 읽기 데이터
        .q_1(dout_1)
    );

    poly_mult #(
        .MAX_WEIGHT(MAX_WEIGHT),
        .N(N),
        .M(M),
        .W(W),
        .RAMWIDTH(RAMWIDTH),
        .X(X)
    )
    DUT  (
        .clk(clk),
        .rst(rst),
        .start(start),
                
        // Shift Position loading
        .loc_addr(loc_addr),
        .loc_in(loc_in),
        .weight(WEIGHT),
        
        // Random Vector Loading
        .mux_word_0(mux_word_0),
        .mux_word_1(mux_word_1),
        .addr_0(addr_0_mux),
		.addr_1(addr_1_mux),
		
		.valid(valid),
		.addr_result(addr_result),
		.rd_dout(rd_dout),
		.dout(dout),
		
		.add_wr_en(0),
		.add_addr(0),
		.add_in(0)
  );



        always @(posedge clk) begin
        if (load_i) begin
            busy_o <= 1;

            if (data_i == 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) begin // ✅ 128비트가 전부 1이면 start 신호 활성화
                start <= 1;
                rd_dout <= 0;
            end
            else if (start) begin
                start <= 0;
            end
            //여기 문제 가능성 큼
            if (data_i != 0) begin // ✅ `data_i`가 0이 아니면 저장
                if (key_i < WEIGHT) begin  // ✅ key_i < 66 → POSITION_RAM에 16비트 저장
                    wr_en_pos <= 1;
                    wr_en_dual <= 0;
                    loc_addr_write <= key_i;
                    data_write   <= data_i[15:0];  // ✅ 16비트 저장
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
                    loc_addr_read <= key_i; // ✅ POSITION_RAM에서 데이터 읽기
                    data_o <= { 112'b0, loc_in};  // ✅ 데이터는 상위 16비트에 배치, 나머지는 0
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
        else if (start == 0 && valid) begin
            // ✅ poly_mult 종료 후 valid가 1이 될 때까지 대기
            busy_o <= 0; 
            data_o <= dout;  
        end 
        else begin
            busy_o <= 0;
            wr_en_pos <= 0;
            wr_en_dual <= 0;
        end
    end
endmodule