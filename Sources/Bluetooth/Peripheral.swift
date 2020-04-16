//
//  Peripheral.swift
//  Bluetooth
//
//  Created by Neil Smith on 07/04/2020.
//

import Foundation
import CoreBluetooth
import Combine

public struct Peripheral: Hashable {
    
    /// The wrapped CBPeripheral object
    let cbPeripheral: CBPeripheral
    
    /// State property. Manually assigned by Bluetooth object
    /// Could have used KVO to respond to changes to this property
    /// however, Peripheral needed to be a struct to ensure the
    /// Combine pipeline and higher level ObservedObjects would trigger
    /// a UI update in SwiftUI
    public internal(set) var state: CBPeripheralState
    
    /// The identifier of the CBPeripheral
    /// Used for Equality and Hashing
    public var identifier: UUID { cbPeripheral.identifier }
    
    /// The user (or manufacturer provided) name of the peripheral
    public var name: String { cbPeripheral.name ?? "Unnamed Device" }
    
    
    /// Manually assigned by Bluetooth object upon discovery
    /// This property is provided to help consumers of this library
    /// determine whether they are interested in this peripheral
    /// based on it's services.
    public internal(set) var services: [AnyService]?
    
    /// Used to determine whether this is a peripheral that the
    /// user has previously connected to.
    public internal(set) var isKnown: Bool
    
    /// Battery level, in percent (0-100), if available
    public internal(set) var batteryLevel: Int?
    
    /// The main value provided by this peripheral. Typically, can be
    /// described by an Integer. In future releases, this value may need
    /// to change. Possible case for a generic value
    public internal(set) var value: Int?

    /// If desired, the frequency and timeout period for polling the
    /// peripherals RSSI number to continually get a signal
    public internal(set) var signalStrengthPollingOptions: SignalStrengthPollingOptions?
    
    /// The signal strength of the peripheral. This is updated in response
    /// to reading the RSSI number
    public internal(set) var signalStrength: SignalStrength?
    
    /// The status of the peripheral for the purposes of displaying
    /// in app UIs
    public var status: Peripheral.Status {
        guard state != .connected else { return .connected }
        return isKnown ? .known : .available
    }
    
    /// Hashable conformance
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
    /// Equality conformance
    public static func ==(lhs: Peripheral, rhs: Peripheral) -> Bool {
        lhs.identifier == rhs.identifier
    }
    
}


// MARK: - Status
public extension Peripheral {
    
    enum Status: String {
        case unknown
        case available
        case known
        case connected
        var name: String { self.rawValue }
    }
    
}


public extension Peripheral {

    enum SignalStrength: String {
        case excellent
        case good
        case fair
        case weak
        init?(nsNumber: NSNumber?) {
            guard let number = nsNumber?.doubleValue else { return nil }
            let n = min(0, number)
            switch n {
            case -50...0: self = .excellent
            case -60 ..< -50: self = .good
            case -70 ..< -60: self = .fair
            default: self = .weak
            }
        }
    }
    
    struct SignalStrengthPollingOptions {
        let every: TimeInterval
        let timeOutAfter: TimeInterval
        public init(every: TimeInterval, timeOutAfter: TimeInterval) {
            self.every = every
            self.timeOutAfter = timeOutAfter
        }
    }

}
