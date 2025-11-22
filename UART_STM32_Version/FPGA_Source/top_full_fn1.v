`timescale 1ns / 1ps

module top_full_fn1(
    input wire clk,
    input wire rst,
    input wire button,      // Nút nhấn Enable TRNG
    
    // Output ra ngoài (cho LED hoặc Logic Analyzer)
    output wire [31:0] data_out, // Final output from FIFO 2
    output wire [3:0] data_output, // LED debug (4 bit cuối)
    output wire full_1,     // Debug: FIFO 1 Full
    output wire full_2,     // Debug: FIFO 2 Full
    output wire loading_out, // Debug: CPU Status

    // Các tín hiệu Debug nội bộ (đưa ra port để quan sát waveform dễ hơn)
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
    
    //------------------------------------------------------------------
    // 1. TRNG CORE (Sinh số ngẫu nhiên)
    //------------------------------------------------------------------
    wire trng_valid;
    // Nút nhấn dùng để enable module sinh số
    wire enable_trng = 1'b1; 

    top_trng u_trng_inst (
        .clk(clk),
        .rst(rst),
        .enable(enable_trng),
        .data_out(trng_word),   // Output 32-bit Random
        .data_valid(trng_valid) // Valid Pulse
    );

    //------------------------------------------------------------------
    // 2. FIFO 1 (Input Buffer: TRNG -> CPU)
    //------------------------------------------------------------------
    // Chỉ ghi vào FIFO khi TRNG có dữ liệu mới VÀ FIFO chưa đầy
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
        .rd_data(fifo1_rd_data), // Sử dụng fifo32.v mới (dạng wire output)
        .empty(fifo1_empty)
    );

    //------------------------------------------------------------------
    // 3. FIFO 2 (Output Buffer: CPU -> External Output)
    //------------------------------------------------------------------
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

    //------------------------------------------------------------------
    // 4. RAM & I/O CONTROLLER
    //------------------------------------------------------------------
    wire mem_valid_cpu, mem_ready_cpu;
    wire [3:0] mem_wstrb_cpu;
    wire [31:0] mem_addr_cpu, mem_wdata_cpu, mem_rdata_cpu;

    // Gán ra output debug module
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

    // Gán tín hiệu debug FIFO ra ngoài module
    assign full_1 = fifo1_full;
    assign full_2 = fifo2_full;

    //------------------------------------------------------------------
    // 5. PicoRV32 CPU
    //------------------------------------------------------------------
    picorv32 #(
        .PROGADDR_RESET(32'h0000_0000),
        .STACKADDR(32'h0000_2000), // 8KB RAM end address
        .ENABLE_MUL(0),
        .ENABLE_DIV(0),
        .ENABLE_IRQ(0),
        .ENABLE_IRQ_QREGS(0)
    ) uv_cpu (
        .clk       (clk),
        .resetn    (~rst), // Active Low Reset
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