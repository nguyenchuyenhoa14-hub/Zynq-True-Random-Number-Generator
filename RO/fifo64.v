`timescale 1ns/1ps



module fifo64 #(
    parameter DEPTH = 16
)(
        input wire clk,
        input wire rst,
        input wire wr_en,
        input wire [63:0] din,
        input wire rd_en,
        output reg [31:0] dout,
        output wire full,
        output wire empty
        );
        
        (* ram_style = "block" *)
        reg [63:0] mem [DEPTH-1:0];

        reg [$clog2(DEPTH)-1:0] w_ptr;
        reg [$clog2(DEPTH)-1:0] r_ptr;
        reg [$clog2(DEPTH):0] count; 
        
        assign full = (count == DEPTH);
        assign empty = (count == 0);
    

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            w_ptr <= 0;
            r_ptr <= 0;
            count <= 0;
            dot <= 64'd0;
        end
        else begin
            // Write
            if (wr_en && !full) begin
                mem[w_ptr] <= wr_data;
                w_ptr <= (w_ptr == DEPTH-1) ? 0 : w_ptr + 1; // Wrap around
            end

            // Read 
            if (rd_en && !empty) begin
                rd_data <= mem[r_ptr];
                r_ptr <= (r_ptr == DEPTH-1) ? 0 : r_ptr + 1; // Wrap around
            end

           
            case ({ (wr_en && !full), (rd_en && !empty) })
                2'b10: count <= count + 1; // Chỉ ghi thành công
                2'b01: count <= count - 1; // Chỉ đọc thành công
                // 2'b11: Vừa đọc vừa ghi cùng lúc -> count giữ nguyên
                // 2'b00: Không làm gì -> count giữ nguyên
                default: count <= count;
            endcase
        end
    end
    
        
    endmodule