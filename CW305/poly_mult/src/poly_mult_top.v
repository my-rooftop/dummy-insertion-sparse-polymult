`include "clog2.v"

module poly_mult_top #(
    parameter MAX_WEIGHT = 75,
    parameter WEIGHT = 2, //2
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
    wire [LOG_WEIGHT-1:0] loc_addr_write;
    wire [LOG_WEIGHT-1:0] loc_addr_read;

    reg [W_BY_X-1:0] din;
    wire [ADDR_WIDTH-1:0]addr_0;
    wire [ADDR_WIDTH-1:0]addr_1;
    reg [ADDR_WIDTH-1:0] addr_0_reg;
    reg [ADDR_WIDTH-1:0] addr_1_reg;
    wire [W_BY_X-1:0] mux_word_0;
    wire [W_BY_X-1:0] mux_word_1;
    wire [W_BY_X-1:0] dout_0; // ✅ RANDOM_BITS_MEM에서 읽은 데이터
    wire [W_BY_X-1:0] dout_1; // ✅ RANDOM_BITS_MEM에서 읽은 데이터
    reg [ADDR_WIDTH-1:0]addr_result;
    wire [W_BY_X-1:0]dout;
    wire valid;
    reg rd_dout;
    reg wr_en_pos;
    reg wr_en_dual;
    reg flag;

    reg start;
    wire [LOG_WEIGHT-1:0] loc_addr;
    wire [ADDR_WIDTH-1:0] addr_0_mux;
    wire [ADDR_WIDTH-1:0] addr_1_mux;

    assign loc_addr_write = (data_i == 0) ? 0 : key_i;
    assign loc_addr_read = (data_i == 0) ? key_i : loc_addr;

    assign mux_word_0 = (addr_0_reg> RAMSIZE/2 - 1)? 0: dout_0;
    assign mux_word_1 = (addr_1_reg> RAMSIZE/2 - 1)? 0: dout_1;  

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
    mem_dual #(.WIDTH(W_BY_X), .DEPTH(RAMSIZE)) RANDOM_BITS_MEM (
        .clock(clk),
        .data_0(din),
        .data_1(0),
        .address_0(addr_0_mux),
        .address_1(addr_1_mux),
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
        .X(X),
        .WEIGHT(WEIGHT)
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
        .addr_0(addr_0),
		.addr_1(addr_1),
		
		.valid(valid),
		.addr_result(addr_result),
		.rd_dout(rd_dout),
		.dout(dout),
		
		.add_wr_en(0),
		.add_addr(0),
		.add_in(0)
    );

    always @(posedge clk) begin
        if (key_i >= WEIGHT && key_i < (WEIGHT + 553)) begin
            addr_0_reg <= key_i - WEIGHT;
            addr_1_reg <= 0;
        end
        else begin
            addr_0_reg <= addr_0; 
            addr_1_reg <= addr_1; 
        end
    end

    assign addr_0_mux = (key_i >= WEIGHT && key_i < (WEIGHT + 553)) ? (key_i - WEIGHT) : addr_0;
    assign addr_1_mux = (key_i >= WEIGHT && key_i < (WEIGHT + 553)) ? 0 : addr_1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // ✅ 리셋이 들어오면 모든 상태 초기화
            busy_o <= 0;
            start <= 0;
            wr_en_pos <= 0;
            wr_en_dual <= 0;
            rd_dout <= 0;

            // loc_addr_write <= 0;
            // loc_addr_read <= 0;
            data_write <= 0;
            // addr_0_reg <= 0;
            // addr_1_reg <= 0;
            din <= 0;
            addr_result <= 0;
            data_o <= 0;
            flag <= 0;
        end
        else if (load_i) begin
            busy_o <= 1;

            if (data_i == 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) begin
                if(key_i == 0) begin
                    rd_dout <= 1;
                    addr_result <= 0;//추후 수정 필요
                end
                else begin
                    start <= 1;
                    flag <= 1;
                end
            end

            if (data_i != 0) begin 
                if (key_i < WEIGHT) begin
                    wr_en_pos <= 1;
                    wr_en_dual <= 0;
                    // loc_addr_write <= key_i;
                    data_write   <= data_i[15:0];
                    data_o <= data_i;
                end
                else if (key_i >= WEIGHT && key_i < (WEIGHT + 553)) begin
                    wr_en_pos <= 0;
                    wr_en_dual <= 1;
                    // addr_0_reg <= key_i - WEIGHT;
                    din <= data_i[31:0];
                    data_o <= data_i;
                end
                else begin
                    wr_en_pos <= 0;
                    wr_en_dual <= 0;
                end
            end
            else begin
                wr_en_pos <= 0;
                wr_en_dual <= 0;

                if (key_i < WEIGHT) begin
                    // loc_addr_read <= key_i;
                    data_o <= {112'b0, loc_in};
                end
                else if (key_i >= WEIGHT && key_i < (WEIGHT + 553)) begin
                    // addr_0_reg <= key_i - WEIGHT;
                    data_o <= {96'b0, dout_0};
                end
                else begin
                    data_o <= 128'b1;
                end
            end
        end
        else if (start) begin
            start <= 0;
        end
        else if (start == 0 && valid) begin
            data_o <= dout;
            busy_o <= 0;
            flag <= 0;
        end 
        else begin
            if (flag == 0) begin
                busy_o <= 0;
            end
            wr_en_pos <= 0;
            wr_en_dual <= 0;
        end
    end
endmodule