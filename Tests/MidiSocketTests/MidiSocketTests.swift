import XCTest
@testable import MidiSocket

final class MidiSocketTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(MidiSocket().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
