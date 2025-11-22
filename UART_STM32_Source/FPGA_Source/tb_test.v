`timescale 1ns / 1ps 

module tb_test;
  

    reg clk;
    reg rst;
    reg button;

    wire [31:0] data_out;
    wire full_1;        // Debug: TRNG FIFO Full
    wire full_2;        // Debug: Output FIFO Full
    wire loading_out;   // Debug: CPU Status LED

    top_test uut (
        .clk(clk),
        .rst(rst),
        .button(button), 
        .data_out(data_out),
        .full_1(full_1),
        .full_2(full_2),
        .loading_out(loading_out)
    );

    always #5 clk = ~clk;

    initial begin
        // --- Khởi tạo ---
        clk = 0;
        rst = 1;        
        button = 0;     

        $display("   START SIMULATION   ");

        // --- Reset ---
        #200;
        rst = 0;        // Thả reset, CPU bắt đầu chạy
        $display("[SYSTEM] Time %t: Reset Released. CPU Starting", $time);

        // --- Bật nút (Enable Output) ---
        // Quan trọng: Phải bật nút thì FIFO 2 mới đẩy data ra data_out
        #5000; // Chờ 5us cho ổn định
        button = 1; 
        $display("[SYSTEM] Time %t: Button ON (Enable Output Reading)", $time);

        // --- Chạy ---
        // Thời gian đủ dài để thấy nhiều số
        #200000; 

        $display("   SIMULATION FINISHED    ");
        $finish;
    end


    always @(uut.top_full_fn1.trng_word) begin
        if (uut.top_full_fn1.fifo1_wr_en) begin
             $display("[TRNG CORE] Time %t: Sinh ra so RAW: 0x%h", $time, uut.top_full_fn1.trng_word);
        end
    end

    always @(data_out) begin
        if (!rst && data_out !== 32'h0 && data_out !== 32'hX) begin
             $display(">> [OUTPUT]    Time %t: CPU tra ve so : 0x%h", $time, data_out);
        end
    end

    always @(posedge full_1) $display("[WARNING] Time %t: FIFO 1 (Input) FULL - CPU xu ly cham!", $time);

endmodule
