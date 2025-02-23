`include "clog2.v"

module poly_mult #(
    parameter MAX_WEIGHT = 75,
    parameter WEIGHT = 66,
    parameter N = 17_669,
    parameter M = 15,
    parameter RAMWIDTH = 32, // Width of each chunk W needs to be divided in to. Best to choose a 2 power
    parameter TWO_N = 2*N,
    parameter W_RAMWIDTH = TWO_N + (RAMWIDTH-TWO_N%RAMWIDTH)%RAMWIDTH, 
    parameter W = W_RAMWIDTH + RAMWIDTH*((W_RAMWIDTH/RAMWIDTH)%2),
    parameter X = W/RAMWIDTH,
    parameter LOGX = `CLOG2(X), 
    parameter Y = X/2,
    parameter LOGW = `CLOG2(W),
    parameter W_BY_X = W/X, 
    parameter W_BY_Y = W/Y, // This number needs to be a power of 2 for optimized synthesis
    parameter RAMSIZE = X + X%2,
    parameter ADDR_WIDTH = `CLOG2(RAMSIZE),
    parameter LOG_WEIGHT = `CLOG2(WEIGHT),
    parameter LOG_MAX_WEIGHT = `CLOG2(MAX_WEIGHT),
    parameter MEM_WIDTH = RAMWIDTH,	
    parameter N_MEM = N + (MEM_WIDTH - N%MEM_WIDTH)%MEM_WIDTH, // Memory width adjustment for N
    parameter N_B = N + (8-N%8)%8, // Byte adjustment on N
    parameter N_Bd = N_B - N, // difference between N and byte adjusted N
    parameter N_MEMd = N_MEM - N_B // difference between byte adjust and Memory adjusted N                                      
)(
    input wire clk,
    input wire load_i,
    input wire [127:0] key_i,
    input wire [127:0] data_i,
    output reg [127:0] data_o,
    output reg busy_o
);

    // 내부 상태 및 신호
    reg wr_en;
    reg [LOGW-1:0] loc_in;
    reg [LOG_WEIGHT-1:0] loc_addr;
    wire [LOGW-1:0] loc_out;
    reg [3:0] write_counter; // 16비트씩 8회 저장하기 위한 카운터

    mem_single #(.WIDTH(LOGW), .DEPTH(WEIGHT)) POSITION_RAM (
        .clock(clk),
        .data(loc_in),
        .address(loc_addr),
        .wr_en(wr_en),
        .q(loc_out)
    );

    always @(posedge clk) begin
        if (load_i) begin
            busy_o <= 1;  // ✅ load_i가 들어오면 즉시 busy_o를 1로 설정
            write_counter <= 0; // 상태 머신 초기화
        end

        else if (busy_o) begin  // ✅ busy_o를 통해 진행 상태 확인
            case (write_counter)
                4'd0: begin
                    wr_en    <= 1;
                    loc_addr <= 0;
                    loc_in   <= data_i[15:0];
                    data_o[15:0] <= data_i[15:0];
                    write_counter <= write_counter + 1;
                end
                4'd1: begin
                    wr_en    <= 1;
                    loc_addr <= 1;
                    loc_in   <= data_i[31:16];
                    data_o[31:16] <= data_i[31:16];
                    write_counter <= write_counter + 1;
                end
                4'd2: begin
                    wr_en    <= 1;
                    loc_addr <= 2;
                    loc_in   <= data_i[47:32];
                    data_o[47:32] <= data_i[47:32];
                    write_counter <= write_counter + 1;
                end
                4'd3: begin
                    wr_en    <= 1;
                    loc_addr <= 3;
                    loc_in   <= data_i[63:48];
                    data_o[63:48] <= data_i[63:48];
                    write_counter <= write_counter + 1;
                end
                4'd4: begin
                    wr_en    <= 1;
                    loc_addr <= 4;
                    loc_in   <= data_i[79:64];
                    data_o[79:64] <= data_i[79:64];
                    write_counter <= write_counter + 1;
                end
                4'd5: begin
                    wr_en    <= 1;
                    loc_addr <= 5;
                    loc_in   <= data_i[95:80];
                    data_o[95:80] <= data_i[95:80];
                    write_counter <= write_counter + 1;
                end
                4'd6: begin
                    wr_en    <= 1;
                    loc_addr <= 6;
                    loc_in   <= data_i[111:96];
                    data_o[111:96] <= data_i[111:96];
                    write_counter <= write_counter + 1;
                end
                4'd7: begin
                    wr_en    <= 1;
                    loc_addr <= 7;
                    loc_in   <= data_i[127:112];
                    data_o[127:112] <= data_i[127:112];
                    write_counter <= write_counter + 1;
                end
                4'd8: begin
                    // ✅ 마지막 데이터 쓰기가 완료된 후 busy_o 종료
                    wr_en         <= 0;
                    busy_o        <= 0;  // ✅ busy_o 0으로 설정하여 종료
                    write_counter <= 0;
                end
                default: begin
                    write_counter <= 0;
                end
            endcase
        end else begin
            // ✅ 알고리즘이 진행 중이 아니면 모든 신호 초기화
            busy_o <= 0;
            wr_en  <= 0;
            data_o <= 128'b0;
        end
    end

endmodule