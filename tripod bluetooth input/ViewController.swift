//
//  ViewController.swift
//  Apron Video Controller
//
//  Created by Atharva Patil on 25/04/2019.
//  Copyright © 2019 Atharva Patil. All rights reserved.
//

import UIKit
import CoreBluetooth
import Foundation

// UUID to identify the arduino device which in this case is the same as the service
let APRON_SERVICE_UUID = CBUUID(string: "4cc4513b-1b63-4c93-a419-dddaeae3fdc7")

// UUID's to identify the characteristics of the sensors
let PLAY_PAUSE_BUTTON_UUID = CBUUID(string: "ef9534b9-2c24-4ddc-b9b2-fc690ecf4cb4")
let REVERSE_BUTTON_UUID = CBUUID(string: "9400449a-cf66-4652-976a-7e162c785a66")
let VIDEO_SCRUB_UUID = CBUUID(string: "6635d693-9ad2-408e-ad48-4d8f88810dee")
let AUDIO_CONTROL_UUID = CBUUID(string:"099af204-5811-4a15-8ffb-4f127ffdfcd7")

class ViewController: UIViewController {
    
    // DECLARING BLUETOOTH VARIABLES: BEGINS HERE
    
    // Initialising the Bluetooth manager object
    var centralManager: CBCentralManager?
    
    // Initialising Peripheral object which is responsible for discovering a nerby Accessory
    var arduinoPeripheral: CBPeripheral?
    
    // Variables to identify different sensors on the arduino as individual services which have chareteristics attached to them
    var apronService: CBService?
    
    var playPauseChar: CBCharacteristic?
    var reverseChar: CBCharacteristic?
    var videoScrubChar: CBCharacteristic?
    var audioControlChar: CBCharacteristic?
    
    // DECLARING BLUETOOTH VARIABLES: ENDS HERE
    
    // label to appened states & the data incoming from the periphral
    @IBOutlet weak var buttonValue: UILabel!
    @IBOutlet weak var volumeLevelText: UILabel!
    @IBOutlet weak var videoCompleteText: UILabel!
    @IBOutlet weak var playPauseState: UIView!
    @IBOutlet weak var reverseState: UIView!
    
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
            central.scanForPeripherals(withServices: [APRON_SERVICE_UUID], options: nil)
            
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
        peripheral.discoverServices([APRON_SERVICE_UUID])
        
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
        guard let service = peripheral.services?.first(where: { service -> Bool in
            service.uuid == APRON_SERVICE_UUID
        }) else {
            return
        }
        
        // Referencing it
        apronService = service
        
        // & Logging it's UUID to make sure it's the right one
        print("Apron Service UUID", apronService!.uuid)
        
        // Now that the service is discovered and referenced to. Search for the charecteristics attached to it.
        peripheral.discoverCharacteristics([PLAY_PAUSE_BUTTON_UUID, REVERSE_BUTTON_UUID, VIDEO_SCRUB_UUID, AUDIO_CONTROL_UUID], for: service)

    }

    // This function handles the cases when charecteristics are discovered(the ones we are looking for just above)
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        guard let characteristics = service.characteristics else {return}
        
        // loop through discovered characteristics, save the ones we care about and subscribe for notifications
        for characteristic in characteristics {
            switch characteristic.uuid {
            case PLAY_PAUSE_BUTTON_UUID:
                playPauseChar = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            case REVERSE_BUTTON_UUID:
                reverseChar = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            case VIDEO_SCRUB_UUID:
                videoScrubChar = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            case AUDIO_CONTROL_UUID:
                audioControlChar = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            default:
                print("Ignoring characteristic", characteristic)
            }
        }
        
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
        
        guard let data = characteristic.value else {
            // It's also a good idea to print before returning so you can debug
            print("Unable to get data from characteristic:", characteristic)
            return
        }
        
        // call the correct function based on which characteristic was updated
        switch characteristic.uuid {
        case PLAY_PAUSE_BUTTON_UUID:
            playPause(data: data)
        case REVERSE_BUTTON_UUID:
            reverse(data: data)
        case VIDEO_SCRUB_UUID:
            videoScrub(data: data)
        case AUDIO_CONTROL_UUID:
            audioControl(data:data)
        default:
            print("Ignoring characteristic", characteristic)
        }
    
    }
    
    // TODO: I think this might be better as a toggle...
    // When playPause is 1, pause if playing or play if paused
    // Otherwise, just ignore the value?
    func playPause(data: Data) {
        let value = data.int8Value();
        print("playPause", value);
        if value == 0 {
            buttonValue.text = "Video Playing"
            self.playPauseState.backgroundColor = .yellow
        } else if value == 1 {
            buttonValue.text = "Video Paused"
            self.playPauseState.backgroundColor = .blue
        }
    }
    
    func reverse(data: Data) {
        let value = data.int8Value();
        print("reverse", value);
        if value == 0 {
            self.reverseState.backgroundColor = .yellow
        } else {
            self.reverseState.backgroundColor = .green
        }
    }
    
    func audioControl(data: Data) {
        let value = data.int8Value();
        print("audio", value);
        volumeLevelText.text = "Volume level: " + "\(value)"
    }
    
    func videoScrub(data: Data) {
        let value = data.int8Value();
        print("Video", value);
        videoCompleteText.text = "Video scrub position: " + "\(value)"
    }

}

// Functions to convert raw data to other formats
extension Data {
    func int8Value() -> Int8 {
        return Int8(bitPattern: self[0])
    }
}
