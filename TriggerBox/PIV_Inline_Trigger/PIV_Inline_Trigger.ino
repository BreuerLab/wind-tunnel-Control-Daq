/*  Inline Trigger
 *  inline trigger box for PIV sync,
 *  receive a TTL plus from upstream(Galil), out put 20 even distributed TTL pulses in 100 ms
 *  the timer is not blocked during the process for improved accurcy

 *  Siyang Hao
 *  20211008
 *  Brown, PVD 
 * 
*/

unsigned long t1 = 0;        // will store time since start is set
unsigned long start =0;
unsigned long laststart;
int freq;
// The value will quickly become too large for an int to store
// constants won't change :
const long interval = 5;           // interval at which to run (milliseconds)

const int masterPin = 2; //pin mapping
const int slavePin = 10;
int  lastmasterState = HIGH;
int masterState = HIGH;    // variable to store the master trigger signal
int t2 = 5000; // microsecond laser interval

void setup() {
  
  Serial.begin(9600); // open the serial port at 9600 bps:
  // initialize the master pin as an input:
  pinMode(masterPin, INPUT);
  
  // initialize the slave pin as an output:
  pinMode(slavePin, OUTPUT);
}

void loop() {
  masterState = digitalRead(masterPin);        // read upstream signal, high before triggered, stay low after triggered
  if (masterState != lastmasterState) {        // reset start time on falling edge
    if( masterState == LOW) {                  //compare state to find falling edge
     laststart = start;                        // for debuging
     freq = 1/(start-laststart);
     Serial.print(freq);
     Serial.println();
     start = micros();                         // reset start time
    
    }
   } 
   lastmasterState = masterState;             //reset master state
   t1 = micros()-start;                       //acquiring  time
   while( t1%t2<2000) {
   digitalWrite(slavePin,HIGH);               //write output
   }
   digitalWrite(slavePin,LOW); 
   
}
