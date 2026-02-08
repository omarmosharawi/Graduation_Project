/*
 * Test 01: Servo Motor
 * --------------------
 * Wires:
 * - Orange (Signal) -> GPIO 13
 * - Red (VCC)       -> 5V (Vin) or separate 6V source
 * - Brown (GND)     -> GND
 */

#include <ESP32Servo.h>

Servo myServo;
const int SERVO_PIN = 13;

void setup() {
  Serial.begin(115200);
  Serial.println("Servo Test Starting...");
  
  // Allow allocation of all timers
  ESP32PWM::allocateTimer(0);
  ESP32PWM::allocateTimer(1);
  ESP32PWM::allocateTimer(2);
  ESP32PWM::allocateTimer(3);
  
  myServo.setPeriodHertz(50); // Standard 50hz servo
  myServo.attach(SERVO_PIN, 500, 2400); // Pulse width range
}

void loop() {
  Serial.println("Moving to 0 degrees (Bin A)");
  myServo.write(0);
  delay(2000);
  
  Serial.println("Moving to 90 degrees (Idle)");
  myServo.write(90);
  delay(2000);
  
  Serial.println("Moving to 180 degrees (Bin B)");
  myServo.write(180);
  delay(2000);
}
