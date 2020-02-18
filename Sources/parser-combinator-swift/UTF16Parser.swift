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
            return .success(result: string, source: source, next: i)
        }
    }

    public static func elem(_ elem: String.UTF16View.Element) -> Parser<String.UTF16View, String.UTF16View.Index, String.UTF16View.Element> {
        Parser<String.UTF16View, String.UTF16View.Index, String.UTF16View.Element> { source, index in
            let e = source[index]
            if e == elem {
                return .success(result: elem, source: source, next: source.index(after: index))
            } else {
                return .failure(GenericErrors.unexpectedToken(expected: elem, got: e))
            }
        }
    }

    public static let one = Parser<String.UTF16View, String.UTF16View.Index, String.UTF16View.Element> { source, index in
        if index < source.endIndex {
            return .success(result: source[index], source: source, next: source.index(after: index))
        } else {
            return .failure(Errors.noMoreSource)
        }
    }

    public static let char = Parser<String.UTF16View, String.UTF16View.Index, Character> { source, index in
        guard index < source.endIndex else {
            return .failure(Errors.noMoreSource)
        }
        if UTF16.isSurrogate(source[index]) {
            let nextIndex = source.index(index, offsetBy: 2)
            return .success(result: Character(String(source[index ..< nextIndex])!), source: source, next: nextIndex)
        } else {
            let nextIndex = source.index(after: index)
            return .success(result: Character(String(utf16CodeUnits: [source[index]], count: 1)), source: source, next: nextIndex)
        }
    }

    public static func elemPred(_ f: @escaping (String.UTF16View.Element) -> Bool) -> Parser<String.UTF16View, String.UTF16View.Index, String> {
        Parser<String.UTF16View, String.UTF16View.Index, String> { source, index in
            if index >= source.endIndex {
                return .failure(Errors.noMoreSource)
            }
            let c = source[index]
            if f(c) {
                return .success(result: String(utf16CodeUnits: [c], count: 1), source: source, next: source.index(after: index))
            } else {
                return .failure(GenericParseError(message: "[WIP]")) // TODO:
            }
        }
    }

    public static func elemWhilePred(_ f: @escaping (String.UTF16View.Element) -> Bool, min: Int, max: Int? = nil) -> Parser<String.UTF16View, String.UTF16View.Index, String> {
        Parser<String.UTF16View, String.UTF16View.Index, String> { source, index in
            var count = 0
            var i = index
            var buffer = ContiguousArray<String.UTF16View.Element>()
            loop: while max == nil || count < max!, i < source.endIndex, f(source[i]) {
                buffer.append(source[i])
                count += 1
                i = source.index(after: i)
            }
            if count >= min {
                return .success(result: String(buffer), source: source, next: i)
            } else {
                return .failure(Errors.expectedAtLeast(min, got: count))
            }
        }
    }

    public static func elemIn(_ elems: String) -> Parser<String.UTF16View, String.UTF16View.Index, String> {
        elemIn(Array(elems))
    }

    public static func elemIn(_ elems: Character...) -> Parser<String.UTF16View, String.UTF16View.Index, String> {
        elemIn(elems)
    }

    public static func elemIn(_ elems: [Character]) -> Parser<String.UTF16View, String.UTF16View.Index, String> {
        let cs: [String.UTF16View.Element] = elems.map { char in
            let elem = String(char).utf16.first!
            precondition(!UTF16.isSurrogate(elem))
            return elem
        }
        return elemIn(cs)
    }

    public static func elemIn(_ elems: String.UTF16View.Element...) -> Parser<String.UTF16View, String.UTF16View.Index, String> { elemIn(Set(elems)) }

    public static func elemIn(_ elems: [String.UTF16View.Element]) -> Parser<String.UTF16View, String.UTF16View.Index, String> { elemIn(Set(elems)) }

    public static func elemIn(_ elems: Set<String.UTF16View.Element>) -> Parser<String.UTF16View, String.UTF16View.Index, String> {
        elemPred { elems.contains($0) }
    }

    public static func elemsWhileIn(_ elems: String, min: Int, max: Int? = nil) -> Parser<String.UTF16View, String.UTF16View.Index, String> {
        let arr = Array(elems.utf16)
        precondition(arr.allSatisfy { elem in !UTF16.isSurrogate(elem) })
        return elemsWhileIn(arr, min: min, max: max)
    }

    public static func elemsWhileIn(_ elems: [String.UTF16View.Element], min: Int, max: Int? = nil) -> Parser<String.UTF16View, String.UTF16View.Index, String> {
        elemsWhileIn(Set(elems), min: min, max: max)
    }

    public static func elemsWhileIn(_ set: Set<String.UTF16View.Element>, min: Int, max: Int? = nil) -> Parser<String.UTF16View, String.UTF16View.Index, String> {
        elemWhilePred({ set.contains($0) }, min: min, max: max)
    }

    public static func stringWhilePred(_ length: Int, _ f: @escaping (String.UTF16View.SubSequence) -> Bool, min: Int, max: Int? = nil) -> Parser<String.UTF16View, String.UTF16View.Index, String> {
        Parser<String.UTF16View, String.UTF16View.Index, String> { source, index in
            var count = 0
            var start: String.UTF16View.Index = index
            guard var end: String.UTF16View.Index = source.index(index, offsetBy: length, limitedBy: source.endIndex) else {
                return .failure(Errors.noMoreSource)
            }
            var buffer = ContiguousArray<String.UTF16View.Element>()
            loop: while max == nil || count < max!, start < source.endIndex, end < source.endIndex, f(source[start ..< end]) {
                buffer.append(source[start])
                count += 1
                start = source.index(after: start)
                end = source.index(after: end)
            }
            if count >= min {
                return .success(result: String(buffer), source: source, next: start)
            } else {
                return .failure(Errors.expectedAtLeast(min, got: count))
            }
        }
    }

    public static func stringIn(_ xs: String...) -> Parser<String.UTF16View, String.UTF16View.Index, String> { stringIn(Set(xs)) }

    public static func stringIn(_ xs: [String]) -> Parser<String.UTF16View, String.UTF16View.Index, String> { stringIn(Set(xs)) }

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
                return .success(result: currentNode.original!, source: source, next: i)
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
                return .success(result: res, source: source, next: i)
            } else {
                return .failure(error)
            }
        }
    }

    // MARK: - numbers

    /// Parses a digit [0-9] from a given String
    public static let digit: Parser<String.UTF16View, String.UTF16View.Index, String> = elemIn("0123456789")

    public static let digits: Parser<String.UTF16View, String.UTF16View.Index, String> = elemsWhileIn("0123456789", min: 1)

    /// Parses a binary digit (0 or 1)
    public static let binaryDigit: Parser<String.UTF16View, String.UTF16View.Index, String> = elemIn("01")

    /// Parses a hexadecimal digit (0 to 15)
    public static let hexDigit: Parser<String.UTF16View, String.UTF16View.Index, String> = elemIn("01234567")

    // MARK: - Common characters

    public static let start: Parser<String.UTF16View, String.UTF16View.Index, String> = Parser<String.UTF16View, String.UTF16View.Index, String> { source, index in
        if index == source.startIndex {
            return .success(result: "", source: source, next: index)
        } else {
            return .failure(Errors.notTheEnd)
        }
    }

    public static let end: Parser<String.UTF16View, String.UTF16View.Index, String> = Parser<String.UTF16View, String.UTF16View.Index, String> { source, index in
        if index == source.endIndex {
            return .success(result: "", source: source, next: index)
        } else {
            return .failure(Errors.notTheEnd)
        }
    }
}

extension String {
    init(_ arr: [String.UTF16View.Element]) {
        self.init(utf16CodeUnits: arr, count: arr.count)
    }

    init(_ arr: ContiguousArray<String.UTF16View.Element>) {
        self.init(utf16CodeUnits: Array(arr), count: arr.count)
    }
}
