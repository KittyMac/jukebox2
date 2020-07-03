import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(jukebox2Tests.allTests),
    ]
}
#endif
