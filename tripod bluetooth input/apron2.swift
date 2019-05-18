//
//  ViewController.swift
//  tripod bluetooth input
//
//  Created by Atharva Patil on 25/04/2019.
//  Copyright © 2019 Atharva Patil. All rights reserved.
//

import UIKit
import CoreBluetooth
import Foundation


// UUID to identify the arduino device which in this case is the same as the service
//let SERVICE_LED_UUID = "4cc4513b-1b63-4c93-a419-dddaeae3fdc7"
let APRON_SERVICE_UUID = "4cc4513b-1b63-4c93-a419-dddaeae3fdc7"

// UUID's to identify the charecteristics of the sensors
//let LED_CHARACTERISTIC_UUID = "ef9534b9-2c24-4ddc-b9b2-fc690ecf4cb4"
//let BUTTON_CHARACTERISTIC_UUID = "db07a43f-07e3-4857-bccc-f01abfb8845c"

let PLAY_PAUSE_BUTTON_UUID = "ef9534b9-2c24-4ddc-b9b2-fc690ecf4cb4"
let REVERSE_BUTTON_UUID = "9400449a-cf66-4652-976a-7e162c785a66"
let MESUREMENT_BUTTON_UUID = "9400448a-cf66-4652-976a-7e162c785a66"

//let VIDEO_SCRUB_UUID = "6635d693-9ad2-408e-ad48-4d8f88810dee"
//let AUDIO_CONTROL_UUID = "099af204-5811-4a15-8ffb-4f127ffdfcd7"

class ViewController: UIViewController {
    
    
    // DECLARING BLUETOOTH VARIABLES: BEGINS HERE
    
    // Initialising the Bluetooth manager object
    var centralManager: CBCentralManager?
    
    // Initialising Peripheral object which is responsible for discovering a nerby Accessory
    var arduinoPeripheral: CBPeripheral?
    
    // Variables to identify different sensors on the arduino as individual services which have chareteristics attached to them
//    var ledService: CBService?
    var apronService: CBService?
    
    // Variables to communicate the state of a charecteristic to and from the arduino
//    var charOne: CBCharacteristic?
//    var charTwo: CBCharacteristic?
    
    var playPauseChar: CBCharacteristic?
    var reverseChar: CBCharacteristic?
    var mesurementChar: CBCharacteristic?
//    var videoScrubChar: CBCharacteristic?
//    var audioControlChar: CBCharacteristic?
    
    // DECLARING BLUETOOTH VARIABLES: ENDS HERE
    
    // label to appened states & the data incoming from the periphral
    @IBOutlet weak var buttonValue: UILabel!
    

    @IBOutlet weak var volumeLevelText: UILabel!
    
    
    @IBOutlet weak var videoCompleteText: UILabel!
    
    
    @IBOutlet weak var playPauseState: UIView!
    
    @IBOutlet weak var reverseState: UIView!
    
    @IBOutlet weak var mesurmentTest: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Initiating bluetooth
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        // Text values at different states.
        // When the view loads the device starts connecting to Arduino
        buttonValue.text = "Connecting to Arduino"
        
        // TO-DO: Write and alert check here to see if Bluetooth is on or not. If Bluetooth is off through a alert with message.
    }


}


extension ViewController: CBCentralManagerDelegate{
    
