`timescale 1ns / 1ps

//==============================================================================
// VON NEUMANN CORRECTOR - Chi tiết và đầy đủ
//==============================================================================
// 
// Nguyên lý hoạt động:
// - Đọc 2 bits liên tiếp từ TRNG
// - Nếu 01 → output 0
// - Nếu 10 → output 1
// - Nếu 00 hoặc 11 → loại bỏ (không output)
//
// Ưu điểm:
// - Loại bỏ bias (nếu P(0) ≠ P(1))
// - Tăng entropy per bit
// - Đơn giản, không cần bộ nhớ
//
// Nhược điểm:
// - Giảm throughput ~75% (trung bình 1 bit output / 4 bits input)
// - Nếu input đã tốt, có thể không cần thiết
//

module vonneumann (
    input wire clk,
    input wire rst,
    input wire bit_in, //random bit from TRNG
    input wire bit_in_valid, //valid signal for bit_in

    output reg bit_out, //correct bit
    output reg bit_out_valid 
);

    localparam IDLE = 2'b00;
    localparam GOT_FIRST_BIT = 2'b01;

    reg [1:0] state;
    reg first_bit;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            first_bit <= 1'b0;
            bit_out <= 1'b0;
            bit_out_valid <= 1'b0;
        end
        else begin
            bit_out_valid <= 1'b0;  // Default: không có output
            
            if (bit_in_valid) begin
                case (state)
                    IDLE: begin
                        // Nhận bit đầu tiên của cặp
                        first_bit <= bit_in;
                        state <= GOT_FIRST_BIT;
                    end
                    
                    GOT_FIRST_BIT: begin
                        // Nhận bit thứ hai và quyết định output
                        if (first_bit == 1'b0 && bit_in == 1'b1) begin
                            // 01 → output 0
                            bit_out <= 1'b0;
                            bit_out_valid <= 1'b1;
                        end
                        else if (first_bit == 1'b1 && bit_in == 1'b0) begin
                            // 10 → output 1
                            bit_out <= 1'b1;
                            bit_out_valid <= 1'b1;
                        end
                        // else: 00 hoặc 11 → không output, loại bỏ
                        
                        state <= IDLE;  // Quay lại đợi cặp tiếp theo
                    end
                    
                    default: state <= IDLE;
                endcase
            end
        end
    end

endmodule