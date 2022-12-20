// Copyright © 2022 João Mourato. All rights reserved.

import Foundation
import RNP

// MARK: - Data Task

public extension Session {
    func data(for r: Requestable) async throws -> DataResponse {
        let request = try r._buildURLRequest()
        let response: DataResponse

        if #available(iOS 15.0, macOS 12, tvOS 15.0, watchOS 6.0, *), !Session.disableConcurrency {
            response = try await urlSession.data(for: request, delegate: taskDelegate)
        } else {
            response = try await asyncify { urlSession.dataTask(with: request, completionHandler: $0) }
        }

        return response
    }
}

// MARK: - Download Tasks

public extension Session {
    func download(for r: Requestable) async throws -> DownloadResponse {
        let request = try r._buildURLRequest()
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
        let request = try r._buildURLRequest()
        let response: UploadResponse

        if #available(iOS 15.0, macOS 12, tvOS 15.0, watchOS 6.0, *), !Session.disableConcurrency {
            response = try await urlSession.upload(for: request, fromFile: fileURL, delegate: taskDelegate)
        } else {
            response = try await asyncify { urlSession.uploadTask(with: request, fromFile: fileURL, completionHandler: $0) }
        }

        return response
    }

    func upload(for r: Requestable, fromData bodyData: Data) async throws -> UploadResponse {
        let request = try r._buildURLRequest()
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
    func _buildURLRequest() throws -> URLRequest {
        let request: URLRequest
        do {
            request = try buildURLRequest()
        } catch {
            throw SessionError.invalidRequest(rawError: error)
        }
        return request
    }
}

// MARK: - Testing Helpers

extension Session {
    static var disableConcurrency: Bool = false
    static var disableTaskDelegate: Bool = false
}

protocol SessionTask: AnyObject {
    var taskDelegate: URLSessionTaskDelegate? { get set }
    func resume()
}

extension URLSessionTask: SessionTask {
    var taskDelegate: URLSessionTaskDelegate? {
        get {
            let del: URLSessionTaskDelegate?
            if #available(iOS 15.0, macOS 12, tvOS 15.0, watchOS 6.0, *), !Session.disableTaskDelegate {
                del = delegate
            } else {
                del = nil
            }
            return del
        }
        set {
            if #available(iOS 15.0, macOS 12, tvOS 15.0, watchOS 6.0, *), !Session.disableTaskDelegate {
                delegate = newValue
            }
        }
    }
}
