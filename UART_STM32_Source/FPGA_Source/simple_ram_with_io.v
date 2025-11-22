`timescale 1ns / 1ps

module simple_ram_with_io (
    input wire clk,
    input wire rst,
    
    input wire        mem_valid,
    input wire [3:0]  mem_wstrb,
    input wire [31:0] mem_addr,
    input wire [31:0] mem_wdata,
    output reg [31:0] mem_rdata,
    output reg        mem_ready,
    
    input wire [31:0] fifo1_rd_data, 
    input wire        fifo1_empty,   
    input wire        fifo1_full,   
    output reg        fifo1_rd_en,  
    
    output reg [31:0] fifo2_wr_data, 
    input wire        fifo2_full,    
    input wire        fifo2_empty,   
    output reg        fifo2_wr_en,   
    
    output reg        loading_out
);

    (* ram_style = "block" *) reg [31:0] mem_arr [0:2047];

    integer i;
    initial begin
        for (i=0; i<2048; i=i+1) mem_arr[i] = 32'h0000_0013;
        
         $readmemh("C:/Users/Admin/Downloads/sw_project1_2/prog_mem.hex", mem_arr); 
    end

    always @(posedge clk) begin
        if (rst) begin
            mem_ready     <= 0;
            mem_rdata     <= 0;
            fifo1_rd_en   <= 0;
            fifo2_wr_en   <= 0;
            fifo2_wr_data <= 0;
            loading_out   <= 0;
        end else begin
            mem_ready     <= 0;
            fifo1_rd_en   <= 0;
            fifo2_wr_en   <= 0;
            fifo2_wr_data <= 0;

            if (mem_valid && !mem_ready) begin
                mem_ready <= 1; 
                
                if (mem_addr < 32'h0000_2000) begin
                    if (|mem_wstrb) begin 
                        if (mem_wstrb[0]) mem_arr[mem_addr[12:2]][ 7: 0] <= mem_wdata[ 7: 0];
                        if (mem_wstrb[1]) mem_arr[mem_addr[12:2]][15: 8] <= mem_wdata[15: 8];
                        if (mem_wstrb[2]) mem_arr[mem_addr[12:2]][23:16] <= mem_wdata[23:16];
                        if (mem_wstrb[3]) mem_arr[mem_addr[12:2]][31:24] <= mem_wdata[31:24];
                    end
                    mem_rdata <= mem_arr[mem_addr[12:2]];
                end 
                
                else if (mem_addr == 32'h3000_0000) begin
                     mem_rdata <= {29'b0, fifo2_full, fifo1_empty, fifo1_full};
                end 
                
                else if (mem_addr == 32'h3000_0004) begin
                    mem_rdata   <= fifo1_rd_data; 
                    fifo1_rd_en <= 1'b1;          
                end
                
                else if (mem_addr == 32'h3000_0008) begin
                     if (|mem_wstrb) begin
                        fifo2_wr_en   <= 1'b1;
                        fifo2_wr_data <= mem_wdata;
                    end
                    mem_rdata <= {31'b0, fifo2_full}; 
                end
                
                else if (mem_addr == 32'h3000_0010) begin
                    if (|mem_wstrb) begin
                        if (mem_wdata[0]) loading_out <= 1'b1; // Set status
                        if (mem_wdata[1]) loading_out <= 1'b0; // Clear status
                    end
                    mem_rdata <= {31'b0, loading_out};
                end
                
                else begin
                    mem_rdata <= 32'hDEAD_BEEF; 
                end
            end
        end
    end

endmodule
