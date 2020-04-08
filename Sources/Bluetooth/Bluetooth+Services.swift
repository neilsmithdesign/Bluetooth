//
//  Bluetooth+Services.swift
//  Bluetooth
//
//  Created by Neil Smith on 07/04/2020.
//

import Foundation
import CoreBluetooth

public enum BluetoothService: Bluetooth.GATTAssignedNumber, BluetoothAttribute {
    case battery = "0x180F"
    case heartRate = "0x180D"
}


public struct Service<C> where C: BluetoothCharacteristic {
    
    let kind: BluetoothService
    let characteristics: [C]
    
    public init(characteristics: [C]) {
        self.kind = C.serviceKind
        self.characteristics = characteristics
    }
}

public extension Service {
    
    typealias Battery = Service<BatteryCharacteristic>
    typealias HeartRate = Service<HeartRateCharacteristic>
    
}

struct AnyService {
    
    let kind: BluetoothService
    let characteristics: [BluetoothCharacteristic]
    
    init<C: BluetoothCharacteristic>(_ service: Service<C>) {
        self.kind = service.kind
        self.characteristics = service.characteristics
    }
    
    func characteristic(for cbuuid: CBUUID) -> BluetoothCharacteristic? {
        characteristics.first(where: { $0.cbuuid == cbuuid })
    }
}
