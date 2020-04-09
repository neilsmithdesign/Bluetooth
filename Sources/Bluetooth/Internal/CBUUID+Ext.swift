//
//  CBUUID+Ext.swift
//  Bluetooth
//
//  Created by Neil Smith on 08/04/2020.
//

import Foundation
import CoreBluetooth

extension CBUUID {
    
    // MARK: - Battery Service
    static var batteryLevel: CBUUID { .init(string: "2A19") }
    
    // MARK: - Heart Rate Service
    static var heartRateMeasurement: CBUUID { .init(string: "2A37") }
    static var bodySensorLocation: CBUUID { .init(string: "2A38") }
    static var heartRateControlPoint: CBUUID { .init(string: "2A39") }
    
}
