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

    reg [9:0] start_addr;  // ✅ 10비트 start_addr (최대 553)
    reg [3:0] dual_write_counter; // ✅ 32비트 저장 시 카운터 (0~3)

    reg [W_BY_X-1:0] din;
    reg [ADDR_WIDTH-1:0]addr_0_reg;
    reg [ADDR_WIDTH-1:0]addr_1_reg;
    wire [W_BY_X-1:0] mux_word_0;
    wire [W_BY_X-1:0] mux_word_1;
    wire [W_BY_X-1:0] dout_0;
    wire [W_BY_X-1:0] dout_1;

    // 메모리 블록 인스턴스 (POSITION_RAM)
    mem_single #(.WIDTH(LOGW), .DEPTH(WEIGHT)) POSITION_RAM (
        .clock(clk),
        .data(loc_in),
        .address(loc_addr),
        .wr_en(wr_en),
        .q(loc_out)
    );

    mem_dual #(.WIDTH(W_BY_X), .DEPTH(Y)) RANDOM_BITS_MEM (
        .clock(clk),
        .data_0(din),
        .data_1(0),
        .address_0(addr_0_reg),
        .address_1(addr_1_reg),
        .wren_0(wr_en),
        .wren_1(0),
        .q_0(dout_0),
        .q_1(dout_1)
    );

    always @(posedge clk) begin
        case (key_i[127:126])
            2'b00: begin  // ✅ key_i[127] == 0: POSITION_RAM에 16비트 저장
                if (load_i) begin
                    busy_o <= 1;  
                    write_counter <= 0; 
                    start_addr <= key_i[9:0];  // ✅ 10비트 주소 사용
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
                        wr_en         <= 0;
                        busy_o        <= 0;  
                        write_counter <= 0;
                    end
                end
                else begin
                    busy_o <= 0;
                    wr_en  <= 0;
                    data_o <= 128'b0;
                end
            end

            2'b01: begin  // ✅ key_i[127] == 1: mem_dual에 32비트 단위로 저장 (start_addr 포함)
                if (load_i) begin
                    busy_o <= 1;
                    dual_write_counter <= 0;
                    start_addr <= key_i[9:0];  // ✅ key_i에서 10비트 주소 추출
                end
                else if (busy_o) begin
                    if (dual_write_counter < 4 && start_addr + dual_write_counter < Y) begin
                        wr_en <= 1;
                        addr_0_reg <= start_addr + dual_write_counter;
                        
                        case (dual_write_counter)
                            4'd0: din <= data_i[31:0];  // ✅ 첫 번째 저장: start_addr (32비트 중 하위 10비트만)
                            4'd1: din <= data_i[63:32];  // ✅ 32비트 데이터 저장
                            4'd2: din <= data_i[95:64]; 
                            4'd3: din <= data_i[127:96]; 
                            default: din <= 0;
                        endcase
                        data_o[(dual_write_counter * 32) +: 32] <= data_i[(dual_write_counter * 32) +: 32];
                        dual_write_counter <= dual_write_counter + 1;
                    end
                    else begin
                        wr_en <= 0;
                        busy_o <= 0;
                        dual_write_counter <= 0;
                    end
                end
                else begin
                    busy_o <= 0;
                    wr_en  <= 0;
                end
            end
            
            default: begin  // key_i[127] == 2 이상일 경우 동작 안 함
                busy_o <= 0;
                wr_en  <= 0;
                data_o <= 128'b0;
            end
        endcase
    end



endmodule