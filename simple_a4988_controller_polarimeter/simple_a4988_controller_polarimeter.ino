#include <math.h>

// simple a4988 controller

const int stepPin     = 3;
const int dirPin      = 2;
const int enPin       = 7;

const int shutterPin  = 6;

float microStepRes = 8.;
float stepsPerRev   = (200.*microStepRes)*2.;
int steps;
float angleState  = 0.0;
float dAngle;
float targetAngle;
float dir;
int interStep_dt = 800;

const int zero_button_pin = 4;
const int trig_button_pin = 5;
volatile int zero_buttonVal;
volatile int trig_buttonVal;

void setup() {
  // put your setup code here, to run once:
  pinMode(stepPin,OUTPUT);
  pinMode(dirPin,OUTPUT);
  pinMode(enPin,OUTPUT);  
  digitalWrite(enPin,LOW);
  
  pinMode(zero_button_pin,INPUT_PULLUP);
  pinMode(trig_button_pin,INPUT_PULLUP);

  pinMode(shutterPin,OUTPUT);
  digitalWrite(shutterPin,HIGH);

  Serial.begin(115200);
}


void loop() {

  /////// zero the device ///////
  zero_buttonVal = digitalRead(zero_button_pin);  
  while (zero_buttonVal==0){
    buttonZero();
    zero_buttonVal = digitalRead(zero_button_pin);  
    Serial.println(zero_buttonVal);
  }

  /////// triger routine ///////
  trig_buttonVal = digitalRead(trig_button_pin);  
  while (trig_buttonVal==0){
    delay(100);
    trig_buttonVal = digitalRead(trig_button_pin);
    if(trig_buttonVal==1){

      for(targetAngle = 0.; targetAngle <= 135.; targetAngle = targetAngle+45.){

        movetoangle();
        delay(1000);
//        printData();
          
        // trigger shutter by writing shutterPin low
        digitalWrite(shutterPin,LOW);
        delay(200);
        digitalWrite(shutterPin,HIGH);
        delay(100);
      }

      // return to zero
      targetAngle = 0.;
      movetoangle();
      
    }
  }
//  printData();
  delay(100);


}

void printData(){
          Serial.print("angleState = ");
          Serial.print(angleState);
          Serial.print(", target = ");
          Serial.print(targetAngle);
          Serial.print(", dAngle = ");
          Serial.print(dAngle);
          Serial.print(", steps = ");
          Serial.print(steps);
          Serial.println(", moved a step");
}

void buttonZero(){
      digitalWrite(dirPin, HIGH);

      digitalWrite(stepPin, HIGH);
      delayMicroseconds(800);
      digitalWrite(stepPin, LOW);
      delayMicroseconds(2000);

      angleState = 0;  
   
}

void movetoangle(){
  dir = 1.;
  digitalWrite(dirPin, LOW);
  
  dAngle  = targetAngle - angleState;
  if (dAngle < 0){
    dir = -1.;
    digitalWrite(dirPin, HIGH);
  }
  steps   = (abs(dAngle)/360.) * stepsPerRev;
  
  for (int x = 1; x <= steps; x++){  
    
    digitalWrite(stepPin, HIGH);
    delayMicroseconds(interStep_dt);
    digitalWrite(stepPin, LOW);
    delayMicroseconds(interStep_dt);
  
    angleState = fmodf(angleState + dir*360./stepsPerRev,360.);
  
//  printData();
    
  }
}
