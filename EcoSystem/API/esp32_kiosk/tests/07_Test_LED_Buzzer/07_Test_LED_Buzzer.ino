// =============================================================================
// TEST: LED & Buzzer (High Pitch & Loud Version)
// REward Kiosk — Hardware Test #07 High Energy Edition
// Pins: Buzzer = GPIO 17, LED = GPIO 16
// LEDC Channel: 4 (avoids conflict with ESP32Servo on channel 0)
// =============================================================================

#define PIN_BUZZER 17
#define PIN_LED 16
#define BUZZER_CHANNEL 4

// Loud volume levels only (0-1023 for 10-bit PWM)
#define VOL_OFF 0
#define VOL_LOW 400       // Minimum loud
#define VOL_LOUD 800      // Strong
#define VOL_LOUDER 950    // Very strong
#define VOL_MAX 1023      // Full blast

void setup() {
  Serial.begin(115200);
  Serial.println("\n=== LED & Buzzer - HIGH PITCH & LOUD ===\n");

  pinMode(PIN_BUZZER, OUTPUT);
  pinMode(PIN_LED, OUTPUT);
  digitalWrite(PIN_BUZZER, LOW);
  digitalWrite(PIN_LED, LOW);

  // 10-bit resolution for volume control
  ledcSetup(BUZZER_CHANNEL, 2000, 10);
  ledcAttachPin(PIN_BUZZER, BUZZER_CHANNEL);

  // --- Test 1: Loud Volume Range ---
  Serial.println("[Test 1] LOUD Volume Levels...");
  
  Serial.println("  LOUD...");
  playTone(3000, 500, VOL_LOUD);
  delay(300);
  
  Serial.println("  LOUDER...");
  playTone(3000, 500, VOL_LOUDER);
  delay(300);
  
  Serial.println("  MAXIMUM...");
  playTone(3000, 500, VOL_MAX);
  delay(500);
  
  Serial.println("  -> Volume test done.\n");

  // --- Test 2: Sharp High-Pitch Transitions ---
  Serial.println("[Test 2] Sharp High-Pitch Transitions...");
  
  Serial.println("  Sharp attack (drum hit)...");
  playAttack(4000, VOL_OFF, VOL_MAX, 10, 200);
  delay(400);
  
  Serial.println("  Rapid swell (high energy)...");
  playSwell(2000, 5000, VOL_LOW, VOL_MAX, 400);
  delay(400);
  
  Serial.println("  Piercing fade in...");
  playFadeIn(6000, VOL_OFF, VOL_MAX, 800);
  delay(400);
  
  Serial.println("  -> Transition test done.\n");

  // --- Test 3: High-Pitch Loud Sound Profiles ---
  Serial.println("[Test 3] HIGH ENERGY Sound Profiles...");
  
  Serial.println("  HIGH ENERGY Boot...");
  playBootLoud();
  delay(500);
  
  Serial.println("  SHARP Keypress...");
  playKeypressLoud();
  delay(500);
  
  Serial.println("  TRIUMPH Success...");
  playSuccessLoud();
  delay(500);
  
  Serial.println("  ALARM Error...");
  playErrorLoud();
  delay(500);
  
  Serial.println("  LASER Detect...");
  playDetectLoud();
  delay(500);
  
  Serial.println("  SIREN Alert...");
  playSiren();
  delay(500);
  
  Serial.println("  -> High energy profiles done.\n");

  // --- Test 4: Intense LED Sync ---
  Serial.println("[Test 4] INTENSE LED + Buzzer...");
  for (int i = 0; i < 5; i++) {
    digitalWrite(PIN_LED, HIGH);
    playAttack(3000 + (i * 500), VOL_OFF, VOL_MAX, 5, 100);
    digitalWrite(PIN_LED, LOW);
    delay(100);
  }
  Serial.println("  -> Intense sync test done.\n");

  Serial.println("=== ALL TESTS COMPLETE ===");
  Serial.println("Looping: Aggressive alert pattern.\n");
}

void loop() {
  static unsigned long lastSound = 0;
  
  // Aggressive alert pattern every 2 seconds
  if (millis() - lastSound > 2000) {
    // Rapid high-low siren
    playTone(4000, 150, VOL_MAX);
    delay(50);
    playTone(2500, 150, VOL_MAX);
    delay(50);
    playTone(4000, 150, VOL_MAX);
    
    lastSound = millis();
  }
  
  // Rapid LED flashing
  digitalWrite(PIN_LED, (millis() / 100) % 2);
}

// =============================================================================
// LOUD PLAYBACK FUNCTIONS
// =============================================================================

void playTone(int freq, int duration, int volume) {
  ledcWrite(BUZZER_CHANNEL, volume);
  ledcWriteTone(BUZZER_CHANNEL, freq);
  delay(duration);
  ledcWriteTone(BUZZER_CHANNEL, 0);
  ledcWrite(BUZZER_CHANNEL, 0);
}

