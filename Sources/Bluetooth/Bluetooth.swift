//
//  Bluetooth.swift
//  Bluetooth
//
//  Created by Neil Smith on 07/04/2020.
//

import Foundation
import CoreBluetooth
import Combine

public final class Bluetooth: NSObject, ObservableObject {
    
    
    // MARK: - Init
    public init(scanDuration: TimeInterval = 5) {
        self.scanDuration = scanDuration
        let isAuthorized = CBCentralManager.authorization == .allowedAlways
        self.state = isAuthorized ? .preparing : .notAuthorizedYet
        super.init()
    }
    
    public func require<C: BluetoothCharacteristic>(_ service: Service<C>) {
        self.services.append(AnyService(service))
    }
    
    public typealias Authorization = CBManagerAuthorization
    
    public static var authorization: Authorization { CBCentralManager.authorization }
    
    public static var isAuthorized: Bool {
        CBCentralManager.authorization == .allowedAlways
    }
    
    public func start() {
        manager = .init(delegate: self, queue: nil)
    }

    
    // MARK: - Published properties
    
    /// The current scanning state of the bluetooth 'central' hardware
    @Published public private(set) var state: Bluetooth.State
    
    /// The public publisher of peripherals. This operates on the private property
    /// called 'peripherals'. It's purpose is to provide a stream of single Peripherals
    /// rather than a Set. This makes it easier to consume the API.
    public private(set) lazy var peripheralsPublisher: AnyPublisher<Peripheral, Never> = {
        let p = self.$peripherals
            .map { $0.publisher }
            .switchToLatest()
            .eraseToAnyPublisher()
        return p
    }()
    
    
    // MARK: - Private
    
    /// The in-memory representation of all peripherals
    /// Core Bluetooth requires that all CBPeripheral objects be
    /// held with a strong reference. Peripheral wraps the CBPeripheral
    /// instance and only exposes relevant properties outside this library
    @Published private var peripherals: Set<Peripheral> = []

    /// The central manager instance for interacting with Core Bluetooth
    private var manager: CBCentralManager!
    
    private var isManagerReady: Bool {
        guard manager != nil else { return false }
        guard manager.state == .poweredOn else { return false }
        return true
    }
    
    /// A UserDefaults-based cache for remembering a user's devices across app launches
    private lazy var cache: PeripheralCache = .init()

    /// The requested peripheral services to look for
    private var services: [AnyService] = []
    
    private var serviceUUIDs: [CBUUID]? {
        services.isEmpty ? nil : services.map { $0.kind.cbuuid }
    }
    
    /// The all peripheral characteristics of all services to look for
    private var characteristicsUUIDs: [CBUUID]? {
        services.isEmpty ? nil : services.flatMap({ $0.characteristics }).map { $0.cbuuid }
    }
    
    /// The duration a central manager should conduct a scane for before stopping
    /// Keep this value to a few seconds to minimise battery usage
    private let scanDuration: TimeInterval
    
    /// Reference held to work item responsible for stopping the polling of RSSI
    /// values of specific periperhals. UUID is the identifier of the peripheral
    private var activeRSSIPolling: [UUID : Timer] = [:]
    
}


// MARK: - Interface methods
public extension Bluetooth {
    
    /// Called if the user still requires to authorize bluetooth use.
    /// Library users can use the public 'state' property to determine
    /// user authorization status.
    func requestBluetoothAuthorization() {
        manager = .init(delegate: self, queue: nil)
    }
    
    /// Can be called once the bluetooth central manager is in the 'poweredOn' state
    /// Library users can use the 'state' property and wait for the 'ready' value
    /// before attempting any connections
    func reconnectToKnowPeripheralIfAvailable() {
        guard isManagerReady else {
            logOnApiMisuse()
            return
        }
        guard let identifiers = cache.identifiers?.compactMap(UUID.init) else { return }
        let peripherals: [CBPeripheral]
        if !identifiers.isEmpty {
            peripherals = manager.retrievePeripherals(withIdentifiers: identifiers)
        } else if let uuids = serviceUUIDs {
            peripherals = manager.retrieveConnectedPeripherals(withServices: uuids)
        } else {
            peripherals = []
        }
        reconnet(toKnown: peripherals)
    }
    
