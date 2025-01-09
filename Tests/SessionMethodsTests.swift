import Foundation
@testable import Session
import XCTest

final class SessionMethodsTests: XCTestCase {
    let session = Session { ProtocolClasses(classes: [MockURLProtocol.self]) }
    let mockURL = URL(string: "www.google.com")!
    var mockURLRequest: URLRequest { URLRequest(url: mockURL) }
    let requestResponse = "Success"

    // MARK: - Task Delegate Tests

    func test_taskDelegate_helper() {
        // Given
        let request = mockURLRequest
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        // When
        let taskOne: SessionTask = session.dataTask(with: request)
        let taskTwo: SessionTask = session.dataTask(with: request)
        taskTwo.taskDelegate = MockURLSessionTaskDelegate()
        let delegateOne = taskOne.taskDelegate
        let delegateTwo = taskTwo.taskDelegate
        // Then
        XCTAssertNil(delegateOne)
        XCTAssertNotNil(delegateTwo)
    }

    // MARK: - Task Methods With Session Concurrency Enabled

    // MARK: Data

    func test_data_task() async throws {
        // Given
        let request: URLRequest = mockURLRequest
        let mResponse = HTTPURLResponse(url: mockURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let mData = requestResponse.data(using: .utf8)
        MockURLProtocol.requestHandler = { _ in (mResponse, mData) }
        // When
        let response = try await session.response(for: request)
        // Then
        XCTAssertEqual(response.request, request)
        XCTAssertEqual((response.result.urlResponse as? HTTPURLResponse)?.url, mResponse.url)
        XCTAssertEqual((response.result.urlResponse as? HTTPURLResponse)?.statusCode, mResponse.statusCode)
        XCTAssertEqual(response.result.data, mData)
    }

    // MARK: Download

    func test_download_task() async throws {
        // Given
        let request: URLRequest = mockURLRequest
        let mResponse = HTTPURLResponse(url: mockURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let mData = requestResponse.data(using: .utf8)!
        MockURLProtocol.requestHandler = { _ in (mResponse, mData) }
        // When
        let (url, response) = try await session.download(for: request)
        // Then
        XCTAssertEqual((response as? HTTPURLResponse)?.url, mResponse.url)
        XCTAssertEqual(requestResponse, try String(contentsOf: url))
    }

    func test_download_resume_task() async throws {
        // Given
        let mResponse = HTTPURLResponse(url: mockURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let mData = requestResponse.data(using: .utf8)!
        MockURLProtocol.requestHandler = { _ in (mResponse, mData) }
        // When
        let (url, response) = try await session.download(resumeFrom: Data())
        // Then
        XCTAssertEqual((response as? HTTPURLResponse)?.url, mResponse.url)
        XCTAssertEqual(requestResponse, try String(contentsOf: url))
    }

    // MARK: Upload

    func test_upload_from_data_task() async throws {
        // Given
        let request: URLRequest = mockURLRequest
        let mResponse = HTTPURLResponse(url: mockURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let mData = requestResponse.data(using: .utf8)!
        MockURLProtocol.requestHandler = { _ in (mResponse, mData) }
        // When
        let (data, response) = try await session.upload(for: request, fromData: Data())
        // Then
        XCTAssertEqual((response as? HTTPURLResponse)?.url, mResponse.url)
        XCTAssertEqual(String(data: data, encoding: .utf8), requestResponse)
    }

    func test_upload_from_url_task() async throws {
        // Given
        let request: URLRequest = mockURLRequest
        let mResponse = HTTPURLResponse(url: mockURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let mData = requestResponse.data(using: .utf8)!
        MockURLProtocol.requestHandler = { _ in (mResponse, mData) }
        // When
        let (data, response) = try await session.upload(for: request, fromFile: mockURL)
        // Then
        XCTAssertEqual((response as? HTTPURLResponse)?.url, mResponse.url)
        XCTAssertEqual(String(data: data, encoding: .utf8), requestResponse)
    }
}

// MARK: - Mock URLSessionTask

class MockURLSessionTask: SessionTask {
    var taskDelegate: URLSessionTaskDelegate?

    let data: Data?
    let response: URLResponse?
    let error: Error?

    init(delegate: URLSessionTaskDelegate? = nil, data: Data?, response: URLResponse?, error: Error?) {
        taskDelegate = delegate
        self.data = data
        self.response = response
        self.error = error
    }

    func resume() { /* Do nothing */ }

    func executeWith(completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> SessionTask {
        defer { completionHandler(data, response, error) }
        return self
    }
}

// MARK: - Mock URLProtocol

class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    override class func canInit(with _: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else { fatalError("Handler is unavailable.") }

        do {
            // 2. Call handler with received request and capture the tuple of response and data.
            let (response, data) = try handler(request)

            // 3. Send received response to the client.
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

            if let data {
                // 4. Send received data to the client.
                client?.urlProtocol(self, didLoad: data)
            }

            // 5. Notify request has been finished.
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            // 6. Notify received error.
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
}

// MARK: - Mock URLSessionTaskDelegate

class MockURLSessionTaskDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {}
