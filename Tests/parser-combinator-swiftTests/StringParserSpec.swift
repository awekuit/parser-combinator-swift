import Foundation
import Nimble
import ParserCombinatorSwift
import Quick

class StringParserSpec: QuickSpec {
    typealias P = ParserCombinatorSwift.StringParser

    override func spec() {
        it("one") {
            let input = "abc"
            let output = try! P.one.parse(input, input.startIndex).unwrap()
            expect("a").to(equal(output))
        }
        it("one.rep(1)") {
            let input = "abc"
            let output = try! P.one.rep(1).map { String($0) }.parse(input, input.startIndex).unwrap()
            expect("abc").to(equal(output))
        }
        it("string") {
            let input = "abc"
            let output = try! P.string(input).parse(input, input.startIndex).unwrap()
            expect(input).to(equal(output))
        }
//        it("stringIn") {
//            let input = "\u{2000}\u{2002}"
//            let parser = P.stringIn("\u{2000}", "\u{2002}").rep(1).map { $0.joined(separator: "") }
//            let output = try! parser.parse(input, input.startIndex).unwrap()
//            expect(input).to(equal(output))
//        }
        describe("log") {
            it("short") {
                let input = "abc"
                try! P.one.log("one").parse(input, input.startIndex)
            }
            it("long") {
                let input = "123456789012345***678901234567890"
                let parser = P.digits ~> P.string("***").log("aster")
                try! parser.parse(input, input.startIndex)
            }
        }
    }
}
