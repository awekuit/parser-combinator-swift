import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        return [
            testCase(parser_combinator_swiftTests.allTests),
        ]
    }
#endif
