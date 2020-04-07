//
//  BluetoothAttribute.swift
//  Bluetooth
//
//  Created by Neil Smith on 07/04/2020.
//

import Foundation
import CoreBluetooth

/// A convenience protocol for accessing uuids of services and characteristics
protocol BluetoothAttribute {
    var cbuuid: CBUUID { get }
}

extension BluetoothAttribute where Self: RawRepresentable, Self.RawValue == Bluetooth.GATTAssignedNumber {
    var cbuuid: CBUUID { .init(string: self.rawValue) }
}
