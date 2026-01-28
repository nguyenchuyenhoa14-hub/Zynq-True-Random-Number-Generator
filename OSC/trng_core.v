`timescale 1ns/1ps  

module trng_core( 
    input wire clk,
    input wire rst,
    input wire enable,

    output wire random_bit
);
    //signal wire OSC and RG
    wire [3:0] osc_jitter;

    //signal controll osc_cell
    wire osc_T;
    wire osc_I1;
    wire osc_I2;
    //use enable signal to initative, T = enable = 0 -> reset, enable =1 -> T = 1
    assign osc_T = enable;
    assign osc_I1 = 1'b1;
    assign osc_I2 = 1'b0;
    
    (* DONT_TOUCH = "TRUE" *)
    osc_cell u_osc_0 (
        .T(osc_T),
        .I1(osc_I1),
        .I2(osc_I2),
        .OSC(osc_jitter[0])
    );

    (* DONT_TOUCH = "TRUE" *)
    osc_cell u_osc_1 (
        .T(osc_T),
        .I1(osc_I1),
        .I2(osc_I2),
        .OSC(osc_jitter[1])
    );

    (* DONT_TOUCH = "TRUE" *)
    osc_cell u_osc_2 (
        .T(osc_T),
        .I1(osc_I1),
        .I2(osc_I2),
        .OSC(osc_jitter[2])
    );

    (* DONT_TOUCH = "TRUE" *)
    osc_cell u_osc_3 (
        .T(osc_T),
        .I1(osc_I1),
        .I2(osc_I2),
        .OSC(osc_jitter[3])
    );
    
    ring_generator u_ring_gen (
        .clk(clk),
        .rst(rst),
        .osc_in(osc_jitter),
        .bit_out(random_bit)
    );
    
endmodule