import Foundation

public struct Session {
    internal weak var taskDelegate: URLSessionTaskDelegate?
    internal var urlSession: URLSession!

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

public struct Response<Request: Requestable, Data> {
    let request: Request
    let result: DataResponse
}

public protocol Requestable {
    func makeURLRequest() throws -> URLRequest
}

extension URLRequest: Requestable {
    public func makeURLRequest() throws -> URLRequest { self }
}

public enum SessionError: Error {
    case invalidRequest(rawError: Error), invalidResponse
}

extension SessionError: Equatable {
    public static func == (lhs: SessionError, rhs: SessionError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidResponse, .invalidResponse):
            return true
        case let (.invalidRequest(lhsError), .invalidRequest(rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
