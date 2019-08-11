import XCTest
@testable import VDCodable

final class VDCodableTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(VDCodable().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
