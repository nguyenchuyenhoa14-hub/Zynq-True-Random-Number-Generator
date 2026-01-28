`timescale 1ns/1ps



module bit_collector (
    input wire clk,
    input wire rst,
    input wire bit_in,
    input wire bit_valid,

    output reg [63:0] data_out,
    output reg data_valid
);

    reg [63:0] shift_reg;
    reg [5:0] bit_counter; //0->63

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg <= 64'h0;
            bit_counter <= 6'h0;
            data_out <= 64'h0;
            data-bit_valid <= 1'b0;
        end else begin
            data_valid <= 1'b0;

            if (bit_valid) begin
                shift_reg <= {shift_reg[62:0], bit_in};

                if (bit_counter == 6'd63) begin
                    bit_counter <= 6'h0;

                    data_out <= {shift_reg[62:0], bit_in};
                    data_valid <= 1'b1;
                end
                else begin
                    bit_counter <= bit_counter +1;
                end
            end
        end
    end

endmodule