// Copyright © 2022 João Mourato. All rights reserved.

import Foundation
import RNP

// MARK: - Data Task

public extension Session {
    func data(for r: Requestable) async throws -> DataResponse {
        let request = try r._buildURLRequest()
        let response: DataResponse = try await urlSession.data(for: request, delegate: taskDelegate)
        return response
    }
}

// MARK: - Download Tasks

public extension Session {
    func download(for r: Requestable) async throws -> DownloadResponse {
        let request = try r._buildURLRequest()
        let response: DownloadResponse = try await urlSession.download(for: request, delegate: taskDelegate)
        return response
    }

    func download(resumeFrom data: Data) async throws -> DownloadResponse {
        let response: DownloadResponse = try await urlSession.download(resumeFrom: data, delegate: taskDelegate)
        return response
    }
}

// MARK: - Upload Tasks

public extension Session {
    func upload(for r: Requestable, fromFile fileURL: URL) async throws -> UploadResponse {
        let request = try r._buildURLRequest()
        let response: UploadResponse = try await urlSession.upload(for: request, fromFile: fileURL, delegate: taskDelegate)
        return response
    }

    func upload(for r: Requestable, fromData bodyData: Data) async throws -> UploadResponse {
        let request = try r._buildURLRequest()
        let response: UploadResponse = try await urlSession.upload(for: request, from: bodyData, delegate: taskDelegate)
        return response
    }
}

// MARK: - Internal Helpers

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
