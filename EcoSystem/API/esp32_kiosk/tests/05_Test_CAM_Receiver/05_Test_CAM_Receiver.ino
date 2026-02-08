/*
 * Test 05: ESP32-CAM Serial Receiver (Run on MAIN ESP32)
 * -----------------------------------------------------
 * This test listens for data from the ESP32-CAM.
 * Wires:
 * - Main ESP32 RX2 (GPIO 16) -> CAM TX
 * - Main ESP32 TX2 (GPIO 17) -> CAM RX
 */

#define RXD2 16
#define TXD2 17

void setup() {
  Serial.begin(115200); // USB Serial logging
  
  // Hardware Serial 2 for communication with CAM
  Serial2.begin(115200, SERIAL_8N1, RXD2, TXD2);
  
  Serial.println("Serial Receiver Test Starting...");
  Serial.println("Connect ESP32-CAM TX to GPIO 16 (RX2)");
  Serial.println("Waiting for QR Codes...");
}

void loop() {
  if (Serial2.available()) {
    String data = Serial2.readStringUntil('\n');
    Serial.print("Received from CAM: ");
    Serial.println(data);
  }
}
