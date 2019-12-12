import Foundation

public enum StringParser {
    // MARK: - strings

    /// Parses a given String from a String.
    ///
    /// - Parameter string: the String which should be parsed
    /// - Returns: a parser that parses that String
    public static func string(_ string: String) -> Parser<String, String.Index, String> {
        return Parser<String, String.Index, String> { source, index in
            var i = index
            for c in string {
                if i >= source.endIndex {
                    return .failure(Errors.noMoreSource)
                }
                if c != source[i] {
                    return .failure(Errors.unexpectedCharacter(expected: c, got: source[i]))
                }
                i = source.index(after: i)
            }
            return .success(result: string, source: source, resultIndex: i)
        }
    }

    public static func char(_ char: Character) -> Parser<String, String.Index, Character> {
        return Parser<String, String.Index, Character> { source, index in
            guard index < source.endIndex else {
                return .failure(Errors.noMoreSource)
            }
            let c = source[index]
            if c == char {
                return .success(result: char, source: source, resultIndex: source.index(after: index))
            } else {
                return .failure(Errors.unexpectedCharacter(expected: char, got: c))
            }
        }
    }

    /// Parses one Character from a given String
    public static let one = Parser<String, String.Index, Character> { source, Index in
        if Index < source.endIndex {
            return .success(result: source[Index], source: source, resultIndex: source.index(after: Index))
        } else {
            return .failure(Errors.noMoreSource)
        }
    }

    /// Parses a string with the given length
    ///
    /// - Parameter length: the length the string should have
    /// - Returns: a parser that parses a string with exactly the given length
    public static func string(length: Int) -> Parser<String, String.Index, String> {
        return Parser<String, String.Index, String> { source, index in
            guard let endIndex = source.index(index, offsetBy: length, limitedBy: source.endIndex) else {
                return .failure(Errors.noMoreSource)
            }
            let result = source[index ..< endIndex]
            return .success(result: String(result), source: source, resultIndex: endIndex)
        }
    }

    public static func charPred(_ f: @escaping (Character) -> Bool) -> Parser<String, String.Index, Character> {
        let error = GenericParseError(message: "[WIP]") // TODO:
        return Parser<String, String.Index, Character> { source, index in
            if index >= source.endIndex {
                return .failure(Errors.noMoreSource)
            }
            let c = source[index]
            if f(c) {
                return .success(result: c, source: source, resultIndex: source.index(after: index))
            } else {
                return .failure(error)
            }
        }
    }

    public static func charWhilePred(_ f: @escaping (Character) -> Bool, min: Int, max: Int? = nil) -> Parser<String, String.Index, [Character]> {
        return Parser<String, String.Index, [Character]> { source, index in
            var count = 0
            var i = index
            loop: while max == nil || count < max!, i < source.endIndex, f(source[i]) {
                count += 1
                i = source.index(after: i)
            }
            if count >= min {
                return .success(result: Array(source[index ..< i]), source: source, resultIndex: i)
            } else {
                return .failure(Errors.expectedAtLeast(min, got: count))
            }
        }
    }

    public static func charIn(_ chars: String) -> Parser<String, String.Index, Character> { return charIn(Array(chars)) }

    public static func charIn(_ chars: Character...) -> Parser<String, String.Index, Character> { return charIn(Set(chars)) }

    public static func charIn(_ chars: [Character]) -> Parser<String, String.Index, Character> { return charIn(Set(chars)) }

    public static func charIn(_ chars: Set<Character>) -> Parser<String, String.Index, Character> {
        return charPred { chars.contains($0) }
    }

    // TODO: Deprecated if performance is worse than `charIn(_ set: Set<Character>)`
    public static func charIn(_ charset: CharacterSet) -> Parser<String, String.Index, Character> {
        return charPred { charset.contains($0.unicodeScalars[$0.unicodeScalars.startIndex]) }
    }

    public static func charsWhileIn(_ chars: String, min: Int, max: Int? = nil) -> Parser<String, String.Index, String> {
        return charsWhileIn(Array(chars), min: min, max: max).map { String($0) }
    }

    public static func charsWhileIn(_ chars: [Character], min: Int, max: Int? = nil) -> Parser<String, String.Index, String> {
        return charsWhileIn(Set(chars), min: min, max: max).map { String($0) }
    }

    public static func charsWhileIn(_ set: Set<Character>, min: Int, max: Int? = nil) -> Parser<String, String.Index, String> {
        return charWhilePred({ set.contains($0) }, min: min, max: max).map { String($0) }
    }

    public static func stringIn(_ xs: String...) -> Parser<String, String.Index, String> { return stringIn(Set(xs)) }

    public static func stringIn(_ xs: [String]) -> Parser<String, String.Index, String> { return stringIn(Set(xs)) }

    // TODO: Replace with one using trie
    public static func stringIn(_ xs: Set<String>) -> Parser<String, String.Index, String> {
        let error = GenericParseError(message: "Did not match stringIn(\(xs).")
        let dict = Dictionary(grouping: xs) { s in
            s.count
        }
        let sets: [(Int, Set<String>)] = Array(dict).sorted {
            $0.key < $1.key
        }.map { k, v in
            (k, Set(v))
        }

        return Parser<String, String.Index, String> { source, index in
            var subStr: Substring?
            let found = sets.first { len, set in
                guard let end = source.index(index, offsetBy: len, limitedBy: source.endIndex) else {
                    return false
                }
                subStr = source[index ..< end] // TODO: improve performance
                return set.contains(String(subStr!))
            }
            if let (len, _) = found {
                return .success(result: String(subStr!), source: source, resultIndex: source.index(index, offsetBy: len))
            } else {
                return .failure(error)
            }
        }
    }

    public static func trieStringIn(_ xs: Set<String>) -> Parser<String, String.Index, String> {
        let error = GenericParseError(message: "Did not match stringIn(\(xs)).")
        let trie = Trie<Character, String>()
        xs.forEach { trie.insert(Array($0), $0) }

        return Parser<String, String.Index, String> { source, index in
            if let (res, i) = trie.contains(source, index) {
                return .success(result: res, source: source, resultIndex: i)
            } else {
                return .failure(error)
            }
        }
    }

    public static let ascii = charPred { $0.isASCII }

    // MARK: - numbers

    /// Parses a digit [0-9] from a given String
    public static let digit: Parser<String, String.Index, Character> = charPred { $0.isNumber }

    public static let digits: Parser<String, String.Index, String> = charWhilePred({ $0.isNumber }, min: 1).map { String($0) }

    /// Parses a binary digit (0 or 1)
    public static let binaryDigit: Parser<String, String.Index, Character> = charPred { $0 == "0" || $0 == "1" }

    /// Parses a hexadecimal digit (0 to 15)
    public static let hexDigit: Parser<String, String.Index, Character> = charPred { $0.isHexDigit }

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
    public static let whitespace = charPred { $0.isWhitespace }

    /// Parses at least one whitespace
    public static let whitespaces = charWhilePred({ $0.isWhitespace }, min: 1)
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
