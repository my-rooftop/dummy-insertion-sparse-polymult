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


    reg wr_en;
    reg [LOGW-1:0] loc_in;
    reg [LOG_WEIGHT-1:0] loc_addr;
    wire [LOGW-1:0] loc_out;

    mem_single #(.WIDTH(LOGW), .DEPTH(WEIGHT)) POSITION_RAM
    (
        .clock(clk),
        .data(loc_in),
        .address(loc_addr),
        .wr_en(wr_en),
        .q(loc_out)
    );



    // Handling load_i signal
    always @(posedge clk) begin
        if (load_i) begin
            loc_addr <= key_i[LOG_WEIGHT-1:0]; // Extract address bits
            loc_in <= data_i[LOGW-1:0]; // Store data
            wr_en <= 1;
            data_o <= 16'b0000000011111111;
            busy_o <= 1;
        end else begin
            wr_en <= 0;
            data_o <= 16'b1111111100000000;
            busy_o <= 0;
        end
    end


endmodule
