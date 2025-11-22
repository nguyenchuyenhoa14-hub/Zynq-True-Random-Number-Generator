`timescale  1ns/1ps


(* KEEP_HIERARCHY = "TRUE" *)
module osc_cell(
    //T = 0, I1 = 0, I2 = 0 =>  RST
    //T = 0, I1 = 1, I2 =0 =>  OSC
    //I1 = 1 -> start

    input wire T, //Trigger alow osc
    input wire I1, //Input 1 allow osc
    input wire I2, //Input 2 allow osc

    output wire OSC //Oscillator output
);
    //internal wire
    //prevent synthesys tool break loop
    (* KEEP = "TRUE", DONT_TOUCH = "TRUE" *) reg and1, and2, xor1, xor2;
    
    initial begin
    and1 =0;
    and2 =0;
    xor1=0;
    xor2=0;
    end
    always @(*) begin
    (* KEEP = "TRUE", DONT_TOUCH = "TRUE" *) #1 xor1 = and2 ^ I1; 
    (* KEEP = "TRUE", DONT_TOUCH = "TRUE" *) #1 and1 = T & xor1;
    (* KEEP = "TRUE", DONT_TOUCH = "TRUE" *) #1 xor2 = and1 ^ I2;
    (* KEEP = "TRUE", DONT_TOUCH = "TRUE" *) #1 and2 = xor2 & T; 
    end
    (* KEEP = "TRUE", DONT_TOUCH = "TRUE" *)assign OSC = and2;
endmodule