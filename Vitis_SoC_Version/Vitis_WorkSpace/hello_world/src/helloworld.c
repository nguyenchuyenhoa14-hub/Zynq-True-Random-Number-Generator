/******************************************************************************
* Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "sleep.h"

#define DATA_BASE    XPAR_AXI_GPIO_0_BASEADDR // Random number 32-bit
#define CTRL_BASE    XPAR_AXI_GPIO_1_BASEADDR // Rst, En, Read
#define STATUS_BASE  XPAR_AXI_GPIO_2_BASEADDR

#define GPIO_DATA_REG  0x00  // Thanh ghi dữ liệu
#define GPIO_TRI_REG   0x04

int main()
{
    init_platform();

    print("\033[2J\033[H"); // Delete terminal screen
    print("===========================================\n\r");
    print("   TRNG SYSTEM ON ARTY Z7 - READY   \n\r");
    print("===========================================\n\r");
    print(" > Press BTN0: Generate Random Number\n\r");
    print(" > Press BTN1: Hardware Reset\n\r");
    print("-------------------------------------------\n\r");

    // Write into reg: 1 = Input, 0 = Output
    Xil_Out32(DATA_BASE   + GPIO_TRI_REG, 0xFFFFFFFF); // Data = Input
    Xil_Out32(CTRL_BASE   + GPIO_TRI_REG, 0x00000000); // Control = Output
    Xil_Out32(STATUS_BASE + GPIO_TRI_REG, 0xFFFFFFFF); // Status = Input

    // ENABLE TRNG
    // Control Bits: [0]=RST, [1]=ENABLE, [2]=READ_REQ
    
    print("Initializing TRNG...\n\r");
    Xil_Out32(CTRL_BASE + GPIO_DATA_REG, 0x01); // RST = 1
    usleep(1000);
    Xil_Out32(CTRL_BASE + GPIO_DATA_REG, 0x00); // RST = 0
    Xil_Out32(CTRL_BASE + GPIO_DATA_REG, 0x02); // Enable = 1
    print("Done. Waiting for user input...\n\r");

    // Save btn state to find rising edge
    u32 last_btn0 = 0;
    u32 last_btn1 = 0;

    while(1) {
        // Status Register Layout (4 bit):
        // Bit 0: Empty
        // Bit 1: Valid
        // Bit 2: BTN0 l
        // Bit 3: BTN1
        u32 status = Xil_In32(STATUS_BASE + GPIO_DATA_REG);
        
        int is_empty = status & 0x01;
        int is_valid = (status >> 1) & 0x01;
        int btn0     = (status >> 2) & 0x01;
        int btn1     = (status >> 3) & 0x01;

        if (btn1 == 1 && last_btn1 == 0) {
            print("\n!!! HARDWARE RESET DETECTED !!!\n\r");
            // Lưu ý: Phần cứng Verilog đã tự Reset rồi (nhờ dây sys_rst),
            // Code C chỉ cần Enable lại để chắc chắn mạch chạy tiếp.
            Xil_Out32(CTRL_BASE + GPIO_DATA_REG, 0x02); 
        }

        // --- XỬ LÝ NÚT LẤY SỐ (BTN0) ---
        if (btn0 == 1 && last_btn0 == 0) { // Phát hiện cạnh lên (vừa ấn nút)
            
            if (is_empty == 0) { // Nếu kho có hàng (Empty = 0)
                
                // B1: Gửi lệnh Read Request
                // Bit 2=1 (Read), Bit 1=1 (Enable) -> Giá trị 0x06
                Xil_Out32(CTRL_BASE + GPIO_DATA_REG, 0x06);
                
                // B2: Đợi phần cứng phản hồi (Valid lên 1)
                // Dùng vòng lặp timeout để tránh treo máy nếu mạch lỗi
                int timeout = 10000;
                while (timeout > 0) {
                    u32 s = Xil_In32(STATUS_BASE + GPIO_DATA_REG);
                    if ((s >> 1) & 0x01) break; // Valid = 1 -> Thoát
                    timeout--;
                }

                // B3: Đọc dữ liệu nếu Valid OK
                if (timeout > 0) {
                    u32 rand_num = Xil_In32(DATA_BASE + GPIO_DATA_REG);
                    xil_printf("Random Number: 0x%08X\n\r", rand_num);
                } else {
                    print("Error: Timeout waiting for Valid signal!\n\r");
                }
                
                // B4: Tắt lệnh Read, chỉ giữ Enable -> Giá trị 0x02
                Xil_Out32(CTRL_BASE + GPIO_DATA_REG, 0x02);

            } else {
                print("Warning: FIFO Empty! Generating data...\n\r");
            }
        }

        // Cập nhật trạng thái nút cũ
        last_btn0 = btn0;
        last_btn1 = btn1;
        
        // Delay chống rung phím (Debounce) 50ms
        usleep(50000); 
    }

    cleanup_platform();
    return 0;
}
