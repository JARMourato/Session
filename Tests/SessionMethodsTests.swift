import Foundation
@testable import Session
import XCTest

final class SessionMethodsTests: XCTestCase {
    let session = Session { ProtocolClasses(classes: [MockURLProtocol.self]) }
    let mockURL = URL(string: "www.google.com")!
    var mockURLRequest: URLRequest { URLRequest(url: mockURL) }
    let requestResponse = "Success"

    override func setUp() {
        Session.disableConcurrency = false
    }

    override class func tearDown() {
        Session.disableConcurrency = false
    }

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
        Session.disableTaskDelegate = true
        let delegateThree = taskTwo.taskDelegate
        // Then
        XCTAssertNil(delegateOne)
        XCTAssertNotNil(delegateTwo)
        XCTAssertNil(delegateThree)
    }

    // MARK: - Asyncify Tests

    func test_asyncify_data() async throws {
        // Given
        let mResponse = HTTPURLResponse(url: mockURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let mData = requestResponse.data(using: .utf8)
        let mockSessionTask = MockURLSessionTask(data: mData, response: mResponse, error: nil)
        // When
        let (data, response) = try await session.asyncify { mockSessionTask.executeWith(completionHandler: $0) }
        // Then
        XCTAssertEqual(String(data: data, encoding: .utf8), requestResponse)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
    }

    func test_asyncify_error() async throws {
        // Given
        enum MockError: Equatable, Error {
            case failed
        }
        let mockSessionTask = MockURLSessionTask(data: nil, response: nil, error: MockError.failed)
        do { // When
            _ = try await session.asyncify { mockSessionTask.executeWith(completionHandler: $0) }
        } catch { // Then
            assert(thrownError: error, is: MockError.failed)
        }
    }

    func test_asyncify_invalid() async throws {
        // Given
        let mockSessionTask = MockURLSessionTask(data: nil, response: nil, error: nil)
        do { // When
            _ = try await session.asyncify { mockSessionTask.executeWith(completionHandler: $0) }
        } catch { // Then
            assert(thrownError: error, is: SessionError.invalidResponse)
        }
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
        let response = try await session.dataResponse(for: request)
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

    // MARK: - Task Methods With Session Concurrency Disabled

    // MARK: Data

    func test_data_task_asyncify() async throws {
        Session.disableConcurrency = true
        try await test_data_task()
    }

    // MARK: Download

    func test_download_task_asyncify() async throws {
        Session.disableConcurrency = true
        try await test_download_task()
    }

    func test_download_resume_task_asyncify() async throws {
        Session.disableConcurrency = true
        try await test_download_resume_task()
    }

    // MARK: Upload

    func test_upload_from_data_task_asyncify() async throws {
        Session.disableConcurrency = true
        try await test_upload_from_data_task()
    }

    func test_upload_from_url_task_asyncify() async throws {
        Session.disableConcurrency = true
        try await test_upload_from_url_task()
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
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

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

class MockURLSessionTaskDelegate: NSObject, URLSessionTaskDelegate {}
