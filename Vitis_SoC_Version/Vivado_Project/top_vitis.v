`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.11.2025 11:40:24
// Design Name: 
// Module Name: top_vitis
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


module top_vitis(
    input wire clk,
    input wire rst,
    input wire [2:0] ctrl_in,
    output wire [3:0] status_out,
    output wire [31:0] data_out,
    input wire [1:0] btn_phys,
    output wire [3:0] led_debug
    );
    wire rst_sw = ctrl_in[0];
    wire enable_sw = ctrl_in[1];
    wire read_req = ctrl_in[2];
    
    wire sys_rst = rst_sw | btn_phys[1] | rst;
    
    wire bit_stream;
    trng_core u_core(
        .clk(clk),
        .rst(sys_rst),
        .enable(enable_sw),
        .random_bit(bit_stream)
    );
    
    wire [31:0] word_raw;
    wire word_valid;
    bit_collector u_bit (
        .clk(clk),
        .rst(sys_rst),
        .bit_in(bit_stream),
        .data_out(word_raw),
        .data_valid(word_valid)
    );
    
    wire fifo_full, fifo_empty;
    wire [31:0] fifo_data;
    wire fifo_wr = word_valid & ~fifo_full;
    
    reg req_d;
    always @(posedge clk) req_d <= read_req;
    wire fifo_rd = (read_req & ~req_d) & ~fifo_empty;

    fifo32 #(.DEPTH(16)) u_fifo (
        .clk(clk), .rst(sys_rst),
        .wr_en(fifo_wr), .wr_data(word_raw), .full(fifo_full),
        .rd_en(fifo_rd), .rd_data(fifo_data), .empty(fifo_empty)
    );
    
    reg [31:0] data_reg;
    reg valid_reg;
    
    always @(posedge clk) begin
        if (sys_rst) begin
            data_reg <= 0;
            valid_reg <= 0;
        end else begin
            if (fifo_rd) begin
                data_reg <= fifo_data;
                valid_reg <= 1;
            end 
            else if (!read_req) begin
                valid_reg <= 0;
            end
        end
    end
    
    assign data_out = data_reg;
    
    assign status_out = {btn_phys[1], btn_phys[0], valid_reg, fifo_empty};
    
    assign led_debug = {sys_rst, btn_phys[0], valid_reg, fifo_empty};
endmodule
