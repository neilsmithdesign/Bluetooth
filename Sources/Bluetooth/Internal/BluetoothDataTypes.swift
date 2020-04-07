//
//  BluetoothDataTypes.swift
//  Bluetooth
//
//  Created by Neil Smith on 07/04/2020.
//

import Foundation
import CoreBluetooth

/// A data value which is obtained from a characteristic reading
protocol BluetoothData: CustomStringConvertible {
    var value: Int { get }
    init?(from characteristic: CBCharacteristic)
}

extension BluetoothData where Self: RawRepresentable, Self.RawValue == Int {
    var value: Int { self.rawValue }
}


// MARK: - Specific characteristics values

/// Peripheral battery level
struct BatteryLevel: BluetoothData {
    let value: Int
    init?(from characteristic: CBCharacteristic) {
        guard let byte = characteristic.value?.first else { return nil }
        self.value = Int(byte)
    }
    var description: String {
        return "Battery Level: \(value)%"
    }
}


/// Heart rate beats per minute
/// First bit of first byte indcates if value is 8 or 16 bit
/// -- Equal to 0? 8-bit number
/// -- Equal to 1? 16-bit number
/// If 8-bit number, value is in the 2nd byte (index 1)
/// If 16-bit number, value is in the 2nd byte (shifted by 8 bits) and 3rd byte
struct BPM: BluetoothData {
    let value: Int
    init(bytes: [Byte]) {
        if bytes[0] & 0x01 == 0 {
            self.value = Int(bytes[1])
        } else {
            self.value = Int(bytes[1] << 8) + Int(bytes[2])
        }
    }
    
    init?(from characteristic: CBCharacteristic) {
        guard let data = characteristic.value else { return nil }
        self.init(bytes: .init(data))
    }
    
    var description: String {
        "Heart Rate: \(value) bpm"
    }
}


/// Heart rate sensor body location
/// The first byte contains the value
enum BodySensorLocation: Int, BluetoothData {
    case other = 0
    case chest
    case wrist
    case finger
    case hand
    case earLobe
    case foot
    
    var name: String {
        switch self {
        case .other: return "other"
        case .chest: return "chest"
        case .wrist: return "wrist"
        case .finger: return "finger"
        case .hand: return "hand"
        case .earLobe: return "ear lobe"
        case .foot: return "foot"
        }
    }
    
    init?(from characteristic: CBCharacteristic) {
        guard let byte = characteristic.value?.first else { return nil }
        self.init(rawValue: Int(byte))
    }
    
    var description: String {
        "Body sensor location: \(name)"
    }
}

typealias Byte = Data.Element

