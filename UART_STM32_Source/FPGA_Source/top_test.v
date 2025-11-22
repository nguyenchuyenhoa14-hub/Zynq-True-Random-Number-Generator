`timescale 1ns / 1ps

module top_test(
    input wire clk,
    input wire rst,
    input wire button,
    
    output wire [31:0] data_out,
    output wire full_1,
    output wire full_2,
    output wire loading_out
    );
    
    wire [3:0]  data_output_dummy;
    wire [31:0] fifo2_wr_data;
    wire [31:0] trng_word;
    wire [31:0] fifo1_rd_data;
    wire [31:0] mem_wdata;
    
    wire fifo1_full;
    wire fifo1_empty;
    wire fifo1_rd_en;
    wire fifo2_full;
    wire fifo2_empty;
    wire fifo2_wr_en;
    wire fifo1_wr_en;
    
    wire [31:0] mem_addr;
    wire [31:0] mem_rdata;
    
    // Instance Top System
    top_full_fn1 u_system_inst (
        .clk(clk),
        .rst(rst),
        .button(button),
        
        // Main Outputs
        .data_out(data_out), 
        .data_output(data_output_dummy),
        .full_1(full_1),
        .full_2(full_2),
        .loading_out(loading_out),
        
        // Debug Connections
        .fifo2_wr_data(fifo2_wr_data),
        .trng_word(trng_word),
        .fifo1_rd_data(fifo1_rd_data),
        .mem_wdata(mem_wdata),
        
        .fifo1_full(fifo1_full),
        .fifo1_empty(fifo1_empty),
        .fifo1_rd_en(fifo1_rd_en),
        .fifo2_full(fifo2_full),
        .fifo2_empty(fifo2_empty),
        .fifo2_wr_en(fifo2_wr_en),
        .fifo1_wr_en(fifo1_wr_en),
    
        .mem_addr(mem_addr), 
        .mem_rdata(mem_rdata)
    );

endmodule
