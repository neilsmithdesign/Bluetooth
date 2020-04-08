import XCTest
@testable import Bluetooth

final class BluetoothTests: XCTestCase {
    
    func testAllCharacteristicsAreHandledWhenReceived() {
        
        // Given
        // A bluetooth instance with a mock CBCentralManager that is asked to discover services/chars for all that have been declared in this library
        
        // When
        // The mock CBCM should eventually have one or more mock CBPeripherals call the delegate method:
        //
        // - func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
        //
        // with all possible characteristics
        
        // Then
        // The bluetooth instance's method: func handle(updatedValueFor:), should never hit preconditionFailure
        // (or, some other way of ensuring that code path in the switch statement is never executed with a test
        //
        // The purpose of this test is to ensure that 
        
    }

}
