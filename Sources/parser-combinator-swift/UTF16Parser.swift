import Foundation

public enum UTF16Parser {
    // MARK: - strings

    /// Parses a given String from a String.
    ///
    /// - Parameter string: the String which should be parsed
    /// - Returns: a parser that parses that String
    public static func string(_ string: String) -> Parser<String.UTF16View, String> {
        let noMoreSourceFailure = ParseResult<String.UTF16View, String>.failure(Errors.noMoreSource)
        let unexpectedStringFailure = ParseResult<String.UTF16View, String>.failure(Errors.unexpectedString(expected: string))
        let view = string.utf16

        return Parser<String.UTF16View, String> { input, index in
            var i = index
            for e in view {
                guard i < input.endIndex else {
                    return noMoreSourceFailure
                }
                guard e == input[i] else {
                    return unexpectedStringFailure
                }
                i = input.index(after: i)
            }
            return .success(output: string, input: input, next: i)
        }
    }

    public static func elem(_ elem: String.UTF16View.Element) -> Parser<String.UTF16View, String.UTF16View.Element> {
        let noMoreSourceFailure = ParseResult<String.UTF16View, String.UTF16View.Element>.failure(Errors.noMoreSource)
        let unexpectedElementFailure = ParseResult<String.UTF16View, String.UTF16View.Element>.failure(Errors.unexpectedElement(expected: Int(elem)))

        return Parser<String.UTF16View, String.UTF16View.Element> { input, index in
            guard index < input.endIndex else {
                return noMoreSourceFailure
            }
            let e = input[index]
            if e == elem {
                return .success(output: elem, input: input, next: input.index(after: index))
            } else {
                return unexpectedElementFailure
            }
        }
    }

    public static let one: Parser<String.UTF16View, String.UTF16View.Element> = {
        let failure = ParseResult<String.UTF16View, String.UTF16View.Element>.failure(Errors.noMoreSource)

        return Parser<String.UTF16View, String.UTF16View.Element> { input, index in
            if index < input.endIndex {
                return .success(output: input[index], input: input, next: input.index(after: index))
            } else {
                return failure
            }
        }
    }()

    public static let char: Parser<String.UTF16View, Character> = {
        let failure = ParseResult<String.UTF16View, Character>.failure(Errors.noMoreSource)

        return Parser<String.UTF16View, Character> { input, index in
            guard index < input.endIndex else {
                return failure
            }
            if UTF16.isSurrogate(input[index]) {
                let nextIndex = input.index(index, offsetBy: 2)
                return .success(output: Character(String(input[index ..< nextIndex])!), input: input, next: nextIndex)
            } else {
                let nextIndex = input.index(after: index)
                return .success(output: Character(String(utf16CodeUnits: [input[index]], count: 1)), input: input, next: nextIndex)
            }
        }
    }()

    public static func elemPred(_ f: @escaping (String.UTF16View.Element) -> Bool) -> Parser<String.UTF16View, String> {
        let noMoreSourceFailure = ParseResult<String.UTF16View, String>.failure(Errors.noMoreSource)
        let unsatisfiedPredicateFailure = ParseResult<String.UTF16View, String>.failure(Errors.unsatisfiedPredicate)

        return Parser<String.UTF16View, String> { input, index in
            guard index < input.endIndex else {
                return noMoreSourceFailure
            }
            let c = input[index]
            if f(c) {
                return .success(output: String(utf16CodeUnits: [c], count: 1), input: input, next: input.index(after: index))
            } else {
                return unsatisfiedPredicateFailure
            }
        }
    }

    public static func elemWhilePred(_ f: @escaping (String.UTF16View.Element) -> Bool, min: Int, max: Int? = nil) -> Parser<String.UTF16View, String> {
        let failure = ParseResult<String.UTF16View, String>.failure(Errors.expectedAtLeast(count: min))

        return Parser<String.UTF16View, String> { input, index in
            var i = index
            var buffer = ContiguousArray<String.UTF16View.Element>()
            loop: while max == nil || buffer.count < max!, i < input.endIndex, f(input[i]) {
                buffer.append(input[i])
                i = input.index(after: i)
            }
            if buffer.count >= min {
                return .success(output: String(buffer), input: input, next: i)
            } else {
                return failure
            }
        }
    }

    public static func elemIn(_ elems: String) -> Parser<String.UTF16View, String> {
        elemIn(Array(elems))
    }

    public static func elemIn(_ elems: Character...) -> Parser<String.UTF16View, String> {
        elemIn(elems)
    }

    public static func elemIn(_ elems: [Character]) -> Parser<String.UTF16View, String> {
        let cs: [String.UTF16View.Element] = elems.map { char in
            let elem = String(char).utf16.first!
            precondition(!UTF16.isSurrogate(elem))
            return elem
        }
        return elemIn(cs)
    }

    public static func elemIn(_ elems: String.UTF16View.Element...) -> Parser<String.UTF16View, String> { elemIn(Set(elems)) }

    public static func elemIn(_ elems: [String.UTF16View.Element]) -> Parser<String.UTF16View, String> { elemIn(Set(elems)) }

    public static func elemIn(_ elems: Set<String.UTF16View.Element>) -> Parser<String.UTF16View, String> {
        elemPred { elems.contains($0) }
    }

