@testable import Session
import XCTest

final class ConfigurationTests: XCTestCase {
    func test_configuration_of_cache() {
        // Given
        let customCache = URLCache(memoryCapacity: 123, diskCapacity: 321)
        let configurations: [Configuration] = [Cache(urlCache: customCache)]
        // When
        let (session, _) = createSession(from: configurations)
        // Then
        XCTAssertNotNil(session.configuration.urlCache)
        XCTAssertEqual(session.configuration.urlCache?.memoryCapacity, customCache.memoryCapacity)
        XCTAssertEqual(session.configuration.urlCache?.diskCapacity, customCache.diskCapacity)
    }

    func test_configuration_of_delegates() {
        // Given
        class MockDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate {}
        let delegate = MockDelegate()
        let configurations: [Configuration] = [Delegate.session(delegate), Delegate.task(delegate)]
        // When
        let (session, taskDelegate) = createSession(from: configurations)
        // Then
        XCTAssertTrue(taskDelegate === delegate)
        XCTAssertTrue(session.delegate === delegate)
    }

    func test_configuration_of_flags_disabled() {
        // Given
        let configurations: [Configuration] = [
            Disable.constrainedNetworkAccess,
            Disable.expensiveNetworkAccess,
            Disable.waitingForConnectivity,
        ]
        // When
        let (sessionOne, _) = createSession(from: configurations)
        let (sessionTwo, _) = createSession(from: [])
        // Then
        XCTAssertFalse(sessionOne.configuration.allowsConstrainedNetworkAccess)
        XCTAssertFalse(sessionOne.configuration.allowsExpensiveNetworkAccess)
        XCTAssertFalse(sessionOne.configuration.waitsForConnectivity)
        XCTAssertTrue(sessionTwo.configuration.allowsConstrainedNetworkAccess)
        XCTAssertTrue(sessionTwo.configuration.allowsExpensiveNetworkAccess)
        XCTAssertTrue(sessionTwo.configuration.waitsForConnectivity)
    }

    func test_configuration_of_headers() {
        // Given
        let headers = ["header": "value"]
        let configurations: [Configuration] = [Headers(httpHeaders: headers)]
        // When
        let (session, _) = createSession(from: configurations)
        // Then
        XCTAssertNotNil(session.configuration.httpAdditionalHeaders)
        XCTAssertTrue((session.configuration.httpAdditionalHeaders?["header"] as? String) == "value")
    }

    func test_configuration_of_background_preset() {
        // Given
        let preset = Preset.background(identifier: "background", sharedContainerIdentifier: "shared", isDiscretionary: true)
        // When
        let (sessionOne, _) = createSession(from: [preset])
        let (sessionTwo, _) = createSession(from: [])
        // Then
        XCTAssertTrue(sessionOne.configuration.identifier == "background")
        XCTAssertTrue(sessionOne.configuration.sharedContainerIdentifier == "shared")
        XCTAssertTrue(sessionOne.configuration.isDiscretionary)
        XCTAssertNil(sessionTwo.configuration.identifier)
        XCTAssertNil(sessionTwo.configuration.sharedContainerIdentifier)
        XCTAssertFalse(sessionTwo.configuration.isDiscretionary)
    }

    func test_configuration_of_custom_preset() {
        // Given
        let customConfig = URLSessionConfiguration.default
        customConfig.allowsCellularAccess = false
        // When
        let (sessionOne, _) = createSession(from: [Preset.custom(customConfig)])
        let (sessionTwo, _) = createSession(from: [])
        // Then
        XCTAssertEqual(sessionOne.configuration.allowsCellularAccess, false)
        XCTAssertEqual(sessionTwo.configuration.allowsCellularAccess, true)
    }

    func test_configuration_of_ephemeral_preset() {
        // Given
        let preset = Preset.ephemeral
        // When
        let (sessionOne, _) = createSession(from: [preset])
        let (sessionTwo, _) = createSession(from: [])
        // Then
        XCTAssertTrue(sessionOne.configuration.value(forKey: "_disposition") as? String == "EphemeralDisposition")
        XCTAssertTrue(sessionTwo.configuration.value(forKey: "_disposition") as? String == "DefaultDisposition")
    }

    func test_configuration_of_protocol_classes() {
        // Given
        class MockClass {}
        // When
        let (sessionOne, _) = createSession(from: [ProtocolClasses(classes: [MockClass.self])])
        let (sessionTwo, _) = createSession(from: [])
        // Then
        XCTAssertTrue(sessionOne.configuration.protocolClasses?.first == MockClass.self)
        XCTAssertNil(sessionTwo.configuration.protocolClasses)
    }

    func test_configuration_of_timeouts() {
        // Given
        let configurations: [Configuration] = [
            Timeout.request(1000),
            Timeout.resource(10),
        ]
        // When
        let (sessionOne, _) = createSession(from: configurations)
        let (sessionTwo, _) = createSession(from: [])
        // Then
        XCTAssertEqual(sessionOne.configuration.timeoutIntervalForRequest, configurations.timeoutIntervalForRequest)
        XCTAssertEqual(sessionOne.configuration.timeoutIntervalForResource, configurations.timeoutIntervalForResource)
        XCTAssertEqual(sessionTwo.configuration.timeoutIntervalForRequest, ConfigDefaults.timeoutIntervalForRequest)
        XCTAssertEqual(sessionTwo.configuration.timeoutIntervalForResource, ConfigDefaults.timeoutIntervalForResource)
    }
}
