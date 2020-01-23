import Foundation

public enum UTF16Parser {
    // MARK: - strings

    /// Parses a given String from a String.
    ///
    /// - Parameter string: the String which should be parsed
    /// - Returns: a parser that parses that String
    public static func string(_ string: String) -> Parser<String.UTF16View, String.UTF16View.Index, String> {
        let view = string.utf16
        return Parser<String.UTF16View, String.UTF16View.Index, String> { source, index in
            var i = index
            for e in view {
                guard i < source.endIndex else {
                    return .failure(Errors.noMoreSource)
                }
                guard e == source[i] else {
                    return .failure(GenericErrors.unexpectedToken(expected: e, got: source[i]))
                }
                i = source.index(after: i)
            }
            return .success(result: string, source: source, resultIndex: i)
        }
    }

    public static func elem(_ elem: String.UTF16View.Element) -> Parser<String.UTF16View, String.UTF16View.Index, String.UTF16View.Element> {
        Parser<String.UTF16View, String.UTF16View.Index, String.UTF16View.Element> { source, index in
            let e = source[index]
            if e == elem {
                return .success(result: elem, source: source, resultIndex: source.index(after: index))
            } else {
                return .failure(GenericErrors.unexpectedToken(expected: elem, got: e))
            }
        }
    }

    public static let one = Parser<String.UTF16View, String.UTF16View.Index, String.UTF16View.Element> { source, index in
        if index < source.endIndex {
            return .success(result: source[index], source: source, resultIndex: source.index(after: index))
        } else {
            return .failure(Errors.noMoreSource)
        }
    }

    public static let char = Parser<String.UTF16View, String.UTF16View.Index, Character> { source, index in
        guard index < source.endIndex else {
            return .failure(Errors.noMoreSource)
        }
        if UTF16.isSurrogate(source[index]) {
            let resultIndex = source.index(index, offsetBy: 2)
            return .success(result: Character(String(source[index ..< resultIndex])!), source: source, resultIndex: resultIndex)
        } else {
            let resultIndex = source.index(after: index)
            return .success(result: Character(String(utf16CodeUnits: [source[index]], count: 1)), source: source, resultIndex: resultIndex)
        }
    }

    public static func charPred(_ f: @escaping (String.UTF16View.Element) -> Bool) -> Parser<String.UTF16View, String.UTF16View.Index, String> {
        Parser<String.UTF16View, String.UTF16View.Index, String> { source, index in
            if index >= source.endIndex {
                return .failure(Errors.noMoreSource)
            }
            let c = source[index]
            if f(c) {
                return .success(result: String(utf16CodeUnits: [c], count: 1), source: source, resultIndex: source.index(after: index))
            } else {
                return .failure(GenericParseError(message: "[WIP]")) // TODO:
            }
        }
    }

    public static func charWhilePred(_ f: @escaping (String.UTF16View.Element) -> Bool, min: Int, max: Int? = nil) -> Parser<String.UTF16View, String.UTF16View.Index, String> {
        Parser<String.UTF16View, String.UTF16View.Index, String> { source, index in
            var count = 0
            var i = index
            var buffer: [String.UTF16View.Element] = []
            loop: while max == nil || count < max!, i < source.endIndex, f(source[i]) {
                buffer.append(source[i])
                count += 1
                i = source.index(after: i)
            }
            if count >= min {
                return .success(result: String(utf16CodeUnits: buffer, count: buffer.count), source: source, resultIndex: i)
            } else {
                return .failure(Errors.expectedAtLeast(min, got: count))
            }
        }
    }

    public static func charIn(_ chars: String) -> Parser<String.UTF16View, String.UTF16View.Index, String> {
        charIn(Array(chars))
    }

    public static func charIn(_ chars: Character...) -> Parser<String.UTF16View, String.UTF16View.Index, String> {
        charIn(chars)
    }

    public static func charIn(_ chars: [Character]) -> Parser<String.UTF16View, String.UTF16View.Index, String> {
        let cs: [String.UTF16View.Element] = chars.map { char in
            let view = String(char).utf16
            precondition(view.count == 1)
            return view.first!
        }
        return charIn(cs)
    }

    public static func charIn(_ chars: String.UTF16View.Element...) -> Parser<String.UTF16View, String.UTF16View.Index, String> { charIn(Set(chars)) }

    public static func charIn(_ chars: [String.UTF16View.Element]) -> Parser<String.UTF16View, String.UTF16View.Index, String> { charIn(Set(chars)) }

