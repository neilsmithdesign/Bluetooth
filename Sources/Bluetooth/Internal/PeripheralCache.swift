//
//  PeripheralCache.swift
//  Bluetooth
//
//  Created by Neil Smith on 07/04/2020.
//

import Foundation

final class PeripheralCache {
    
    let storage: UserDefaults
    init(storage: UserDefaults = .bluetoothPeripherals) {
        self.storage = storage
    }
    
    
    // MARK: GET / READ
    var identifiers: [String]? {
        storage.array(forKey: .identifier) as? [String]
    }
    
    func details(forPeripheralWith identifier: String) -> Peripheral.Details? {
        guard let dictionary = storage.dictionary(forKey: identifier) else { return nil }
        return Peripheral.Details(from: dictionary)
    }
    
    func contains(peripheralWith identifier: String) -> Bool {
        identifiers?.contains(where: { $0 == identifier }) ?? false
    }
    
    
    // MARK: CREATE / UPDATE
    func store(_ peripheral: Peripheral) {
        store(peripheral: peripheral.identifier.uuidString)
        store(detailsFor: peripheral)
    }
    
    private func store(peripheral identifier: String) {
        if var list = storage.array(forKey: .identifier) as? [String] {
            guard !list.contains(identifier) else { return }
            list.append(identifier)
            storage.set(list, forKey: .identifier)
        } else {
            storage.set([identifier], forKey: .identifier)
        }
    }
    
    func store(detailsFor peripheral: Peripheral) {
        if let details = Peripheral.Details(peripheral: peripheral) {
            storage.set(details.dictionary, forKey: peripheral.detailsKey)
        }
    }
    
    
    // MARK: DELETE
    func remove(_ peripheral: Peripheral) {
        if var list = storage.array(forKey: .identifier) as? [String] {
            guard let i = list.firstIndex(where: { $0 == peripheral.identifier.uuidString }) else { return }
            list.remove(at: i)
            storage.set(list, forKey: .identifier)
        }
        storage.set(nil, forKey: peripheral.detailsKey)
    }

}

extension Peripheral {
    
    struct Details {
        
        let servicesIdentifiers: [String]
        let characteristicsIdentifiers: [String]
        
        init?(peripheral: Peripheral) {
            guard let services = peripheral.services else { return nil }
            let serviceIDs = services.map({ $0.kind.cbuuid.uuidString })
            let characteristicsIDs = services.flatMap { $0.characteristics.map { $0.cbuuid.uuidString } }
            self.servicesIdentifiers = serviceIDs
            self.characteristicsIdentifiers = characteristicsIDs
        }
        
        init?(from dictionary: [String : Any]) {
            guard
                let serviceIDs = dictionary[.services] as? [String],
                let characteristicIDs = dictionary[.characteristics] as? [String] else {
                    return nil
            }
            self.servicesIdentifiers = serviceIDs
            self.characteristicsIdentifiers = characteristicIDs
        }
        
        var dictionary: [String : Any] {
            return [
                .services : servicesIdentifiers,
                .characteristics : characteristicsIdentifiers
            ]
        }
        
        var services: [AnyService]? {
            let serviceKinds = servicesIdentifiers.compactMap(BluetoothService.init)
            var services: [AnyService] = []
            for s in serviceKinds {
                switch s {
                case .battery:
                    let chars = availableCharacteristics(from: BatteryCharacteristic.allCases)
                    services.append(AnyService(.Battery(characteristics: chars)))
                case .heartRate:
                    let chars = availableCharacteristics(from: HeartRateCharacteristic.allCases)
                    services.append(AnyService(.HeartRate(characteristics: chars)))
                }
            }
            return services.isEmpty ? nil : services
        }
        
        private func availableCharacteristics<C: BluetoothCharacteristic>(from list: [C]) -> [C] {
            list.filter { characteristicsIdentifiers.contains($0.cbuuid.uuidString) }
        }
        
    }
    
}


// MARK: User defaults keys
private extension String {
    
    static var identifier: String { "peripheral.identifiers.list" }
    static var services: String { "peripheral.details.dictionary.services" }
    static var characteristics: String { "peripheral.details.dictionary.characteristics" }
    
}

private extension Peripheral {
    
    var detailsKey: String { self.identifier.uuidString }
    
}

private extension UserDefaults {
    
    static var bluetoothPeripherals: UserDefaults {
        UserDefaults(suiteName: "bluetooth.peripheral.cache")!
    }
    
}
