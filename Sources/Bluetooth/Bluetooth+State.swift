//
//  Bluetooth+State.swift
//  Bluetooth
//
//  Created by Neil Smith on 07/04/2020.
//

import Foundation

public extension Bluetooth {
    
    enum State {
        case notAuthorizedYet
        case preparing
        case ready
        case scanningForPeripherals
        case completedScan
    }
    
}
