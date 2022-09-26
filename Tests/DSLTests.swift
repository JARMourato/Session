@testable import Session
import XCTest

final class DSLTests: XCTestCase {
    func test_empty_array() {
        // Given
        let configurations: [Configuration] = []
        // When
        let session = Session(builder: { configurations })
        // Then
        XCTAssertEqual(session.configuration.timeoutIntervalForRequest, ConfigDefaults.timeoutIntervalForRequest)
    }

    func test_if() {
        // Given
        let disableWaitingForConnectivity = true
        // When
        let sessionOne = Session {
            if disableWaitingForConnectivity {
                Disable.waitingForConnectivity
            }
        }
        let sessionTwo = Session()
        // Then
        XCTAssertFalse(sessionOne.configuration.waitsForConnectivity)
        XCTAssertTrue(sessionTwo.configuration.waitsForConnectivity)
    }

    func test_if_else() {
        // Given
        let disableWaitingForConnectivity = true
        // When
        let sessionOne = Session {
            if !disableWaitingForConnectivity {
                Disable.waitingForConnectivity
            } else {
                Disable.constrainedNetworkAccess
            }
        }
        let sessionTwo = Session {
            if disableWaitingForConnectivity {
                Disable.waitingForConnectivity
            } else {
                Disable.constrainedNetworkAccess
            }
        }
        // Then
        XCTAssertTrue(sessionOne.configuration.waitsForConnectivity)
        XCTAssertFalse(sessionOne.configuration.allowsConstrainedNetworkAccess)
        XCTAssertFalse(sessionTwo.configuration.waitsForConnectivity)
        XCTAssertTrue(sessionTwo.configuration.allowsConstrainedNetworkAccess)
    }

    func test_optional() {
        // Given
        let configurationsOne: [Configuration]? = [Disable.waitingForConnectivity]
        let configurationsTwo: [Configuration]? = nil
        // When
        let sessionOne = Session {
            if let configs = configurationsOne {
                configs
            }
        }
        let sessionTwo = Session {
            if let configs = configurationsTwo {
                configs
            }
        }
        // Then
        XCTAssertFalse(sessionOne.configuration.waitsForConnectivity)
        XCTAssertTrue(sessionTwo.configuration.waitsForConnectivity)
    }

    func test_availability() {
        // Given
        let configs: [Configuration] = [Disable.waitingForConnectivity]
        // When
        let sessionOne = Session {
            if #available(iOS 15, *) {
                configs
            }
        }
        let sessionTwo = Session {
            if #available(iOS 15, *) {
                // Do nothing
            } else {
                configs
            }
        }
        // Then
        XCTAssertFalse(sessionOne.configuration.waitsForConnectivity)
        XCTAssertTrue(sessionTwo.configuration.waitsForConnectivity)
    }

    func test_array() {
        // Given
        let configs = [Disable.waitingForConnectivity, Disable.constrainedNetworkAccess]
        // When
        let sessionOne = Session {
            for item in configs {
                item
            }
        }
        let sessionTwo = Session()
        // Then
        XCTAssertFalse(sessionOne.configuration.waitsForConnectivity)
        XCTAssertFalse(sessionOne.configuration.allowsConstrainedNetworkAccess)
        XCTAssertTrue(sessionTwo.configuration.waitsForConnectivity)
        XCTAssertTrue(sessionTwo.configuration.allowsConstrainedNetworkAccess)
    }
}
