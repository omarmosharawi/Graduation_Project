#include "Arduino.h"
#include "esp_camera.h"
#include "quirc.h"
#include "soc/rtc_cntl_reg.h"
#include "soc/soc.h"

// =======================
// AI THINKER ESP32-CAM PINS
// =======================
#define PWDN_GPIO_NUM 32
#define RESET_GPIO_NUM -1
#define XCLK_GPIO_NUM 0
#define SIOD_GPIO_NUM 26
#define SIOC_GPIO_NUM 27
#define Y9_GPIO_NUM 35
#define Y8_GPIO_NUM 34
#define Y7_GPIO_NUM 39
#define Y6_GPIO_NUM 36
#define Y5_GPIO_NUM 21
#define Y4_GPIO_NUM 19
#define Y3_GPIO_NUM 18
#define Y2_GPIO_NUM 5
#define VSYNC_GPIO_NUM 25
#define HREF_GPIO_NUM 23
#define PCLK_GPIO_NUM 22

#define FLASH_LED_PIN 4

// =======================
// QR
// =======================
struct quirc *q;

// =======================
// SETUP
// =======================
void setup() {
  WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0);

  Serial.begin(115200);
  Serial.println("\n--- ESP32-CAM QR SCANNER ---");

  pinMode(FLASH_LED_PIN, OUTPUT);
  digitalWrite(FLASH_LED_PIN, LOW);

  // =======================
  // CAMERA CONFIG (GRAYSCALE)
  // =======================
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;

  config.xclk_freq_hz = 10000000; // Lowered to 10MHz for GC2145 stability
  config.pixel_format = PIXFORMAT_GRAYSCALE;
  config.frame_size = FRAMESIZE_QQVGA;     // 160x120
  config.fb_location = CAMERA_FB_IN_PSRAM; // Required for GC2145 compatibility
  config.fb_count = 1;
  config.grab_mode = CAMERA_GRAB_LATEST;

  if (esp_camera_init(&config) != ESP_OK) {
    Serial.println("❌ Camera init failed");
    while (true)
      delay(1000);
  }

  Serial.println("✅ Camera ready");

  // =======================
  // QR INIT
  // =======================
  q = quirc_new();
  if (!q || quirc_resize(q, 160, 120) < 0) {
    Serial.println("❌ Quirc init failed");
    while (true)
      delay(1000);
  }

  Serial.println("📷 Ready to scan QR codes");
}

// =======================
// LOOP
// =======================
void loop() {
  camera_fb_t *fb = esp_camera_fb_get();
  if (!fb) {
    Serial.println("❌ Failed to get camera frame!");
    delay(1000);
    return;
  }

  // Copy frame into quirc buffer
  int w, h;
  uint8_t *qr_buf = quirc_begin(q, &w, &h);
  memcpy(qr_buf, fb->buf, 160 * 120);
  quirc_end(q);

  int count = quirc_count(q);

  // Heartbeat every 2 seconds to show it's scanning
  static unsigned long last_alive = 0;
  if (millis() - last_alive >= 2000) {
    Serial.printf("📸 Capturing frames... Shapes detected: %d\n", count);
    last_alive = millis();
  }

  if (count > 0) {
    static struct quirc_code code;
    static struct quirc_data data;

    quirc_extract(q, 0, &code);
    if (!quirc_decode(&code, &data)) {
      // Print just the payload so the receiver or Serial Monitor gets a clean
      // string
      Serial.println((char *)data.payload);

      digitalWrite(FLASH_LED_PIN, HIGH);
      delay(150);
      digitalWrite(FLASH_LED_PIN, LOW);

      delay(1200); // debounce
    }
  }

  esp_camera_fb_return(fb);
  delay(50);
}
