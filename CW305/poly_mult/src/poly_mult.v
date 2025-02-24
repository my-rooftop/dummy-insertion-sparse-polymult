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
    input wire [127:0] key_i,   // 위치 제공
    input wire [127:0] data_i,  // 저장할 데이터
    output reg [127:0] data_o,
    output reg busy_o
);

    // 내부 상태 및 신호
    reg wr_en;
    reg [LOGW-1:0] loc_in;
    reg [LOG_WEIGHT-1:0] loc_addr;
    wire [LOGW-1:0] loc_out;
    reg [3:0] write_counter; 

    reg [6:0] start_addr;  // key_i에서 추출한 시작 위치

    // 메모리 블록 인스턴스
    mem_single #(.WIDTH(LOGW), .DEPTH(WEIGHT)) POSITION_RAM (
        .clock(clk),
        .data(loc_in),
        .address(loc_addr),
        .wr_en(wr_en),
        .q(loc_out)
    );

    always @(posedge clk) begin
        if (load_i) begin
            busy_o <= 1;  
            write_counter <= 0; 
            start_addr <= key_i[6:0];  
        end
        else if (busy_o) begin
            if (write_counter < 8 && (start_addr + write_counter) < WEIGHT) begin  
                wr_en    <= 1;
                loc_addr <= start_addr + write_counter;
                loc_in   <= data_i[(write_counter * 16) +: 16];
                data_o[(write_counter * 16) +: 16] <= data_i[(write_counter * 16) +: 16];
                write_counter <= write_counter + 1;
            end
            else begin
                // ✅ WEIGHT를 넘었거나 8개 완료되면 종료
                wr_en         <= 0;
                busy_o        <= 0;  
                write_counter <= 0;
            end
        end else begin
            busy_o <= 0;
            wr_en  <= 0;
            data_o <= 128'b0;
        end
    end

endmodule