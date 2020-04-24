import XCTest

import MidiSocketTests

var tests = [XCTestCaseEntry]()
tests += MidiSocketTests.allTests()
XCTMain(tests)