    // Scanning for a Peripherial with a Unique accessory UUID. This id the arduino UUID
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        if central.state == .poweredOn {
            
            // The commented statement below searches for all discoverable peripherals, turn on for testing
            // central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
            
            // Scanning for a specific UUID peripheral
            central.scanForPeripherals(withServices: [CBUUID(string: APRON_SERVICE_UUID)], options: nil)
            
            // Logging to see of Bluetooth is scanning for the defined UUID peripheral
            print("Scanning for peripheral with UUID: ", APRON_SERVICE_UUID)
            
        }
    }
    
    // This function handles the cases when the Bluetooth device we are looking for is discovered
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {

        // If the peripheral is discovered log the details
        print("Discovered peripheral", peripheral)
    
        // Reference it
        arduinoPeripheral = peripheral
        
        // Connect to the Arduino peripheral
        centralManager?.connect(arduinoPeripheral!, options: nil)

        // print out the connection attempt
        print("Connecting to: ", arduinoPeripheral!)

    }
    
    // This function hadles the cases when the connection is successful
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
       
        // Check if we are connected to the same peripheral
        guard let peripheral = arduinoPeripheral else {
            return
        }
        
        // Delegating
        peripheral.delegate = self
        
        // the connected peripheral's properties
        print("Connected to: ", arduinoPeripheral!)
        
        // Also the same feeback on the screen
        buttonValue.text = "Connection Successful"
        
        // Now that the device is connected start loooking for services attached to it.
        peripheral.discoverServices([CBUUID(string: APRON_SERVICE_UUID)])
        
        // Test statement to discover all the services attached to the peripheral
        // peripheral.discoverServices(nil)

    }
    
}

// Now that is the a periphral discovered and referenced to start looking for properties attached to it.
extension ViewController: CBPeripheralDelegate{

    // This function handles the cases when there are services discovered for the peripheral
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?){
        
        // Logging the discovered services
        print("Discovered services:", peripheral.services!)
        
        // Feedback on screen
        buttonValue.text = "Services Discovered"
        
        // iterating through the services to retrive the one we are looking for
        guard let LEDService = peripheral.services?.first(where: { service -> Bool in
            service.uuid == CBUUID(string: APRON_SERVICE_UUID)
        }) else {
            return
        }
        
        // Referencing it
        apronService = LEDService
        
        // & Logging it's UUID to make sure it's the right one
        print("LED Service UUID", apronService!.uuid)
        
        // Now that the service is discovered and referenced to. Search for the charecteristics attached to it.
        peripheral.discoverCharacteristics([CBUUID(string: PLAY_PAUSE_BUTTON_UUID)], for: LEDService)
        peripheral.discoverCharacteristics([CBUUID(string: REVERSE_BUTTON_UUID)], for: LEDService)
        
        peripheral.discoverCharacteristics([CBUUID(string: MESUREMENT_BUTTON_UUID)], for: LEDService)
//        peripheral.discoverCharacteristics([CBUUID(string: VIDEO_SCRUB_UUID)], for: LEDService)
//        peripheral.discoverCharacteristics([CBUUID(string: AUDIO_CONTROL_UUID)], for: LEDService)
        
    }

    // This function handles the cases when charecteristics are discovered(the ones we are looking for just above)
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        // Log all the charecteristics for test
        // print("Charecteristics Discovered", service.characteristics!)
        
        // Look for a specific charecteristic
        guard let playPauseCharecteristic = service.characteristics?.first(where: { characteristic -> Bool in
            characteristic.uuid == CBUUID(string: PLAY_PAUSE_BUTTON_UUID)
        }) else {
            return
        }
        
        // If discovered, reference it
        playPauseChar = playPauseCharecteristic
        
        // Log the properties of the charecteristic
        print("Play/Pause char info ", playPauseCharecteristic)
        
        
        
        
        
        // Look for a specific charecteristic
        guard let reverseCharecteristic = service.characteristics?.first(where: { characteristic -> Bool in
            characteristic.uuid == CBUUID(string: REVERSE_BUTTON_UUID)
        }) else {
            return
        }
        
        // If discovered, reference it
        reverseChar = reverseCharecteristic
        
        // Log the properties of the charecteristic
        print("Reverse char info", reverseCharecteristic)
        
        guard let mesurementCharecteristic = service.characteristics?.first(where: { characteristic -> Bool in
            characteristic.uuid == CBUUID(string: MESUREMENT_BUTTON_UUID)
        }) else {
            return
        }
        
        // If discovered, reference it
        mesurementChar = mesurementCharecteristic
        
        // Log the properties of the charecteristic
        print("mesurement char info", reverseCharecteristic)
        
        
