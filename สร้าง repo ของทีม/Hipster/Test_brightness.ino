#include <Wire.h>
#include "MAX30105.h"
#include "spo2_algorithm.h"

MAX30105 sensor;

#define BUFFER_SIZE 100

uint32_t irBuffer[BUFFER_SIZE];
uint32_t redBuffer[BUFFER_SIZE];

int32_t spo2;
int32_t heartRate;
int8_t validSpO2;
int8_t validHeartRate;

// ไล่ brightness
int brightnessList[] = {10, 20, 30, 50, 80};
int idx = 0;

void setup() {
  Serial.begin(115200);
  Wire.begin(21, 22);

  if (!sensor.begin(Wire, I2C_SPEED_FAST)) {
    Serial.println("MAX30102 not found!");
    while (1);
  }

  Serial.println("=== Brightness + BPM + SpO2 Test ===");
}

void loop() {

  int b = brightnessList[idx];

  // 👉 ตั้งค่าใหม่ทุกครั้ง
  sensor.setup(b, 4, 2, 100, 411, 4096);

  Serial.println("\n=======================");
  Serial.print("Brightness: ");
  Serial.println(b);

  delay(1000);

  // เก็บ sample
  for (int i = 0; i < BUFFER_SIZE; i++) {
    while (!sensor.available())
      sensor.check();

    redBuffer[i] = sensor.getRed();
    irBuffer[i]  = sensor.getIR();

    sensor.nextSample();
  }

  // เช็คนิ้ว
  if (irBuffer[BUFFER_SIZE - 1] < 10000) {
    Serial.println("❌ No finger");
  } else {

    // คำนวณ BPM + SpO2
    maxim_heart_rate_and_oxygen_saturation(
      irBuffer,
      BUFFER_SIZE,
      redBuffer,
      &spo2,
      &validSpO2,
      &heartRate,
      &validHeartRate
    );

    Serial.print("IR  : ");
    Serial.println(irBuffer[BUFFER_SIZE - 1]);

    Serial.print("RED : ");
    Serial.println(redBuffer[BUFFER_SIZE - 1]);

    if (validHeartRate) {
      Serial.print("BPM  : ");
      Serial.println(heartRate);
    } else {
      Serial.println("BPM  : Invalid");
    }

    if (validSpO2) {
      Serial.print("SpO2 : ");
      Serial.print(spo2);
      Serial.println(" %");
    } else {
      Serial.println("SpO2 : Invalid");
    }
  }

  // ไป brightness ถัดไป
  idx++;
  if (idx >= 5) idx = 0;

  delay(3000);
}