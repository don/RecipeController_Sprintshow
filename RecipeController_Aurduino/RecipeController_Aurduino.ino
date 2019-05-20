/* Mobile Lab class final project

  Playcook a wearable cooking assistant

  By Atharva Patil & Anna Oh - May 2019

  Hardware used Arduino mkr 1010

*/
#include <SPI.h>
// Using the ArduinoBLE library for Bluetooth communication by advertising Arduino as a discoverable peripheral
#include <ArduinoBLE.h>
// Using Capacitive sensing library to check for touches against the fabric
#include <CapacitiveSensor.h>

//#include <Scheduler.h>

CapacitiveSensor   playPausePin = CapacitiveSensor(2, 4);     //  resistor between pins 2 & 4. To check for interaction for play/pause
CapacitiveSensor   backwardScrubPin = CapacitiveSensor(2, 5); // 10M resistor between pins 2 & 5. To check for interaction for 10 sec backward scrub

const int videoScrubPin = A3;   // to scrub the video based on the chain position on the apron
const int audioScrubPin = A4;   // to control the audio of the iOS device.

//int thisIsOn = 1;
//int thisIsOff = 0;
const int ON = 1;
const int OFF = 0;

// code had 50,000 - changing to 20,000 since I only have 1M resistors
const int CAP_TOUCH_THRESHOLD = 20000;

// Creating a service which will act as the accessory advertiser & the primary service
BLEService apronService("4cc4513b-1b63-4c93-a419-dddaeae3fdc7");

// Creating Digital characteristics to allow remote device to get notifications

BLEByteCharacteristic playPauseCharacteristic("ef9534b9-2c24-4ddc-b9b2-fc690ecf4cb4", BLERead | BLENotify);
BLEDescriptor playPauseDescriptor("2901", "Play / Pause");
BLEByteCharacteristic backwardCharacteristic("9400449a-cf66-4652-976a-7e162c785a66", BLERead | BLENotify);
BLEDescriptor backwardDescriptor("2901", "Backward");

// Creating Analog characteristics to allow remote device to get notifications

BLEByteCharacteristic videoScrubCharacteristic("6635d693-9ad2-408e-ad48-4d8f88810dee", BLERead | BLENotify);
BLEDescriptor videoScrubDescriptor("2901", "Video Scrub");
BLEByteCharacteristic audioScrubCharacteristic("099af204-5811-4a15-8ffb-4f127ffdfcd7", BLERead | BLENotify);
BLEDescriptor audioScrubDescriptor("2901", "Volume");

void setup() {

  Serial.begin(9600);
  while (!Serial);

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
  playPauseCharacteristic.addDescriptor(playPauseDescriptor);
  apronService.addCharacteristic(backwardCharacteristic);
  backwardCharacteristic.addDescriptor(backwardDescriptor);

  apronService.addCharacteristic(videoScrubCharacteristic);
  videoScrubCharacteristic.addDescriptor(videoScrubDescriptor);
  apronService.addCharacteristic(audioScrubCharacteristic);
  audioScrubCharacteristic.addDescriptor(audioScrubDescriptor);

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

  // only send the values when they change
  if (total1 >= CAP_TOUCH_THRESHOLD && playPauseCharacteristic.value() == OFF) {
    Serial.println("Play Pause ON");
    playPauseCharacteristic.writeValue(ON);
  } else if (total1 < CAP_TOUCH_THRESHOLD && playPauseCharacteristic.value() == ON) {
    Serial.println("Play Pause OFF");
    playPauseCharacteristic.writeValue(OFF);
  }

  if (total2 >= CAP_TOUCH_THRESHOLD && backwardCharacteristic.value() == OFF) {
    Serial.println("Backward ON");
    backwardCharacteristic.writeValue(ON);
  } else if (total2 < CAP_TOUCH_THRESHOLD && backwardCharacteristic.value() == ON) {
    Serial.println("Backward OFF");
    backwardCharacteristic.writeValue(OFF);
  }

  videoScrubCharacteristic.writeValue(videoScrubState);
  audioScrubCharacteristic.writeValue(audioControlState);


//  Serial.print(total1);
//  Serial.print(",");
//  Serial.print(total2);
//  Serial.print(",");
//  Serial.print(videoScrubState);
//  Serial.print(",");
//  Serial.println(audioControlState);

  //  playPauseCharacteristic.writeValue(total1);
  //  backwardCharacteristic.writeValue(total2);
  //  videoScrubCharacteristic.writeValue(videoScrubValue);
  //  audioScrubCharacteristic.writeValue(audioScrubValue);

//  delay(100);

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
