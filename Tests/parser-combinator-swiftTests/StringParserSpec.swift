import Foundation
import Nimble
import ParserCombinatorSwift
import Quick

typealias P = ParserCombinatorSwift.StringParser

class StringParserSpec: QuickSpec {
    override func spec() {
        describe("one") {
            it("hoge") {
                let s = "abc"
                let result = try! P.one.parse(s, s.startIndex).unwrap()
                expect("a").to(equal(result))
            }
            it("one.rep(1)") {
                let s = "abc"
                let result = try! P.one.rep(1).map { String($0) }.parse(s, s.startIndex).unwrap()
                expect("abc").to(equal(result))
            }
        }
        describe("string") {
            it("hoge") {
                let s = "abc"
                let result = try! P.string(s).parse(s, s.startIndex).unwrap()
                expect(s).to(equal(result))
            }
        }
        describe("log") {
            it("short") {
                let s = "abc"
                try! P.one.log("one").parse(s, s.startIndex)
            }
            it("long") {
                let s = "123456789012345***678901234567890"
                let parser = P.digits ~> P.string("***").log("aster")
                try! parser.parse(s, s.startIndex)
            }
        }
    }
}
