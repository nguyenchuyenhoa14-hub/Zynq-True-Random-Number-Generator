`timescale 1ns/1ps

module tb_top_trng();
    reg clk;
    reg rst;
    reg enable;
    wire [63:0] data_out;
    wire data_valid;

    // 1. Gọi module Top [cite: 42-45]
    top_trng uut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .data_out(data_out),
        .data_valid(data_valid)
    );

    // 2. Tạo xung nhịp 50MHz (Chu kỳ 20ns -> 10ns mức cao, 10ns mức thấp)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // 3. Tiến trình mô phỏng
    initial begin
        // Khởi tạo
        rst = 1;
        enable = 0;
        
        // Giải phóng Reset
        #100;
        rst = 0;
        #50;
        enable = 1; // Bắt đầu cho RO dao động [cite: 47]

        // Chạy trong 5000ns để thu được vài mẫu 64-bit
        #5000;
        
        $display("Mo phong ket thuc. Kiem tra file dump.vcd de xem ket qua.");
        $finish;
    end

    // 4. Lệnh xuất file cho GTKWave
    initial begin
        $dumpfile("dump.vcd"); // Tên file xuất ra
        $dumpvars(0, tb_top_trng); // Xuất tất cả các biến trong testbench
    end

endmodule