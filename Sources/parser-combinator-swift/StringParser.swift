import Foundation

public enum StringParser {
    // MARK: - strings

    /// Parses a given String from a String.
    ///
    /// - Parameter string: the String which should be parsed
    /// - Returns: a parser that parses that String
    public static func string(_ string: String) -> Parser<String, String> {
        let noMoreSourceFailure = ParseResult<String, String>.failure(Errors.noMoreSource)
        let unexpectedStringFailure = ParseResult<String, String>.failure(Errors.unexpectedString(expected: string))
        return Parser<String, String> { input, index in
            var i = index
            for c in string {
                if i >= input.endIndex {
                    return noMoreSourceFailure
                }
                if c != input[i] {
                    return unexpectedStringFailure
                }
                i = input.index(after: i)
            }
            return .success(output: string, input: input, next: i)
        }
    }

    public static func char(_ char: Character) -> Parser<String, Character> {
        let noMoreSourceFailure = ParseResult<String, Character>.failure(Errors.noMoreSource)
        let unexpectedCharacterFailure = ParseResult<String, Character>.failure(Errors.unexpectedCharacter(expected: char))
        return Parser<String, Character> { input, index in
            guard index < input.endIndex else {
                return noMoreSourceFailure
            }
            let c = input[index]
            if c == char {
                return .success(output: char, input: input, next: input.index(after: index))
            } else {
                return unexpectedCharacterFailure
            }
        }
    }

    /// Parses one Character from a given String
    public static let one : Parser<String, Character> = {
        let failure = ParseResult<String, Character>.failure(Errors.noMoreSource)
        return Parser<String, Character> { input, index in
            if index < input.endIndex {
                return .success(output: input[index], input: input, next: input.index(after: index))
            } else {
                return failure
            }
        }
    }()

    /// Parses a string with the given length
    ///
    /// - Parameter length: the length the string should have
    /// - Returns: a parser that parses a string with exactly the given length
    public static func string(length: Int) -> Parser<String, String> {
        let failure = ParseResult<String, String>.failure(Errors.noMoreSource)
        return Parser<String, String> { input, index in
            guard let endIndex = input.index(index, offsetBy: length, limitedBy: input.endIndex) else {
                return failure
            }
            let output = input[index ..< endIndex]
            return .success(output: String(output), input: input, next: endIndex)
        }
    }

    public static func charPred(_ f: @escaping (Character) -> Bool) -> Parser<String, Character> {
        let noMoreSourceFailure = ParseResult<String, Character>.failure(Errors.noMoreSource)
        let unsatisfiedPredicateFailure =  ParseResult<String, Character>.failure(Errors.unsatisfiedPredicate)
        return Parser<String, Character> { input, index in
            if index >= input.endIndex {
                return noMoreSourceFailure
            }
            let c = input[index]
            if f(c) {
                return .success(output: c, input: input, next: input.index(after: index))
            } else {
                return unsatisfiedPredicateFailure
            }
        }
    }

    public static func charWhilePred(_ f: @escaping (Character) -> Bool, min: Int, max: Int? = nil) -> Parser<String, [Character]> {
        let failure = ParseResult<String, [Character]>.failure(Errors.expectedAtLeast(count: min))
        return Parser<String, [Character]> { input, index in
            var count = 0
            var i = index
            loop: while max == nil || count < max!, i < input.endIndex, f(input[i]) {
                count += 1
                i = input.index(after: i)
            }
            if count >= min {
                return .success(output: Array(input[index ..< i]), input: input, next: i)
            } else {
                return failure
            }
        }
    }

    public static func charIn(_ chars: String) -> Parser<String, Character> { charIn(Array(chars)) }

    public static func charIn(_ chars: Character...) -> Parser<String, Character> { charIn(Set(chars)) }

    public static func charIn(_ chars: [Character]) -> Parser<String, Character> { charIn(Set(chars)) }

    public static func charIn(_ chars: Set<Character>) -> Parser<String, Character> {
        charPred { chars.contains($0) }
    }

    // TODO: Deprecated if performance is worse than `charIn(_ set: Set<Character>)`
    public static func charIn(_ charset: CharacterSet) -> Parser<String, Character> {
        charPred { charset.contains($0.unicodeScalars[$0.unicodeScalars.startIndex]) }
    }

    public static func charsWhileIn(_ chars: String, min: Int, max: Int? = nil) -> Parser<String, String> {
        charsWhileIn(Array(chars), min: min, max: max).map { String($0) }
    }

    public static func charsWhileIn(_ chars: [Character], min: Int, max: Int? = nil) -> Parser<String, String> {
        charsWhileIn(Set(chars), min: min, max: max).map { String($0) }
    }

