// Copyright © 2022 João Mourato. All rights reserved.

@testable import Session
import XCTest

final class AuxiliaryTypesTests: XCTestCase {
//    // MARK: Requestable
//
//    func test_urlRequest_make() throws {
//        // Given
//        let urlRequest = URLRequest(url: URL(string: "www.google.com")!)
//        // When
//        let requestable: Requestable = urlRequest
//        // Then
//        XCTAssertEqual(urlRequest, try requestable._makeURLRequest())
//    }
//
//    func test_invalid_make() {
//        // Given
//        enum CustomError: Error, Equatable { case invalidURL }
//        struct InvalidMaker: Requestable {
//            func makeURLRequest() throws -> URLRequest {
//                throw CustomError.invalidURL
//            }
//        }
//        // When
//        let makerExpression = { try InvalidMaker()._makeURLRequest() }
//        // Then
//        assert(try makerExpression(), throws: SessionError.invalidRequest(rawError: CustomError.invalidURL))
//    }
//
//    // MARK: SessionError conformance to Equatable
//
//    func test_sessionError_is_equatable() {
//        enum CustomError: Error { case failed, timeout }
//
//        XCTAssertEqual(SessionError.invalidResponse, SessionError.invalidResponse)
//        XCTAssertEqual(SessionError.invalidRequest(rawError: CustomError.failed), SessionError.invalidRequest(rawError: CustomError.failed))
//        XCTAssertNotEqual(SessionError.invalidResponse, SessionError.invalidRequest(rawError: CustomError.failed))
//        XCTAssertNotEqual(SessionError.invalidRequest(rawError: CustomError.timeout), SessionError.invalidRequest(rawError: CustomError.failed))
//    }
}
