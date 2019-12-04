import Foundation

public enum StringParser {
    // MARK: - strings

    /// Parses one Character from a given String
    public static let one = Parser<String, String.Index, Character> { source, Index in
        if Index < source.endIndex {
            return .success(result: source[Index], source: source, resultIndex: source.index(after: Index))
        } else {
            return .failure(Errors.noMoreSources)
        }
    }

    /// Parses a given String from a String.
    ///
    /// - Parameter string: the String which should be parsed
    /// - Returns: a parser that parses that String
    public static func string(_ string: String) -> Parser<String, String.Index, String> {
        return Parser<String, String.Index, String> { source, index in
            let count: Int = string.count
            guard let endIndex = source.index(index, offsetBy: count, limitedBy: source.endIndex) else {
                return .failure(Errors.noMoreSources)
            }
            let got = String(source[index ..< endIndex])
            if got == string {
                return .success(result: string, source: source, resultIndex: endIndex)
            } else {
                return .failure(Errors.unexpectedToken(expected: string, got: got))
            }
        }
    }

    /// Parses a string with the given length
    ///
    /// - Parameter length: the length the string should have
    /// - Returns: a parser that parses a string with exactly the given length
    public static func string(length: Int) -> Parser<String, String.Index, String> {
        return one.rep(length, length).map { String($0) }
    }

    public static let ascii = one.filter { $0.isASCII }

    public static func charIn(_ xs: Character...) -> Parser<String, String.Index, Character> { return charIn(Set(xs)) }

    public static func charIn(_ xs: [Character]) -> Parser<String, String.Index, Character> { return charIn(Set(xs)) }

    public static func charIn(_ set: Set<Character>) -> Parser<String, String.Index, Character> {
        return StringParser.one.filter { set.contains($0) }
    }

    // TODO: Deprecated if performance is worse than `charIn(_ set: Set<Character>)`
    public static func charIn(_ charset: CharacterSet) -> Parser<String, String.Index, Character> {
        return StringParser.one.filter { charset.contains($0.unicodeScalars[$0.unicodeScalars.startIndex]) }
    }

    public static func stringIn(_ xs: String...) -> Parser<String, String.Index, String> { return stringIn(Set(xs)) }

    public static func stringIn(_ xs: [String]) -> Parser<String, String.Index, String> { return stringIn(Set(xs)) }

    // TODO: Replace with one using trie
    public static func stringIn(_ xs: Set<String>) -> Parser<String, String.Index, String> {
        let dict = Dictionary(grouping: xs) { s in
            s.count
        }
        let sets: [(Int, Set<String>)] = Array(dict).sorted {
            $0.key < $1.key
        }.map { k, v in
            (k, Set(v))
        }
        let errorMessage = "Did not match stringIn(\(xs)."

        return Parser<String, String.Index, String> { source, index in
            let src = source[index...]
            var subStr: String?
            let found = sets.first { len, set in
                if src.count < len {
                    return false
                } else {
                    subStr = String(src.prefix(len))
                    return set.contains(subStr!)
                }
            }
            if let (len, _) = found {
                return .success(result: subStr!, source: source, resultIndex: source.index(index, offsetBy: len))
            } else {
                return .failure(GenericParseError(message: errorMessage))
            }
        }
    }

    // MARK: - numbers

    /// Parses a digit [0-9] from a given String
    public static let digit: Parser<String, String.Index, Character> = one.filter { $0.isNumber }

    public static let digits: Parser<String, String.Index, String> = one.filter { $0.isNumber }.rep(1).map { String($0) }

    /// Parses a binary digit (0 or 1)
    public static let binaryDigit: Parser<String, String.Index, Character> = charIn("0", "1")

    /// Parses an octal digit (0 to 7)
    public static let octalDigit: Parser<String, String.Index, Character> = digit.filter { Int(String($0))! < 8 }

    /// Parses a hexadecimal digit (0 to 15)
    public static let hexDigit: Parser<String, String.Index, Character> = one.filter { $0.isHexDigit }

    // MARK: - Common characters

    public static let start: Parser<String, String.Index, String> = Parser<String, String.Index, String> { source, index in
        if index == source.startIndex {
            return .success(result: "", source: source, resultIndex: index)
        } else {
            return .failure(Errors.notTheEnd)
        }
    }

    public static let end: Parser<String, String.Index, String> = Parser<String, String.Index, String> { source, index in
        if index == source.endIndex {
            return .success(result: "", source: source, resultIndex: index)
        } else {
            return .failure(Errors.notTheEnd)
        }
    }

    // MARK: - Whitespaces

    /// Parses one space character
    public static let whitespace = one.filter { $0.isWhitespace }

    /// Parses at least one whitespace
    public static let whitespaces = whitespace.rep(1)
}

extension Parser where Source == String, Index == String.Index {
    public func log(_ name: String, _ offset: Int = 20) -> Parser<String, String.Index, Result> {
        return Parser<Source, Index, Result> { source, index in
            let result = try self.parse(source, index)
            let idx: String.Index
            let resStr: String
            switch result {
            case let .success(res, _, i):
                resStr = String(describing: res)
                idx = i
            case let .failure(err):
                resStr = String(describing: err)
                idx = index // FIXME:
            }

            let next = idx < source.endIndex ? "```" + String(source[idx]) + "```" : ""

            let precedingStart = source.index(idx, offsetBy: -offset, limitedBy: source.startIndex) ?? source.startIndex
            let precedingEnd = idx
            let precedingSymbol = source.index(idx, offsetBy: -(offset + 3), limitedBy: source.startIndex).map { _ in "..." } ?? ""

            let succeedingStart = source.index(idx, offsetBy: 1, limitedBy: source.endIndex) ?? source.endIndex
            let succeedingEnd = source.index(idx, offsetBy: offset, limitedBy: source.endIndex) ?? source.endIndex
            let succeedingSymbol = source.index(idx, offsetBy: offset + 3, limitedBy: source.endIndex).map { _ in "..." } ?? ""

            let preceding = source[precedingStart ..< precedingEnd]
            let succeeding = source[succeedingStart ..< succeedingEnd]
            let partialSource = precedingSymbol + preceding + next + succeeding + succeedingSymbol

            print("\(name): result = \(resStr), source = \(partialSource)")
            return result
        }
    }
}
