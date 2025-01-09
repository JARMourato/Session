import XCTest

extension XCTestCase {
    func assert<E: Swift.Error & Equatable>(thrownError: Swift.Error?, is error: E, in file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(thrownError is E, "Unexpected error type: \(type(of: thrownError))", file: file, line: line)
        XCTAssertEqual(thrownError as? E, error, file: file, line: line)
        XCTAssertEqual(thrownError?.localizedDescription, (thrownError as? E)?.localizedDescription)
    }

    func assert(_ expression: @autoclosure () throws -> some Any, throws error: some Swift.Error & Equatable, in file: StaticString = #filePath, line: UInt = #line) {
        var thrownError: Swift.Error?
        XCTAssertThrowsError(try expression(), file: file, line: line) { thrownError = $0 }
        assert(thrownError: thrownError, is: error)
    }
}
