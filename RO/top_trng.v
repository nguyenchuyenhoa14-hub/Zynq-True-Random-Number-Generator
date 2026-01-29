`timescale 1ns/1ps  


module top_trng (
    input wire clk,
    input wire rst,
    input wire enable,

    output wire [63:0] data_out,
    output wire data_valid
);

    wire raw_bit;

    trng_core u_core (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .random_bit(raw_bit)
    );

    bit_collector u_collect (
        .clk(clk),
        .rst(rst),
        .bit_in(raw_bit),
        .bit_valid(1'b1),
        .data_out(data_out),
        .data_valid(data_valid)
    );

endmodule