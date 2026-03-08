#ifndef KIOSK_HARDWARE_H
#define KIOSK_HARDWARE_H

#include "KioskConfig.h"
#include <Adafruit_GFX.h>    // Core graphics library
#include <Adafruit_ST7789.h> // Hardware-specific library (matches working test)
#include <ESP32Servo.h>
#include <Keypad.h>
#include <SPI.h>
#include <WiFi.h>

// =============================================================================
// COLOR ALIASES (map old TFT_eSPI names to Adafruit ST77XX)
// =============================================================================
#define TFT_BLACK ST77XX_BLACK
#define TFT_WHITE ST77XX_WHITE
#define TFT_RED ST77XX_RED
#define TFT_GREEN ST77XX_GREEN
#define TFT_BLUE ST77XX_BLUE
#define TFT_YELLOW ST77XX_YELLOW
#define TFT_CYAN ST77XX_CYAN
#define TFT_ORANGE ST77XX_ORANGE
#define TFT_GREY 0x8410

// =============================================================================
// GLOBAL OBJECTS

// =============================================================================
Adafruit_ST7789 tft =
    Adafruit_ST7789(TFT_CS, TFT_DC, TFT_MOSI, TFT_SCLK, TFT_RST);
Servo myServo;

char keys[KEYPAD_ROWS][KEYPAD_COLS] = {{'1', '2', '3', 'A'},
                                       {'4', '5', '6', 'B'},
                                       {'7', '8', '9', 'C'},
                                       {'*', '0', '#', 'D'}};
Keypad keypad =
    Keypad(makeKeymap(keys), ROW_PINS, COL_PINS, KEYPAD_ROWS, KEYPAD_COLS);

// =============================================================================
// AUDIO & VISUAL HELPER FUNCTIONS
// =============================================================================
void setLED(bool state) { digitalWrite(PIN_LED, state ? HIGH : LOW); }

// =============================================================================
// LED STATE INDICATOR (non-blocking, call from loop)
// =============================================================================
// Pattern meanings:
//   SLOW BLINK  = Idle / Welcome (waiting for user)
//   FAST BLINK  = Auth / Entering code
//   SOLID ON    = Recycling session active
//   PULSE       = Processing / Submitting
//   OFF         = Result screen / Error
//
// ledMode is set externally from the main .ino when state changes.
// updateLED() must be called every loop() iteration.
// =============================================================================
enum LEDMode {
  LED_OFF,        // Completely off
  LED_ON,         // Solid on
  LED_SLOW_BLINK, // 1s on / 1s off — idle
  LED_FAST_BLINK, // 200ms on / 200ms off — user input
  LED_PULSE       // Smooth breathing — processing
};

LEDMode ledMode = LED_OFF;

void updateLED() {
  unsigned long now = millis();

  switch (ledMode) {
  case LED_OFF:
    digitalWrite(PIN_LED, LOW);
    break;

  case LED_ON:
    digitalWrite(PIN_LED, HIGH);
    break;

  case LED_SLOW_BLINK:
    // 1 second on, 1 second off
    digitalWrite(PIN_LED, (now / 1000) % 2 ? HIGH : LOW);
    break;

  case LED_FAST_BLINK:
    // 200ms on, 200ms off
    digitalWrite(PIN_LED, (now / 200) % 2 ? HIGH : LOW);
    break;

  case LED_PULSE: {
    // Smooth breathing using PWM-like toggle (fade approximation)
    // Cycle: 2 seconds total (1s fade in, 1s fade out)
    int phase = (now / 50) % 40; // 0-39, each step = 50ms, total = 2s
    bool on = (phase < 20) ? (phase % 4 < 2) : ((39 - phase) % 4 < 2);
    digitalWrite(PIN_LED, on ? HIGH : LOW);
    break;
  }
  }
}

// =============================================================================
// VOLUME-CONTROLLED PLAYBACK ENGINE (10-bit PWM)
// =============================================================================

// Core: Play a frequency at a specific volume for a duration
void playToneLoud(int freq, int duration, int volume) {
  ledcWrite(PIN_BUZZER, volume);
  ledcWriteTone(PIN_BUZZER, freq);
  delay(duration);
  ledcWriteTone(PIN_BUZZER, 0);
  ledcWrite(PIN_BUZZER, 0);
}

// Rapid frequency + volume swell (aggressive transition)
void playSwell(int startFreq, int endFreq, int startVol, int endVol,
               int duration) {
  int steps = 15;
  int stepTime = duration / steps;
  for (int i = 0; i <= steps; i++) {
    int vol = map(i, 0, steps, startVol, endVol);
    int freq = map(i, 0, steps, startFreq, endFreq);
    ledcWrite(PIN_BUZZER, vol);
    ledcWriteTone(PIN_BUZZER, freq);
    delay(stepTime);
  }
  ledcWriteTone(PIN_BUZZER, 0);
  ledcWrite(PIN_BUZZER, 0);
}

