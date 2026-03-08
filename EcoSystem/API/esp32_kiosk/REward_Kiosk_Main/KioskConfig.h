#ifndef KIOSK_CONFIG_H
#define KIOSK_CONFIG_H

#include <Arduino.h>
#include <Preferences.h>

// =============================================================================
// WIFI & API CONFIGURATION (Mutable — overwritten by BLE or NVS)
// =============================================================================
// Default values used on first boot (before BLE configuration)
#define DEFAULT_WIFI_SSID "Wazonet"
#define DEFAULT_WIFI_PASS "19631218"
#define DEFAULT_API_BASE_URL "https://reward.ibrahim-azab.com/api/"
#define DEFAULT_KIOSK_ID "kiosk_01"
#define DEFAULT_API_SECRET "53cdf4760cdd5bd629a0b214d80e15ec"

// Runtime config buffers (loaded from NVS or defaults)
char cfgWifiSSID[64];
char cfgWifiPass[64];
char cfgApiBaseUrl[128];
char cfgKioskId[32];
char cfgApiSecret[64];

// Legacy pointers (point to mutable buffers for backward compatibility)
char *WIFI_SSID = cfgWifiSSID;
char *WIFI_PASS = cfgWifiPass;
char *API_BASE_URL = cfgApiBaseUrl;
char *KIOSK_ID = cfgKioskId;
char *API_SECRET = cfgApiSecret;

// =============================================================================
// BLE CONFIGURATION UUIDs
// =============================================================================
#define BLE_DEVICE_NAME "REward-Kiosk"
#define BLE_SERVICE_UUID "12345678-1234-1234-1234-123456789abc"
#define BLE_CHAR_SSID_UUID "12345678-1234-1234-1234-000000000001"
#define BLE_CHAR_PASS_UUID "12345678-1234-1234-1234-000000000002"
#define BLE_CHAR_KIOSK_UUID "12345678-1234-1234-1234-000000000003"
#define BLE_CHAR_SECRET_UUID "12345678-1234-1234-1234-000000000004"

// =============================================================================
// NVS PERSISTENCE (Preferences library)
// =============================================================================
Preferences prefs;

void loadConfig() {
  prefs.begin("kiosk_cfg", true); // Read-only

  String ssid = prefs.getString("ssid", DEFAULT_WIFI_SSID);
  String pass = prefs.getString("pass", DEFAULT_WIFI_PASS);
  String url = prefs.getString("apiUrl", DEFAULT_API_BASE_URL);
  String kid = prefs.getString("kioskId", DEFAULT_KIOSK_ID);
  String sec = prefs.getString("secret", DEFAULT_API_SECRET);

  ssid.toCharArray(cfgWifiSSID, sizeof(cfgWifiSSID));
  pass.toCharArray(cfgWifiPass, sizeof(cfgWifiPass));
  url.toCharArray(cfgApiBaseUrl, sizeof(cfgApiBaseUrl));
  kid.toCharArray(cfgKioskId, sizeof(cfgKioskId));
  sec.toCharArray(cfgApiSecret, sizeof(cfgApiSecret));

  prefs.end();

  Serial.println("Config loaded:");
  Serial.println("  SSID: " + String(cfgWifiSSID));
  Serial.println("  Kiosk ID: " + String(cfgKioskId));
  Serial.println("  API URL: " + String(cfgApiBaseUrl));
}

void saveConfig() {
  prefs.begin("kiosk_cfg", false); // Read-write
  prefs.putString("ssid", cfgWifiSSID);
  prefs.putString("pass", cfgWifiPass);
  prefs.putString("apiUrl", cfgApiBaseUrl);
  prefs.putString("kioskId", cfgKioskId);
  prefs.putString("secret", cfgApiSecret);
  prefs.end();
  Serial.println("Config saved to NVS!");
}

// =============================================================================
// HARDWARE PINS
// =============================================================================

// Display (ST7789) - Using VSPI
#define TFT_MISO -1
#define TFT_MOSI 23
#define TFT_SCLK 18
#define TFT_CS 5   // Chip Select
#define TFT_DC 19  // Data/Command
#define TFT_RST 21 // Reset
#define TFT_BL 22  // Backlight

// Servo Motor
#define PIN_SERVO 13

// Sensors
#define PIN_IR_PLASTIC 25      // IR Sensor (Active HIGH based on test)
#define PIN_INDUCTIVE_METAL 26 // Metal Sensor (Active LOW Inductive)

// Indicators
#define PIN_BUZZER 17
#define PIN_LED 16

// Audio (LEDC PWM)
// NOTE: Must NOT be 0 — ESP32Servo uses LEDC channel 0 for the servo.
// Using channel 4 (separate timer) to avoid PWM conflict.
#define BUZZER_CHANNEL 4

// Volume Levels (0-1023 for 10-bit PWM resolution)
#define VOL_OFF 0
#define VOL_LOW 400    // Minimum loud
#define VOL_LOUD 800   // Strong
#define VOL_LOUDER 950 // Very strong
#define VOL_MAX 1023   // Full blast

// Keypad (4x4)
#define KEYPAD_ROWS 4
#define KEYPAD_COLS 4
// Row Pins: R1, R2, R3, R4
byte ROW_PINS[KEYPAD_ROWS] = {32, 33, 27, 14};
// Col Pins: C1, C2, C3, C4
byte COL_PINS[KEYPAD_COLS] = {4, 0, 2, 15};

// =============================================================================
// LOGIC CONSTANTS
// =============================================================================
#define SERVO_BIN_A_ANGLE 0   // Metal  -> Rotate LEFT
#define SERVO_BIN_B_ANGLE 180 // Plastic -> Rotate RIGHT
#define SERVO_CENTER_ANGLE 90 // Idle/Blocked (Zero Position)

#define SENSOR_IR_ACTIVE_STATE HIGH   // User confirmed IR is Active HIGH
#define SENSOR_METAL_ACTIVE_STATE LOW // Standard NPN Inductive is Active LOW

#endif
