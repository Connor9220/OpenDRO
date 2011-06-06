/*
 * GLCDexample
 *
 * Basic test code for the Arduino KS0108 GLCD library.
 * This code exercises a range of graphic functions supported
 * by the library and is an example of its use.
 * It also gives an indication of performance, showing the
 *  number of frames drawn per second.  
 */

#include <Wire.h>
#include <IOexpander.h>

IOexpander IOexp;

#include <glcd.h>
#include "fonts/Arial14.h"         // proportional font
#include "fonts/SystemFont5x7.h"   // system font
#include "bitmaps/ArduinoIcon64x64.h"     // bitmap 

union u_tag {
    byte b[4];
    float ulval;
} u;

long prevMillis = 0;
long prevMillis2 = 0;
unsigned int loops = 0;
unsigned int iter = 0;
int ledState = LOW;    
int rotaryArray1[] = {
  306,409,512,614,717,819};
char axisArray[] = {
  'X','Y','Z','A'}; 
int rs1_prev = -1;
int offTrip = 0;
int rs1 = rotarySwitch(1,rotaryArray1,3);
volatile int axis = 0;
char axis_x;
volatile int stepPulse = 0 ;
volatile int e_value = 0;
volatile int c_value = 0;
volatile long multiplier = 1;
volatile int dir = 0;
volatile long encoder0Pos = 0;
long prev_value = 0;
long cc = 0;
long cc_old = 0;
volatile boolean PastA = 0;
volatile boolean PastB = 0;
#define encoder0PinA  2
#define encoder0PinB  3
#define TERMINATOR '!'
#define SEPARATOR ','
#define MAX_COMMAND_LENGTH 32
#define MAX_COMMANDS 16
#define MAX_MESSAGE MAX_COMMAND_LENGTH * MAX_COMMANDS
#define MAX_NUMBER_SIZE 9

byte commandArray[MAX_COMMAND_LENGTH];
byte messageArray[MAX_MESSAGE];
int commandArrayCount = 0;
int messageArrayCount = 0;
long myNum[MAX_NUMBER_SIZE]; // used by ATOI

void setup(){
  Serial.begin(115200);
  GLCD.Init(NON_INVERTED);   // initialise the library, non inverted writes pixels onto a clear screen
  GLCD.ClearScreen();  
  //GLCD.DrawBitmap(ArduinoIcon, 32,0, BLACK); //draw the bitmap at the given x,y position
  GLCD.SelectFont(System5x7); // switch to fixed width system font 
  //countdown(5); 
  //GLCD.ClearScreen();
  //introScreen();              // show some intro stuff 
  GLCD.ClearScreen();
  //GLCD.DefineArea(1,1,127,63);
  Wire.begin();

  if(IOexp.init(0x20, MCP23016))
    Serial.println("Communication with IOexpander works!");
  else
    Serial.println("No communication with the IOexpander!!");  

  IOexp.pinMode(0,0, OUTPUT); 
  IOexp.digitalWrite(0,0,HIGH);
  //IOexp.pinModePort(0, INPUT);   
  IOexp.pinMode(0,1, INPUT); 
  IOexp.pinMode(0,2, INPUT); 
  IOexp.pinMode(0,3, INPUT); 
  IOexp.pinMode(0,4, INPUT);   
  //pinMode(15, INPUT) ;

  pinMode(encoder0PinA, INPUT);
  //turn on pullup resistor
  //digitalWrite(encoder0PinA, HIGH); //ONLY FOR SOME ENCODER(MAGNETIC)!!!! 
  pinMode(encoder0PinB, INPUT); 
  //turn on pullup resistor
  //digitalWrite(encoder0PinB, HIGH); //ONLY FOR SOME ENCODER(MAGNETIC)!!!! 
  PastA = (boolean)digitalRead(encoder0PinA); //initial value of channel A;
  PastB = (boolean)digitalRead(encoder0PinB); //and channel B
  attachInterrupt(0, doEncoderA, CHANGE);
  attachInterrupt(1, doEncoderB, CHANGE); 

  GLCD.CursorTo(0,0);              // positon cursor  
  GLCD.Puts("X: 000.0000");               // print a text string
  GLCD.CursorTo(0,1);              // positon cursor  
  GLCD.Puts("Y: 000.0000");               // print a text string
  GLCD.CursorTo(0,2);              // positon cursor  
  GLCD.Puts("Z: 000.0000");               // print a text string
  GLCD.CursorTo(0,3);              // positon cursor  
  GLCD.Puts("A: 000.0000");               // print a text string

}

