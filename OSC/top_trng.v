    `timescale 1ns/1ps  
    
    
    module top_trng (
    input wire clk,         // System clock
    input wire rst,         // System reset
    input wire enable,      // Turn on/off TRNG
    input wire enable_von,  // Enable Von Neumann corrector

    output wire [31:0] data_out,    // 32 random bits
    output wire data_valid          // Signal when data_out has new word
);

    //==========================================================================
    // STAGE 1: TRNG Core - Generate raw random bits
    //==========================================================================
    wire raw_random_bit;
    
    trng_core u_core (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .random_bit(raw_random_bit)  // Raw output từ ring generator
    );

    //==========================================================================
    // STAGE 2: Von Neumann Corrector (Optional)
    //==========================================================================
    wire corrected_bit;
    wire corrected_valid;
    
    vonneumann u_von (
        .clk(clk),
        .rst(rst),
        .bit_in(raw_random_bit),        // Input: raw bits từ TRNG
        .bit_in_valid(1'b1),             // Raw bits luôn valid
        .bit_out(corrected_bit),         // Output: corrected bits
        .bit_out_valid(corrected_valid)  // Valid chỉ khi có cặp 01 hoặc 10
    );

    //==========================================================================
    // STAGE 3: MUX - Select between raw and corrected bits
    //==========================================================================
    wire selected_bit;
    wire selected_valid;
    
    // Nếu enable_von = 1 → dùng corrected bit
    // Nếu enable_von = 0 → dùng raw bit (bypass Von Neumann)
    assign selected_bit = enable_von ? corrected_bit : raw_random_bit;
    assign selected_valid = enable_von ? corrected_valid : 1'b1;
    
    //==========================================================================
    // STAGE 4: Bit Collector - Collect 32 bits into word
    //==========================================================================
    bit_collector u_collector (
        .clk(clk),
        .rst(rst),
        .bit_in(selected_bit),      // Bit đã chọn (raw hoặc corrected)
        .bit_valid(selected_valid),  // Valid signal tương ứng
        .data_out(data_out),
        .data_valid(data_valid)
    );

endmodule
