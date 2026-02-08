/*
 * Test 03: 4x4 Matrix Keypad
 * --------------------------
 * Rows: GPIO 32, 33, 27, 14
 * Cols: GPIO 4, 0, 2, 15
 */

#include <Keypad.h>

const byte ROWS = 4;
const byte COLS = 4;

char keys[ROWS][COLS] = {{'1', '2', '3', 'A'},
                         {'4', '5', '6', 'B'},
                         {'7', '8', '9', 'C'},
                         {'*', '0', '#', 'D'}};

byte rowPins[ROWS] = {32, 33, 27, 14};
byte colPins[COLS] = {4, 0, 2, 15};

Keypad keypad = Keypad(makeKeymap(keys), rowPins, colPins, ROWS, COLS);

void setup() {
  Serial.begin(115200);
  Serial.println("Keypad Test Starting...");
  Serial.println("Press any key...");
}

void loop() {
  char key = keypad.getKey();

  if (key) {
    Serial.print("Key Pressed: ");
    Serial.println(key);
  }
}
