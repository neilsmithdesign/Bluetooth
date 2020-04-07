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
    
    func contains(peripheralWith identifier: String) -> Bool {
        retrieve()?.contains(where: { $0 == identifier }) ?? false
    }
    
    func store(peripheralWith identifier: String) {
        if var list = storage.array(forKey: key) as? [String] {
            guard !list.contains(identifier) else { return }
            list.append(identifier)
            storage.set(list, forKey: key)
        } else {
            storage.set([identifier], forKey: key)
        }
    }
    
    func remove(peripheralWith identifier: String) {
        if var list = storage.array(forKey: key) as? [String] {
            guard let i = list.firstIndex(where: { $0 == identifier }) else { return }
            list.remove(at: i)
            storage.set(list, forKey: key)
        }
    }
    
    func retrieve() -> [String]? {
        storage.array(forKey: key) as? [String]
    }
    
    private let key: String = "peripheral.identifiers.list"
    
}

private extension UserDefaults {
    
    static var bluetoothPeripherals: UserDefaults {
        UserDefaults(suiteName: "bluetooth.peripheral.cache")!
    }
    
}
