`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.11.2025 12:15:04
// Design Name: 
// Module Name: debounce
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


module debounce #(
    parameter CLK_FREQ = 125000000,
    parameter STABLE_MS = 10 //stable waiting time 10ms
)(
    input wire clk,
    input wire rst,
    input wire btn_in,
    output reg btn_out
    );
    //calculate clock to wait
    localparam CNT_MAX = (CLK_FREQ / 1000) * STABLE_MS;
    
    reg [31:0] counter;
    reg btn_sync_0, btn_sync_1; //fifo sync
    
    always @(posedge clk) begin
        if(rst) begin
            counter <= 0;
            btn_out <= 0;
            btn_sync_0 <= 0;
            btn_sync_1 <= 0;
        end else begin
        //sync input signal
            btn_sync_0 <= btn_in;
            btn_sync_1 <= btn_sync_0;
        //Chong rung
            if (btn_sync_1 == btn_out) begin
            //if signal state = prev state -> reset count
                counter <= 0;
            end else begin
            // if different, start count
                counter <= counter + 1;
                if (counter == CNT_MAX) begin
                //if stable -> acp new state
                    btn_out <= btn_sync_1;
                    counter <= 0;
                 end
             end
         end
    end
    
endmodule
