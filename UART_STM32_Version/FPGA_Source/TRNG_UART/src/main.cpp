
#include <Arduino.h>
/*
// put function declarations here:
int myFunction(int, int);

void setup() {
  // put your setup code here, to run once:
  int result = myFunction(2, 3);
}

void loop() {
  // put your main code here, to run repeatedly:
}

// put function definitions here:
int myFunction(int x, int y) {
  return x + y;
}
*/
/*
 * KẾT NỐI PHẦN CỨNG (STM32 Blue Pill):
 * - PA10 (RX1)  <---> P18 (TX) của FPGA
 * - GND         <---> GND của FPGA
 * - Cáp Micro-USB <---> MacBook
 */

HardwareSerial Serial2(PA3, PA2); 
HardwareSerial &UartFPGA = Serial1;
HardwareSerial &UartPC   = Serial2;

// Biến đếm số lượng ký tự đã nhận
int char_count = 0;

void setup() {
  UartPC.begin(115200);
  UartFPGA.begin(115200);
  pinMode(PC13, OUTPUT);

  UartPC.println("\n\n--- STM32 FORMATTER READY ---");
}

void loop() {
  if (UartFPGA.available()) {
    char c = (char)UartFPGA.read();

    // Lọc: Chỉ xử lý nếu là số (0-9) hoặc chữ (A-F)
    // Bỏ qua các ký tự rác hoặc ký tự xuống dòng cũ (nếu có)
    if (isAlphaNumeric(c)) {
        
        // 1. In ký tự đó ra
        UartPC.print(c);
        char_count++;

        // 2. Nếu đủ 8 ký tự (1 số 32-bit hoàn chỉnh) -> Xuống dòng
        if (char_count >= 8) {
            UartPC.println(); // In thêm dấu xuống dòng (\r\n)
            char_count = 0;   // Reset bộ đếm
            
            // Nháy đèn báo hiệu xong 1 số
            digitalWrite(PC13, !digitalRead(PC13));
        }
    }
  }
}