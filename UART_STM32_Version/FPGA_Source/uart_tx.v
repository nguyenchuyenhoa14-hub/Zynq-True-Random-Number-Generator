`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.11.2025 13:51:47
// Design Name: 
// Module Name: uart_tx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_tx #(
    parameter CLK_FREQ = 125000000,
    parameter BAUD_RATE = 115200
)(
    input wire clk,
    input wire rst,
    input wire tx_start, //xung kich hoat
    input wire [7:0] tx_data, 
    output reg tx_busy,
    output reg tx_pin //pin with USB uart
    );
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;
    
    reg [1:0] state = IDLE;
    reg [13:0] clk_cnt = 0;
    reg [2:0] bit_idx = 0;
    reg [7:0] data_reg = 0;
    
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            tx_pin <= 1; //IDLE state of tx is high
            tx_busy <= 0;
            clk_cnt <= 0;
            bit_idx <= 0;
         end else begin
            case (state) 
                IDLE: begin
                    tx_pin <= 1;
                    if (tx_start) begin
                        state <= START;
                        tx_busy <= 1;
                        data_reg <= tx_data;
                        clk_cnt <= 0;
                    end else begin
                        tx_busy <= 0;
                    end
                end
                
                START: begin
                    tx_pin <= 0;
                    if (clk_cnt < CLKS_PER_BIT -1)  begin
                        clk_cnt <= clk_cnt + 1;
                    end else begin
                        clk_cnt <= 0;
                        state <= DATA;
                        bit_idx <= 0;
                    end
                end
                
                DATA: begin
                    tx_pin <= data_reg[bit_idx];
                    if (clk_cnt < CLKS_PER_BIT -1) begin
                        clk_cnt <= clk_cnt +1;
                    end
                    else begin
                        clk_cnt <= 0;
                        if (bit_idx < 7)
                            bit_idx <= bit_idx + 1;
                         else state <= STOP;
                        
                    end
                end
                
                STOP: begin
                    tx_pin <= 1;
                    if (clk_cnt < CLKS_PER_BIT - 1) begin
                        clk_cnt <= clk_cnt + 1;
                    end else begin
                        clk_cnt <= 0;
                        state <= IDLE;
                        tx_busy <= 0; //done
                    end
                end
            endcase
        end
    end
 
endmodule