    /// Scans for peripherals upon user request
    /// Requires the 'central' to be in the poweredOn state
    /// Scan is stopped after a few seconds
    func scanForPeripherals() {
        guard isManagerReady else {
            logOnApiMisuse()
            return
        }
        state = .scanningForPeripherals
        manager.scanForPeripherals(withServices: serviceUUIDs)
        DispatchQueue.main.asyncAfter(deadline: .now() + scanDuration) {
            self.manager.stopScan()
            self.state = .completedScan
        }
    }
    
    /// A user initiated request to connect to a peripheral they have selected
    func connect(toPeripheralWith identifier: UUID, signalPolling options: Peripheral.SignalStrengthPollingOptions? = nil) {
        guard isManagerReady else {
            logOnApiMisuse()
            return
        }
        guard var p = fetch(peripheralFor: identifier) else { return }
        p.signalStrengthPollingOptions = options
        p.cbPeripheral.delegate = self
        peripherals.update(with: p)
        manager.connect(p.cbPeripheral)
    }
    
    /// A user initiated request to disconnect to a peripheral they have selected
    func disconnect(fromPeripheralWith identifier: UUID, shouldForget: Bool = false) {
        guard isManagerReady else {
            logOnApiMisuse()
            return
        }
        guard let p = fetch(peripheralFor: identifier, matching: .connected) else { return }
        manager.cancelPeripheralConnection(p.cbPeripheral)
        if shouldForget {
            cache.remove(p)
        }
    }
    
    /// A user initiated request to forget a peripheral they have selected
    /// A call to read RSSI is made. This helps determine whether the peripheral
    /// being forgotten is either available or not. Useful in order to determine
    /// the final state/status of the peripheral    
    func forget(knownPeripheralWith identifier: UUID) {
        guard isManagerReady else {
            logOnApiMisuse()
            return
        }
        guard var p = fetch(peripheralFor: identifier) else { return }
        p.isKnown = false
        p.cbPeripheral.readRSSI()
        peripherals.update(with: p)
        cache.remove(p)
    }
    
}


// MARK: - Helper methods for mutatuing the model
private extension Bluetooth {
    
    func reconnet(toKnown peripherals: [CBPeripheral]) {
        for peripheral in peripherals {
            store(discovered: peripheral)
            connect(toPeripheralWith: peripheral.identifier, signalPolling: .init(every: 1, timeOutAfter: 10))
        }
    }
    
    func store(discovered peripheral: CBPeripheral, rssi: NSNumber? = nil) {
        let id = peripheral.identifier.uuidString
        let isKnown = cache.contains(peripheralWith: id)
        let details = cache.details(forPeripheralWith: id)
        update(peripheral, isKnown: isKnown, rssi: rssi, details: details)
    }
    
    func pollRSSI(of periperhal: CBPeripheral, every interval: TimeInterval, timeOutAfter end: TimeInterval) {
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            periperhal.readRSSI()
        }
        self.activeRSSIPolling[periperhal.identifier] = timer
        let workItem = DispatchWorkItem {
            guard let timer = self.activeRSSIPolling[periperhal.identifier] else { return }
            timer.invalidate()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + end, execute: workItem)
    }
    
    @discardableResult
    func update(_ peripheral: CBPeripheral, isKnown: Bool, rssi: NSNumber? = nil, details: Peripheral.Details? = nil) -> Peripheral {
        if var p = fetch(peripheralFor: peripheral.identifier) {
            p.isKnown = isKnown
            p.state = peripheral.state
            p.services = details?.services
            p.signalStrength = Peripheral.SignalStrength(nsNumber: rssi)
            peripherals.update(with: p)
            return p
        } else {
            let p = Peripheral(
                cbPeripheral: peripheral,
                state: peripheral.state,
                services: details?.services,
                isKnown: isKnown,
                signalStrength: Peripheral.SignalStrength(nsNumber: rssi)
            )
            peripherals.insert(p)
            return p
        }
    }
    
    func update(_ peripheral: CBPeripheral, for cbServices: [CBService]) {
        guard var p = peripherals.first(where:  { $0.identifier == peripheral.identifier }) else { return }
        let services = fetch(servicesFor: cbServices)
        p.services = services
        peripherals.update(with: p)
        cache.store(detailsFor: p)
    }
    
    func fetch(servicesFor cbServices: [CBService]) -> [AnyService] {
        let ids = cbServices.map { $0.uuid }
        return self.services.filter { ids.contains($0.kind.cbuuid) }
    }
    
    func update(_ peripheral: CBPeripheral, rssi: NSNumber) {
        guard var p = peripherals.first(where: { $0.identifier == peripheral.identifier }) else { return }
        p.signalStrength = Peripheral.SignalStrength(nsNumber: rssi)
        peripherals.update(with: p)
    }
    
    func fetch(peripheralFor identifier: UUID, matching state: CBPeripheralState? = nil) -> Peripheral? {
        guard let p = peripherals.first(where: { $0.identifier == identifier }) else { return nil }
        if let state = state {
            guard p.state == state else { return nil }
        }
        return p
    }
    
}


