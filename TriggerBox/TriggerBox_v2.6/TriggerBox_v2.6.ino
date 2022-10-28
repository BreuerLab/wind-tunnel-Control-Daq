// Camera library
// Buzzer library (tone generator)
#include <toneAC.h>
/*  TriggerBox_2.5, 
    Trigger HSV;
    Flash LED and buzzer;
    with push trigger and/or motion triggering from TTL;

    Periodic flash and beep for machine vision cams to sync;
    Cam output shrinked 
    
    Siyang Hao
    20220413
    Brown, PVD
 v2.7
 
*/
// Pin Mapping
const int buttonPin = 2;   // the number of the Pushbutton pin
const int TTLPin =3;       // TTL trigger input pin, from motion
const int ledPin =  9;     // the number of the LED pin
const int buzzerPin = 6;   // the number of the Buzzer (Speaker) pin
const int cameraPin = 10;  // the number of the Camera pin, should be 10
const int gatePin = 8;     // Gate pin, should be 8, but Q&D test set to 10
// Variables
int buttonState ;         // variable for reading the pushbutton status
int TTLState;
int previous;
int stateLED;
long time = 0;
long debounce = 200;
int i;
int arm =0;
unsigned long previousMillis = 0;        // will store last time servo was updated
unsigned long currentMillis ;
const long interval = 5000;           // interval at which to run (milliseconds)

void setup() {
 int buttonState = LOW;         // variable for reading the pushbutton status
 int TTLState = LOW;         // variable for reading the TTL status
 int previous= LOW;
 int stateLED = LOW;
  // put your setup code here, to run once:
  Serial.begin(9600);
  // initialize the Pushbutton pin as an input:
  pinMode(buttonPin, INPUT);
  pinMode(TTLPin, INPUT);
  // initialize the LED pin as an output:
  pinMode(ledPin, OUTPUT);
  // initialize the Buzzer pin as an output:
  pinMode(buzzerPin, OUTPUT);
  // initialize the CAMERA as an output:
  pinMode(cameraPin, OUTPUT);

  pinMode(gatePin, OUTPUT);
}

void loop() {
  buttonState = digitalRead(buttonPin);
  TTLState = digitalRead(TTLPin);
  stateLED = LOW;
  digitalWrite(ledPin, stateLED);
  // initial triggering loop
    if(buttonState == HIGH||TTLState ==HIGH) { //system armed for recording
      stateLED = HIGH; 
      digitalWrite(ledPin, stateLED);  // turn on the LED
      digitalWrite(cameraPin, HIGH); // sets the cameraPin on
      delay(1);
      digitalWrite(cameraPin, LOW); // sets the cameraPin off
      // 3 Buzzer sounds
      tone(buzzerPin, 2000, 200);
      delay(100);
      
      
Serial.print("trigger pushed \n"); // for debuging 
 
      tone(buzzerPin, 2200, 200);
      delay(100);
      tone(buzzerPin, 2600, 200);
      delay(100);
      tone(buzzerPin, 2400, 200);
      delay(100);
      tone(buzzerPin, 2200, 200);
      delay(100);
      stateLED = LOW;
      digitalWrite(ledPin, stateLED);
      delay (500);
      if (arm ==0){
      arm =1;
      } else {
      arm =0; // disarm the routine beeping
      }
    }

    buttonState = LOW; // set button state back to low
    // routine perodic beeping
    currentMillis = millis();
    if (arm ==1){
      digitalWrite(gatePin, HIGH);
      if ( currentMillis - previousMillis >= interval) {
         previousMillis = currentMillis; // reset clock
         digitalWrite(ledPin, HIGH);
         tone(buzzerPin, 2200, 200);
         delay(100);
         tone(buzzerPin, 7200, 200);
         digitalWrite(ledPin, LOW);
         }
     } else {
       digitalWrite(gatePin, LOW);  
     }
    
}
