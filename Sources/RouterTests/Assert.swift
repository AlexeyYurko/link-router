import Foundation

var checks = 0
var failures = 0

func check(_ condition: Bool, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) {
    checks += 1
    if !condition {
        failures += 1
        print("FAIL \(file):\(line) \(message())")
    }
}

func checkEqual<T: Equatable>(_ got: T, _ expected: T, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    check(got == expected, "\(message) expected \(expected), got \(got)", file: file, line: line)
}

func checkNil<T>(_ value: T?, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
    check(value == nil, "\(message) expected nil, got \(String(describing: value))", file: file, line: line)
}