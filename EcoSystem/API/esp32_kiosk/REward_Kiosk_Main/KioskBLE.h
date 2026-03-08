#ifndef KIOSK_BLE_H
#define KIOSK_BLE_H

#include "KioskConfig.h"
#include <BLE2902.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>


// =============================================================================
// BLE CONFIGURATION SERVER
// =============================================================================
// Allows the Flutter admin app to set WiFi credentials, Kiosk ID, and API
// secret over Bluetooth Low Energy. Values are saved to NVS (Preferences)
// and applied without re-flashing the firmware.
//
// The BLE server advertises as "REward-Kiosk" and exposes one service with
// 4 writable characteristics.
// =============================================================================

// Flag checked in main loop — when true, save config and reconnect WiFi
volatile bool bleConfigReceived = false;
bool bleDeviceConnected = false;

// Temporary buffers for incoming BLE writes
char bleSsid[64] = "";
char blePass[64] = "";
char bleKioskId[32] = "";
char bleSecret[64] = "";

// Track which fields were written (bitmask)
uint8_t bleFieldsWritten = 0;
#define BLE_FIELD_SSID 0x01
#define BLE_FIELD_PASS 0x02
#define BLE_FIELD_KIOSK 0x04
#define BLE_FIELD_SECRET 0x08
#define BLE_ALL_FIELDS 0x0F

BLEServer *pServer = nullptr;

// =============================================================================
// BLE CALLBACKS
// =============================================================================

class KioskBLEServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *server) override {
    bleDeviceConnected = true;
    Serial.println("BLE: Device connected");
  }

  void onDisconnect(BLEServer *server) override {
    bleDeviceConnected = false;
    Serial.println("BLE: Device disconnected");
    // Restart advertising so another device can connect
    delay(500);
    server->getAdvertising()->start();
    Serial.println("BLE: Advertising restarted");
  }
};

// Generic characteristic write callback
class ConfigCharCallback : public BLECharacteristicCallbacks {
private:
  char *targetBuffer;
  size_t bufferSize;
  uint8_t fieldBit;
  const char *fieldName;

public:
  ConfigCharCallback(char *buf, size_t size, uint8_t bit, const char *name)
      : targetBuffer(buf), bufferSize(size), fieldBit(bit), fieldName(name) {}

  void onWrite(BLECharacteristic *pChar) override {
    String value = pChar->getValue();
    if (value.length() > 0 && value.length() < bufferSize) {
      value.toCharArray(targetBuffer, bufferSize);
      targetBuffer[bufferSize - 1] = '\0';
      bleFieldsWritten |= fieldBit;
      Serial.printf("BLE: %s set to \"%s\" [%d/%d fields]\n", fieldName,
                    targetBuffer, __builtin_popcount(bleFieldsWritten), 4);

      // When all 4 fields are written, signal the main loop
      if (bleFieldsWritten == BLE_ALL_FIELDS) {
        bleConfigReceived = true;
        bleFieldsWritten = 0; // Reset for next config push
        Serial.println("BLE: All config received! Flagging for save...");
      }
    }
  }
};

// =============================================================================
// BLE INITIALIZATION
// =============================================================================
void initBLE() {
  BLEDevice::init(BLE_DEVICE_NAME);

  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new KioskBLEServerCallbacks());

  BLEService *pService = pServer->createService(BLE_SERVICE_UUID);

  // --- SSID Characteristic ---
  BLECharacteristic *charSSID = pService->createCharacteristic(
      BLE_CHAR_SSID_UUID,
      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE);
  charSSID->setCallbacks(
      new ConfigCharCallback(bleSsid, sizeof(bleSsid), BLE_FIELD_SSID, "SSID"));
  charSSID->setValue(cfgWifiSSID); // Show current value on read

  // --- Password Characteristic ---
  BLECharacteristic *charPass = pService->createCharacteristic(
      BLE_CHAR_PASS_UUID,
      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE);
  charPass->setCallbacks(new ConfigCharCallback(blePass, sizeof(blePass),
                                                BLE_FIELD_PASS, "Password"));
  charPass->setValue("****"); // Don't expose password on read

  // --- Kiosk ID Characteristic ---
  BLECharacteristic *charKiosk = pService->createCharacteristic(
      BLE_CHAR_KIOSK_UUID,
      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE);
  charKiosk->setCallbacks(new ConfigCharCallback(bleKioskId, sizeof(bleKioskId),
                                                 BLE_FIELD_KIOSK, "KioskID"));
  charKiosk->setValue(cfgKioskId); // Show current value on read

  // --- API Secret Characteristic ---
  BLECharacteristic *charSecret = pService->createCharacteristic(
      BLE_CHAR_SECRET_UUID,
      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE);
  charSecret->setCallbacks(new ConfigCharCallback(
      bleSecret, sizeof(bleSecret), BLE_FIELD_SECRET, "APISecret"));
  charSecret->setValue("****"); // Don't expose secret on read

  // Start service and advertising
  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(BLE_SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06); // For iPhone compatibility
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.println("BLE Server started: " + String(BLE_DEVICE_NAME));
}

// =============================================================================
// APPLY BLE CONFIG (called from main loop when bleConfigReceived == true)
// =============================================================================
void applyBLEConfig() {
  Serial.println("Applying BLE config...");

  // Copy BLE buffers to active config
  strncpy(cfgWifiSSID, bleSsid, sizeof(cfgWifiSSID));
  strncpy(cfgWifiPass, blePass, sizeof(cfgWifiPass));
  strncpy(cfgKioskId, bleKioskId, sizeof(cfgKioskId));
  strncpy(cfgApiSecret, bleSecret, sizeof(cfgApiSecret));

  // Save to NVS (persists across reboots)
  saveConfig();

  Serial.println("New config applied:");
  Serial.println("  SSID: " + String(cfgWifiSSID));
  Serial.println("  Kiosk ID: " + String(cfgKioskId));
}

#endif
