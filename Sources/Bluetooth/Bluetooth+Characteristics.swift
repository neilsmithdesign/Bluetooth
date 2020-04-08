//
//  Bluetooth+Characteristics.swift
//  Bluetooth
//
//  Created by Neil Smith on 07/04/2020.
//

import Foundation
import CoreBluetooth

public protocol BluetoothCharacteristic: BluetoothAttribute {
    static var serviceKind: BluetoothService { get }
}

// MARK: - Heart Rate
public struct HeartRateCharacteristic: BluetoothCharacteristic, Equatable, CaseIterable {
    
    
    public static var serviceKind: BluetoothService { .heartRate }
    public var cbuuid: CBUUID
    init(cbuuid: CBUUID) {
        self.cbuuid = cbuuid
    }
    

    public typealias AllCases = [HeartRateCharacteristic]
    public static var allCases: [HeartRateCharacteristic] {
        [
            HeartRateCharacteristic.measurement,
            HeartRateCharacteristic.bodySensorLocation,
            HeartRateCharacteristic.controlPoint
        ]
    }
    
    public static let measurement: HeartRateCharacteristic = .init(cbuuid: .heartRateMeasurement)
    public static let bodySensorLocation: HeartRateCharacteristic = .init(cbuuid: .bodySensorLocation)
    public static let controlPoint: HeartRateCharacteristic = .init(cbuuid: .heartRateControlPoint)

}


// MARK: - Battery
public struct BatteryCharacteristic: BluetoothCharacteristic, Equatable, CaseIterable {

    public static var serviceKind: BluetoothService { .battery }
    public var cbuuid: CBUUID
    init(cbuuid: CBUUID) {
        self.cbuuid = cbuuid
    }
    
    public typealias AllCases = [BatteryCharacteristic]
    public static var allCases: [BatteryCharacteristic] {
        [BatteryCharacteristic.level]
    }
    
    public static let level: BatteryCharacteristic = .init(cbuuid: .batteryLevel)
    
}
