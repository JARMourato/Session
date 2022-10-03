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
        let enableWaitingForConnectivity = true
        // When
        let sessionOne = Session {
            if enableWaitingForConnectivity {
                Enable.waitingForConnectivity
            }
        }
        let sessionTwo = Session()
        // Then
        XCTAssertTrue(sessionOne.configuration.waitsForConnectivity)
        XCTAssertFalse(sessionTwo.configuration.waitsForConnectivity)
    }

    func test_if_else() {
        // Given
        let enableWaitingForConnectivity = false
        // When
        let sessionOne = Session {
            if !enableWaitingForConnectivity {
                Enable.waitingForConnectivity
            } else {
                Disable.constrainedNetworkAccess
            }
        }
        let sessionTwo = Session {
            if enableWaitingForConnectivity {
                Enable.waitingForConnectivity
            } else {
                Disable.constrainedNetworkAccess
            }
        }
        // Then
        XCTAssertTrue(sessionOne.configuration.waitsForConnectivity)
        XCTAssertTrue(sessionOne.configuration.allowsConstrainedNetworkAccess)
        XCTAssertFalse(sessionTwo.configuration.waitsForConnectivity)
        XCTAssertFalse(sessionTwo.configuration.allowsConstrainedNetworkAccess)
    }

    func test_optional() {
        // Given
        let configurationsOne: [Configuration]? = [Enable.waitingForConnectivity]
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
        XCTAssertTrue(sessionOne.configuration.waitsForConnectivity)
        XCTAssertFalse(sessionTwo.configuration.waitsForConnectivity)
    }

    func test_availability() {
        // Given
        let configs: [Configuration] = [Enable.waitingForConnectivity]
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
        XCTAssertTrue(sessionOne.configuration.waitsForConnectivity)
        XCTAssertFalse(sessionTwo.configuration.waitsForConnectivity)
    }

    func test_array() {
        // Given
        let configs: [Configuration] = [Enable.waitingForConnectivity, Disable.constrainedNetworkAccess]
        // When
        let sessionOne = Session {
            for item in configs {
                item
            }
        }
        let sessionTwo = Session()
        // Then
        XCTAssertFalse(sessionOne.configuration.allowsConstrainedNetworkAccess)
        XCTAssertTrue(sessionOne.configuration.waitsForConnectivity)
        XCTAssertTrue(sessionTwo.configuration.allowsConstrainedNetworkAccess)
        XCTAssertFalse(sessionTwo.configuration.waitsForConnectivity)
    }
}
