`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.01.2026 16:39:33
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
    // System signals
    input wire clk,              // 125 MHz system clock từ PS
    input wire rst_btn,          // Reset button (active high)
       // ✅ THÊM: Von Neumann enable switch (SW0)
    
    // AXI GPIO Interface - Data to PS
    output wire [31:0] trng_to_ps_data,  // Random data output
    output wire trng_fifo_empty,         // FIFO empty status
    
    // AXI GPIO Interface - Control from PS  
    input wire ps_rd_en                  // Read enable from PS
    
    // Optional debug outputs (uncomment if needed)
    // output wire [3:0] led_debug
);

    //==========================================================================
    // Internal Signals
    //==========================================================================
    
    // TRNG enable - always ON in this design
    // Nếu muốn control từ software, đổi thành input port
    wire enable_sw;
    assign enable_sw = 1'b1;
    
    wire enable_von_sw;
    assign enable_von_sw = 1'b1;
    
    // TRNG outputs
    wire [31:0] trng_data;       // 32-bit random word từ TRNG
    wire trng_valid;             // Valid signal khi có word mới
    
    // FIFO status
    wire fifo_full;              // FIFO full flag (internal)
    
    //==========================================================================
    // Module 1: TRNG Core với Von Neumann Corrector
    //==========================================================================
    
    top_trng u_trng (
        .clk(clk),
        .rst(rst_btn),
        .enable(enable_sw),
        .enable_von(enable_von_sw),  // ✅ CONNECT: Von Neumann control
        .data_out(trng_data),         // 32-bit random data
        .data_valid(trng_valid)       // Valid when new data ready
    );

    //==========================================================================
    // Module 2: FIFO Buffer (1024 words = 4KB)
    //==========================================================================
    // 
    // Purpose: Decouple TRNG từ PS read timing
    // - TRNG writes continuously when data_valid = 1
    // - PS reads on demand via ps_rd_en
    //
    // Depth: 1024 words × 32 bits = 4KB
    // - Raw mode: Fills in ~6.4 ms
    // - Von Neumann: Fills in ~26 ms
    //
    //==========================================================================
    
    fifo32 #(
        .DEPTH(1024)             // 1024 words = 4KB buffer
    ) u_fifo (
        .clk(clk),
        .rst(rst_btn),
        
        // Write interface (TRNG side)
        .wr_en(trng_valid),      // Write when TRNG has new data
        .wr_data(trng_data),     // 32-bit random word
        
        // Read interface (PS side)
        .rd_en(ps_rd_en),        // Read when PS requests
        .rd_data(trng_to_ps_data), // Output to AXI GPIO
        
        // Status
        .full(fifo_full),        // Internal (not used)
        .empty(trng_fifo_empty)  // To PS: 1 = no data available
    );


endmodule
