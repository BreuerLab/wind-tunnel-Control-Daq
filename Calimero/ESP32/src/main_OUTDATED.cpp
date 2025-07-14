#include <Arduino.h> // needed for dacWrite
#include "AS5600.h"
#include "Wire.h"
#include "Adafruit_INA3221.h"

// Define I2C pins and configuration
#define AS1_SDA_PIN 21
#define AS1_SCL_PIN 22
#define AS1_FREQU_I2C 400000UL  // 800 kHz

// Define pins for the PWM and sense of rotation of the motor
#define ENA 27
#define IN1 34
#define IN2 35

#define DAC_POWER_OUT 26 // Power (goes to the DAQ)
#define DAC_POSITION_OUT 25  // Position (Goes to the DAQ)

#define PWM_CHANNEL 0
#define PWM_FREQ 5000
#define PWM_RESOLUTION 8

// Initialize second I2C bus
TwoWire as5600_I2C = TwoWire(1);       
AS5600 as5600_1 = AS5600(&as5600_I2C); 

// Global variables
int32_t initialAngle = 0;
int32_t counter = 0;
boolean initialize = true;

// Adding this global variable:
bool phaseInitiale = true;

int pwmValueAuto = 0;
unsigned long lastUpdateTime = 0;
bool started = false;

int32_t previousAngle = 0;
unsigned long previousTime = 0;

// === Sensor INA3221 ===
Adafruit_INA3221 ina3221;

// seting the max and min values for the PWM
int pwmValue = 0;
int pwmMin = 0;
int pwmMax = 255; // PWM max values seting up to 255 (0-255)

const int ticksPerOutputRevolution = 4096 * 9;  // 36864

void setup() {
  Serial.begin(115200);  // High-speed serial communication

  // -------------------------
  // ------ Motor Setup ------
  // -------------------------
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  // Set spin direction of motor
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);

  ledcSetup(PWM_CHANNEL, PWM_FREQ, PWM_RESOLUTION);
  ledcAttachPin(ENA, PWM_CHANNEL);
  ledcWrite(PWM_CHANNEL, pwmValue);

  // Initialize I2C
  as5600_I2C.begin(AS1_SDA_PIN, AS1_SCL_PIN, AS1_FREQU_I2C);
  as5600_1.begin();  // No need to specify SDA/SCL here
  as5600_I2C.setClock(AS1_FREQU_I2C); 
  delay(100);

  // INCLUDE CHECK IF MAGNET DETECTED
  if (as5600_1.detectMagnet()) {
    Serial.println("Encoder magnet detected")
  }

  // INA3221 setup
  if (!ina3221.begin(0x40, &as5600_I2C)) {
    Serial.println("INA3221 not detected !");
    while (1) delay(10);
  }
  ina3221.setAveragingMode(INA3221_AVG_16_SAMPLES);
  for (uint8_t i = 0; i < 3; i++) {
    ina3221.setShuntResistance(i, 0.05);
  }

  previousTime = millis();   // Initialize time tracking
  previousAngle = 0;         // Initial angle value

    // PHASE 1 : PWM at 0
  ledcWrite(PWM_CHANNEL, 0);
  delay(1000);

  // PHASE 2 : PWM at ~50 for 1 second
  ledcWrite(PWM_CHANNEL, 80);
  delay(500);

  // PHASE 3 : PWM at 0 and waiting for a keyboard key
  ledcWrite(PWM_CHANNEL, 0);
  Serial.println("Turn the motor by hand, then press a key in the serial monitor to continue...");

  // Wait for a character to be received
  while (Serial.available() == 0) {
    delay(10); // avoids overloading the CPU
  }
  Serial.read(); // reads and flushes the buffer

  

  // Optional: set offset and hysteresis
  as5600_1.setOffsetRAW(as5600_1.getAnglePos(true));
  as5600_1.setHysteresis(0);

  // PHASE 5 : PWM at 100 to start normally
  // Read the current angle
  uint16_t angleRAW = as5600_1.getAnglePos(true);              
  uint8_t quadrant = as5600_1.getQuadrant(angleRAW);            
  int32_t totalAngle = as5600_1.getTotalAngle(quadrant, angleRAW);

  Serial.println("=== Checking angle variables at initialization ===");
  Serial.print("angleRaw : ");
  Serial.println(angleRAW);

  Serial.println("==============================================");

  delay(1000);

  pwmValue = 0;
  ledcWrite(PWM_CHANNEL, pwmValue);

}

