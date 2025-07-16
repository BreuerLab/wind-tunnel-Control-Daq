#include <Arduino.h>
#include "AS5600.h"
#include "Wire.h"
#include "Adafruit_INA3221.h"

// Define I2C pins and configuration
#define AS1_SDA_PIN 21
#define AS1_SCL_PIN 22
#define AS1_FREQU_I2C 100000UL  // 800 kHz

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

// Ajout de cette variable globale :
bool phaseInitiale = true;


int pwmValueAuto = 0;
unsigned long lastUpdateTime = 0;
bool started = false;

int32_t previousAngle = 0;
unsigned long previousTime = 0;

// === Sensor INA3221 ===
Adafruit_INA3221 ina3221;

//seting the max and min values for the PWM
int pwmValue = 0;
int pwmMin = 0;
int pwmMax = 255; //PWM max values seting up to 255 (0-255)

const int ticksPerOutputRevolution = 4096 * 9;  // 36864

bool retourZero = false;
const int pwmRetourZero = 50;        // Petite PWM lente pour retour
const int seuilErreurAngle = 5;      // Tolérance autour de la cible

void setup() {
  Serial.begin(115200);  // High-speed serial communication

  // Moteur
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  ledcSetup(PWM_CHANNEL, PWM_FREQ, PWM_RESOLUTION);
  ledcAttachPin(ENA, PWM_CHANNEL);
  ledcWrite(PWM_CHANNEL, pwmValue);

    previousTime = millis();   // Initialize time tracking
  previousAngle = 0;         // Initial angle value

    // PHASE 1 : PWM à 0
  ledcWrite(PWM_CHANNEL, 0);
  delay(1000);

  // PHASE 2 : PWM à ~50 pendant 1 seconde
  ledcWrite(PWM_CHANNEL, 0);
  delay(5000);

  // PHASE 3 : PWM à 0 et attente d'une touche clavier
  ledcWrite(PWM_CHANNEL, 0);
  

  // // Attend qu'un caractère soit reçu
  // while (Serial.available() == 0) {
  //   delay(10); // évite de surcharger la CPU
  // }
  Serial.read(); // lit et vide le buffer


    // Initialize I2C
  as5600_I2C.begin(AS1_SDA_PIN, AS1_SCL_PIN, AS1_FREQU_I2C);
  as5600_1.begin();  // No need to specify SDA/SCL here
  as5600_I2C.setClock(AS1_FREQU_I2C); 
  delay(100);


  // INA3221 setup
  if (!ina3221.begin(0x40, &as5600_I2C)) {
    Serial.println("INA3221 not detected !");
    while (1) delay(10);
  }
  ina3221.setAveragingMode(INA3221_AVG_16_SAMPLES);
  for (uint8_t i = 0; i < 3; i++) {
    ina3221.setShuntResistance(i, 0.05);
  }


  // Optional: set offset and hysteresis
  as5600_1.setOffsetRAW(as5600_1.getAnglePos(true));
  as5600_1.setHysteresis(0);

  // PHASE 5 : PWM à 100 pour démarrer normalement
    // Read the current angle
  uint16_t angleRAW = as5600_1.getAnglePos(true);          
  uint8_t quadrant = as5600_1.getQuadrant(angleRAW);            
  int32_t totalAngle = as5600_1.getTotalAngle(quadrant, angleRAW);

  Serial.print("angleRaw : ");
  Serial.println(angleRAW);

  delay(1000);

  pwmValue = 0;
  ledcWrite(PWM_CHANNEL, pwmValue);

  Serial.println("ESP32 SETUP");

}

void loop() {
  counter++;

  // Read the current angle
  uint16_t angleRAW = as5600_1.getAnglePos(true);           
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
  delay(1);

  // Convertir en plage 0–255 pour le DAC (8 bits)
  
  int x = map(totalAngle % ticksPerOutputRevolution, 0, ticksPerOutputRevolution - 1, 0, 255);

  
  // === Contrôle clavier pour arrêter et redémarrer avec nouvelle PWM ===
  static String inputString = "";   // Stocke l'entrée utilisateur
  static bool moteurArrete = false;
  unsigned long currentTime = millis();


  if (Serial.available() > 0) {
    char c = Serial.read();
    
    if (c == 'z') {
      retourZero = true;
      ledcWrite(PWM_CHANNEL,90);
      delay(10);
      ledcWrite(PWM_CHANNEL, pwmRetourZero);  // Démarre doucement
      // Serial.println("Retour vers angle initial...");
    }

    if (c == 'p') {
      pwmValueAuto = 60;
      ledcWrite(PWM_CHANNEL, pwmValueAuto);
      lastUpdateTime = currentTime;
      started = true;
    }

    if (c == 's') {
      ledcWrite(PWM_CHANNEL, 0);  // Arrêt moteur
      moteurArrete = true;
      inputString = "";           // Réinitialise la saisie
      // Serial.println("Moteur arrêté. Entrez une valeur PWM puis '.' pour redémarrer.");
      started = false;
    }
    else if (moteurArrete && isDigit(c)) {
      inputString += c;  // Accumule les chiffres de la PWM souhaitée
      // Serial.print("PWM cible: ");
      // Serial.println(inputString);
    }
    else if (moteurArrete && c == '.') {
      int newPWM = inputString.toInt();
      newPWM = constrain(newPWM, pwmMin, pwmMax);  // Sécurité
      ledcWrite(PWM_CHANNEL, newPWM);
      pwmValue = newPWM;  // Met à jour le pwmValue global
      moteurArrete = false;
      // Serial.print("Moteur redémarré avec PWM = ");
      // Serial.println(newPWM);
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

  if (retourZero) {
    // Lire angle actuel
   
    int32_t erreur = totalAngle % ticksPerOutputRevolution;  // Distance au multiple
    // On veut que l'erreur soit proche de 0 ou de 36864
    if (erreur < seuilErreurAngle || abs(erreur - ticksPerOutputRevolution) < seuilErreurAngle) {
      ledcWrite(PWM_CHANNEL, 0);  // Stop moteur
      retourZero = false;

      //Corrige la référence ici
      uint16_t angle0 = as5600_1.getAnglePos(true);
      uint8_t quadrant0 = as5600_1.getQuadrant(angle0);
      initialAngle = as5600_1.getTotalAngle(quadrant0, angle0);

      previousAngle = initialAngle;
      previousTime = millis();

      Serial.println("ZERO");
      // Serial.println(initialAngle);
    }

  }

  // Sorties DAC (GPIO25 et GPIO26)
  //dacWrite(DAC_POWER_OUT, dacPowerOut);
  dacWrite(DAC_POSITION_OUT, x);

}