    public static func elemsWhileIn(_ elems: String, min: Int, max: Int? = nil) -> Parser<String.UTF16View, String> {
        let arr = Array(elems.utf16)
        precondition(arr.allSatisfy { elem in !UTF16.isSurrogate(elem) })
        return elemsWhileIn(arr, min: min, max: max)
    }

    public static func elemsWhileIn(_ elems: [String.UTF16View.Element], min: Int, max: Int? = nil) -> Parser<String.UTF16View, String> {
        elemsWhileIn(Set(elems), min: min, max: max)
    }

    public static func elemsWhileIn(_ set: Set<String.UTF16View.Element>, min: Int, max: Int? = nil) -> Parser<String.UTF16View, String> {
        elemWhilePred({ set.contains($0) }, min: min, max: max)
    }

    public static func stringWhilePred(_ length: Int, _ f: @escaping (String.UTF16View.SubSequence) -> Bool, min: Int, max: Int? = nil) -> Parser<String.UTF16View, String> {
        let failure = ParseResult<String.UTF16View, String>.failure(Errors.expectedAtLeast(count: min))

        return Parser<String.UTF16View, String> { input, index in
            var start: String.UTF16View.Index = index
            guard var end: String.UTF16View.Index = input.index(index, offsetBy: length, limitedBy: input.endIndex) else {
                return failure
            }
            var buffer = ContiguousArray<String.UTF16View.Element>()
            loop: while max == nil || buffer.count < max!, start < input.endIndex, end < input.endIndex, f(input[start ..< end]) {
                buffer.append(input[start])
                start = input.index(after: start)
                end = input.index(after: end)
            }
            if buffer.count >= min {
                return .success(output: String(buffer), input: input, next: start)
            } else {
                return failure
            }
        }
    }

    public static func stringIn(_ xs: String...) -> Parser<String.UTF16View, String> { stringIn(xs) }

    public static func stringIn(_ xs: [String]) -> Parser<String.UTF16View, String> { stringIn(Set(xs.map { Array($0.utf16) })) }

    // The type of argument xs cannot be `Set<String>`.
    // Because `Set<[String.UTF16View.Element]>` and `Set<String>` have different deduplication criteria.
    // Specifically,
    // - Set(arrayLiteral: "\u{2000}", "\u{2002}").count == 1
    // - Set(arrayLiteral: Array("\u{2000}".utf16), Array("\u{2002}".utf16)).count == 2
    public static func stringIn(_ xs: Set<[String.UTF16View.Element]>) -> Parser<String.UTF16View, String> {
        let failure = ParseResult<String.UTF16View, String>.failure(GenericParseError(message: "Did not match stringIn(\(xs))."))
        let trie = Trie<String.UTF16View.Element, String>()
        xs.forEach { trie.insert($0, String($0)) }

        return Parser<String.UTF16View, String> { input, index in
            var i: String.UTF16View.Index = index
            var currentNode = trie.root
            var matched = false // FIXME: Remove this var if that is possible.
            loop: while i < input.endIndex {
                let elem = input[i]
                i = input.index(after: i)
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
                return .success(output: currentNode.original!, input: input, next: i)
            } else {
                return failure
            }
        }
    }

    public static func dictionaryIn<A>(_ dict: [String: A]) -> Parser<String.UTF16View, A> {
        let failure = ParseResult<String.UTF16View, A>.failure(GenericParseError(message: "Did not match dictionaryIn(\(dict))."))
        let trie = Trie<String.UTF16View.Element, A>()
        dict.forEach { k, v in trie.insert(Array(k.utf16), v) }

        return Parser<String.UTF16View, A> { input, index in
            if let (res, i) = trie.contains(input, index) {
                return .success(output: res, input: input, next: i)
            } else {
                return failure
            }
        }
    }

    // MARK: - numbers

    /// Parses a digit [0-9] from a given String
    public static let digit: Parser<String.UTF16View, String> = elemIn("0123456789")

    public static let digits: Parser<String.UTF16View, String> = elemsWhileIn("0123456789", min: 1)

    /// Parses a binary digit (0 or 1)
    public static let binaryDigit: Parser<String.UTF16View, String> = elemIn("01")

    /// Parses a hexadecimal digit (0 to 15)
    public static let hexDigit: Parser<String.UTF16View, String> = elemIn("01234567")

    // MARK: - Common characters

    public static let start: Parser<String.UTF16View, String> = {
        let failure = ParseResult<String.UTF16View, String>.failure(Errors.notTheEnd)

        return Parser<String.UTF16View, String> { input, index in
            if index == input.startIndex {
                return .success(output: "", input: input, next: index)
            } else {
                return failure
            }
        }
    }()

    public static let end: Parser<String.UTF16View, String> = {
        let failure = ParseResult<String.UTF16View, String>.failure(Errors.notTheEnd)

        return Parser<String.UTF16View, String> { input, index in
            if index == input.endIndex {
                return .success(output: "", input: input, next: index)
            } else {
                return failure
            }
        }
    }()
}

extension String {
    init(_ arr: [String.UTF16View.Element]) {
        self.init(utf16CodeUnits: arr, count: arr.count)
    }

    init(_ arr: ContiguousArray<String.UTF16View.Element>) {
        self.init(utf16CodeUnits: Array(arr), count: arr.count)
    }
}