    public static func charsWhileIn(_ set: Set<Character>, min: Int, max: Int? = nil) -> Parser<String, String> {
        charWhilePred({ set.contains($0) }, min: min, max: max).map { String($0) }
    }

    public static func stringIn(_ xs: String...) -> Parser<String, String> { stringIn(xs) }

    public static func stringIn(_ xs: [String]) -> Parser<String, String> { stringIn(Set(xs)) }

    // Note that Set<String> can be counterintuitive in deduplication criteria !
    // Specifically,
    // - Set(arrayLiteral: "\u{2000}", "\u{2002}").count == 1
    public static func stringIn(_ xs: Set<String>) -> Parser<String, String> {
        let failure = ParseResult<String, String>.failure(GenericParseError(message: "Did not match stringIn(\(xs))."))
        let trie = Trie<Character, String>()
        xs.forEach { trie.insert(Array($0), $0) }

        return Parser<String, String> { input, index in
            if let (res, i) = trie.contains(input, index) {
                return .success(output: res, input: input, next: i)
            } else {
                return failure
            }
        }
    }

    public static func dictionaryIn<A>(_ dict: [String: A]) -> Parser<String, A> {
        let failure = ParseResult<String, A>.failure(GenericParseError(message: "Did not match dictionaryIn(\(dict))."))
        let trie = Trie<Character, A>()
        dict.forEach { k, v in trie.insert(Array(k), v) }

        return Parser<String, A> { input, index in
            if let (res, i) = trie.contains(input, index) {
                return .success(output: res, input: input, next: i)
            } else {
                return failure
            }
        }
    }

    public static let ascii: Parser<String, Character> = charPred { $0.isASCII }

    // MARK: - numbers

    /// Parses a digit [0-9] from a given String
    public static let digit: Parser<String, Character> = charPred { $0.isNumber }

    public static let digits: Parser<String, String> = charWhilePred({ $0.isNumber }, min: 1).map { String($0) }

    /// Parses a binary digit (0 or 1)
    public static let binaryDigit: Parser<String, Character> = charPred { $0 == "0" || $0 == "1" }

    /// Parses a hexadecimal digit (0 to 15)
    public static let hexDigit: Parser<String, Character> = charPred { $0.isHexDigit }

    // MARK: - Common characters

    public static let start: Parser<String, String> = {
        let failure = ParseResult<String, String>.failure(Errors.notTheEnd)
        return Parser<String, String> { input, index in
            if index == input.startIndex {
                return .success(output: "", input: input, next: index)
            } else {
                return failure
            }
        }
    }()

    public static let end: Parser<String, String> = {
        let failure = ParseResult<String, String>.failure(Errors.notTheEnd)
        return Parser<String, String> { input, index in
            if index == input.endIndex {
                return .success(output: "", input: input, next: index)
            } else {
                return failure
            }
        }
    }()

    // MARK: - Whitespaces

    /// Parses one space character
    public static let whitespace: Parser<String, Character> = charPred { $0.isWhitespace }

    /// Parses at least one whitespace
    public static let whitespaces: Parser<String, [Character]> = charWhilePred({ $0.isWhitespace }, min: 1)
}

extension Parser where Input == String {
    public func log(_ name: String, _ offset: Int = 20) -> Parser<String, Output> {
        Parser<Input, Output> { input, index in
            let output = try self.parse(input, index)
            let idx: String.Index
            let resStr: String
            switch output {
            case let .success(res, _, i):
                resStr = String(describing: res)
                idx = i
            case let .failure(err):
                resStr = String(describing: err)
                idx = index // FIXME:
            }

            let next = idx < input.endIndex ? "```" + String(input[idx]) + "```" : ""

            let precedingStart = input.index(idx, offsetBy: -offset, limitedBy: input.startIndex) ?? input.startIndex
            let precedingEnd = idx
            let precedingSymbol = input.index(idx, offsetBy: -(offset + 3), limitedBy: input.startIndex).map { _ in "..." } ?? ""

            let succeedingStart = input.index(idx, offsetBy: 1, limitedBy: input.endIndex) ?? input.endIndex
            let succeedingEnd = input.index(idx, offsetBy: offset, limitedBy: input.endIndex) ?? input.endIndex
            let succeedingSymbol = input.index(idx, offsetBy: offset + 3, limitedBy: input.endIndex).map { _ in "..." } ?? ""

            let preceding = input[precedingStart ..< precedingEnd]
            let succeeding = input[succeedingStart ..< succeedingEnd]
            let partialSource = precedingSymbol + preceding + next + succeeding + succeedingSymbol

            print("\(name): output = \(resStr), input = \(partialSource)")
            return output
        }
    }
}
