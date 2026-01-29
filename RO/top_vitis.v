`timescale 1ns/1ps


module top_vitis(
    // System signals
    input wire clk,              // 125 MHz system clock từ PS
    input wire rst,          // Reset button (active high)

    output wire [63:0] trng_to_ps_data,  // Random data output
    output wire fifo_empty,         // FIFO empty status
    
    // AXI GPIO Interface - Control from PS  
    input wire ps_rd_en                  // Read enable from PS
    
);

    wire enable_sw;
    assign enable_sw = 1'b1;
    
    wire clk_50M;
    wire locked;
    wire sys_rst;

    wire raw_random_bit;
    wire [63:0] trng_data;
    wire trng_valid;
    
    assign sys_rst = (~rst) | (~locked);

    clk_wiz_0 u_clock(
        .clk_in1(clk),
        .clk_out1(clk_50M),
        .reset(~rst),
        .locked(locked)
    );

    // FIFO status
    wire fifo_full;              // FIFO full flag (internal)
    
    top_trng u_trng (
        .clk(clk_50M),
        .rst(sys_rst),
        .enable(enable_sw),
        .data_out(trng_data),         // 32-bit random data
        .data_valid(trng_valid)       // Valid when new data ready
    );

    fifo64 #(
        .DEPTH(1024)             // 1024 words = 4KB buffer
    ) u_fifo (
        .clk(clk_50M),
        .rst(sys_rst),
        
        // Write interface (TRNG side)
        .wr_en(trng_valid),      // Write when TRNG has new data
        .din(trng_data),     // 32-bit random word
        
        // Read interface (PS side)
        .rd_en(ps_rd_en),        // Read when PS requests
        .dout(trng_to_ps_data), // Output to AXI GPIO
        
        // Status
        .full(fifo_full),        // Internal (not used)
        .empty(fifo_empty)  // To PS: 1 = no data available
    );


endmodule
