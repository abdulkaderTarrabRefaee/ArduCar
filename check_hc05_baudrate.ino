// برنامج للتحقق من Baud Rate الصحيح لـ HC-05
// جرب كل سرعة حتى يعمل

#include <SoftwareSerial.h>

SoftwareSerial BT(6, 7);

// جميع سرعات Baud الشائعة
long baudRates[] = {9600, 38400, 19200, 57600, 115200, 4800, 2400, 1200};
int numRates = 8;

void setup() {
  Serial.begin(9600);
  Serial.println("=== Testing HC-05 Baud Rates ===");
  Serial.println();

  for (int i = 0; i < numRates; i++) {
    Serial.print("Trying ");
    Serial.print(baudRates[i]);
    Serial.print(" baud... ");

    BT.begin(baudRates[i]);
    delay(100);

    // أرسل أمر AT للاختبار
    BT.print("AT\r\n");
    delay(100);

    if (BT.available()) {
      String response = "";
      while (BT.available()) {
        response += (char)BT.read();
      }
      Serial.print("SUCCESS! Response: ");
      Serial.println(response);
      Serial.println();
      Serial.print(">>> HC-05 is using ");
      Serial.print(baudRates[i]);
      Serial.println(" baud <<<");

      // توقف هنا
      while(1) {
        if (BT.available()) {
          Serial.write(BT.read());
        }
        if (Serial.available()) {
          BT.write(Serial.read());
        }
      }
    } else {
      Serial.println("No response");
    }

    delay(500);
  }

  Serial.println();
  Serial.println("Could not find HC-05 baud rate!");
  Serial.println("Check connections:");
  Serial.println("  HC-05 VCC  → Arduino 5V");
  Serial.println("  HC-05 GND  → Arduino GND");
  Serial.println("  HC-05 TXD  → Arduino Pin 6");
  Serial.println("  HC-05 RXD  → Arduino Pin 7");
}

void loop() {
  // لا شيء
}
