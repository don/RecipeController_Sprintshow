/* Mobile Lab class final project

Playcook a wearable cooking assistant

By Atharva Patil & Anna Oh - May 2019

Hardware used Arduino mkr 1010

*/

// Using the ArduinoBLE library for Bluetooth communication by advertising Arduino as a discoverable peripheral
#include <ArduinoBLE.h>
// Using Capacitive sensing library to check for touches against the fabric 
#include <CapacitiveSensor.h>

//#include <Scheduler.h> 

CapacitiveSensor   playPausePin = CapacitiveSensor(2,4);        //  resistor between pins 4 & 2. To check for interaction for play/pause
CapacitiveSensor   backwardScrubPin = CapacitiveSensor(2,5);        // 10M resistor between pins 4 & 6. To check for interaction for 10 sec backward scrub

const int videoScrubPin = A3;   // to scrub the video based on the chain position on the apron
const int audioScrubPin = A4;   // to control the audio of the iOS device.

int thisIsOn = 1;
int thisIsOff = 0;

//int ledPin = A6; // set ledPin to on-board LED
//const int buttonPin = 1; // set buttonPin to digital pin 1
//int potValue = 0;

// Creating a service which will act as the accessory advertiser & the primary service
BLEService apronService("4cc4513b-1b63-4c93-a419-dddaeae3fdc7"); 

// Creating Digital characteristics to allow remote device to get notifications

BLEByteCharacteristic playPauseCharacteristic("ef9534b9-2c24-4ddc-b9b2-fc690ecf4cb4", BLERead | BLENotify);
BLEByteCharacteristic backwardCharacteristic("9400449a-cf66-4652-976a-7e162c785a66", BLERead | BLENotify);

// Creating Analog characteristics to allow remote device to get notifications

BLEByteCharacteristic videoScrubCharacteristic("6635d693-9ad2-408e-ad48-4d8f88810dee", BLERead | BLENotify);
BLEByteCharacteristic audioScrubCharacteristic("099af204-5811-4a15-8ffb-4f127ffdfcd7", BLERead | BLENotify);

void setup() {
  
  Serial.begin(9600);
//  while (!Serial);

  playPausePin.set_CS_AutocaL_Millis(0xFFFFFFFF);     // turn off autocalibrate on channel 1 - just as an example
  backwardScrubPin.set_CS_AutocaL_Millis(0xFFFFFFFF);     // turn off autocalibrate on channel 1 - just as an example

  pinMode(videoScrubPin, INPUT); // use the slide potentiometer as a input
  pinMode(audioScrubPin, INPUT); // use the slide potentiometer as a input

  // begin initialization
  if (!BLE.begin()) {
    Serial.println("starting BLE failed!");
//    while (1);
  }

  // set the local name peripheral advertises
  BLE.setLocalName("Playcook");
  
  // set the UUID for the service this peripheral advertises:
  BLE.setAdvertisedService(apronService);

  
  // add the characteristics to the service
  apronService.addCharacteristic(playPauseCharacteristic);
  apronService.addCharacteristic(backwardCharacteristic);

  apronService.addCharacteristic(videoScrubCharacteristic);
  apronService.addCharacteristic(audioScrubCharacteristic);

  // add the service
  BLE.addService(apronService);

  playPauseCharacteristic.writeValue(0);
  backwardCharacteristic.writeValue(0);
  
  videoScrubCharacteristic.writeValue(0);
  audioScrubCharacteristic.writeValue(0);

  // start advertising
  BLE.advertise();

  Serial.println("Bluetooth device active, waiting for connections...");
}

void loop() {
  // poll for BLE events
  BLE.poll();

  long start = millis();
  long total1 =  playPausePin.capacitiveSensor(80);
  long total2 =  backwardScrubPin.capacitiveSensor(80);

  int videoScrubValue = analogRead(videoScrubPin);
  int audioScrubValue = analogRead(audioScrubPin);

  int videoScrubState = map(videoScrubValue, 0, 1023, 0, 100);
  int audioControlState = map(audioScrubValue, 0, 1023, 0, 100);

  if (total1 >= 50000){
    playPauseCharacteristic.writeValue(thisIsOn);
  } else if (total1 < 50000) {
    playPauseCharacteristic.writeValue(thisIsOff);  
  }


  if (total2 >= 50000){
    backwardCharacteristic.writeValue(thisIsOn);
  } else if (total2 < 50000){
    backwardCharacteristic.writeValue(thisIsOff);  
  }

  videoScrubCharacteristic.writeValue(videoScrubState);
  audioScrubCharacteristic.writeValue(audioControlState);


  Serial.print(total1);
  Serial.print(",");
  Serial.print(total2);
  Serial.print(",");
  Serial.print(videoScrubState);
  Serial.print(",");
  Serial.println(audioControlState);

//  playPauseCharacteristic.writeValue(total1);
//  backwardCharacteristic.writeValue(total2);
//  videoScrubCharacteristic.writeValue(videoScrubValue);
//  audioScrubCharacteristic.writeValue(audioScrubValue);

  delay(100);

}

//  // read the current button pin state
//  char buttonValue = digitalRead(buttonPin);
//
////   has the value changed since the last read
//  boolean buttonChanged = (buttonCharacteristic.value() != buttonValue);
//
////  boolean buttonChanged = (buttonCharacteristic.value() == 1);
//
//
//  if (buttonChanged) {
//    // button state changed, update characteristics
////    ledCharacteristic.writeValue(buttonValue);
//    buttonCharacteristic.writeValue(buttonValue);
//    Serial.println("Button One interaction");
//  }
//
////  char buttonTwoValue = digitalRead(ledPin);
//
//  int potValue = analogRead(ledPin);
//
//  
//
//  int mappedButtonTwoValue = map(potValue, 0, 1024, 0, 255);
//  Serial.println(mappedButtonTwoValue);
//
//
//  boolean buttonTwoChanged = (ledCharacteristic.value() != mappedButtonTwoValue);
//
//   if (buttonTwoChanged) {
//    // button state changed, update characteristics
//    ledCharacteristic.writeValue(mappedButtonTwoValue);
////    buttonCharacteristic.writeValue(buttonValue);
//
////Serial.println(mappedButtonTwoValue);
//  }
