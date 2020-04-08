import XCTest
@testable import Bluetooth

final class BatteryCharacteristicTests: XCTest {
    
    func testAllBatteryCharacteristicsIncludedInAllArray() {
        
        // Given
        let all: [BatteryCharacteristic] = [BatteryCharacteristic.level]
        
        let sut = BatteryCharacteristic.allCases
        
        // When
        // Then
        XCTAssertTrue(all == sut)
        
    }
    
}
