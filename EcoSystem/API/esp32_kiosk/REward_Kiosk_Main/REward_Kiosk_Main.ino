#include "KioskBLE.h"
#include "KioskConfig.h"
#include "KioskHardware.h"
#include "KioskNetwork.h"

// =============================================================================
// STATE MACHINE DEFINITIONS
// =============================================================================
enum KioskState {
  STATE_INIT,
  STATE_WELCOME,
  STATE_AUTH,
  STATE_RECYCLING,
  STATE_SUBMITTING,
  STATE_RESULT,
  STATE_ERROR
};

KioskState currentState = STATE_INIT;
String inputKioskCode = "";
int currentPlastic = 0;
int currentMetal = 0;
unsigned long stateStartTime = 0;

// =============================================================================
// SETUP
// =============================================================================
void setup() {
  initHardware(); // Serial.begin() happens here
  loadConfig();   // Load saved WiFi/ID from NVS (or use defaults)

  // Debug: Show what config is active (check via Serial Monitor!)
  Serial.println("======= ACTIVE CONFIG =======");
  Serial.println("  SSID: " + String(WIFI_SSID));
  Serial.println("  Kiosk ID: " + String(KIOSK_ID));
  Serial.println("  API URL: " + String(API_BASE_URL));
  Serial.println("  API Key: " + String(API_SECRET).substring(0, 8) + "...");
  Serial.println("=============================");

  // Connect WiFi and report online BEFORE starting BLE
  initWiFi();
  updateKioskStatus("available");

  // Now start BLE for admin config (will be stopped on first user session)
  initBLE();
  bleActive = true;

  currentState = STATE_WELCOME;
  ledMode = LED_SLOW_BLINK; // Idle — waiting for user
  showScreenWelcome();
}

