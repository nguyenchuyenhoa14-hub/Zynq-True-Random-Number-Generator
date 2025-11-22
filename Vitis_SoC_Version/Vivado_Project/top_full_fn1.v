module top_full_fn1(
    input wire clk,
    input wire rst,          // Active HIGH reset (phù hợp với GPIO Zynq)
    input wire read_req,     // SỬA: Tín hiệu đọc từ Zynq (thay cho button)
    input wire enable_trng,  // SỬA: Tín hiệu enable từ Zynq (thay cho button treo cứng)
    
    // Output data to Zynq
    output wire [31:0] data_out, 
    output wire data_valid,  // Báo cho Zynq biết data ở data_out là hợp lệ
    
    // Debug LEDs (vẫn giữ để nhìn trên board)
    output wire [3:0] led_debug,
    output wire fifo_empty_flag // Báo cho Zynq biết có dữ liệu để đọc không
    );

    // --- 1. TRNG Core ---
    wire [31:0] trng_word;
    wire trng_valid;
    
    top_trng u_trng_inst (
        .clk(clk),
        .rst(rst),
        .enable(enable_trng), 
        .data_out(trng_word),   
        .data_valid(trng_valid) 
    );

    // --- 2. FIFO 1 (TRNG -> CPU) ---
    wire fifo1_full, fifo1_empty, fifo1_rd_en, fifo1_wr_en;
    wire [31:0] fifo1_rd_data;

    assign fifo1_wr_en = trng_valid & ~fifo1_full;

    fifo32 #(.DEPTH(16)) fifo_in (
        .clk(clk), .rst(rst),
        .wr_en(fifo1_wr_en), .wr_data(trng_word), .full(fifo1_full),
        .rd_en(fifo1_rd_en), .rd_data(fifo1_rd_data), .empty(fifo1_empty)
    );

    // --- 3. FIFO 2 (CPU -> Zynq Output) ---
    wire fifo2_full, fifo2_empty, fifo2_wr_en;
    wire [31:0] fifo2_wr_data;
    wire [31:0] fifo2_rd_data_internal;

    // Logic đọc mới: Khi Zynq gửi tín hiệu read_req VÀ FIFO không rỗng
    reg read_req_d;
    always @(posedge clk) begin
        if (rst) read_req_d <= 0;
        else     read_req_d <= read_req;
    end
    
    wire fifo2_rd_en = read_req & ~read_req_d;

    fifo32 #(.DEPTH(16)) fifo_out (
        .clk(clk), .rst(rst),
        .wr_en(fifo2_wr_en), .wr_data(fifo2_wr_data), .full(fifo2_full),
        .rd_en(fifo2_rd_en), .rd_data(fifo2_rd_data_internal), .empty(fifo2_empty)
    );
    
    // Giữ data ở output để Zynq kịp đọc
    reg [31:0] data_out_reg;
    reg data_valid_reg;
    
    always @(posedge clk) begin
        if (rst) begin
            data_out_reg <= 0;
            data_valid_reg <= 0;
        end else begin
            data_valid_reg <= fifo2_rd_en; // Valid pulse 1 chu kỳ sau lệnh đọc
            if (fifo2_rd_en)
                data_out_reg <= fifo2_rd_data_internal;
        end
    end

    assign data_out = data_out_reg;
    assign data_valid = data_valid_reg;
    assign fifo_empty_flag = fifo2_empty;
    assign led_debug = data_out[3:0]; // Debug LED

    // --- 4. RAM & CPU ---
    // (Giữ nguyên phần kết nối Simple RAM và PicoRV32 như cũ)
    wire mem_valid_cpu, mem_ready_cpu;
    wire [3:0] mem_wstrb_cpu;
    wire [31:0] mem_addr_cpu, mem_wdata_cpu, mem_rdata_cpu;
    wire loading_out_dummy;

    simple_ram_with_io u_ram_io (
        .clk(clk), .rst(rst),
        .mem_valid(mem_valid_cpu), .mem_wstrb(mem_wstrb_cpu), .mem_addr(mem_addr_cpu),
        .mem_wdata(mem_wdata_cpu), .mem_rdata(mem_rdata_cpu), .mem_ready(mem_ready_cpu),
        
        .fifo1_rd_data(fifo1_rd_data), .fifo1_empty(fifo1_empty), .fifo1_full(fifo1_full), .fifo1_rd_en(fifo1_rd_en),
        .fifo2_wr_data(fifo2_wr_data), .fifo2_full(fifo2_full), .fifo2_empty(fifo2_empty), .fifo2_wr_en(fifo2_wr_en),
        .loading_out(loading_out_dummy)
    );

    picorv32 #(
        .PROGADDR_RESET(32'h0000_0000),
        .STACKADDR(32'h0000_2000),
        .ENABLE_MUL(0), .ENABLE_DIV(0), .ENABLE_IRQ(0), .ENABLE_IRQ_QREGS(0)
    ) uv_cpu (
        .clk(clk), .resetn(~rst), // Reset active LOW cho PicoRV32
        .mem_valid(mem_valid_cpu), .mem_ready(mem_ready_cpu), .mem_addr(mem_addr_cpu),
        .mem_wdata(mem_wdata_cpu), .mem_wstrb(mem_wstrb_cpu), .mem_rdata(mem_rdata_cpu),
        .trap(), .mem_instr()
    );
endmodule