// Rapid swell (aggressive)
void playSwell(int startFreq, int endFreq, int startVol, int endVol, int duration) {
  int steps = 15; // Fast transition
  int stepTime = duration / steps;
  
  for (int i = 0; i <= steps; i++) {
    int vol = map(i, 0, steps, startVol, endVol);
    int freq = map(i, 0, steps, startFreq, endFreq);
    
    ledcWrite(BUZZER_CHANNEL, vol);
    ledcWriteTone(BUZZER_CHANNEL, freq);
    delay(stepTime);
  }
  
  ledcWriteTone(BUZZER_CHANNEL, 0);
  ledcWrite(BUZZER_CHANNEL, 0);
}

// Sharp attack (percussive, punchy)
void playAttack(int freq, int startVol, int peakVol, int attackTime, int decayTime) {
  // Instant attack
  for (int i = 0; i <= 5; i++) {
    int vol = map(i, 0, 5, startVol, peakVol);
    ledcWrite(BUZZER_CHANNEL, vol);
    ledcWriteTone(BUZZER_CHANNEL, freq);
    delay(attackTime / 5);
  }
  
  // Sharp decay
  for (int i = 10; i >= 0; i--) {
    int vol = map(i, 0, 10, startVol, peakVol);
    ledcWrite(BUZZER_CHANNEL, vol);
    ledcWriteTone(BUZZER_CHANNEL, freq);
    delay(decayTime / 10);
  }
  
  ledcWriteTone(BUZZER_CHANNEL, 0);
  ledcWrite(BUZZER_CHANNEL, 0);
}

// Fast fade in (aggressive)
void playFadeIn(int freq, int startVol, int endVol, int duration) {
  int steps = 20; // Fast
  int stepTime = duration / steps;
  
  ledcWriteTone(BUZZER_CHANNEL, freq);
  
  for (int i = 0; i <= steps; i++) {
    int vol = map(i, 0, steps, startVol, endVol);
    ledcWrite(BUZZER_CHANNEL, vol);
    delay(stepTime);
  }
  
  ledcWriteTone(BUZZER_CHANNEL, 0);
  ledcWrite(BUZZER_CHANNEL, 0);
}

// Fast fade out
void playFadeOut(int freq, int startVol, int endVol, int duration) {
  int steps = 20;
  int stepTime = duration / steps;
  
  ledcWriteTone(BUZZER_CHANNEL, freq);
  
  for (int i = steps; i >= 0; i--) {
    int vol = map(i, 0, steps, endVol, startVol);
    ledcWrite(BUZZER_CHANNEL, vol);
    delay(stepTime);
  }
  
  ledcWriteTone(BUZZER_CHANNEL, 0);
  ledcWrite(BUZZER_CHANNEL, 0);
}

// =============================================================================
// HIGH-PITCH LOUD SOUND PROFILES
// =============================================================================

void playBootLoud() {
  // Energetic high-pitch startup sequence
  int notes[] = {2093, 2637, 3136, 4186, 5274}; // C7, E7, G7, C8, E8
  int durations[] = {100, 100, 100, 200, 400};
  
  for (int i = 0; i < 5; i++) {
    playAttack(notes[i], VOL_OFF, VOL_MAX, 5, durations[i]);
    delay(30);
  }
  // Final power chord
  playTone(8372, 600, VOL_MAX); // C9
}

void playKeypressLoud() {
  // Sharp mechanical click (high freq, short)
  playAttack(4000, VOL_OFF, VOL_MAX, 2, 30);
  delay(10);
  playAttack(3000, VOL_OFF, VOL_LOUDER, 2, 40);
}

void playSuccessLoud() {
  // Triumphant high-pitch fanfare
  playAttack(4186, VOL_OFF, VOL_MAX, 5, 150); // C8
  delay(50);
  playAttack(5274, VOL_OFF, VOL_MAX, 5, 150); // E8
  delay(50);
  playAttack(6272, VOL_OFF, VOL_MAX, 5, 300); // G8
  delay(100);
  playAttack(8372, VOL_OFF, VOL_MAX, 5, 600); // C9 (very high!)
  
  // Victory shimmer
  for (int i = 0; i < 3; i++) {
    delay(100);
    playTone(10000 + (i * 500), 80, VOL_LOUD);
  }
}

void playErrorLoud() {
  // Harsh alarm pattern (dissonant high frequencies)
  for (int cycle = 0; cycle < 3; cycle++) {
    // Dissonant pair
    playTone(3000, 300, VOL_MAX);
    playTone(2900, 300, VOL_MAX); // Beating effect
    
    // Sharp warning beeps
    for (int i = 0; i < 3; i++) {
      playAttack(5000, VOL_OFF, VOL_MAX, 2, 100);
      delay(100);
    }
    delay(200);
  }
  // Low-high siren finish
  playSwell(2000, 6000, VOL_LOUD, VOL_MAX, 1000);
}

void playDetectLoud() {
  // Laser/sci-fi detection sound
  // Rapid sweep up
  for (int freq = 2000; freq <= 8000; freq += 500) {
    playTone(freq, 40, VOL_MAX);
  }
  // High pitch hold
  playTone(10000, 200, VOL_MAX);
  // Echo decay
  playFadeOut(8000, VOL_MAX, VOL_OFF, 600);
}

void playSiren() {
  // European police siren (high pitch)
  for (int i = 0; i < 5; i++) {
    playSwell(3000, 5000, VOL_LOUD, VOL_MAX, 400);
    playSwell(5000, 3000, VOL_MAX, VOL_LOUD, 400);
  }
}