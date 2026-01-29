`timescale 1ns/1ps


module trng_core (
    input wire clk,
    input wire rst,
    input wire enable,

    output wire random_bit
);

    wire [63:0] ro_out;

    genvar i;
        generate
            for(i = 0; i < 64; i=i+1) begin : gen_ro
                ro_cell #(
                    .STAGES(3)
                ) u_ro (
                    .en(enable),
                    .osc_out(ro_out[i])
                );
            end
        endgenerate
    
    ring_generator u_mixer (
        .clk(clk),
        .rst(rst),
        .osc_in(ro_out),
        .bit_out(random_bit)
    );
    endmodule
