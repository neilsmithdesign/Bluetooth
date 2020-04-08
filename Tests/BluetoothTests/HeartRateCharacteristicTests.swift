import XCTest
@testable import Bluetooth

final class HeartRateCharacteristicTests: XCTest {
    
    func testAllHeartRateCharacteristicsIncludedInAllArray() {
        
        // Given
        let all: [HeartRateCharacteristic] = [
            HeartRateCharacteristic.measurement,
            HeartRateCharacteristic.bodySensorLocation,
            HeartRateCharacteristic.controlPoint
        ]
        
        let sut = HeartRateCharacteristic.allCases
        
        // When
        // Then
        XCTAssertTrue(all == sut)
        
    }
    
}
