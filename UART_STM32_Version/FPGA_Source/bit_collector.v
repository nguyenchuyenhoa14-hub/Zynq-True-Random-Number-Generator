`timescale 1ns/1ps       



module bit_collector (
    input wire clk,
    input wire rst,
    input wire bit_in, //random 1-bit from trng_core

    output reg [31:0] data_out, //32 random_bit
    output reg  data_valid //signal when data out with new word
);
    reg [31:0] shift_reg; //32-bit register
    reg [4:0] bit_counter; //5-bit counter

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg <= 32'h0;
            bit_counter <= 5'h0;
            data_out <= 32'h0;
            data_valid <= 1'b0;
        end
        else begin
            data_valid <= 1'b0; //default

            //shift newbit to reg
            shift_reg <= {shift_reg[30:0], bit_in};

            if (bit_counter == 5'd31) begin //enough 32bit
                bit_counter <= 5'h0;
                data_out <= {shift_reg[30:0], bit_in};
                data_valid <= 1'b1;
            end
            else begin
                bit_counter <= bit_counter + 1;
            end
        end
    end
endmodule

