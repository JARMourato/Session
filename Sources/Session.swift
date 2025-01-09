// Copyright © 2022 João Mourato. All rights reserved.

import Foundation
import RNP

public struct Session: RequestLoader {
    weak var taskDelegate: URLSessionTaskDelegate?
    var urlSession: URLSession!

    // MARK: Initialization

    public init(@Builder builder: () -> [Configuration] = { [] }) {
        let configs = builder()
        (urlSession, taskDelegate) = createSession(from: configs)
    }
}

// MARK: - Auxiliary Methods

extension Session {
    var configuration: URLSessionConfiguration { urlSession.configuration }
}

// MARK: - Auxiliary Types

public enum SessionError: Error {
    case invalidRequest(rawError: Error), invalidResponse
}

extension SessionError: Equatable {
    public static func == (lhs: SessionError, rhs: SessionError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidResponse, .invalidResponse):
            true
        case let (.invalidRequest(lhsError), .invalidRequest(rhsError)):
            lhsError.localizedDescription == rhsError.localizedDescription
        default:
            false
        }
    }
}