// Sharp percussive attack with decay
void playAttack(int freq, int startVol, int peakVol, int attackTime,
                int decayTime) {
  // Instant attack
  for (int i = 0; i <= 5; i++) {
    int vol = map(i, 0, 5, startVol, peakVol);
    ledcWrite(PIN_BUZZER, vol);
    ledcWriteTone(PIN_BUZZER, freq);
    delay(attackTime / 5);
  }
  // Sharp decay
  for (int i = 10; i >= 0; i--) {
    int vol = map(i, 0, 10, startVol, peakVol);
    ledcWrite(PIN_BUZZER, vol);
    ledcWriteTone(PIN_BUZZER, freq);
    delay(decayTime / 10);
  }
  ledcWriteTone(PIN_BUZZER, 0);
  ledcWrite(PIN_BUZZER, 0);
}

// Fast fade in
void playFadeIn(int freq, int startVol, int endVol, int duration) {
  int steps = 20;
  int stepTime = duration / steps;
  ledcWriteTone(PIN_BUZZER, freq);
  for (int i = 0; i <= steps; i++) {
    int vol = map(i, 0, steps, startVol, endVol);
    ledcWrite(PIN_BUZZER, vol);
    delay(stepTime);
  }
  ledcWriteTone(PIN_BUZZER, 0);
  ledcWrite(PIN_BUZZER, 0);
}

// Fast fade out
void playFadeOut(int freq, int startVol, int endVol, int duration) {
  int steps = 20;
  int stepTime = duration / steps;
  ledcWriteTone(PIN_BUZZER, freq);
  for (int i = steps; i >= 0; i--) {
    int vol = map(i, 0, steps, endVol, startVol);
    ledcWrite(PIN_BUZZER, vol);
    delay(stepTime);
  }
  ledcWriteTone(PIN_BUZZER, 0);
  ledcWrite(PIN_BUZZER, 0);
}

// =============================================================================
// HIGH-PITCH LOUD SOUND PROFILES
// =============================================================================

void playBootLoud() {
  // Energetic high-pitch startup: C7, E7, G7, C8, E8 + final power chord
  int notes[] = {2093, 2637, 3136, 4186, 5274};
  int durations[] = {100, 100, 100, 200, 400};
  for (int i = 0; i < 5; i++) {
    playAttack(notes[i], VOL_OFF, VOL_MAX, 5, durations[i]);
    delay(30);
  }
  playToneLoud(8372, 600, VOL_MAX); // C9 power chord
}

void playKeypressLoud() {
  // Sharp mechanical double-click
  playAttack(4000, VOL_OFF, VOL_MAX, 2, 30);
  delay(10);
  playAttack(3000, VOL_OFF, VOL_LOUDER, 2, 40);
}

void playSuccessLoud() {
  // Triumphant high-pitch fanfare: C8 -> E8 -> G8 -> C9
  playAttack(4186, VOL_OFF, VOL_MAX, 5, 150);
  delay(50);
  playAttack(5274, VOL_OFF, VOL_MAX, 5, 150);
  delay(50);
  playAttack(6272, VOL_OFF, VOL_MAX, 5, 300);
  delay(100);
  playAttack(8372, VOL_OFF, VOL_MAX, 5, 600);
  // Victory shimmer
  for (int i = 0; i < 3; i++) {
    delay(100);
    playToneLoud(10000 + (i * 500), 80, VOL_LOUD);
  }
}

void playErrorLoud() {
  // Harsh alarm pattern with dissonant high frequencies
  for (int cycle = 0; cycle < 3; cycle++) {
    playToneLoud(3000, 300, VOL_MAX);
    playToneLoud(2900, 300, VOL_MAX); // Beating effect
    for (int i = 0; i < 3; i++) {
      playAttack(5000, VOL_OFF, VOL_MAX, 2, 100);
      delay(100);
    }
    delay(200);
  }
  playSwell(2000, 6000, VOL_LOUD, VOL_MAX, 1000); // Siren finish
}

void playDetectLoud() {
  // Laser/sci-fi sweep up -> hold -> echo decay
  for (int freq = 2000; freq <= 8000; freq += 500) {
    playToneLoud(freq, 40, VOL_MAX);
  }
  playToneLoud(10000, 200, VOL_MAX);
  playFadeOut(8000, VOL_MAX, VOL_OFF, 600);
}

void playSiren() {
  // European-style high-pitch siren
  for (int i = 0; i < 5; i++) {
    playSwell(3000, 5000, VOL_LOUD, VOL_MAX, 400);
    playSwell(5000, 3000, VOL_MAX, VOL_LOUD, 400);
  }
}

