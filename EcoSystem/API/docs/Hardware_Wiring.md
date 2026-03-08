# REward Kiosk - Hardware Wiring Guide

This guide details how to wire your components for the Smart Recycling Kiosk.

## 🧠 System Architecture
We will use a **Dual-Procesesor Setup**:
1.  **ESP32-CAM**: Dedicated to scanning QR codes. It sends the scanned User ID to the Main ESP32 via Serial.
2.  **ESP32 (Main)**: Controls the UI (OLED, Keypad), Sensors (IR, Inductive), and Motors (Servo). It handles the Logic and API calls.

## 🔌 Pinout Table (Main ESP32)

| Component | Pin Label | ESP32 GPIO | Notes |
| :--- | :--- | :--- | :--- |
| **ST7789 Display** | SDA (MOSI) | GPIO 23 | VSPI MOSI (Hardware SPI) |
| | SCL (SCK) | GPIO 18 | VSPI SCK (Hardware SPI) |
| | CS | GPIO 5 | VSPI SS |
| | DC | GPIO 19 | Data/Command |
| | RES | GPIO 21 | Reset |
| | BLK | GPIO 22 | Backlight (PWM) |
| **Servo Motor** | Signal (Orange) | GPIO 13 | PWM Output |
| | VCC (Red) | 5V (Vin) | Needs external power if unstable |
| | GND (Brown) | GND | Common Ground |
| **IR Sensor** | Signal (Black) | GPIO 25 | Detects Object Presence |
| | VCC (Brown) | 5V | |
| | GND (Blue) | GND | Common Ground |
| **Inductive Sensor** | Signal (Black) | GPIO 26 | **12V -> 3.3V Divider Needed!** |
| | VCC (Brown) | 12V | Power (check rating) |
| | GND (Blue) | GND | Common Ground |
| **Keypad (Rows)** | R1 | GPIO 32 | |
| | R2 | GPIO 33 | |
| | R3 | GPIO 27 | |
| | R4 | GPIO 14 | |
| **Keypad (Cols)** | C1 | GPIO 4 | Safe |
| | C2 | GPIO 0 | Strapping (Boot High) |
| | C3 | GPIO 2 | Strapping (Boot Low) |
| | C4 | GPIO 15 | Strapping (Boot High/Low) |

> **⚠️ CRITICAL WARNING FOR SENSORS:**
> Inductive proximity sensors often run on **6V-30V**.
> **DO NOT** connect the output of a 12V/24V sensor directly to the ESP32 (which is 3.3V). You **MUST** use a **Voltage Divider** or Optocoupler on the signal wire, or you will **destroy** the ESP32.
>
> **Voltage Divider for 12V Sensor:**
> - Sensor Signal -> Resistor 10kΩ --+--> GPIO 26
> -                                  |
> -                               Resistor 3.3kΩ
> -                                  |
> -                                 GND

## 📸 ESP32-CAM Wiring
The ESP32-CAM mostly needs power. It communicates the result via Serial (TX/RX).

| CAM Pin | Connect To | Notes |
| :--- | :--- | :--- |
| 5V | 5V Source | High current supply needed |
| GND | GND | Common Ground |
| U0T (TX) | ESP32 GPIO 16 (RX2) | Send QR data to Main ESP32 |
| U0R (RX) | ESP32 GPIO 17 (TX2) | Receive commands (optional) |

## 📐 Sorting Logic
1.  **Idle State**: Servo at **90°** (Center/Blocked).
2.  **Object Detected (IR = LOW)**:
    - Check **Inductive Sensor**.
    - If **Inductive = ACTIVE (Metal)** -> Servo moves to **0°** (Bin A).
    - If **Inductive = INACTIVE (Plastic)** -> Servo moves to **180°** (Bin B).
3.  **Wait**: 2 seconds for drop.
4.  **Reset**: Servo returns to **90°**.
