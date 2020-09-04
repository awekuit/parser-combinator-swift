import Foundation

public enum UTF8Parser {
    // MARK: - strings

    /// Parses a given String from a String.
    ///
    /// - Parameter string: the String which should be parsed
    /// - Returns: a parser that parses that String
    public static func string(_ string: String) -> Parser<String.UTF8View, String> {
        let noMoreSourceFailure = ParseResult<String.UTF8View, String>.failure(Errors.noMoreSource)
        let unexpectedStringFailure = ParseResult<String.UTF8View, String>.failure(Errors.unexpectedString(expected: string))
        let view = string.utf8

        return Parser<String.UTF8View, String> { input, index in
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

    public static func elem(_ elem: String.UTF8View.Element) -> Parser<String.UTF8View, String.UTF8View.Element> {
        let noMoreSourceFailure = ParseResult<String.UTF8View, String.UTF8View.Element>.failure(Errors.noMoreSource)
        let unexpectedElementFailure = ParseResult<String.UTF8View, String.UTF8View.Element>.failure(Errors.unexpectedElement(expected: Int(elem)))

        return Parser<String.UTF8View, String.UTF8View.Element> { input, index in
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

    public static let one: Parser<String.UTF8View, String.UTF8View.Element> = {
        let failure = ParseResult<String.UTF8View, String.UTF8View.Element>.failure(Errors.noMoreSource)

        return Parser<String.UTF8View, String.UTF8View.Element> { input, index in
            if index < input.endIndex {
                return .success(output: input[index], input: input, next: input.index(after: index))
            } else {
                return failure
            }
        }
    }()

    public static let char: Parser<String.UTF8View, Character> = {
        let noMoreSourceFailure = ParseResult<String.UTF8View, Character>.failure(Errors.noMoreSource)
        let encodingFailure = ParseResult<String.UTF8View, Character>.failure(GenericParseError(message: "UTF8View to String encoding failed."))

        return Parser<String.UTF8View, Character> { input, index in
            guard index < input.endIndex else {
                return noMoreSourceFailure
            }
            var buffer = ContiguousArray(arrayLiteral: input[index])
            var i = input.index(after: index)
            loop: while i < input.endIndex, UTF8.isContinuation(input[i]) {
                buffer.append(input[i])
                i = input.index(after: i)
            }
            if let output = String(buffer) {
                return .success(output: Character(output), input: input, next: i)
            } else {
                return encodingFailure
            }
        }
    }()

    public static func elemPred(_ f: @escaping (String.UTF8View.Element) -> Bool) -> Parser<String.UTF8View, String> {
        let noMoreSourceFailure = ParseResult<String.UTF8View, String>.failure(Errors.noMoreSource)
        let encodingFailure = ParseResult<String.UTF8View, String>.failure(GenericParseError(message: "UTF8View to String encoding failed."))
        let unsatisfiedPredicateFailure = ParseResult<String.UTF8View, String>.failure(Errors.unsatisfiedPredicate)

        return Parser<String.UTF8View, String> { input, index in
            guard index < input.endIndex else {
                return noMoreSourceFailure
            }
            let c = input[index]
            if f(c) {
                if let output = String(bytes: [c], encoding: .utf8) {
                    return .success(output: output, input: input, next: input.index(after: index))
                } else {
                    return encodingFailure
                }
            } else {
                return unsatisfiedPredicateFailure
            }
        }
    }

    public static func elemWhilePred(_ f: @escaping (String.UTF8View.Element) -> Bool, min: Int, max: Int? = nil) -> Parser<String.UTF8View, String> {
        let encodingFailure = ParseResult<String.UTF8View, String>.failure(GenericParseError(message: "UTF8View to String encoding failed."))
        let expectedAtLeastFailure = ParseResult<String.UTF8View, String>.failure(Errors.expectedAtLeast(count: min))

        return Parser<String.UTF8View, String> { input, index in
            var i = index
            var buffer = ContiguousArray<String.UTF8View.Element>()
            loop: while max == nil || buffer.count < max!, i < input.endIndex, f(input[i]) {
                buffer.append(input[i])
                i = input.index(after: i)
            }
            if buffer.count >= min {
                if let output = String(buffer) {
                    return .success(output: output, input: input, next: i)
                } else {
                    return encodingFailure
                }
            } else {
                return expectedAtLeastFailure
            }
        }
    }

    public static func elemIn(_ elems: String) -> Parser<String.UTF8View, String> {
        let arr = Array(elems.utf8)
        precondition(arr.allSatisfy { elem in !UTF8.isContinuation(elem) })
        return elemIn(arr)
    }

    public static func elemIn(_ elems: Character...) -> Parser<String.UTF8View, String> {
        elemIn(elems)
    }

    public static func elemIn(_ elems: [Character]) -> Parser<String.UTF8View, String> {
        elemIn(String(elems))
    }

    public static func elemIn(_ elems: String.UTF8View.Element...) -> Parser<String.UTF8View, String> { elemIn(Set(elems)) }

    public static func elemIn(_ elems: [String.UTF8View.Element]) -> Parser<String.UTF8View, String> { elemIn(Set(elems)) }

    public static func elemIn(_ elems: Set<String.UTF8View.Element>) -> Parser<String.UTF8View, String> {
        elemPred { elems.contains($0) }
    }

    public static func elemsWhileIn(_ elems: String, min: Int, max: Int? = nil) -> Parser<String.UTF8View, String> {
        let arr = Array(elems.utf8)
        precondition(arr.allSatisfy { elem in !UTF8.isContinuation(elem) })
        return elemsWhileIn(arr, min: min, max: max)
    }

    public static func elemsWhileIn(_ elems: [String.UTF8View.Element], min: Int, max: Int? = nil) -> Parser<String.UTF8View, String> {
        elemsWhileIn(Set(elems), min: min, max: max)
    }

    public static func elemsWhileIn(_ set: Set<String.UTF8View.Element>, min: Int, max: Int? = nil) -> Parser<String.UTF8View, String> {
        elemWhilePred({ set.contains($0) }, min: min, max: max)
    }

    public static func stringIn(_ xs: String...) -> Parser<String.UTF8View, String> { stringIn(xs) }

    public static func stringIn(_ xs: [String]) -> Parser<String.UTF8View, String> { stringIn(Set(xs.map { Array($0.utf8) })) }

    // The type of argument xs cannot be `Set<String>`.
    // Because `Set<[String.UTF8View.Element]>` and `Set<String>` have different deduplication criteria.
    // Specifically,
    // - Set(arrayLiteral: "\u{2000}", "\u{2002}").count == 1
    // - Set(arrayLiteral: Array("\u{2000}".utf8), Array("\u{2002}".utf8)).count == 2
    public static func stringIn(_ xs: Set<[String.UTF8View.Element]>) -> Parser<String.UTF8View, String> {
        let failure = ParseResult<String.UTF8View, String>.failure(GenericParseError(message: "Did not match stringIn(\(xs))."))
        let trie = Trie<String.UTF8View.Element, String>(xs.map { ($0, String($0)!) })

        return Parser<String.UTF8View, String> { input, index in
            var i: String.UTF8View.Index = index
            var currentNode = trie
            var matched = false // FIXME: Remove this var if that is possible.
            loop: while i < input.endIndex {
                let elem = input[i]
                i = input.index(after: i)
                if let childNode = currentNode.query(elem) {
                    currentNode = childNode
                    if currentNode.isLeaf {
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

    public static func dictionaryIn<A>(_ dict: [String: A]) -> Parser<String.UTF8View, A> {
        let failure = ParseResult<String.UTF8View, A>.failure(GenericParseError(message: "Did not match dictionaryIn(\(dict))."))
        let trie = Trie<String.UTF8View.Element, A>(dict.map { k, v in (Array(k.utf8), v) })

        return Parser<String.UTF8View, A> { input, index in
            if let (res, i) = trie.contains(input, index) {
                return .success(output: res, input: input, next: i)
            } else {
                return failure
            }
        }
    }

    // MARK: - numbers

    /// Parses a digit [0-9] from a given String
    public static let digit: Parser<String.UTF8View, String> = elemIn("0123456789")

    public static let digits: Parser<String.UTF8View, String> = elemsWhileIn("0123456789", min: 1)

    /// Parses a binary digit (0 or 1)
    public static let binaryDigit: Parser<String.UTF8View, String> = elemIn("01")

    /// Parses a hexadecimal digit (0 to 15)
    public static let hexDigit: Parser<String.UTF8View, String> = elemIn("01234567")

    // MARK: - Common characters

    public static let start: Parser<String.UTF8View, String> = {
        let failure = ParseResult<String.UTF8View, String>.failure(Errors.notTheEnd)

        return Parser<String.UTF8View, String> { input, index in
            if index == input.startIndex {
                return .success(output: "", input: input, next: index)
            } else {
                return failure
            }
        }
    }()

    public static let end: Parser<String.UTF8View, String> = {
        let failure = ParseResult<String.UTF8View, String>.failure(Errors.notTheEnd)

        return Parser<String.UTF8View, String> { input, index in
            if index == input.endIndex {
                return .success(output: "", input: input, next: index)
            } else {
                return failure
            }
        }
    }()
}

extension String {
    init?(_ arr: [String.UTF8View.Element]) {
        self.init(bytes: arr, encoding: .utf8)
    }

    init? (_ arr: ContiguousArray<String.UTF8View.Element>) {
        self.init(bytes: Array(arr), encoding: .utf8)
    }
}