// =============================================================================
// DISPATCHER: Maps event names to loud profiles (backward compatible)
// =============================================================================
void playTone(String type) {
  if (type == "BOOT") {
    playBootLoud();
  } else if (type == "KEYPRESS") {
    playKeypressLoud();
  } else if (type == "SUCCESS") {
    playSuccessLoud();
  } else if (type == "ERROR") {
    playErrorLoud();
  } else if (type == "DETECT") {
    playDetectLoud();
  }
}

// =============================================================================
// HELPER: Draw centered text (replaces TFT_eSPI drawString with datum)
// =============================================================================
// fontScale: 1=small, 2=medium (default), 3=large, 4=extra large
void drawCenteredString(const char *text, int16_t cx, int16_t cy,
                        uint8_t fontScale) {
  tft.setTextSize(fontScale);
  int16_t x1, y1;
  uint16_t w, h;
  tft.getTextBounds(text, 0, 0, &x1, &y1, &w, &h);
  tft.setCursor(cx - w / 2, cy - h / 2);
  tft.print(text);
}

// Overload for String
void drawCenteredString(String text, int16_t cx, int16_t cy,
                        uint8_t fontScale) {
  drawCenteredString(text.c_str(), cx, cy, fontScale);
}

// =============================================================================
// INITIALIZATION
// =============================================================================
void initHardware() {
  Serial.begin(115200);

  // Initialize Buzzer and LED
  pinMode(PIN_BUZZER, OUTPUT);
  pinMode(PIN_LED, OUTPUT);
  digitalWrite(PIN_BUZZER, LOW);
  digitalWrite(PIN_LED, LOW);

  // Servo Setup FIRST (ESP32Servo must claim LEDC channel 0 before ledcAttach)
  myServo.attach(PIN_SERVO);
  myServo.write(SERVO_CENTER_ANGLE); // Start at Center (Blocked)

  // Setup Buzzer PWM AFTER servo (to avoid channel conflict)
  // ESP32 Core 3.x API: ledcAttach(pin, freq, resolution)
  ledcAttach(PIN_BUZZER, 2000, 10); // 2 kHz, 10-bit resolution

  // 1. Backlight ON first (GPIO 22)
  pinMode(TFT_BL, OUTPUT);
  digitalWrite(TFT_BL, HIGH);

  // 2. Display Setup (Adafruit ST7789 - 135x240)
  tft.init(135, 240);
  tft.setRotation(1); // Landscape
  tft.fillScreen(TFT_BLACK);
  tft.setTextColor(TFT_WHITE);
  tft.setTextSize(2);
  tft.setCursor(10, 10);
  tft.println("Booting Kiosk...");

  // Play Boot Sound
  playTone("BOOT");

  // 4. Sensor Setup
  pinMode(PIN_IR_PLASTIC, INPUT_PULLUP);      // IR Sensor
  pinMode(PIN_INDUCTIVE_METAL, INPUT_PULLUP); // Metal Sensor
}

// =============================================================================
// STATUS BAR (WiFi signal + BLE indicator — drawn on top of every screen)
// =============================================================================
// Draws a 16px tall bar at the top showing:
//   [WiFi bars] SSID          [BLE dot] KioskID
// =============================================================================

void drawWifiBars(int x, int y, int bars) {
  // Draw 4 bars of increasing height (3px wide each, 2px gap)
  for (int i = 0; i < 4; i++) {
    int barH = 3 + (i * 3); // Heights: 3, 6, 9, 12
    int barX = x + (i * 5);
    int barY = y + (12 - barH);                       // Align bottom
    uint16_t color = (i < bars) ? TFT_GREEN : 0x4208; // Green or dark gray
    tft.fillRect(barX, barY, 3, barH, color);
  }
}

void drawStatusBar() {
  // Dark semi-transparent bar at top
  tft.fillRect(0, 0, 240, 16, 0x18E3); // Dark gray

  // WiFi signal strength (RSSI -> bars)
  int bars = 0;
  if (WiFi.status() == WL_CONNECTED) {
    int rssi = WiFi.RSSI();
    if (rssi > -50)
      bars = 4; // Excellent
    else if (rssi > -60)
      bars = 3; // Good
    else if (rssi > -70)
      bars = 2; // Fair
    else
      bars = 1; // Weak
  }

  drawWifiBars(4, 2, bars);

  // SSID or "No WiFi"
  tft.setTextColor(bars > 0 ? TFT_WHITE : TFT_RED);
  tft.setTextSize(1);
  if (WiFi.status() == WL_CONNECTED) {
    tft.setCursor(26, 4);
    tft.print(cfgWifiSSID);
  } else {
    tft.setCursor(26, 4);
    tft.print("No WiFi");
  }

  // BLE indicator (right side) — blue dot if connected
  if (bleDeviceConnected) {
    tft.fillCircle(200, 8, 4, TFT_BLUE);
    tft.setTextColor(TFT_CYAN);
    tft.setCursor(207, 4);
    tft.print("BLE");
  }

  // Kiosk ID (far right)
  tft.setTextColor(0x7BEF); // Light gray
  tft.setCursor(170, 4);
  // Show last 5 chars of kiosk ID to save space
  String kid = String(cfgKioskId);
  if (kid.length() > 5 && !bleDeviceConnected) {
    tft.setCursor(195, 4);
    tft.print(kid.substring(kid.length() - 5));
  }
}

