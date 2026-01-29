`timescale 1ns/1ps


module ring_generator(
    input wire clk,
    input wire rst,
    input wire [63:0] osc_in,
    output wire bit_out
);

    reg [63:0] q_reg;
    wire [63:0] q_next;
    wire feedback_bit;

    assign feedback_bit = q_reg[63] ^ q_reg[62] ^ q_reg[60] ^ q_reg[59];
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            q_reg <= 64'hACE1_2468_BACE_1357; //init random
        end else begin
            q_reg <= q_next;
        end
    end

    genvar i;
    generate 
        for (i = 0; i < 64; i =i + 1) begin : gen_mix
            if (i == 0)
                assign q_next[0] = feedback_bit ^ osc_in[0];
            else 
                assign q_next[i] = q_reg[i-1] ^ osc_in[i];
        end
    endgenerate

    assign bit_out = q_reg[63];
endmodule