    public static func charIn(_ chars: Set<String.UTF16View.Element>) -> Parser<String.UTF16View, String.UTF16View.Index, String> {
        charPred { chars.contains($0) }
    }

    // TODO: Deprecated if performance is worse than `charIn(_ set: Set<Character>)`
    public static func charIn(_ charset: CharacterSet) -> Parser<String.UTF16View, String.UTF16View.Index, String> {
        // TODO: precondition で charset が UTF16 で1要素なもののみで構成されている事をチェックする
        charPred { charset.contains(String(utf16CodeUnits: [$0], count: 1).unicodeScalars.first!) }
    }

    public static func charsWhileIn(_ chars: String, min: Int, max: Int? = nil) -> Parser<String.UTF16View, String.UTF16View.Index, String> {
        charsWhileIn(Array(chars.utf16), min: min, max: max)
    }

    public static func charsWhileIn(_ chars: [String.UTF16View.Element], min: Int, max: Int? = nil) -> Parser<String.UTF16View, String.UTF16View.Index, String> {
        charsWhileIn(Set(chars), min: min, max: max)
    }

    public static func charsWhileIn(_ set: Set<String.UTF16View.Element>, min: Int, max: Int? = nil) -> Parser<String.UTF16View, String.UTF16View.Index, String> {
        charWhilePred({ set.contains($0) }, min: min, max: max)
    }

    public static func stringIn(_ xs: String...) -> Parser<String.UTF16View, String.UTF16View.Index, String> { stringIn(Set(xs)) }

    public static func stringIn(_ xs: [String]) -> Parser<String.UTF16View, String.UTF16View.Index, String> { stringIn(Set(xs)) }

    // TODO: Replace with one using trie
    public static func stringIn(_ xs: Set<String>) -> Parser<String.UTF16View, String.UTF16View.Index, String> {
        let errorMessage = "Did not match stringIn(\(xs))."
        let trie = Trie<String.UTF16View.Element, String>()
        xs.forEach { trie.insert(Array($0.utf16), $0) }

        return Parser<String.UTF16View, String.UTF16View.Index, String> { source, index in
            var i: String.UTF16View.Index = index
            var currentNode = trie.root
            var matched = false // FIXME: Remove this var if that is possible.
            loop: while i < source.endIndex {
                let elem = source[i]
                i = source.index(after: i)
                if let childNode = currentNode.children[elem] {
                    currentNode = childNode
                    if currentNode.isTerminating {
                        matched = true
                        break loop
                    }
                } else {
                    break loop
                }
            }
            if matched {
                return .success(result: currentNode.original!, source: source, resultIndex: i)
            } else {
                return .failure(GenericParseError(message: errorMessage))
            }
        }
    }

    public static func dictionaryIn<A>(_ dict: [String: A]) -> Parser<String.UTF16View, String.UTF16View.Index, A> {
        let error = GenericParseError(message: "Did not match dictionaryIn(\(dict)).")
        let trie = Trie<String.UTF16View.Element, A>()
        dict.forEach { k, v in trie.insert(Array(k.utf16), v) }

        return Parser<String.UTF16View, String.UTF16View.Index, A> { source, index in
            if let (res, i) = trie.contains(source, index) {
                return .success(result: res, source: source, resultIndex: i)
            } else {
                return .failure(error)
            }
        }
    }

    // MARK: - numbers

    /// Parses a digit [0-9] from a given String
    public static let digit: Parser<String.UTF16View, String.UTF16View.Index, String> = charIn("0123456789")

    public static let digits: Parser<String.UTF16View, String.UTF16View.Index, String> = charsWhileIn("0123456789", min: 1)

    /// Parses a binary digit (0 or 1)
    public static let binaryDigit: Parser<String.UTF16View, String.UTF16View.Index, String> = charIn("01")

    /// Parses a hexadecimal digit (0 to 15)
    public static let hexDigit: Parser<String.UTF16View, String.UTF16View.Index, String> = charIn("01234567")

    // MARK: - Common characters

    public static let start: Parser<String.UTF16View, String.UTF16View.Index, String> = Parser<String.UTF16View, String.UTF16View.Index, String> { source, index in
        if index == source.startIndex {
            return .success(result: "", source: source, resultIndex: index)
        } else {
            return .failure(Errors.notTheEnd)
        }
    }

    public static let end: Parser<String.UTF16View, String.UTF16View.Index, String> = Parser<String.UTF16View, String.UTF16View.Index, String> { source, index in
        if index == source.endIndex {
            return .success(result: "", source: source, resultIndex: index)
        } else {
            return .failure(Errors.notTheEnd)
        }
    }
}