void introScreen(){
  GLCD.SelectFont(Arial_14); // you can also make your own fonts, see playground for details   
  GLCD.GotoXY(20, 2);
  GLCD.Puts("GLCD  version  ");
  GLCD.PrintNumber(GLCD_VERSION);
  GLCD.DrawRoundRect(16,0,99,18, 5, BLACK);  // rounded rectangle around text area   
  GLCD.SelectFont(System5x7); // switch to fixed width system font 
  showCharacters();
  //  countdown(5);
}

void showCharacters(){
  byte line = 3; // start on the fourth line 
  for(byte c = 32; c <=127; c++){
    if( (c-32) % 20 == 0)
      GLCD.CursorTo(1,line++);  // CursorTo is used for fixed width system font
    GLCD.PutChar(c);    
  }   
}


void displayDRO(int axis,char cmd)
{
    GLCD.CursorTo(0,axis);              // positon cursor  
    GLCD.Printf("%c:",cmd);
      for(int i = 0; i < commandArrayCount-1; i++)
      {
        // skip the first element 'n' in the array 
        //myNum[i] = commandArray[i+1];
        GLCD.Printf("%c",commandArray[i+1]);
      }
}
void  loop(){   // run over and over again
  iter = 0;
  long outd;
  long outx;
  
  
long current_value = encoder0Pos;
 if (current_value != prev_value & (current_value % 4) == 0  )
 {
   if (dir == 1)
     Serial.print("P");
   else
     Serial.print("M");  
   prev_value = current_value;
 }
  
  
  
  rs1 = rotarySwitch(1,rotaryArray1,4);
  if (rs1 == 0) {
    if (rs1 != rs1_prev) {
      GLCD.ClearScreen();
      GLCD.SelectFont(Arial_14);
      GLCD.GotoXY(55, 25);
      GLCD.Printf("OFF");
      GLCD.SelectFont(System5x7);
      offTrip = -1;
    }      

    if( millis() - prevMillis > 2000 && offTrip == -1){ // loop for one second
      prevMillis = millis();      
      GLCD.ClearScreen();
      IOexp.digitalWrite(0,0,LOW);
      offTrip = 0;
    }      
    rs1_prev = rs1;         
  } 
  else {

  if (rs1 != rs1_prev) {
    if (rs1 == 1) {
      Serial.print("X");
    } 
    else if (rs1== 2) { 
      Serial.print("Y");      
    }
    else if (rs1 == 3) {
      Serial.print("Z");            
    } 
    else if (rs1 == 4) {
    }
  }
    if (1 ^ IOexp.digitalRead(0,1) == 1) {
      multiplier = 25000;
      Serial.print("M1");
    } 
    else if (1 ^ IOexp.digitalRead(0,2) == 1) { 
      multiplier = 2500; 
     Serial.print("M2");
    }
    else if (1 ^ IOexp.digitalRead(0,3) == 1) {
      multiplier = 250;
     Serial.print("M3");      
    } 
    else if (1 ^ IOexp.digitalRead(0,4) ==1) {
      multiplier = 25;
     Serial.print("M4");      
    }    

    if(Serial.available() > 6) {
      Serial.read();
      axis_x = Serial.read(); 
      
      if (axis_x == 'X')
        axis = 0;
      else if(axis_x == 'Y')
        axis = 1;
      else if(axis_x == 'Z')
        axis = 2;
      else if(axis_x == 'A')
        axis = 3;

      GLCD.CursorTo(0,axis);              // positon cursor        
       GLCD.print(axis_x);
       GLCD.print(":");

      
      u.b[0] = Serial.read();
      u.b[1] = Serial.read();
      u.b[2] = Serial.read();
      u.b[3] = Serial.read();
      Serial.read();    
     
      if (abs(u.ulval) < 10) 
        GLCD.Printf("  ");
      else if (abs(u.ulval) < 100) 
        GLCD.Printf(" ");        

      if (u.ulval < 0) {
        GLCD.Printf("");
      }
      else{
        GLCD.Printf(" ");
      }      
      
      GLCD.print(u.ulval,4);
      cc_old = cc;
   }      

    prevMillis = millis();      
    if (rs1 != rs1_prev && rs1_prev == 0) {
      GLCD.ClearScreen();
      IOexp.digitalWrite(0,0,HIGH);
    }
    else if (rs1 != rs1_prev) {
      GLCD.CursorTo(11,rs1_prev-1);
      GLCD.Printf(" ");
      if(rs1 != -1) {
        GLCD.CursorTo(11,rs1-1);
        GLCD.Printf("<");
      }  
    }
    rs1_prev = rs1;

    GLCD.CursorTo(12,0);              // positon cursor  
    GLCD.Puts("FRO: 100%");               // print a text string

    GLCD.CursorTo(12,1);              // positon cursor  
    GLCD.Puts("SRO: 100%");               // print a text string

    GLCD.CursorTo(12,2);              // positon cursor  
    GLCD.Puts("VEL: 200");               // print a text string

    GLCD.DefineArea(0,32,127,32);

//    GLCD.CursorTo(0,7);              // positon cursor  
//    GLCD.Puts("x1");               // print a text strin//g

//    GLCD.CursorTo(5,7);              // positon cursor  
  //  GLCD.Puts("x10 ");               // print a text string

    //GLCD.CursorTo(10,7);              // positon cursor  
//    GLCD.Puts("x100");               // print a text string

  //  GLCD.CursorTo(15,7);              // positon cursor  
//    GLCD.Puts("x10005");               // print a text string

    GLCD.CursorTo(12,4);
    GLCD.Printf("%i%i%i%i",1 ^ IOexp.digitalRead(0,1),1 ^ IOexp.digitalRead(0,2),1 ^ IOexp.digitalRead(0,3),1 ^ IOexp.digitalRead(0,4));
  }  
}


