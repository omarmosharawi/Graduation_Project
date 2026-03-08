#ifndef KIOSK_NETWORK_H
#define KIOSK_NETWORK_H

#include "KioskConfig.h"
#include <ArduinoJson.h> // You need to install ArduinoJson library
#include <HTTPClient.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>

// BLE + HTTPS can't run simultaneously (not enough heap for SSL).
// Stop BLE permanently before the first API call. BLE is only needed
// for initial admin config — once the kiosk is in use, BLE is not needed.
bool bleActive = false; // Tracks if BLE is currently running

void stopBLEIfNeeded() {
  if (bleActive) {
    Serial.println("Stopping BLE to free heap for HTTPS...");
    BLEDevice::deinit(false);
    bleActive = false;
    delay(200);
    Serial.println("BLE stopped. Free heap: " + String(ESP.getFreeHeap()));
  }
}

// =============================================================================
// WIFI FUNCTIONS
// =============================================================================
void initWiFi() {
  Serial.print("Connecting to WiFi");
  WiFi.begin(WIFI_SSID, WIFI_PASS);

  int timeout = 0;
  while (WiFi.status() != WL_CONNECTED && timeout < 20) {
    delay(500);
    Serial.print(".");
    timeout++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi Connected!");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\nWiFi Failed!");
  }
}

// =============================================================================
// API FUNCTIONS
// =============================================================================

// Resolved user ID stored after successful kioskCode lookup
String resolvedUserId = "";

// Look up user by 8-digit kiosk code. Returns true if valid, stores Firebase
// UID.
bool checkUserByKioskCode(String kioskCode) {
  if (WiFi.status() != WL_CONNECTED)
    return false;

  stopBLEIfNeeded(); // Stop BLE once to free heap for HTTPS

  WiFiClientSecure client;
  client.setInsecure();
  HTTPClient http;
  String url = String(API_BASE_URL) + "user/by-code/" + kioskCode;

  Serial.println("API Request: " + url);
  http.begin(client, url);
  http.addHeader("X-API-Key", API_SECRET);
  http.setFollowRedirects(HTTPC_STRICT_FOLLOW_REDIRECTS);

  int httpCode = http.GET();
  bool isValid = false;

  if (httpCode == 200) {
    String payload = http.getString();
    Serial.println("Response: " + payload);

    JsonDocument doc;
    deserializeJson(doc, payload);

    if (doc["success"] == true) {
      resolvedUserId = doc["user"]["id"].as<String>();
      isValid = true;
      Serial.println("User found: " + resolvedUserId);
    } else {
      Serial.println("User check failed: " + doc["error"].as<String>());
    }
  } else {
    Serial.printf("API Error: %d\n", httpCode);
    if (httpCode < 0) {
      Serial.println("Connection failed! Check WiFi or URL.");
    }
  }

  http.end();
  return isValid;
}

// Submit Transaction using resolved Firebase UID. Returns points earned or -1.
int submitTransactionAPI(int plastic, int metal) {
  if (WiFi.status() != WL_CONNECTED || resolvedUserId.length() == 0)
    return -1;

  stopBLEIfNeeded(); // Stop BLE once to free heap for HTTPS

  WiFiClientSecure client;
  client.setInsecure();
  HTTPClient http;
  String url = String(API_BASE_URL) + "kiosk/transaction";

  http.begin(client, url);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("X-API-Key", API_SECRET); // Authentication
  http.setFollowRedirects(HTTPC_STRICT_FOLLOW_REDIRECTS);

  // Create JSON Payload using resolved Firebase UID
  String json = "{";
  json += "\"kioskId\":\"" + String(KIOSK_ID) + "\",";
  json += "\"userId\":\"" + resolvedUserId + "\",";
  json += "\"plasticCount\":" + String(plastic) + ",";
  json += "\"metalCount\":" + String(metal);
  json += "}";

  Serial.println("Posting: " + json);

  http.setTimeout(10000); // 10 second timeout
  int httpCode = http.POST(json);
  int earnedPoints = -1;

  if (httpCode >= 200 && httpCode < 300) {
    String payload = http.getString();
    Serial.println("Response: " + payload);

    JsonDocument doc;
    DeserializationError err = deserializeJson(doc, payload);

    if (!err && doc["success"] == true) {
      earnedPoints = doc["transaction"]["pointsEarned"];
    } else {
      // Server accepted it (200) but response parsing failed
      // Estimate points: plastic=5pts, metal=10pts
      earnedPoints = (plastic * 5) + (metal * 10);
      Serial.println("Response parse failed, estimating points: " +
                     String(earnedPoints));
    }
  } else {
    Serial.printf("API POST Error: %d\n", httpCode);
  }

  http.end();
  return earnedPoints;
}

// Update kiosk status and capacity on the server (heartbeat)
bool updateKioskStatus(const char *status, int currentCapacity = -1) {
  if (WiFi.status() != WL_CONNECTED)
    return false;

  stopBLEIfNeeded(); // Stop BLE once to free heap for HTTPS

  WiFiClientSecure client;
  client.setInsecure();
  HTTPClient http;
  String url = String(API_BASE_URL) + "kiosk/" + String(KIOSK_ID) + "/status";

  http.begin(client, url);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("X-API-Key", API_SECRET); // Authentication
  http.setFollowRedirects(HTTPC_STRICT_FOLLOW_REDIRECTS);

  String json = "{\"status\":\"" + String(status) + "\"";
  if (currentCapacity >= 0) {
    json += ",\"currentCapacity\":" + String(currentCapacity);
  }
  json += "}";

  Serial.println("Status Update: " + json);

  int httpCode = http.POST(json);
  bool success = (httpCode == 200);

  if (!success) {
    Serial.printf("Status Update Error: %d\n", httpCode);
  } else {
    Serial.println("Kiosk status -> " + String(status));
  }

  http.end();
  return success;
}

#endif
