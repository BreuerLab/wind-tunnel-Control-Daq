// Camera library
// Buzzer library (tone generator)
#include <toneAC.h>

// Wave Generator library
// 

// Constants
const int buttonPin = 2;     // the number of the Pushbutton pin
const int digtalPin =
const int ledPin =  9;      // the number of the LED pin
const int buzzerPin = 6;   // the number of the Buzzer (Speaker) pin
const int cameraPin = 10;   // the number of the Camera pin

// Variables
int buttonState ;         // variable for reading the pushbutton status
 int previous;
 int stateLED;
long time = 0;
long debounce = 200;
int i;

void setup() {
 int buttonState = LOW;         // variable for reading the pushbutton status
 int previous;
 int stateLED = LOW;
  // put your setup code here, to run once:
  Serial.begin(9600);

  // initialize the Pushbutton pin as an input:
  pinMode(buttonPin, INPUT);
  
  // initialize the LED pin as an output:
  pinMode(ledPin, OUTPUT);

  // initialize the Buzzer pin as an output:
  pinMode(buzzerPin, OUTPUT);

  // initialize the CAMERA, WAVE, BUZZER as an output:
}

void loop() {
  buttonState = digitalRead(buttonPin);
  stateLED = LOW;
  digitalWrite(ledPin, stateLED);
  
    if(buttonState == HIGH) {
      stateLED = HIGH; 
      digitalWrite(ledPin, stateLED);  // turn on the LED
      digitalWrite(cameraPin, HIGH); // sets the cameraPin on
      // 3 Buzzer sounds
      tone(buzzerPin, 2000, 200);
      delay(100);
      digitalWrite(cameraPin, LOW); // sets the cameraPin off
      
//Serial.print("trigger pushed \n"); //disabled execpt for debug, this is slow.
 
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
    }

    buttonState = LOW;
}
