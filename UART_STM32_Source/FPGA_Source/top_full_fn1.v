`timescale 1ns / 1ps

module top_full_fn1(
    input wire clk,
    input wire rst,
    input wire button,     
    
    output wire [31:0] data_out, // Final output from FIFO 2
    output wire [3:0] data_output, // LED debug 
    output wire full_1,     // Debug: FIFO 1 Full
    output wire full_2,     // Debug: FIFO 2 Full
    output wire loading_out, // Debug: CPU Status

    output wire [31:0] fifo2_wr_data,
    output wire [31:0] trng_word,
    output wire [31:0] fifo1_rd_data,
    output wire [31:0] mem_wdata,
    
    output wire fifo1_full,
    output wire fifo1_empty,
    output wire fifo1_rd_en,
    output wire fifo2_full,
    output wire fifo2_empty,
    output wire fifo2_wr_en,
    output wire fifo1_wr_en,
    output wire [31:0] mem_addr, 
    output wire [31:0] mem_rdata
    );
    

    wire trng_valid;
    wire enable_trng = 1'b1; //enable to genẻate number

    top_trng u_trng_inst (
        .clk(clk),
        .rst(rst),
        .enable(enable_trng),
        .data_out(trng_word),   // Output 32-bit Random
        .data_valid(trng_valid) // Valid Pulse
    );

    assign fifo1_wr_en = trng_valid & ~fifo1_full;
    
    fifo32 #(.DEPTH(16)) fifo_in (
        .clk(clk),
        .rst(rst),
        // Write Side (From TRNG)
        .wr_en(fifo1_wr_en),
        .wr_data(trng_word),
        .full(fifo1_full),
        // Read Side (To CPU via RAM_IO)
        .rd_en(fifo1_rd_en),
        .rd_data(fifo1_rd_data),
        .empty(fifo1_empty)
    );

    wire [31:0] fifo2_rd_data_wire;
    reg button_prev;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
        button_prev = 1'b0;
        end else begin
        button_prev = button;
        end
       end
       
      wire button_pressed = button & ~button_prev;
      wire fifo2_rd_en_int = ~fifo2_empty & button_pressed;
        
            

    fifo32 #(.DEPTH(16)) fifo_out (
        .clk(clk),
        .rst(rst),
        // Write Side (From CPU via RAM_IO)
        .wr_en(fifo2_wr_en),
        .wr_data(fifo2_wr_data),
        .full(fifo2_full),
        // Read Side (To External Output)
        .rd_en(fifo2_rd_en_int),
        .rd_data(fifo2_rd_data_wire),
        .empty(fifo2_empty)       
    );
    
    
    reg [31:0] data_out_reg;
    always @(posedge rst or posedge clk) begin
        if (rst) begin
        data_out_reg <= 32'd0;
        end 
        else if (fifo2_rd_en_int) begin
            data_out_reg <= fifo2_rd_data_wire;
        end
    end
    assign data_out = data_out_reg;
    assign data_output = data_out[3:0]; // Debug LEDs

    wire mem_valid_cpu, mem_ready_cpu;
    wire [3:0] mem_wstrb_cpu;
    wire [31:0] mem_addr_cpu, mem_wdata_cpu, mem_rdata_cpu;

    assign mem_addr = mem_addr_cpu;
    assign mem_rdata = mem_rdata_cpu;
    assign mem_wdata = mem_wdata_cpu;

    simple_ram_with_io u_ram_io (
        .clk(clk), 
        .rst(rst),
        
        // CPU Interface
        .mem_valid(mem_valid_cpu),
        .mem_wstrb(mem_wstrb_cpu),
        .mem_addr(mem_addr_cpu),
        .mem_wdata(mem_wdata_cpu),
        .mem_rdata(mem_rdata_cpu),
        .mem_ready(mem_ready_cpu),

        // FIFO 1 Interface (Read side)
        .fifo1_rd_data(fifo1_rd_data),
        .fifo1_empty(fifo1_empty),
        .fifo1_full(fifo1_full),
        .fifo1_rd_en(fifo1_rd_en),

        // FIFO 2 Interface (Write side)
        .fifo2_wr_data(fifo2_wr_data),
        .fifo2_full(fifo2_full),
        .fifo2_empty(fifo2_empty),
        .fifo2_wr_en(fifo2_wr_en),

        // Status Outputs
        .loading_out(loading_out)
    );

    assign full_1 = fifo1_full;
    assign full_2 = fifo2_full;

    picorv32 #(
        .PROGADDR_RESET(32'h0000_0000),
        .STACKADDR(32'h0000_2000), 
        .ENABLE_MUL(0),
        .ENABLE_DIV(0),
        .ENABLE_IRQ(0),
        .ENABLE_IRQ_QREGS(0)
    ) uv_cpu (
        .clk       (clk),
        .resetn    (~rst),
        .mem_valid (mem_valid_cpu),
        .mem_ready (mem_ready_cpu),
        .mem_addr  (mem_addr_cpu),
        .mem_wdata (mem_wdata_cpu),
        .mem_wstrb (mem_wstrb_cpu),
        .mem_rdata (mem_rdata_cpu),
        .trap      (),
        .mem_instr ()
    );
    
endmodule
