#include <SoftwareSerial.h>

SoftwareSerial BT(6, 7); // (RX, TX)

#define ENA 9
#define IN1 2
#define IN2 3
#define IN3 4
#define IN4 5
#define ENB 10

String inputString = "";
int joyX = 0, joyY = 0, joyZ = 0;

unsigned long lastCommandTime = 0;
const unsigned long TIMEOUT_MS = 500;

// ========== متغيرات وضع الكيبورد ==========
char activeKey = 0;                  // الزر النشط حالياً (w/a/s/d) أو 0 إذا لا شيء
unsigned long keyPressStart = 0;     // وقت بدء ضغط الزر
const unsigned long RAMP_DURATION = 2000; // 2 ثانية للوصول للسرعة القصوى
const int MIN_PWM = 60;              // الحد الأدنى لتحريك المحركات
const int MAX_PWM = 255;             // السرعة القصوى
unsigned long lastKeyTime = 0;       // آخر مرة وصل فيها أمر كيبورد
const unsigned long KEY_TIMEOUT = 600; // إذا لم يصل الأمر خلال 600ms => توقف

void setup() {
    pinMode(ENA, OUTPUT);
    pinMode(ENB, OUTPUT);
    pinMode(IN1, OUTPUT);
    pinMode(IN2, OUTPUT);
    pinMode(IN3, OUTPUT);
    pinMode(IN4, OUTPUT);

    Serial.begin(9600);
    BT.begin(9600);

    stopCar();
    inputString.reserve(30);

    Serial.println("=== Arduino Ready ===");
    Serial.println("Modes:");
    Serial.println("  Keyboard: w/a/s/d (ramp up 2s), c=stop");
    Serial.println("  Joystick: X,Y,Z");
}

void loop() {
    while (BT.available()) {
        char c = BT.read();

        if (c == '\n') {
            processInput(inputString);
            inputString = "";
        } else if (c != '\r') {
            inputString += c;
        }
    }

    // ========== تحديث السرعة الأسية إذا كان زر مضغوط ==========
    if (activeKey != 0) {
        updateRampSpeed();

        // إذا انقطع إرسال أمر الكيبورد لأكثر من KEY_TIMEOUT => توقف
        if (millis() - lastKeyTime > KEY_TIMEOUT) {
            Serial.println(">>> Key timeout - stopping");
            activeKey = 0;
            stopCar();
        }
    }

    // الأمان للـ Joystick فقط
    if (activeKey == 0 && (joyX != 0 || joyY != 0)) {
        if (millis() - lastCommandTime > TIMEOUT_MS) {
            stopCar();
            joyX = 0; joyY = 0;
        }
    }
}

// ========== معالجة المدخلات ==========
void processInput(String data) {
    data.trim();
    if (data.length() == 0) return;

    Serial.print(">>> Received: \"");
    Serial.print(data);
    Serial.println("\"");

    // إذا كان حرفاً واحداً => أمر كيبورد
    if (data.length() == 1) {
        handleKeyCommand(data.charAt(0));
        return;
    }

    // غير ذلك => بيانات Joystick
    activeKey = 0; // إلغاء وضع الكيبورد
    parseJoystick(data);
}

// ========== معالجة أوامر الكيبورد ==========
void handleKeyCommand(char key) {
    // تحويل لحروف صغيرة
    if (key >= 'A' && key <= 'Z') key = key + 32;

    lastKeyTime = millis();

    // أمر التوقف
    if (key == 'c') {
        Serial.println("    [STOP]");
        activeKey = 0;
        stopCar();
        return;
    }

    // أوامر W/A/S/D
    if (key == 'w' || key == 'a' || key == 's' || key == 'd') {
        if (activeKey != key) {
            // زر جديد => إعادة تصفير المؤقت
            activeKey = key;
            keyPressStart = millis();
            Serial.print("    [NEW KEY] ");
            Serial.println(key);
        }
        // وإلا نفس الزر => المؤقت مستمر => السرعة تتزايد
    }
}

