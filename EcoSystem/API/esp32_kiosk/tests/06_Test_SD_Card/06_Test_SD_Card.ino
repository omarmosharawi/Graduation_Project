/*
 * Test 06: ESP32-CAM SD Card Test
 * ----------------------------------
 * This script tests the onboard TF (SD) card slot on the ESP32-CAM.
 * Note: On the AI-Thinker model, Pins 2, 4, 12, 13, 14, 15 are used for SD card.
 * PIN 4 is shared with the FLASH LED.
 */

#include "FS.h"
#include "SD_MMC.h"

void setup() {
  Serial.begin(115200);
  Serial.println("\n--- SD Card Test Start ---");

  // Mount SD Card (using 1-bit mode for better compatibility)
  if(!SD_MMC.begin("/sdcard", true)) {
    Serial.println("SD Card Mount Failed!");
    Serial.println("Check if card is inserted correctly and formatted as FAT32.");
    return;
  }

  uint8_t cardType = SD_MMC.cardType();
  if(cardType == CARD_NONE) {
    Serial.println("No SD card attached");
    return;
  }

  Serial.print("SD Card Type: ");
  if(cardType == CARD_MMC) Serial.println("MMC");
  else if(cardType == CARD_SD) Serial.println("SDSC");
  else if(cardType == CARD_SDHC) Serial.println("SDHC");
  else Serial.println("UNKNOWN");

  uint64_t cardSize = SD_MMC.cardSize() / (1024 * 1024);
  Serial.printf("SD Card Size: %lluMB\n", cardSize);

  // --- Write Test ---
  Serial.println("\nTesting Write...");
  File file = SD_MMC.open("/test.txt", FILE_WRITE);
  if(!file) {
    Serial.println("Failed to open file for writing");
  } else {
    if(file.print("ESP32-CAM SD Test Successful!")) {
      Serial.println("Write successfully");
    } else {
      Serial.println("Write failed");
    }
    file.close();
  }

  // --- Read Test ---
  Serial.println("\nTesting Read...");
  file = SD_MMC.open("/test.txt");
  if(!file) {
    Serial.println("Failed to open file for reading");
  } else {
    Serial.print("File content: ");
    while(file.available()) {
      Serial.write(file.read());
    }
    Serial.println();
    file.close();
  }

  Serial.println("\n--- Test Complete ---");
}

void loop() {
  // Do nothing
}
