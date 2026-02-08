/*
 * Test 02: Sensors (IR & Inductive)
 * ---------------------------------
 * Wires:
 * - IR Sensor Signal        -> GPIO 25
 * - Inductive Sensor Signal -> GPIO 26 (REMEMBER VOLTAGE DIVIDER 12V->3.3V!)
 */

const int PIN_IR_PLASTIC = 25;
const int PIN_INDUCTIVE_METAL = 26;

void setup() {
  Serial.begin(115200);
  pinMode(PIN_IR_PLASTIC, INPUT_PULLUP); // Use Pullup if sensor is Open Collector
  pinMode(PIN_INDUCTIVE_METAL, INPUT_PULLUP);
  
  Serial.println("Sensor Test Starting...");
  Serial.println("Open Serial Plotter to see signals graphically!");
}

void loop() {
  // Read sensors (Usually LOW means DETECTED for industrial sensors)
  int irState = digitalRead(PIN_IR_PLASTIC);
  int metalState = digitalRead(PIN_INDUCTIVE_METAL);
  
  Serial.print("IR_Plastic:");
  Serial.print(irState);
  Serial.print("  Metal_Inductive:");
  Serial.println(metalState);
  
  if (irState == LOW) {
    Serial.println(">> OBJECT DETECTED (IR)");
  }
  
  if (metalState == LOW) {
    Serial.println(">> METAL DETECTED");
  }
  
  delay(100);
}
