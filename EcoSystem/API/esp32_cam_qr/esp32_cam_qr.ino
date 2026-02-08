/*
 * ESP32-CAM QR Code Scanner
 * -------------------------
 * Board: AI Thinker ESP32-CAM
 * Library Required: "ESP32QRCodeReader" by alvarowolfx (Install via Library
 * Manager)
 *
 * Wiring:
 * - 5V  -> 5V Supply (Solid 2A+)
 * - GND -> GND
 * - U0R (GPIO 3) -> FTDI TX (For Upload)
 * - U0T (GPIO 1) -> FTDI RX (For Upload)
 * - GPIO 0       -> GND (Only during upload!)
 *
 * Operation:
 * - Scans for QR Codes using the camera.
 * - Sends decoded text via Serial (U0T/TX) to Main ESP32.
 * - Baud Rate: 115200
 */

#include <ESP32QRCodeReader.h>

ESP32QRCodeReader reader(CAMERA_MODEL_AI_THINKER);

// Flash Light Pin (GPIO 4)
#define FLASH_PIN 4

void onQrCodeTask(void *pvParameters) {
  struct QRCodeData qrCodeData;

  while (true) {
    if (reader.receiveQrCode(&qrCodeData, 100)) {
      Serial.println("QR Detected");
      if (qrCodeData.valid) {
        String payload = (const char *)qrCodeData.payload;

        // Send to Main ESP32
        Serial.println(payload);

        // Blink Flash to indicate success
        digitalWrite(FLASH_PIN, HIGH);
        delay(100);
        digitalWrite(FLASH_PIN, LOW);
      }
    }
    vTaskDelay(100 / portTICK_PERIOD_MS);
  }
}

void setup() {
  Serial.begin(115200);
  Serial.println("ESP32-CAM QR Reader Starting...");

  // Setup Flash Pin
  pinMode(FLASH_PIN, OUTPUT);
  digitalWrite(FLASH_PIN, LOW);

  // Initialize Camera & QR Reader
  reader.setup();

  Serial.println("Setup Complete");

  // Create QR Scanning Task
  reader.beginOnCore(1); // Run on Core 1
  xTaskCreate(onQrCodeTask, "onQrCode", 4 * 1024, NULL, 4, NULL);
}

void loop() {
  // Main loop does nothing, task handles scanning
  delay(1000);
}