//
//        // Look for a specific charecteristic
//        guard let videoScrubCharecteristic = service.characteristics?.first(where: { characteristic -> Bool in
//            characteristic.uuid == CBUUID(string: VIDEO_SCRUB_UUID)
//        }) else {
//            return
//        }
//
//        // If discovered, reference it
//        videoScrubChar = videoScrubCharecteristic
//
//        // Log the properties of the charecteristic
//        print("Video Scrub char info ", videoScrubCharecteristic)
//
//
//
//
//        // Look for a specific charecteristic
//        guard let audioControlCharecteristic = service.characteristics?.first(where: { characteristic -> Bool in
//            characteristic.uuid == CBUUID(string: AUDIO_CONTROL_UUID)
//        }) else {
//            return
//        }
//
//        // If discovered, reference it
//        audioControlChar = audioControlCharecteristic
//
//        // Log the properties of the charecteristic
//        print("Audio control char info ", audioControlCharecteristic)
        
        
        // If the propter can send/notify (BLENotify on arduino) then we need to reference a listener for it
        // This is the listenter event for that
        peripheral.setNotifyValue(true, for: playPauseCharecteristic)
        peripheral.setNotifyValue(true, for: reverseCharecteristic)
        peripheral.setNotifyValue(true, for: mesurementCharecteristic)

//        peripheral.setNotifyValue(true, for: videoScrubCharecteristic)
//        peripheral.setNotifyValue(true, for: audioControlCharecteristic)
    
        
        // Now that the charectertistic is discovered it's time to press the button
        buttonValue.text = "Place hand on button"
        
    }
    
    
    
    
    // This function handles the cases when the sensor is sending some data
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        // SB Notes:
        // Return if there's an error
        if let error = error {
            print("Error receiving characteristic value:", error.localizedDescription)
            return
        }
        
        // As a best practice, you should grab the characteristic
        // that is passed here and do a check that it is the characteristic that you expect
        
        guard let updatedData = characteristic.value else {
            // It's also a good idea to print before returning so you can debug
            print("Unable to get data from characeristic:", characteristic)
            return
        }
        
        // Look into received bytes
//        let byteArray = [UInt8](updatedData)
//        print("Received:", byteArray)
//        print(byteArray, String(bytes: byteArray, encoding: .utf8)!)
        
        
        // Extract data from the charecteristic
//        guard let data = charTwo!.value else {
//            return
//        }
//
        
        
        guard let playState = playPauseChar!.value else {
            return
        }
        
        let playPauseValue = playState.int8Value()
        
        print("Play Value:", playPauseValue)
        
        if playPauseValue == 0{
            buttonValue.text = "Video Playing"
            self.playPauseState.backgroundColor = .yellow
        } else if playPauseValue == 1 {
            buttonValue.text = "Video Paused"
            self.playPauseState.backgroundColor = .blue
        }
        
        
        
        
        guard let reverseState = reverseChar!.value else {
            return
        }
        
        let reverseValue = reverseState.int8Value()
        
        print("Reverse Value:", reverseValue)
        
        if reverseValue == 0{
            self.reverseState.backgroundColor = .yellow
        } else if reverseValue == 1 {
            self.reverseState.backgroundColor = .green
        }
        
        
        guard let mesurementState = mesurementChar!.value else {
            return
        }
        
        let mesurementValue = mesurementState.int8Value()
        
        print("mesurement Value:", reverseValue)
        
        if mesurementValue == 0{
            buttonValue.text = ""
        } else if mesurementValue == 1 {
            buttonValue.text = "1tb"
        }
        
//        guard let videoState = videoScrubChar!.value else {
//            return
//        }
//
//        let videoValue = videoState.int8Value()
//
//        print("Video Value:", videoValue)
//
//        videoCompleteText.text = "Volume level: " + "\(videoValue)"
//
//
//        guard let audioState = audioControlChar!.value else {
//            return
//        }
//
//        let audioValue = audioState.int8Value()
//
//        print("Audio Value:", audioValue)
//
//        volumeLevelText.text = "Volume level: " + "\(audioValue)"
        
    }

}

// Functions to convert raw data to other formats
extension Data {
    func int8Value() -> Int8 {
        return Int8(bitPattern: self[0])
    }
    
}
