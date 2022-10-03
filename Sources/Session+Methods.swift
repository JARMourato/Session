import Foundation

public typealias DataResponse = (data: Data, urlResponse: URLResponse)
public typealias DownloadResponse = (url: URL, urlResponse: URLResponse)
public typealias UploadResponse = DataResponse

// MARK: - Data Task

public extension Session {
    func data(for r: Requestable) async throws -> DataResponse {
        let request = try r._makeURLRequest()
        let response: DataResponse

        if #available(iOS 15.0, macOS 12, tvOS 15.0, watchOS 6.0, *), !Session.disableConcurrency {
            response = try await urlSession.data(for: request, delegate: taskDelegate)
        } else {
            response = try await asyncify { urlSession.dataTask(with: request, completionHandler: $0) }
        }

        return response
    }

    func dataResponse<R: Requestable>(for r: R) async throws -> Response<R, Data> {
        Response(request: r, result: try await data(for: r))
    }
}

// MARK: - Download Tasks

public extension Session {
    func download(for r: Requestable) async throws -> DownloadResponse {
        let request = try r._makeURLRequest()
        let response: DownloadResponse

        if #available(iOS 15.0, macOS 12, tvOS 15.0, watchOS 6.0, *), !Session.disableConcurrency {
            response = try await urlSession.download(for: request, delegate: taskDelegate)
        } else {
            response = try await asyncify { urlSession.downloadTask(with: request, completionHandler: $0) }
        }

        return response
    }

    func download(resumeFrom data: Data) async throws -> DownloadResponse {
        let response: DownloadResponse

        if #available(iOS 15.0, macOS 12, tvOS 15.0, watchOS 6.0, *), !Session.disableConcurrency {
            response = try await urlSession.download(resumeFrom: data, delegate: taskDelegate)
        } else {
            response = try await asyncify { urlSession.downloadTask(withResumeData: data, completionHandler: $0) }
        }

        return response
    }
}

// MARK: - Upload Tasks

public extension Session {
    func upload(for r: Requestable, fromFile fileURL: URL) async throws -> UploadResponse {
        let request = try r._makeURLRequest()
        let response: UploadResponse

        if #available(iOS 15.0, macOS 12, tvOS 15.0, watchOS 6.0, *), !Session.disableConcurrency {
            response = try await urlSession.upload(for: request, fromFile: fileURL, delegate: taskDelegate)
        } else {
            response = try await asyncify { urlSession.uploadTask(with: request, fromFile: fileURL, completionHandler: $0) }
        }

        return response
    }

    func upload(for r: Requestable, fromData bodyData: Data) async throws -> UploadResponse {
        let request = try r._makeURLRequest()
        let response: UploadResponse

        if #available(iOS 15.0, macOS 12, tvOS 15.0, watchOS 6.0, *), !Session.disableConcurrency {
            response = try await urlSession.upload(for: request, from: bodyData, delegate: taskDelegate)
        } else {
            response = try await asyncify { urlSession.uploadTask(with: request, from: bodyData, completionHandler: $0) }
        }

        return response
    }
}

// MARK: - Internal Helpers

extension Session {
    func asyncify<D>(_ syncTaskBuilder: (@escaping @Sendable (D?, URLResponse?, Error?) -> Void) -> SessionTask) async throws -> (D, URLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            let task = syncTaskBuilder { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data, let response {
                    continuation.resume(returning: (data, response))
                } else {
                    continuation.resume(throwing: SessionError.invalidResponse)
                }
            }
            task.taskDelegate = taskDelegate
            task.resume()
        }
    }
}

extension Requestable {
    func _makeURLRequest() throws -> URLRequest {
        let request: URLRequest
        do {
            request = try makeURLRequest()
        } catch {
            throw SessionError.invalidRequest(rawError: error)
        }
        return request
    }
}

// MARK: - Testing Helpers

extension Session {
    static var disableConcurrency: Bool = false
}

protocol SessionTask: AnyObject {
    var taskDelegate: URLSessionTaskDelegate? { get set }
    func resume()
}

extension URLSessionTask: SessionTask {
    var taskDelegate: URLSessionTaskDelegate? {
        get {
            if #available(iOS 15.0, macOS 12, tvOS 15.0, watchOS 6.0, *) {
                return delegate
            } else {
                return nil
            }
        }
        set {
            if #available(iOS 15.0, macOS 12, tvOS 15.0, watchOS 6.0, *) {
                delegate = newValue
            }
        }
    }
}
