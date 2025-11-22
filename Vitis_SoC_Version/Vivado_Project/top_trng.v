    `timescale 1ns/1ps  
    
    
    module top_trng (
        input wire clk, //system clock
        input wire rst, //system reset
        input wire enable, //turn on/off trng
    
        output wire [31:0] data_out, //from 32 random bit
        output wire data_valid //signal when data_out have new word
    );
    
        wire random_bit_stream; //random stream 1-bit
    
        trng_core u_core ( //enable = 1 -> entropy + mix
            .clk(clk),
            .rst(rst),
            .enable(enable),
            .random_bit(random_bit_stream)
        );
    
        bit_collector u_collector ( //received stream & wrap it
            .clk(clk),
            .rst(rst),
            .bit_in(random_bit_stream),
    
            .data_out(data_out),
            .data_valid(data_valid)
        );
    
    endmodule
