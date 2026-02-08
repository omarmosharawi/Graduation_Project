/*
 * Test 04: ST7789 Display (Adafruit Library)
 * ------------------------------------------
 * Model: 1.14" 135x240 RGB TFT
 *
 * Requirements:
 * - Install "Adafruit ST7789 Library" via Library Manager
 * - Install "Adafruit GFX Library" via Library Manager
 *
 * Wires:
 * - SDA (MOSI) -> GPIO 23
 * - SCL (SCK)  -> GPIO 18
 * - CS         -> GPIO 5
 * - DC         -> GPIO 19
 * - RES        -> GPIO 21
 * - BLK        -> GPIO 22 (Backlight)
 */

#include <Adafruit_GFX.h>    // Core graphics library
#include <Adafruit_ST7789.h> // Hardware-specific library
#include <SPI.h>

// Pin Definitions
#define TFT_CS 5
#define TFT_RST 21
#define TFT_DC 19
#define TFT_MOSI 23
#define TFT_SCLK 18
#define TFT_BL 22

// Initialize Adafruit ST7789 with Hardware SPI
// Constructor: CS, DC, MOSI, SCLK, RST
// Note: We use specific constructor to enforce pins if HW SPI default is
// different
Adafruit_ST7789 tft =
    Adafruit_ST7789(TFT_CS, TFT_DC, TFT_MOSI, TFT_SCLK, TFT_RST);

void setup() {
  Serial.begin(115200);
  Serial.println("ST7789 Test (Adafruit) Starting...");

  // 1. Turn on Backlight manually first
  pinMode(TFT_BL, OUTPUT);
  digitalWrite(TFT_BL, HIGH);

  // 2. Initialize Display
  // init(width, height) - standard for 135x240 usually needs specific setup
  tft.init(135, 240);

  // 3. Configuration
  tft.setRotation(1); // Landscape
  tft.fillScreen(ST77XX_BLACK);

  // 4. Draw Text
  tft.setTextSize(2);
  tft.setTextColor(ST77XX_WHITE);
  tft.setCursor(10, 10);
  tft.println("REward Kiosk");

  tft.setTextSize(1);
  tft.setCursor(10, 40);
  tft.println("Lib: Adafruit_ST7789");
  tft.println("Status: SPI OK");
}

void loop() {
  tft.invertDisplay(true);
  delay(500);
  tft.invertDisplay(false);
  delay(500);

  tft.fillScreen(ST77XX_RED);
  delay(200);
  tft.fillScreen(ST77XX_GREEN);
  delay(200);
  tft.fillScreen(ST77XX_BLUE);
  delay(200);
  tft.fillScreen(ST77XX_BLACK);

  tft.setCursor(10, 60);
  tft.setTextColor(ST77XX_YELLOW);
  tft.println(millis() / 1000);
}
