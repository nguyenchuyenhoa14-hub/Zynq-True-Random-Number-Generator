`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.11.2025 14:42:30
// Design Name: 
// Module Name: top_uart
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top_uart(
    input wire sys_clk,     
    input wire [1:0] btns,   
    output wire uart_txd,    
    output wire [3:0] led_debug
    );

    wire clk = sys_clk;
    wire rst_clean;
    debounce #(.CLK_FREQ(125000000), .STABLE_MS(10)) u_db_rst (
        .clk(clk), .rst(1'b0), 
        .btn_in(btns[1]), 
        .btn_out(rst_clean)
    );
    wire rst = rst_clean;
    //wire rst = btns[1];    

    wire [31:0] cpu_data_out;  
    wire fifo2_empty;         
    reg  read_trigger;         

    wire [31:0] dummy_wdata, dummy_addr, dummy_rdata;
    wire [31:0] dummy_trng_word, dummy_fifo1_rd, dummy_fifo2_wr;
    wire dummy_f1_full, dummy_f1_empty, dummy_f1_rd, dummy_f2_full, dummy_f2_wr, dummy_f1_wr;
    wire dummy_load;
    wire [3:0] dummy_led;
    
    wire btn0_clean;
    
    debounce #(.CLK_FREQ(125000000), .STABLE_MS(10)) u_db(
        .clk(clk),
        .rst(rst),
        .btn_in(btns[0]),
        .btn_out(btn0_clean)
    );
    
    reg btn0_d;
    always @(posedge clk) btn0_d <= btn0_clean;
    
    wire btn_press = btn0_clean & ~btn0_d;
    top_full_fn1 u_system (
        .clk(clk),
        .rst(rst),
        .button(read_trigger), 
        
        .data_out(cpu_data_out), 
        .fifo2_empty(fifo2_empty), 

        .data_output(dummy_led), .full_1(dummy_f1_full), .full_2(dummy_f2_full), .loading_out(dummy_load),
        .fifo2_wr_data(dummy_fifo2_wr), .trng_word(dummy_trng_word), .fifo1_rd_data(dummy_fifo1_rd),
        .mem_wdata(dummy_wdata), .fifo1_full(dummy_f1_full), .fifo1_empty(dummy_f1_empty),
        .fifo1_rd_en(dummy_f1_rd), .fifo2_full(dummy_f2_full), .fifo2_wr_en(dummy_f2_wr),
        .fifo1_wr_en(dummy_f1_wr), .mem_addr(dummy_addr), .mem_rdata(dummy_rdata)
    );

    reg tx_start;
    reg [7:0] tx_byte;
    wire tx_busy;

    uart_tx #(.CLK_FREQ(125000000), .BAUD_RATE(115200)) u_uart (
        .clk(clk), .rst(rst),
        .tx_start(tx_start), .tx_data(tx_byte),
        .tx_busy(tx_busy), .tx_pin(uart_txd)
    );

    localparam S_IDLE = 0, S_TRIGGER = 1, S_WAIT_DATA = 2, 
               S_CONVERT = 3, S_SEND = 4, S_WAIT_TX = 5, 
               S_SEND_CR = 6, S_WAIT_CR = 7, S_SEND_LF = 8, S_WAIT_LF = 9;
               
    reg [3:0] state = S_IDLE;
    reg [31:0] captured_data;
    reg [3:0] nibble_idx;
    reg [3:0] nibble_val;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            read_trigger <= 0;
            tx_start <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    if (btn_press && !fifo2_empty) begin
                        read_trigger <= 1; 
                        state <= S_TRIGGER;
                    end
                end

                S_TRIGGER: begin
                    read_trigger <= 0; 
                    state <= S_WAIT_DATA; 
                end

                S_WAIT_DATA: begin
                    captured_data <= cpu_data_out; 
                    nibble_idx <= 7; 
                    state <= S_CONVERT;
                end

                S_CONVERT: begin
                    nibble_val = (captured_data >> (nibble_idx * 4)) & 4'hF;
                  
                    if (nibble_val < 10) tx_byte <= nibble_val + "0";
                    else tx_byte <= nibble_val - 10 + "A";
                    
                    tx_start <= 1;
                    state <= S_SEND;
                end

                S_SEND: begin
                    tx_start <= 0;
                    state <= S_WAIT_TX;
                end

                S_WAIT_TX: begin
                    if (!tx_busy) begin
                        if (nibble_idx > 0) begin
                            nibble_idx <= nibble_idx - 1;
                            state <= S_CONVERT;
                        end else begin
                            state <= S_SEND_CR; 
                        end
                    end
                end
                S_SEND_CR: begin tx_byte <= 8'h0D; tx_start <= 1; state <= S_WAIT_CR; end
                S_WAIT_CR: begin tx_start <= 0; if (!tx_busy) state <= S_SEND_LF; end
                S_SEND_LF: begin tx_byte <= 8'h0A; tx_start <= 1; state <= S_WAIT_LF; end
                S_WAIT_LF: begin tx_start <= 0; if (!tx_busy) state <= S_IDLE; end

            endcase
        end
    end

    assign led_debug = {~fifo2_empty, tx_busy, state[1:0]};

endmodule
