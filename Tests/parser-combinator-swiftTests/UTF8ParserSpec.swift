import Foundation
import Nimble
import ParserCombinatorSwift
import Quick

class UTF8ParserSpec: QuickSpec {
    private typealias P = ParserCombinatorSwift.UTF8Parser

    override func spec() {
        it("one") {
            let input = "abc".utf8
            let output = try! P.one.parse(input, input.startIndex).unwrap()
            expect(input.first!).to(equal(output))
        }
        it("one.rep(1)") {
            let input = "abc".utf8
            let output = try! P.one.rep(1).parse(input, input.startIndex).unwrap()
            expect(Array(input)).to(equal(output))
        }
        it("string") {
            let input = "abc"
            let output = try! P.string(input).parse(input.utf8, input.startIndex).unwrap()
            expect(input).to(equal(output))
        }
        it("stringIn") {
            let input = "\u{2000}\u{2002}"
            let parser = P.stringIn("\u{2000}", "\u{2002}").rep(1).map { $0.joined(separator: "") }
            let output = try! parser.parse(input.utf8, input.startIndex).unwrap()
            expect(input).to(equal(output))
        }
    }
}
