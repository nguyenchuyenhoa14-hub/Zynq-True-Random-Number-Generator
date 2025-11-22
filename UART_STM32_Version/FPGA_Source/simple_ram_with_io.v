`timescale 1ns / 1ps

module simple_ram_with_io (
    input wire clk,
    input wire rst,
    
    // --- Giao diện bộ nhớ PicoRV32 ---
    input wire        mem_valid,
    input wire [3:0]  mem_wstrb,
    input wire [31:0] mem_addr,
    input wire [31:0] mem_wdata,
    output reg [31:0] mem_rdata,
    output reg        mem_ready,
    
    // --- Giao diện FIFO 1 (Input từ TRNG vào CPU) ---
    input wire [31:0] fifo1_rd_data, // Dữ liệu đọc từ FIFO
    input wire        fifo1_empty,   // Trạng thái rỗng
    input wire        fifo1_full,    // Trạng thái đầy
    output reg        fifo1_rd_en,   // Lệnh đọc (pop)
    
    // --- Giao diện FIFO 2 (Output từ CPU ra ngoài) ---
    output reg [31:0] fifo2_wr_data, // Dữ liệu ghi vào FIFO
    input wire        fifo2_full,    // Trạng thái đầy
    input wire        fifo2_empty,   // Trạng thái rỗng (để CPU biết)
    output reg        fifo2_wr_en,   // Lệnh ghi (push)
    
    // --- Tín hiệu điều khiển/Trạng thái ---
    output reg        loading_out
);

    // Khai báo bộ nhớ RAM 2048 từ (8KB)
    (* ram_style = "block" *) reg [31:0] mem_arr [0:2047];

    integer i;
    initial begin
        // Khởi tạo RAM với lệnh NOP (ADDI x0, x0, 0)
        for (i=0; i<2048; i=i+1) mem_arr[i] = 32'h0000_0013;
        
        // LƯU Ý: Bạn cần trỏ đúng đường dẫn file hex code C của bạn ở đây
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
            // Mặc định reset các tín hiệu điều khiển (Pulse 1 chu kỳ)
            mem_ready     <= 0;
            fifo1_rd_en   <= 0;
            fifo2_wr_en   <= 0;
            fifo2_wr_data <= 0;

            if (mem_valid && !mem_ready) begin
                mem_ready <= 1; // Ack ngay lập tức (RAM đơn giản)
                
                // --- Vùng nhớ RAM (0x0000_0000 -> 0x0000_1FFF) ---
                if (mem_addr < 32'h0000_2000) begin
                    if (|mem_wstrb) begin // Ghi RAM (theo byte enable)
                        if (mem_wstrb[0]) mem_arr[mem_addr[12:2]][ 7: 0] <= mem_wdata[ 7: 0];
                        if (mem_wstrb[1]) mem_arr[mem_addr[12:2]][15: 8] <= mem_wdata[15: 8];
                        if (mem_wstrb[2]) mem_arr[mem_addr[12:2]][23:16] <= mem_wdata[23:16];
                        if (mem_wstrb[3]) mem_arr[mem_addr[12:2]][31:24] <= mem_wdata[31:24];
                    end
                    // Đọc RAM
                    mem_rdata <= mem_arr[mem_addr[12:2]];
                end 
                
                // --- Memory Mapped I/O (MMIO) ---
                
                // 0x3000_0000: STATUS REG (Đọc trạng thái các FIFO)
                else if (mem_addr == 32'h3000_0000) begin
                     // Bit 0: FIFO1 Full, Bit 1: FIFO1 Empty, Bit 2: FIFO2 Full
                     mem_rdata <= {29'b0, fifo2_full, fifo1_empty, fifo1_full};
                end 
                
                // 0x3000_0004: READ TRNG DATA (Đọc từ FIFO 1)
                else if (mem_addr == 32'h3000_0004) begin
                    mem_rdata   <= fifo1_rd_data; // Lấy dữ liệu đầu hàng đợi
                    fifo1_rd_en <= 1'b1;          // Kích hoạt tín hiệu POP
                end
                
                // 0x3000_0008: WRITE OUTPUT DATA (Ghi vào FIFO 2)
                else if (mem_addr == 32'h3000_0008) begin
                     if (|mem_wstrb) begin
                        fifo2_wr_en   <= 1'b1;
                        fifo2_wr_data <= mem_wdata;
                    end
                    mem_rdata <= {31'b0, fifo2_full}; // Trả về trạng thái full nếu lỡ đọc
                end
                
                // 0x3000_0010: CONTROL REG (Điều khiển LED/Status)
                else if (mem_addr == 32'h3000_0010) begin
                    if (|mem_wstrb) begin
                        if (mem_wdata[0]) loading_out <= 1'b1; // Set status
                        if (mem_wdata[1]) loading_out <= 1'b0; // Clear status
                    end
                    mem_rdata <= {31'b0, loading_out};
                end
                
                else begin
                    mem_rdata <= 32'hDEAD_BEEF; // Địa chỉ rác
                end
            end
        end
    end

endmodule