// =============================================================================
// DISPLAY HELPER FUNCTIONS
// =============================================================================
void showScreenWelcome() {
  tft.fillScreen(TFT_BLUE);
  tft.setTextColor(TFT_WHITE);
  drawCenteredString("WELCOME TO REward", 120, 35, 2);

  tft.setTextColor(TFT_YELLOW);
  drawCenteredString("Scan Your QR Code", 120, 75, 2);

  tft.setTextColor(TFT_WHITE);
  drawCenteredString("or Press * for Keypad", 120, 110, 1);

  drawStatusBar();
}

void showScreenInputID(String currentInput) {
  tft.fillScreen(TFT_BLACK);
  tft.setTextColor(TFT_WHITE);
  drawCenteredString("Scan QR or Enter ID:", 120, 30, 2);

  tft.setTextColor(TFT_GREEN);
  drawCenteredString(currentInput + "_", 120, 65, 2);

  tft.setTextColor(TFT_GREY);
  drawCenteredString("# Submit | D Delete", 120, 110, 1);

  drawStatusBar();
}

void showScreenRecycling(int plastic, int metal) {
  tft.fillScreen(TFT_BLACK);
  tft.setTextColor(TFT_WHITE);
  drawCenteredString("Insert Item...", 120, 20, 2);

  String pText = "Plastic: " + String(plastic);
  String mText = "Metal: " + String(metal);

  tft.setTextColor(TFT_ORANGE);
  drawCenteredString(pText, 120, 55, 2);

  tft.setTextColor(TFT_CYAN);
  drawCenteredString(mText, 120, 80, 2);

  tft.setTextColor(TFT_GREY);
  drawCenteredString("Press # to Finish", 120, 115, 1);

  drawStatusBar();
}

void showScreenResult(int points, int items) {
  tft.fillScreen(TFT_GREEN);
  tft.setTextColor(TFT_BLACK);
  drawCenteredString("SUCCESS!", 120, 40, 3);

  String res = "Earned " + String(points) + " Pts";
  drawCenteredString(res, 120, 80, 2);

  drawStatusBar();
}

void showScreenError(String msg) {
  tft.fillScreen(TFT_RED);
  tft.setTextColor(TFT_WHITE);
  drawCenteredString("ERROR", 120, 40, 3);
  drawCenteredString(msg, 120, 80, 1);

  drawStatusBar();
  delay(2000);
}

// =============================================================================
// SENSOR & SERVO FUNCTIONS
// =============================================================================

// Returns: 0 = None, 1 = Plastic, 2 = Metal
int checkSensors() {
  int ir = digitalRead(PIN_IR_PLASTIC);

  // 1. Check if Object Detected by IR
  if (ir == SENSOR_IR_ACTIVE_STATE) {
    Serial.println("IR Triggered, polling for Metal (5s timeout)...");

    unsigned long startTime = millis();
    // 2. Poll Metal Sensor for up to 5 seconds
    while (millis() - startTime < 5000) {
      if (digitalRead(PIN_INDUCTIVE_METAL) == SENSOR_METAL_ACTIVE_STATE) {
        Serial.println("Metal detected during timeout!");
        return 2; // Metal detected! Return immediately
      }
      yield(); // Allow background tasks
    }

    Serial.println("No metal detected after 5s. Defaulting to Plastic.");
    return 1; // Plastic (IR detected, but no Metal within 5s)
  }
  return 0; // Nothing
}

void moveServo(int type) {
  int targetAngle = SERVO_CENTER_ANGLE;

  if (type == 1) { // Plastic -> Right (180°)
    targetAngle = SERVO_BIN_B_ANGLE;
    Serial.println("Servo -> RIGHT (Plastic Bin)");
  } else if (type == 2) { // Metal -> Left (0°)
    targetAngle = SERVO_BIN_A_ANGLE;
    Serial.println("Servo -> LEFT (Metal Bin)");
  } else {
    return; // Unknown type, do nothing
  }

  // 1. Rotate to target bin
  myServo.write(targetAngle);
  delay(2000); // Wait for item to slide into bin

  // 2. Return to center (zero/idle position)
  myServo.write(SERVO_CENTER_ANGLE);
  Serial.println("Servo -> CENTER (Ready)");
  delay(500); // Settling delay — prevents sensor re-trigger
}

#endif