// =============================================================================
// MAIN LOOP
// =============================================================================
void loop() {
  updateLED(); // Non-blocking LED state indicator
  char key = keypad.getKey();

  // -------------------------------------------------------------------------
  // CHECK BLE CONFIG (admin sent new WiFi/ID via Bluetooth)
  // -------------------------------------------------------------------------
  if (bleConfigReceived) {
    bleConfigReceived = false;
    applyBLEConfig(); // Save to NVS + update runtime buffers

    // Show config update on screen
    tft.fillScreen(TFT_BLUE);
    tft.setTextColor(TFT_WHITE);
    drawCenteredString("Config Updated!", 120, 40, 2);
    drawCenteredString("Reconnecting WiFi...", 120, 75, 1);
    playTone("SUCCESS");

    // Reconnect WiFi with new credentials
    WiFi.disconnect();
    delay(500);
    initWiFi();
    updateKioskStatus("available");

    currentState = STATE_WELCOME;
    ledMode = LED_SLOW_BLINK;
    showScreenWelcome();
    return; // Skip rest of this loop cycle
  }

  // -------------------------------------------------------------------------
  // CHECK QR SCANNER (Serial)
  // -------------------------------------------------------------------------
  if (Serial.available()) {
    String qrData = Serial.readStringUntil('\n');
    qrData.trim();

    // Look for "reward:XXXXXXXX" format (ignores heartbeat logs from the
    // camera)
    if (qrData.startsWith("reward:") && qrData.length() > 7) {
      String scannedCode =
          qrData.substring(7); // Extract everything after "reward:"
      Serial.println("QR Scanned Code: " + scannedCode);

      // Only process QR codes if we are in Welcome or Auth states
      if (currentState == STATE_WELCOME || currentState == STATE_AUTH) {
        playTone("SUCCESS"); // Acknowledge scan
        inputKioskCode = scannedCode;

        // Auto-submit the scanned code
        drawCenteredString("Checking QR...", 120, 100, 1);
        if (checkUserByKioskCode(inputKioskCode)) {
          currentState = STATE_RECYCLING;
          ledMode = LED_ON; // Solid — session active
          currentPlastic = 0;
          currentMetal = 0;
          showScreenRecycling(currentPlastic, currentMetal);
        } else {
          showScreenError("Invalid QR Code!");
          playTone("ERROR");
          delay(2000);
          inputKioskCode = "";
          currentState = STATE_WELCOME;
          ledMode = LED_SLOW_BLINK;
          showScreenWelcome();
        }
      }
    }
  }

  switch (currentState) {

  // -------------------------------------------------------------------------
  // STATE: WELCOME
  // -------------------------------------------------------------------------
  case STATE_WELCOME:
    if (key == '*') {
      playTone("KEYPRESS");
      currentState = STATE_AUTH;
      ledMode = LED_FAST_BLINK; // User input mode
      inputKioskCode = "";      // Clear input
      showScreenInputID(inputKioskCode);
    }
    break;

  // -------------------------------------------------------------------------
  // STATE: AUTHENTICATION (Enter 8-Digit Kiosk Code)
  // -------------------------------------------------------------------------
  case STATE_AUTH:
    if (key) {
      playTone("KEYPRESS");
      if (key == '#') {
        // Submit code
        if (inputKioskCode.length() != 8) {
          showScreenError("Code must be 8 digits!");
          playTone("ERROR");
          delay(2000);
          showScreenInputID(inputKioskCode);
        } else {
          drawCenteredString("Checking...", 120, 100, 1);
          if (checkUserByKioskCode(inputKioskCode)) {
            playTone("SUCCESS");
            currentState = STATE_RECYCLING;
            ledMode = LED_ON; // Solid — session active
            currentPlastic = 0;
            currentMetal = 0;
            showScreenRecycling(currentPlastic, currentMetal);
          } else {
            showScreenError("Invalid Code!");
            playTone("ERROR");
            delay(2000);
            inputKioskCode = "";
            showScreenInputID(inputKioskCode); // Retry
          }
        }
      } else if (key == 'D') {
        // Delete last char
        if (inputKioskCode.length() > 0) {
          inputKioskCode.remove(inputKioskCode.length() - 1);
          showScreenInputID(inputKioskCode);
        }
      } else if (key >= '0' && key <= '9') {
        // Only accept digits, max 8 chars
        if (inputKioskCode.length() < 8) {
          inputKioskCode += key;
          showScreenInputID(inputKioskCode);
        }
      }
    }
    break;

  // -------------------------------------------------------------------------
  // STATE: RECYCLING (Sensor Loop)
  // -------------------------------------------------------------------------
  case STATE_RECYCLING: { // Scope Block for itemType variable
    // 1. Check Keypad for Finish
    if (key == '#') {
      playTone("KEYPRESS");
      currentState = STATE_SUBMITTING;
      ledMode = LED_PULSE; // Processing / saving
      tft.fillScreen(TFT_BLACK);
      tft.setTextColor(TFT_WHITE);
      drawCenteredString("Saving Points...", 120, 65, 2);
    }

    // 2. Check Sensors
    int itemType = checkSensors(); // 0=None, 1=Plastic, 2=Metal

    if (itemType > 0) {
      playTone("DETECT"); // Beep for detection
      if (itemType == 2) {
        currentMetal++;
        tft.setTextColor(TFT_CYAN); // Flash Color
        drawCenteredString("METAL DETECTED!", 120, 115, 1);
        moveServo(2); // Bin A
      } else {
        currentPlastic++;
        tft.setTextColor(TFT_ORANGE);
        drawCenteredString("PLASTIC DETECTED!", 120, 115, 1);
        moveServo(1); // Bin B
      }

      // Update Screen Counts
      showScreenRecycling(currentPlastic, currentMetal);
    }
  } break;

  // -------------------------------------------------------------------------
  // STATE: SUBMITTING (Save to API)
  // -------------------------------------------------------------------------
  case STATE_SUBMITTING: { // Scope Block for points variable
    if (currentPlastic == 0 && currentMetal == 0) {
      showScreenError("No Items Recycled!");
      playTone("ERROR");
      currentState = STATE_WELCOME;
      showScreenWelcome();
      return;
    }

    // Uses resolvedUserId from successful checkUserByKioskCode()
    int points = submitTransactionAPI(currentPlastic, currentMetal);

    if (points >= 0) {
      playTone("SUCCESS");
      ledMode = LED_ON; // Solid ON for success celebration
      currentState = STATE_RESULT;
      stateStartTime = millis();
      showScreenResult(points, currentPlastic + currentMetal);

      // Capacity is handled by the server's transaction endpoint
    } else {
      showScreenError("Network Error!");
      playTone("ERROR");
      currentState = STATE_WELCOME;
      ledMode = LED_SLOW_BLINK;
      showScreenWelcome();
    }
  } break;

  // -------------------------------------------------------------------------
  // STATE: RESULT (Show Success)
  // -------------------------------------------------------------------------
  case STATE_RESULT:
    if (millis() - stateStartTime > 5000) { // Wait 5 seconds
      currentState = STATE_WELCOME;
      ledMode = LED_SLOW_BLINK; // Back to idle
      resolvedUserId = "";      // Clear for next user
      showScreenWelcome();
    }
    break;

  // -------------------------------------------------------------------------
  // STATE: ERROR
  // -------------------------------------------------------------------------
  case STATE_ERROR:
    showScreenError("System Error");
    playTone("ERROR");
    delay(3000);
    currentState = STATE_WELCOME;
    ledMode = LED_SLOW_BLINK;
    break;
  }
}
