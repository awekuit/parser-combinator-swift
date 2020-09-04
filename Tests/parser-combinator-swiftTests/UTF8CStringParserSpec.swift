import Foundation
import Nimble
import ParserCombinatorSwift
import Quick

class UTF8CStringParserSpec: QuickSpec {
    private typealias P = ParserCombinatorSwift.UTF8CStringParser

    override func spec() {
        it("one") {
            let input = "abc".utf8CString
            let output = try! P.one.parse(input, input.startIndex).unwrap()
            expect(input.first!).to(equal(output))
        }
        it("one.rep(1)") {
            let input = "abc".utf8CString
            let output = try! P.one.rep(1).parse(input, input.startIndex).unwrap()
            expect(input.dropLast()).to(equal(output)) // `dropLast()` means to remove Null Terminated
        }
        it("string") {
            let input = "abc"
            let output = try! P.string(input).parse(input.utf8CString, input.utf8CString.startIndex).unwrap()
            expect(input).to(equal(output))
        }
//        it("stringIn") {
//            let input = "\u{2000}\u{2002}"
//            let parser = P.stringIn("\u{2000}", "\u{2002}").rep(1).map { $0.joined(separator: "") }
//            let output = try! parser.parse(input.utf8CString, input.utf8CString.startIndex).unwrap()
//            expect(input).to(equal(output))
//        }
    }
}
