//
//  PeripheralTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 1/7/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
import CoreBluetooth
import CoreLocation
@testable import BlueCapKit

// MARK - PeripheralTests -
class PeripheralTests: XCTestCase {

    let RSSI = -45
    let updatedRSSI1 = -50
    let updatedRSSI2 = -75

    var centralManagerMock: CBCentralManagerMock!
    var centralManager: CentralManager!
    let immediateContext = ImmediateContext()

    let mockServices = [
        CBServiceMock(UUID:CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6ccc")),
        CBServiceMock(UUID:CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6fff"))
    ]

    var mockCharateristics = [
        CBCharacteristicMock(UUID: CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6111"), properties: [.read, .write], isNotifying: false),
        CBCharacteristicMock(UUID: CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6222"), properties: [.read, .write], isNotifying: false),
        CBCharacteristicMock(UUID: CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6333"), properties: [.read, .write], isNotifying: false)
    ]
    
    override func setUp() {
        super.setUp()
        self.centralManagerMock = CBCentralManagerMock(state: .poweredOn)
        self.centralManager = CentralManagerUT(centralManager: self.centralManagerMock)
    }
    
    override func tearDown() {
        super.tearDown()
    }

    // MARK: discoverAllServices
    func testDiscoverAllServices_WhenConnectedAndNoErrorInResponse_CompletesSuccessfully() {
        let mockPeripheral = CBPeripheralMock(state: .connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.discoverAllServices()
        peripheral.didDiscoverServices(self.mockServices.map { $0 as CBServiceInjectable }, error:nil)
        XCTAssertFutureSucceeds(future, context: self.immediateContext) { _ in
            let discoveredServices = peripheral.services
            XCTAssertEqual(discoveredServices.count, 2)
            XCTAssertEqual(mockPeripheral.discoverServicesCalledCount, 1)
            XCTAssert(mockPeripheral.discoverServicesCalled)
            XCTAssertFalse(mockPeripheral.discoverCharacteristicsCalled)
        }
    }

    func testDiscoverAllServices_WhenConnectedAndErrorInResponse_CompletesWithResponseError() {
        let mockPeripheral = CBPeripheralMock(state: .connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.discoverAllServices()
        peripheral.didDiscoverServices(self.mockServices.map { $0 as CBServiceInjectable }, error: TestFailure.error)
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            let discoveredServices = peripheral.services
            XCTAssertEqual(discoveredServices.count, 0)
            XCTAssertEqualErrors(error, TestFailure.error)
            XCTAssertEqual(mockPeripheral.discoverServicesCalledCount, 1)
            XCTAssert(mockPeripheral.discoverServicesCalled)
            XCTAssertFalse(mockPeripheral.discoverCharacteristicsCalled)
        }
    }

    func testDiscoverAllServices_WhenDisconnected_CompletesWithPeripheralDisconnected() {
        let mockPeripheral = CBPeripheralMock(state: .disconnected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.discoverAllServices()
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            let discoveredServices = peripheral.services
            XCTAssertEqual(discoveredServices.count, 0)
            XCTAssertEqualErrors(error, PeripheralError.disconnected)
            XCTAssertEqual(mockPeripheral.discoverServicesCalledCount, 0)
            XCTAssertFalse(mockPeripheral.discoverServicesCalled)
            XCTAssertFalse(mockPeripheral.discoverCharacteristicsCalled)
        }

    }

    func testDiscoverAllServices_WhenConnectedOnTimeout_CompletesWithServiceDiscoveryTimeout() {
        let mockPeripheral = CBPeripheralMock(state: .connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.discoverAllServices(0.25)
        XCTAssertFutureFails(future, timeout: 5.0) { error in
            let discoveredServices = peripheral.services
            XCTAssertEqual(discoveredServices.count, 0)
            XCTAssertEqualErrors(error, PeripheralError.serviceDiscoveryTimeout)
            XCTAssertEqual(mockPeripheral.discoverServicesCalledCount, 1)
            XCTAssert(mockPeripheral.discoverServicesCalled)
            XCTAssertFalse(mockPeripheral.discoverCharacteristicsCalled)
        }
    }

    // MARK: discoverAllPeripheralServices
    func testDiscoverAllPeripheralServices_WhenConnectedAndNoErrorInResponse_CompletesSuccessfully() {
        let mockPeripheral = CBPeripheralMock(state:.connected)
        let peripheral = PeripheralUT(cbPeripheral:mockPeripheral, centralManager:self.centralManager, advertisements:peripheralAdvertisements as [String : AnyObject], rssi: self.RSSI, error:nil)
        let future = peripheral.discoverAllPeripheralServices()
        peripheral.didDiscoverServices(self.mockServices.map { $0 as CBServiceInjectable }, error:nil)
        XCTAssertFutureSucceeds(future, timeout: 5.0) { _ in
            let discoveredServices = peripheral.services
            XCTAssertEqual(discoveredServices.count, 2)
            XCTAssert(mockPeripheral.discoverServicesCalled)
        }
    }

    func testDiscoverAllPeripheralServices_WhenConnectedAndErrorInServiceDiscoveryResponse_CompletesWithResponseError() {
        let mockPeripheral = CBPeripheralMock(state: .connected)
        let peripheral = PeripheralUT(cbPeripheral:mockPeripheral, centralManager:self.centralManager, advertisements:peripheralAdvertisements as [String : AnyObject], rssi: self.RSSI, error:TestFailure.error)
        let future = peripheral.discoverAllPeripheralServices()
        peripheral.didDiscoverServices(self.mockServices.map { $0 as CBServiceInjectable }, error:nil)
        XCTAssertFutureFails(future, timeout: 5.0) { error in
            XCTAssertEqualErrors(error, TestFailure.error)
            XCTAssert(mockPeripheral.discoverServicesCalled)
        }
    }

    func testDiscoverAllPeripheralServices_WhenConnectedAndNoServicesDiscovered_CompletesWithPeripheralNoServices() {
        let mockPeripheral = CBPeripheralMock(state: .connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.discoverAllPeripheralServices()
        peripheral.didDiscoverServices([], error:nil)
        XCTAssertFutureFails(future, timeout: 5.0) { error in
            XCTAssertEqualErrors(error, PeripheralError.noServices)
        }
    }

    // MARK: connect
    func testConnect_WhenDisconnected_CompletesSuccesfullyWithEventConnect() {
        let mockPeripheral = CBPeripheralMock(state:.disconnected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.connect(connectionTimeout: 120.0)
        peripheral.didConnectPeripheral()
        XCTAssertFutureStreamSucceeds(future, context: self.immediateContext, validations: [
            { (peripheral, connectionEvent) in
                XCTAssert(self.centralManagerMock.connectPeripheralCalled)
                XCTAssertEqual(connectionEvent, ConnectionEvent.connect)
            }
        ])
    }

    func testConnect_WhenConnected_DoesNotConnect() {
        let mockPeripheral = CBPeripheralMock(state:.connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let _ = peripheral.connect()
        XCTAssertFalse(self.centralManagerMock.connectPeripheralCalled)
    }

    func testConnect_WhenDisconnectedWithConnectionError_CompletesWithConnectionError() {
        let mockPeripheral = CBPeripheralMock(state: .disconnected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.connect(connectionTimeout: 120.0)
        peripheral.didFailToConnectPeripheral(TestFailure.error)
        XCTAssert(self.centralManagerMock.connectPeripheralCalled)
        XCTAssertFutureStreamFails(future, context: self.immediateContext, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            }
        ])
    }

    func testConnect_WhenDisconnectedAndForcedDisconnect_CompletesWithPeripheralDisconnected() {
        let mockPeripheral = CBPeripheralMock(state: .disconnected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.connect()
        peripheral.disconnect()
        XCTAssertFutureStreamFails(future, context: self.immediateContext, validations: [
            { error in
                XCTAssertEqualErrors(error, PeripheralError.disconnected)
            }
        ])
    }
    
    func testConnect_WhenConnectedAndForcedDisconnect_CompletesSuccessfullyWithEventForceDisconnect() {
        let mockPeripheral = CBPeripheralMock(state: .connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.connect()
        peripheral.disconnect()
        XCTAssertFutureStreamSucceeds(future, context: self.immediateContext, validations: [
            { (_, connectionEvent) in
                XCTAssertEqual(connectionEvent, ConnectionEvent.forceDisconnect)
            }
        ])
    }

    func testConnect_WhenConnectedAndPeripheralDisconnectsWithoutError_CompletesSuccessfullyWithEventDisconnect() {
        let mockPeripheral = CBPeripheralMock(state: .connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.connect()
        peripheral.didDisconnectPeripheral(nil)
        XCTAssertFutureStreamSucceeds(future, context: self.immediateContext, validations: [
            { (_, connectionEvent) in
                XCTAssertEqual(connectionEvent, ConnectionEvent.disconnect)
            }
        ])
    }

    func testConnect_WhenConnectedAndPeripheralDisconnectsWithError_CompletesDisconnectError() {
        let mockPeripheral = CBPeripheralMock(state: .connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.connect()
        peripheral.didDisconnectPeripheral(TestFailure.error)
        XCTAssertFutureStreamFails(future, context: self.immediateContext, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            }
        ])
    }


    func testConnect_WhenDisconnetedAndConnectionTimeout_CompletesSuccessfullyWithEventTimeout() {
        let mockPeripheral = CBPeripheralMock(state: .disconnected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.connect(connectionTimeout: 0.25)
        XCTAssertFutureStreamSucceeds(future, timeout: 5.0, validations: [
            { (_, connectionEvent) in
                XCTAssertEqual(connectionEvent, ConnectionEvent.timeout)
            }
        ])
    }
    
    func testConnect_WhenDisconnetedAndExceedsTimeoutRetries_CompletesSuccessfullyWithEventGiveUp() {
        let mockPeripheral = CBPeripheralMock(state: .disconnected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.connect(timeoutRetries: 1, connectionTimeout: 0.25)
        XCTAssertFutureStreamSucceeds(future, timeout: 5.0, validations: [
            { (peripheral, connectionEvent) in
                peripheral.reconnect()
                XCTAssertEqual(connectionEvent, ConnectionEvent.timeout)
            },
            { (peripheral, connectionEvent) in
                XCTAssertEqual(connectionEvent, ConnectionEvent.giveUp)
            }
        ])
    }

    func testConnect_WhenDisconnectedWithNoErrorAndExceedsDisconnectRetries_CompletesSuccessfullyWithEventGiveUp() {
        let mockPeripheral = CBPeripheralMock(state:.connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.connect(disconnectRetries: 1)
        peripheral.didConnectPeripheral()
        XCTAssertFutureStreamSucceeds(future, timeout: 5.0, validations: [
            { (peripheral, connectionEvent) in
                XCTAssertEqual(connectionEvent, ConnectionEvent.connect)
                peripheral.didDisconnectPeripheral(nil)
            },
            { (peripheral, connectionEvent) in
                XCTAssertEqual(connectionEvent, ConnectionEvent.disconnect)
                peripheral.reconnect()
                peripheral.didConnectPeripheral()
            },
            { (peripheral, connectionEvent) in
                XCTAssertEqual(connectionEvent, ConnectionEvent.connect)
                peripheral.didDisconnectPeripheral(nil)
            },
            { (peripheral, connectionEvent) in
                XCTAssertEqual(connectionEvent, ConnectionEvent.giveUp)
            }
        ])
    }

    
    func testConnect_WhenDisconnectedWithErrorAndExceedsDisconnectRetries_CompletesSuccessfullyWithEventGiveUp() {
        let mockPeripheral = CBPeripheralMock(state:.connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation = self.expectation(description: "expectation fulfilled")
        let future = peripheral.connect(disconnectRetries: 1)
        future.onSuccess { (peripheral, connectionEvent) in
            switch connectionEvent {
            case .connect:
                peripheral.didDisconnectPeripheral(TestFailure.error)
            case .timeout:
                XCTFail()
            case .disconnect:
                XCTFail()
            case .forceDisconnect:
                XCTFail()
            case .giveUp:
                expectation.fulfill()
            }
        }
        peripheral.didDisconnectPeripheral(TestFailure.error)
        future.onFailure { _ in
            peripheral.reconnect()
            peripheral.didConnectPeripheral()
        }
        waitForExpectations(timeout: 20) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    // MARK: Read RSSI
    func testReadRSSI_WhenConnected_CompletesSuccessfully() {
        let mockPeripheral = CBPeripheralMock(state: .connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.readRSSI()
        peripheral.didReadRSSI(NSNumber(value: Int32(self.updatedRSSI1)), error: nil)
        XCTAssertFutureSucceeds(future, context: self.immediateContext) { rssi in
            XCTAssertEqual(rssi, self.updatedRSSI1)
            XCTAssertEqual(peripheral.RSSI, self.updatedRSSI1)
        }
    }

    func testReadRSSI_WhenDisconnected_CompletesWithPeripheralDisconnected() {
        let mockPeripheral = CBPeripheralMock(state: .disconnected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.readRSSI()
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            XCTAssertEqualErrors(error, PeripheralError.disconnected)
        }
    }

    func testReadRSSI_WhenConnectedAndErrorInResponse_CompletesWithResponseError() {
        let mockPeripheral = CBPeripheralMock(state: .connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.readRSSI()
        peripheral.didReadRSSI(NSNumber(value: Int32(self.updatedRSSI1)), error: TestFailure.error)
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            XCTAssertEqualErrors(error, TestFailure.error)
        }
    }

    func testStartPollingRSSI_WhenConnectedAndNoErrorInAck_CompletesSuccessfully() {
        let mockPeripheral = CBPeripheralMock(state: .connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        mockPeripheral.bcPeripheral = peripheral
        let future = peripheral.startPollingRSSI(0.25)
        XCTAssertFutureStreamSucceeds(future, timeout: 120, validations: [
            { rssi in
                XCTAssertEqual(rssi, mockPeripheral.RSSI)
                XCTAssertEqual(peripheral.RSSI, mockPeripheral.RSSI)
                XCTAssertEqual(mockPeripheral.readRSSICalledCount, 1)
            },
            { rssi in
                XCTAssertEqual(rssi, mockPeripheral.RSSI)
                XCTAssertEqual(peripheral.RSSI, mockPeripheral.RSSI)
                XCTAssertEqual(mockPeripheral.readRSSICalledCount, 2)
                peripheral.stopPollingRSSI()
            }
        ])
    }

    func testStartPollingRSSI_WhenDisconnected_CompletesWithPeripheralDisconnected() {
        let mockPeripheral = CBPeripheralMock(state: .disconnected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let future = peripheral.startPollingRSSI()
        XCTAssertFutureStreamFails(future, context:self.immediateContext, validations: [
            { error in
                peripheral.stopPollingRSSI()
                XCTAssertEqualErrors(error, PeripheralError.disconnected)
            }
        ])
    }


   func testStartPollingRSSI_WhenDisconnectedAfterStart_CompletesWithPeripheralDisconnected() {
        let mockPeripheral = CBPeripheralMock(state: .connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        mockPeripheral.bcPeripheral = peripheral
        let expectation = self.expectation(description: "expectation fulfilled")
        var completed = false
        let future = peripheral.startPollingRSSI(0.25)
        future.onSuccess { rssi in
            if (!completed) {
                completed = true
                XCTAssertEqual(rssi, mockPeripheral.RSSI)
                XCTAssertEqual(peripheral.RSSI, mockPeripheral.RSSI)
                XCTAssertEqual(mockPeripheral.readRSSICalledCount, 1)
                mockPeripheral.state = .disconnected
            } else {
                expectation.fulfill()
                XCTFail()
            }
        }
        future.onFailure { error in
            expectation.fulfill()
            peripheral.stopPollingRSSI()
            XCTAssertEqualErrors(error, PeripheralError.disconnected)
        }
        waitForExpectations(timeout: 120) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartPollingRSSI_WhenConnectedAndErrorInResponse_CompletedWithResponceError() {
        let mockPeripheral = CBPeripheralMock(state: .connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        let expectation = self.expectation(description: "expectation fulfilled")
        let future = peripheral.startPollingRSSI(0.25)
        mockPeripheral.error = TestFailure.error
        mockPeripheral.bcPeripheral = peripheral
        XCTAssertFutureStreamFails(future, validations: [
            { error in
                peripheral.stopPollingRSSI()
                expectation.fulfill()
                XCTAssertEqualErrors(error, TestFailure.error)
            }
        ])
    }

    func testStopPollingRSSI_WhenConnected_StopsRSSIUpdates() {
        let mockPeripheral = CBPeripheralMock(state: .connected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        var count = 0
        let future = peripheral.startPollingRSSI(0.25)
        mockPeripheral.bcPeripheral = peripheral
        future.onSuccess(context: QueueContext.global) { _ in
            count += 1
            peripheral.stopPollingRSSI()
        }
        future.onFailure(context: QueueContext.global) { error in
            XCTFail()
        }
        sleep(1)
        XCTAssertEqual(count, 1)
    }

    func testStopPollingRSSI_WhenDisconnected_StopsRSSIUpdates() {
        let mockPeripheral = CBPeripheralMock(state: .disconnected)
        let peripheral = Peripheral(cbPeripheral: mockPeripheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        var count = 0
        let future = peripheral.startPollingRSSI(0.25)
        mockPeripheral.bcPeripheral = peripheral
        future.onSuccess(context: QueueContext.global) { _ in
            XCTFail()
        }
        future.onFailure(context: QueueContext.global) { error in
            count += 1
            peripheral.stopPollingRSSI()
        }
        sleep(1)
        XCTAssertEqual(count, 1)
   }
}
