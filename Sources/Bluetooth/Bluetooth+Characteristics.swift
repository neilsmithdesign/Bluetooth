//
//  Bluetooth+Characteristics.swift
//  Bluetooth
//
//  Created by Neil Smith on 07/04/2020.
//

import Foundation
import CoreBluetooth

public extension Bluetooth {
    
    enum Characteristic: Bluetooth.GATTAssignedNumber, BluetoothAttribute {
        case batteryLevel = "2A19"
        case heartRateMeasurement = "2A37"
        case bodySensorLocation = "2A38"
    }
    
}

extension Bluetooth.Characteristic {
    
    init?(cbCharacteristic: CBCharacteristic) {
        self.init(rawValue: cbCharacteristic.uuid.uuidString)
    }

}
