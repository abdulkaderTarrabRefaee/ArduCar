// برنامج اختبار بسيط لـ HC-05
// قم برفع هذا البرنامج على الأردوينو أولاً للاختبار

#include <SoftwareSerial.h>

// HC-05 على نفس البنات
SoftwareSerial BT(6, 7); // RX=6, TX=7

void setup() {
  Serial.begin(9600);    // للـ Serial Monitor
  BT.begin(9600);        // للـ HC-05

  Serial.println("=== HC-05 Test Program ===");
  Serial.println("Waiting for Bluetooth data...");
}

void loop() {
  // إذا وصلت بيانات من HC-05، اطبعها على Serial Monitor
  if (BT.available()) {
    String data = BT.readStringUntil('\n');
    Serial.print("Received from Bluetooth: ");
    Serial.println(data);

    // أرسل رد للتطبيق
    BT.println("OK");
  }

  // إذا كتبت شيء في Serial Monitor، أرسله للبلوتوث
  if (Serial.available()) {
    String data = Serial.readStringUntil('\n');
    BT.println(data);
    Serial.print("Sent to Bluetooth: ");
    Serial.println(data);
  }
}