int rotarySwitch(int rotaryPin, int rotaryArray[], int Pos) {
  int rawVal = analogRead(rotaryPin);
  //Serial.println(rawVal);
  int i;
  for(i = 0; i <= Pos; i++)
  {
    if (rawVal > (rotaryArray[i]-25) and rawVal < (rotaryArray[i]+25)) {
      return i;
    }
  } 
  return -1;
}

void doEncoderA(){
  // look for a low-to-high on channel A
  boolean encoder0PinA_state = digitalRead(encoder0PinA);
  boolean encoder0PinB_state = digitalRead(encoder0PinB);  
  if (encoder0PinA_state == HIGH) { 
    // check channel B to see which way encoder is turning
    if (encoder0PinB_state == LOW) {  
      encoder0Pos += 1; // CW
      dir = 1;
      if (stepPulse == 3)
        stepPulse = 0;
      else
        stepPulse += 1;      
    } 
    else {
      encoder0Pos -= 1;// CCW
      dir = 0;
      if (stepPulse == 0)
        stepPulse = 3;
      else
        stepPulse -= 1;      
    }
  }

  else   // must be a high-to-low edge on channel A                                       
  { 
    // check channel B to see which way encoder is turning  
    if (encoder0PinB_state == HIGH) {   
      encoder0Pos += 1; // CW
      dir = 1;
      if (stepPulse == 3)
        stepPulse = 0;
      else
        stepPulse += 1;      
    } 
    else {
      encoder0Pos -= 1;  // CCW
      dir = 0;
      if (stepPulse == 0)
        stepPulse = 3;
      else
        stepPulse -=1;      

    }
  }  
}

void doEncoderB(){
  // look for a low-to-high on channel B
  boolean encoder0PinA_state = digitalRead(encoder0PinA);
  boolean encoder0PinB_state = digitalRead(encoder0PinB);  
  if (encoder0PinB_state == HIGH) {   
    // check channel A to see which way encoder is turning
    if (encoder0PinA_state == HIGH) {  
      dir = 1;
      encoder0Pos += 1;  // CW
      if (stepPulse == 3)
        stepPulse = 0;
      else
        stepPulse += 1;      

    } 
    else {
      dir = 0;
      encoder0Pos -= 1;// CCW
      if (stepPulse == 0)
        stepPulse = 3;
      else
        stepPulse -=1;      
    }
  }
  // Look for a high-to-low on channel B

  else { 
    // check channel B to see which way encoder is turning  
    if (encoder0PinA_state == LOW) {   
      encoder0Pos += 1;// CW
      dir = 1;
      if (stepPulse == 3)
        stepPulse = 0;
      else
        stepPulse += 1;      
    } 
    else {
      encoder0Pos -= 1;// CCW
      dir = 0;
      if (stepPulse == 0)
        stepPulse = 3;
      else
        stepPulse -= 1;      
    }
  }
} 

// ASCII TO Integer

int ATOI()
{   
  // algorithm from atoi() in C standard library   
  int i = 0;
  long n = 0;
  for(i = 0; myNum[i] >= '0' && myNum[i] <= '9'; ++i)
    n = 10 * n + (myNum[i] - '0');
  return(n);  
}







