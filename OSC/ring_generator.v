`timescale 1ns/1ps


(* KEEP_HIERARCHY = "TRUE" *)
module ring_generator (
    input wire clk,
    input wire rst,

    input wire [3:0] osc_in,
    output wire bit_out
);
    reg [15:0] q_reg;
    wire [15:0] q_next;
    wire feedback_bit;
    assign feedback_bit = q_reg[15];
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            q_reg <= 16'hACE1;
        end else begin
            q_reg <= q_next;
        end
    end

    assign q_next[0] = feedback_bit;
    assign q_next[1] = q_reg[0] ^ osc_in[0];
    assign q_next[2] = q_reg[1];
    assign q_next[3] = q_reg[2] ^ feedback_bit;

    assign q_next[4] = q_reg[3];

    assign q_next[5] = q_reg[4] ^ feedback_bit;
    assign q_next[6] = q_reg[5] ^ feedback_bit;

    assign q_next[7] = q_reg[6];

    assign q_next[8] = q_reg[7];

    assign q_next[9] = q_reg[8] ^ osc_in[1];

    assign q_next[10] = q_reg[9];

    assign q_next[11] = q_reg[10] ^ osc_in[2];

    assign q_next[12] = q_reg[11];
    
    assign q_next[13] = q_reg[12];

    assign q_next[14] = q_reg[13] ^ osc_in[3];

    assign q_next[15] = q_reg[14];


    assign bit_out = q_reg[15];

endmodule