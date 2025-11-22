    `timescale 1ns / 1ps 
   
    module fifo32 #(
        parameter DEPTH = 4
        )(
        input wire clk,
        input wire rst,
        input wire wr_en,
        input wire [31:0] wr_data,
        input wire rd_en,
        output wire [31:0] rd_data,
        output wire full,
        output wire empty
        );
        reg [31:0] mem [DEPTH-1:0];
        reg [$clog2(DEPTH)-1:0] w_ptr;
        reg [$clog2(DEPTH)-1:0] r_ptr;
        reg [$clog2(DEPTH):0] count; 
        
        assign full = (count == DEPTH);
        assign empty = (count == 0);
    
assign rd_data = mem[r_ptr]; 

    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            mem[i] = 32'd0;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            w_ptr <= 0;
            r_ptr <= 0;
            count <= 0;
        end
        else begin
            // Write
            if (wr_en && !full) begin
                mem[w_ptr] <= wr_data;
                w_ptr <= (w_ptr == DEPTH-1) ? 0 : w_ptr + 1; // Wrap around
            end

            // Read (Chỉ cần tăng con trỏ)
            if (rd_en && !empty) begin
                r_ptr <= (r_ptr == DEPTH-1) ? 0 : r_ptr + 1; // Wrap around
            end

            // Count
            if (wr_en && !full && !rd_en) begin
                count <= count + 1;
            end
            else if (!wr_en && rd_en && !empty) begin
                count <= count - 1;
            end
        end
    end
    
        
    endmodule
    
