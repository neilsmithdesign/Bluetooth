//
//  Bluetooth+Services.swift
//  Bluetooth
//
//  Created by Neil Smith on 07/04/2020.
//

import Foundation

public extension Bluetooth {
    
    enum Service: Bluetooth.GATTAssignedNumber, BluetoothAttribute {
        case battery = "0x180F"
        case heartRate = "0x180D"
    }
    
}
