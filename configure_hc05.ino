// برنامج لضبط HC-05 على 9600 baud واسم معيّن
// استخدم هذا البرنامج مرة واحدة فقط لإعداد HC-05

#include <SoftwareSerial.h>

SoftwareSerial BT(6, 7);

void setup() {
  Serial.begin(9600);

  // جرب الاتصال بسرعات مختلفة
  long rates[] = {9600, 38400};

  for(int i = 0; i < 2; i++) {
    Serial.print("Trying ");
    Serial.println(rates[i]);

    BT.begin(rates[i]);
    delay(1000);

    // جرب أمر AT
    BT.print("AT\r\n");
    delay(100);

    if(BT.available()) {
      Serial.println("HC-05 found!");

      // اضبط الاسم
      BT.print("AT+NAME=ArduinoCar\r\n");
      delay(100);
      Serial.println("Setting name to: ArduinoCar");

      // اضبط Baud rate على 9600
      BT.print("AT+UART=9600,0,0\r\n");
      delay(100);
      Serial.println("Setting baud rate to: 9600");

      // اطبع الرد
      while(BT.available()) {
        Serial.write(BT.read());
      }

      Serial.println("\nDone! HC-05 is configured.");
      Serial.println("Name: ArduinoCar");
      Serial.println("Baud: 9600");
      Serial.println("\nNow upload arduino.ino");

      while(1); // توقف
    }
  }

  Serial.println("Could not connect to HC-05");
  Serial.println("Make sure EN pin is HIGH (3.3V) during configuration");
}

void loop() {
}