// ========== تحديث السرعة الأسية ==========
void updateRampSpeed() {
    unsigned long elapsed = millis() - keyPressStart;
    if (elapsed > RAMP_DURATION) elapsed = RAMP_DURATION;

    // المعادلة الأسية: progress = t² (تبدأ بطيئة وتتسارع)
    float progress = (float)elapsed / RAMP_DURATION;
    float eased = progress * progress;  // مربع => زيادة أسية

    int pwm = MIN_PWM + (int)(eased * (MAX_PWM - MIN_PWM));
    pwm = constrain(pwm, MIN_PWM, MAX_PWM);

    // طباعة السرعة كل 200ms
    static unsigned long lastPrint = 0;
    if (millis() - lastPrint > 200) {
        Serial.print("    Key=");
        Serial.print(activeKey);
        Serial.print(" elapsed=");
        Serial.print(elapsed);
        Serial.print("ms PWM=");
        Serial.println(pwm);
        lastPrint = millis();
    }

    // تطبيق السرعة على الاتجاه الصحيح
    switch (activeKey) {
        case 'w': moveForward(pwm);    break;
        case 's': moveBackward(pwm);   break;
        case 'd': turnLeft(pwm);       break;
        case 'a': turnRight(pwm);      break;
    }
}

// ========== دوال الحركة المباشرة (للكيبورد) ==========
void moveForward(int pwm) {
    digitalWrite(IN1, HIGH); digitalWrite(IN2, LOW);
    digitalWrite(IN3, HIGH); digitalWrite(IN4, LOW);
    analogWrite(ENA, pwm);
    analogWrite(ENB, pwm);
}

void moveBackward(int pwm) {
    digitalWrite(IN1, LOW); digitalWrite(IN2, HIGH);
    digitalWrite(IN3, LOW); digitalWrite(IN4, HIGH);
    analogWrite(ENA, pwm);
    analogWrite(ENB, pwm);
}

void turnLeft(int pwm) {
    digitalWrite(IN1, LOW);  digitalWrite(IN2, HIGH);
    digitalWrite(IN3, HIGH); digitalWrite(IN4, LOW);
    analogWrite(ENA, pwm);
    analogWrite(ENB, pwm);
}

void turnRight(int pwm) {
    digitalWrite(IN1, HIGH); digitalWrite(IN2, LOW);
    digitalWrite(IN3, LOW);  digitalWrite(IN4, HIGH);
    analogWrite(ENA, pwm);
    analogWrite(ENB, pwm);
}

// ========== وضع الـ Joystick ==========
void parseJoystick(String data) {
    int colonIndex = data.indexOf(':');
    if (colonIndex >= 0) data = data.substring(colonIndex + 1);

    int firstComma = data.indexOf(',');
    int secondComma = data.indexOf(',', firstComma + 1);

    if (firstComma == -1) return;

    joyX = data.substring(0, firstComma).toInt();
    if (secondComma == -1) {
        joyY = data.substring(firstComma + 1).toInt();
        joyZ = 0;
    } else {
        joyY = data.substring(firstComma + 1, secondComma).toInt();
        joyZ = data.substring(secondComma + 1).toInt();
    }

    Serial.print("    [JOY] X="); Serial.print(joyX);
    Serial.print(" Y="); Serial.print(joyY);
    Serial.print(" Z="); Serial.println(joyZ);

    driveCar(joyX, joyY);
    lastCommandTime = millis();
}

void driveCar(int x, int y) {
    int leftMotor  = y - x;
    int rightMotor = y + x;

    leftMotor  = constrain(leftMotor,  -100, 100);
    rightMotor = constrain(rightMotor, -100, 100);

    int leftPWM  = map(abs(leftMotor),  0, 100, 0, 255);
    int rightPWM = map(abs(rightMotor), 0, 100, 0, 255);

    if (leftPWM < 10 && rightPWM < 10) {
        stopCar();
        return;
    }

    if (leftMotor > 0)      { digitalWrite(IN1, HIGH); digitalWrite(IN2, LOW); }
    else if (leftMotor < 0) { digitalWrite(IN1, LOW);  digitalWrite(IN2, HIGH); }
    else                    { digitalWrite(IN1, LOW);  digitalWrite(IN2, LOW); }
    analogWrite(ENA, leftPWM);

    if (rightMotor > 0)      { digitalWrite(IN3, HIGH); digitalWrite(IN4, LOW); }
    else if (rightMotor < 0) { digitalWrite(IN3, LOW);  digitalWrite(IN4, HIGH); }
    else                     { digitalWrite(IN3, LOW);  digitalWrite(IN4, LOW); }
    analogWrite(ENB, rightPWM);
}

void stopCar() {
    analogWrite(ENA, 0);
    analogWrite(ENB, 0);
    digitalWrite(IN1, LOW);
    digitalWrite(IN2, LOW);
    digitalWrite(IN3, LOW);
    digitalWrite(IN4, LOW);
}