void loop() {
  counter++;

  // Read the current angle
  uint16_t angleRAW = as5600_1.getAnglePos(true);
  delay(1);              
  uint8_t quadrant = as5600_1.getQuadrant(angleRAW);            
  int32_t totalAngle = as5600_1.getTotalAngle(quadrant, angleRAW);

  // Initialize baseline angle after a short delay
  if (counter > 1000 && initialize) {
    uint16_t angle0 = as5600_1.getAnglePos(true);               
    uint8_t quadrant0 = as5600_1.getQuadrant(angle0);            
    initialAngle = as5600_1.getTotalAngle(quadrant0, angle0);
    initialize = false;
    previousAngle = initialAngle;   // Reseet for speed measurement
    previousTime = millis();
  }

  // === Lecture INA3221 ===
  float voltage = ina3221.getBusVoltage(1);            // in Volts
  float current = ina3221.getCurrentAmps(1)*1000;  // converted to mA

  // Convertir en plage 0–255 pour le DAC (8 bits)
  
  
  int x = map(totalAngle % ticksPerOutputRevolution, 0, ticksPerOutputRevolution - 1, 0, 255);
  int dacPowerOut = map((int)(voltage * current), 0, 5000, 0, 255);

  //dacPowerOut = constrain(dacPowerOut, 0, 255);
  // === Keyboard control for shutdown and restart with new PWM ===
  static String inputString = "";   // Stores user input
  static bool motorStopped = false;
  unsigned long currentTime = millis();


  if (Serial.available() > 0) {
    char c = Serial.read();
    
    if (c == 'p') {
      pwmValueAuto = 60;
      ledcWrite(PWM_CHANNEL, pwmValueAuto);
      lastUpdateTime = currentTime;
      started = true;
    }

    if (c == '0') {
      ledcWrite(PWM_CHANNEL, 0);  // Arrêt moteur
      motorStopped = true;
      inputString = "";           // Réinitialise la saisie
      Serial.println("Motor stopped. Enter a PWM value then '.' to restart.");
      started = false;
    }
    else if (motorStopped && isDigit(c)) {
      inputString += c;  // Accumule les chiffres de la PWM souhaitée
      Serial.print("PWM cible: ");
      Serial.println(inputString);
    }
    else if (motorStopped && c == '.') {
      int newPWM = inputString.toInt();
      newPWM = constrain(newPWM, pwmMin, pwmMax);  // Sécurité
      ledcWrite(PWM_CHANNEL, newPWM);
      pwmValue = newPWM;  // Updates the global pwmValue
      motorStopped = false;
      Serial.print("Motor restarted with PWM = ");
      Serial.println(newPWM);
      inputString = "";
    }
  }


  // Démarrage automatique de la montée en PWM


  // Augmentation toutes les 5 secondes après le premier palier
  if (started && (currentTime - lastUpdateTime >= 5000)) {
    pwmValueAuto += 10;
    ledcWrite(PWM_CHANNEL, pwmValueAuto);
    lastUpdateTime = currentTime;
  }


  // Sorties DAC (GPIO25 et GPIO26)
  dacWrite(DAC_POWER_OUT, dacPowerOut);
  dacWrite(DAC_POSITION_OUT, x);

  // Compute speed (in ticks per second)

  // float deltaTime = (currentTime - previousTime) / 1000.0;  // seconds
  
  // if (deltaTime > 0.0) {
  //   int32_t deltaAngle = totalAngle - previousAngle;
  //   float speed = deltaAngle / deltaTime;  // ticks/second

  //   // Affichage dans le moniteur série
  //   Serial.print("Speed [rot/s]: ");
  //   Serial.print(speed / (4096.0 * 9), 4);  // Affichage avec 4 décimales

  //   Serial.print(" | Voltage [V]: ");
  //   Serial.print(voltage, 2);              // 2 décimales

  //   Serial.print(" | Current [mA]: ");
  //   Serial.print(current, 1);              // 1 décimale

  //   Serial.print(" | Position (DAC): ");
  //   Serial.println(x);

  //   previousTime = currentTime;
  //   previousAngle = totalAngle;
  // }


}
