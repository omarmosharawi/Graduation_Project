/*
 * Test 02: Sensors (IR & Inductive)
 * ---------------------------------
 * Wires:
 * - IR Sensor Signal        -> GPIO 25
 * - Inductive Sensor Signal -> GPIO 26 (REMEMBER VOLTAGE DIVIDER 12V->3.3V!)
 */

const int PIN_IR_PLASTIC = 25;
const int PIN_INDUCTIVE_METAL = 26;

// CONFIGURATION:
// Change this to HIGH if your sensor outputs HIGH when an object is detected!
const int SENSOR_DETECT_STATE =
    HIGH; // UPDATED: User reports HIGH means Object Detected.

void setup() {
  Serial.begin(115200);
  pinMode(PIN_IR_PLASTIC, INPUT_PULLUP);
  pinMode(PIN_INDUCTIVE_METAL, INPUT_PULLUP);

  Serial.println("Sensor Test Starting...");
  Serial.println("Monitoring Raw Values... Please adjust your sensor "
                 "sensitivity if needed.");
}

void loop() {
  int irState = digitalRead(PIN_IR_PLASTIC);
  int metalState = digitalRead(PIN_INDUCTIVE_METAL);

  // DEBUG PRINT: Show raw state so you can tell if it's inverted or stuck
  Serial.printf("RAW -> IR: %d | Metal: %d ", irState, metalState);

  // 1. Check if an object is present
  if (irState == SENSOR_DETECT_STATE) {

    // 2. Small delay to ensure object is stabilized in front of inductive
    // sensor
    delay(200);

    // Re-read metal sensor after delay for stability
    metalState = digitalRead(PIN_INDUCTIVE_METAL);

    Serial.print(" => OBJECT DETECTED! Type: ");

    // 3. Check Inductive Sensor for Metal
    // Assuming Metal Sensor is also Active LOW (LOW = Metal Detected)
    if (metalState == LOW) {
      Serial.println("METAL (Bin A)");
    } else {
      Serial.println("PLASTIC (Bin B)");
    }

    delay(500); // Don't spam
  } else {
    Serial.println(" (Waiting...)");
  }

  delay(100);
}
