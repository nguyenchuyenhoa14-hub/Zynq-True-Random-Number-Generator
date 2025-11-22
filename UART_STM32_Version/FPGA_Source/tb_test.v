`timescale 1ns / 1ps 

module tb_test;
  
    // ============================================================
    // 1. Khai báo tín hiệu
    // ============================================================
    reg clk;
    reg rst;
    reg button;

    wire [31:0] data_out;
    wire full_1;        // Debug: TRNG FIFO Full
    wire full_2;        // Debug: Output FIFO Full
    wire loading_out;   // Debug: CPU Status LED

    // ============================================================
    // 2. Kết nối module top_test (Device Under Test)
    // ============================================================
    top_test uut (
        .clk(clk),
        .rst(rst),
        .button(button), 
        .data_out(data_out),
        .full_1(full_1),
        .full_2(full_2),
        .loading_out(loading_out)
    );

    // ============================================================
    // 3. Tạo Clock (100MHz -> Chu kỳ 10ns)
    // ============================================================
    always #5 clk = ~clk;

    // ============================================================
    // 4. Kịch bản mô phỏng
    // ============================================================
    initial begin
        // --- Khởi tạo ---
        clk = 0;
        rst = 1;        
        button = 0;     

        $display("===========================================================");
        $display("   START SIMULATION: TRNG + PicoRV32 System Output Check   ");
        $display("===========================================================");

        // --- Reset ---
        #200;
        rst = 0;        // Thả reset, CPU bắt đầu chạy
        $display("[SYSTEM] Time %t: Reset Released. CPU Starting...", $time);

        // --- Bật nút (Enable Output) ---
        // Quan trọng: Phải bật nút thì FIFO 2 mới đẩy data ra data_out
        #5000; // Chờ 5us cho ổn định
        button = 1; 
        $display("[SYSTEM] Time %t: Button ON (Enable Output Reading)...", $time);

        // --- Chạy ---
        // Thời gian đủ dài để thấy nhiều số
        #200000; 

        $display("===========================================================");
        $display("   SIMULATION FINISHED                                     ");
        $display("===========================================================");
        $finish;
    end

    // ============================================================
    // 5. MONITOR: In số ngẫu nhiên ra màn hình Console
    // ============================================================
    
    // --- IN SỐ TỪ LÕI TRNG (Raw Generated Number) ---
    // Kỹ thuật soi vào bên trong: uut -> top_full_fn1 -> trng_word
    // Giúp bạn thấy số ngay cả khi CPU chưa kịp xử lý
    always @(uut.top_full_fn1.trng_word) begin
        // Chỉ in khi tín hiệu ghi vào FIFO 1 (fifo1_wr_en) tích cực
        if (uut.top_full_fn1.fifo1_wr_en) begin
             $display("[TRNG CORE] Time %t: Sinh ra so RAW: 0x%h", $time, uut.top_full_fn1.trng_word);
        end
    end

    // --- IN SỐ TỪ NGÕ RA CUỐI CÙNG (Final Output) ---
    always @(data_out) begin
        // Chỉ in khi không phải Reset và không phải giá trị rác/0
        if (!rst && data_out !== 32'h0 && data_out !== 32'hX) begin
             $display(">> [OUTPUT]    Time %t: CPU tra ve so : 0x%h", $time, data_out);
        end
    end

    // --- Debug lỗi ---
    always @(posedge full_1) $display("[WARNING] Time %t: FIFO 1 (Input) FULL - CPU xu ly cham!", $time);

endmodule