// MARK: - Peripheral scanning, discovery and connection
extension Bluetooth: CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff: state = .preparing
        case .poweredOn: state =  .ready
        case .resetting: break
        case .unauthorized: state = .notAuthorizedYet
        case .unknown: break
        case .unsupported: break
        default: break
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        store(discovered: peripheral, rssi: RSSI)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard var p = fetch(peripheralFor: peripheral.identifier) else { return }
        p.state = peripheral.state
        peripherals.update(with: p)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let p = update(peripheral, isKnown: true)
        if let options = p.signalStrengthPollingOptions {
            pollRSSI(of: peripheral, every: options.every, timeOutAfter: options.timeOutAfter)
        }
        cache.store(p)
        peripheral.readRSSI()
        peripheral.discoverServices(serviceUUIDs)
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to: \(peripheral). Error: \(error?.localizedDescription ?? "-")")
    }
    
}


// MARK: - Peripheral service and characteristic discovery
extension Bluetooth: CBPeripheralDelegate {
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let err = error {
            print("Service discovery error: \(err.localizedDescription)")
            return
        }
        guard let cbServices = peripheral.services else { return }
        update(peripheral, for: cbServices)
        for cbService in cbServices {
            guard let characteristics = self.services.first(where: { $0.kind.cbuuid == cbService.uuid })?.characteristics else { continue }
            peripheral.discoverCharacteristics(characteristics.map { $0.cbuuid }, for: cbService)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let err = error {
            print("Characteristics discovery error: \(err.localizedDescription)")
            return
        }
        guard let chars = service.characteristics else { return }
        for char in chars {
            if char.properties.contains(.read) {
                peripheral.readValue(for: char)
            }
            if char.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: char)
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if let err = error {
            print("Error reading RSSI: \(err.localizedDescription)")
            return
        }
        update(peripheral, rssi: RSSI)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let err = error {
            print("Error receiving updated value for characteristic: \(err.localizedDescription)")
            return
        }
        guard let uuids = characteristicsUUIDs, uuids.contains(characteristic.uuid) else {
            return
        }
        handle(updatedValueFor: characteristic, peripheral: peripheral)
    }

    func handle(updatedValueFor characteristic: CBCharacteristic, peripheral: CBPeripheral) {
        switch characteristic.uuid {
        case .batteryLevel:
            guard let level = BatteryLevel(from: characteristic) else { return }
            guard var p = fetch(peripheralFor: peripheral.identifier) else { return }
            p.batteryLevel = level.value
            peripherals.update(with: p)
            print(level.description)
        case .bodySensorLocation:
            return // Currently not broadcasting this value outside of the framework.
        case .heartRateMeasurement:
            guard let bpm = HeartRateMeasurement(from: characteristic) else { return }
            guard var p = fetch(peripheralFor: peripheral.identifier) else { return }
            p.value = bpm.value
            peripherals.update(with: p)
        default:
            preconditionFailure("Unhandled characteristic. Must ensure all publicly available characteristics are handled by this module.")
        }
    }
    
}

public extension Bluetooth {
    
    typealias GATTAssignedNumber = String
    
}

private extension Bluetooth {
    
    func logOnApiMisuse() {
        print("Bluetooth: Attempting to interact with Core Bluetooth before CBCentralManager has been initialized. Has func start() been called? Failing silently.")
    }
    
}
