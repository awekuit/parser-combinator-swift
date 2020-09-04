import Foundation

public enum UTF8CStringParser {
    // MARK: - strings

    /// Parses a given String from a String.
    ///
    /// - Parameter string: the String which should be parsed
    /// - Returns: a parser that parses that String
    public static func string(_ string: String) -> Parser<ContiguousArray<CChar>, String> {
        let noMoreSourceFailure = ParseResult<ContiguousArray<CChar>, String>.failure(Errors.noMoreSource)
        let unexpectedStringFailure = ParseResult<ContiguousArray<CChar>, String>.failure(Errors.unexpectedString(expected: string))
        let cs = string.utf8CString.dropLast()

        return Parser<ContiguousArray<CChar>, String> { input, index in
            var i = index
            for c in cs {
                guard i < input.endIndexWithoutTerminator else {
                    return noMoreSourceFailure
                }
                guard c == input[i] else {
                    return unexpectedStringFailure
                }
                i += 1
            }
            return .success(output: string, input: input, next: i)
        }
    }

    public static func elem(_ elem: CChar) -> Parser<ContiguousArray<CChar>, CChar> {
        let noMoreSourceFailure = ParseResult<ContiguousArray<CChar>, ContiguousArray<CChar>.Element>.failure(Errors.noMoreSource)
        let unexpectedElementFailure = ParseResult<ContiguousArray<CChar>, ContiguousArray<CChar>.Element>.failure(Errors.unexpectedElement(expected: Int(elem)))

        return Parser<ContiguousArray<CChar>, CChar> { input, index in
            guard index < input.endIndex else {
                return noMoreSourceFailure
            }
            let c = input[index]
            if c == elem {
                return .success(output: elem, input: input, next: index + 1)
            } else {
                return unexpectedElementFailure
            }
        }
    }

    public static let one: Parser<ContiguousArray<CChar>, CChar> = {
        let failure = ParseResult<ContiguousArray<CChar>, ContiguousArray<CChar>.Element>.failure(Errors.noMoreSource)

        return Parser<ContiguousArray<CChar>, CChar> { input, index in
            if index < input.endIndexWithoutTerminator {
                return .success(output: input[index], input: input, next: index + 1)
            } else {
                return failure
            }
        }
    }()

    public static let char: Parser<ContiguousArray<CChar>, Character> = {
        let failure = ParseResult<ContiguousArray<CChar>, Character>.failure(Errors.noMoreSource)

        return Parser<ContiguousArray<CChar>, Character> { input, index in
            guard index < input.endIndexWithoutTerminator else {
                return failure
            }
            var buffer = ContiguousArray<CChar>(arrayLiteral: input[index])
            var i = index + 1
            loop: while i < input.endIndexWithoutTerminator, UTF8.isContinuation(UInt8(bitPattern: input[i])) {
                buffer.append(input[i])
                i += 1
            }
            buffer.append(0) // NULL Terminated
            var output = String(cCharArray: buffer)
            return .success(output: Character(output), input: input, next: i)
        }
    }()

    public static func elemPred(_ f: @escaping (CChar) -> Bool) -> Parser<ContiguousArray<CChar>, String> {
        let noMoreSourceFailure = ParseResult<ContiguousArray<CChar>, String>.failure(Errors.noMoreSource)
        let unsatisfiedPredicateFailure = ParseResult<ContiguousArray<CChar>, String>.failure(Errors.unsatisfiedPredicate)

        return Parser<ContiguousArray<CChar>, String> { input, index in
            if index >= input.endIndexWithoutTerminator {
                return noMoreSourceFailure
            }
            let c = input[index]
            if f(c) {
                let buffer = ContiguousArray<CChar>(arrayLiteral: c, 0) // 0 is NULL Terminated
                return .success(output: String(cCharArray: buffer), input: input, next: index + 1)
            } else {
                return unsatisfiedPredicateFailure
            }
        }
    }

    public static func elemWhilePred(_ f: @escaping (CChar) -> Bool, min: Int, max: Int? = nil) -> Parser<ContiguousArray<CChar>, String> {
        let failure = ParseResult<ContiguousArray<CChar>, String>.failure(Errors.expectedAtLeast(count: min))

        return Parser<ContiguousArray<CChar>, String> { input, index in
            var i = index
            var buffer = ContiguousArray<CChar>()
            loop: while max == nil || buffer.count < max!, i < input.endIndexWithoutTerminator, f(input[i]) {
                buffer.append(input[i])
                i += 1
            }
            buffer.append(0) // NULL Terminated
            if buffer.count >= min {
                return .success(output: String(cCharArray: buffer), input: input, next: i)
            } else {
                return failure
            }
        }
    }

    public static func elemIn(_ elems: String) -> Parser<ContiguousArray<CChar>, String> {
        let arr = elems.utf8CString
        precondition(arr.dropLast().allSatisfy { elem in !UTF8.isContinuation(UInt8(bitPattern: elem)) })
        return elemIn(arr)
    }

    public static func elemIn(_ elems: Character...) -> Parser<ContiguousArray<CChar>, String> {
        elemIn(elems)
    }

    public static func elemIn(_ elems: [Character]) -> Parser<ContiguousArray<CChar>, String> {
        elemIn(String(elems))
    }

    public static func elemIn(_ elems: CChar...) -> Parser<ContiguousArray<CChar>, String> { elemIn(Set(elems)) }

    public static func elemIn(_ elems: ContiguousArray<CChar>) -> Parser<ContiguousArray<CChar>, String> {
        if let last = elems.last, last == 0 {
            return elemIn(Set(elems.dropLast()))
        } else {
            return elemIn(Set(elems))
        }
    }

    public static func elemIn(_ elems: Set<CChar>) -> Parser<ContiguousArray<CChar>, String> {
        elemPred { elems.contains($0) }
    }

    public static func elemsWhileIn(_ elems: String, min: Int, max: Int? = nil) -> Parser<ContiguousArray<CChar>, String> {
        let arr = elems.utf8CString
        precondition(arr.dropLast().allSatisfy { elem in !UTF8.isContinuation(UInt8(bitPattern: elem)) })
        return elemsWhileIn(arr, min: min, max: max)
    }

    public static func elemsWhileIn(_ elems: [CChar], min: Int, max: Int? = nil) -> Parser<ContiguousArray<CChar>, String> {
        elemsWhileIn(Set(elems), min: min, max: max)
    }

    public static func elemsWhileIn(_ elems: ContiguousArray<CChar>, min: Int, max: Int? = nil) -> Parser<ContiguousArray<CChar>, String> {
        if let last = elems.last, last == 0 {
            return elemsWhileIn(Set(elems.dropLast()), min: min, max: max)
        } else {
            return elemsWhileIn(Set(elems), min: min, max: max)
        }
    }

    public static func elemsWhileIn(_ set: Set<CChar>, min: Int, max: Int? = nil) -> Parser<ContiguousArray<CChar>, String> {
        elemWhilePred({ set.contains($0) }, min: min, max: max)
    }

    public static func stringIn(_ xs: String...) -> Parser<ContiguousArray<CChar>, String> { stringIn(xs) }

    public static func stringIn(_ xs: [String]) -> Parser<ContiguousArray<CChar>, String> { stringIn(Set(xs.map { $0.utf8CString })) }

    // The type of argument xs cannot be `Set<String>`.
    // Because `Set<ContiguousArray<CChar>>` and `Set<String>` have different deduplication criteria.
    // Specifically,
    // - Set(arrayLiteral: "\u{2000}", "\u{2002}").count == 1
    // - Set(arrayLiteral: "\u{2000}".utf8CString, "\u{2002}".utf8CString).count == 2
    public static func stringIn(_ xs: Set<ContiguousArray<CChar>>) -> Parser<ContiguousArray<CChar>, String> {
        let failure = ParseResult<ContiguousArray<CChar>, String>.failure(GenericParseError(message: "Did not match stringIn(\(xs))."))
        let trie = Trie<CChar, String>(xs.map { (Array($0).dropLast(), String(cCharArray: $0)) })

        return Parser<ContiguousArray<CChar>, String> { input, index in
            var i: Int = index
            var currentNode = trie
            var matched = false // FIXME: Remove this var if that is possible.
            loop: while i < input.endIndexWithoutTerminator {
                let elem = input[i]
                i += 1
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

    public static func dictionaryIn<A>(_ dict: [String: A]) -> Parser<ContiguousArray<CChar>, A> {
        let failure = ParseResult<ContiguousArray<CChar>, A>.failure(GenericParseError(message: "Did not match dictionaryIn(\(dict))."))
        let trie = Trie<CChar, A>(dict.map { k, v in (Array(k.utf8CString).dropLast(), v) })

        return Parser<ContiguousArray<CChar>, A> { input, index in
            if let (res, i) = trie.contains(input, index) {
                return .success(output: res, input: input, next: i)
            } else {
                return failure
            }
        }
    }

    // MARK: - numbers

    /// Parses a digit [0-9] from a given String
    public static let digit: Parser<ContiguousArray<CChar>, String> = elemIn("0123456789")

    public static let digits: Parser<ContiguousArray<CChar>, String> = elemsWhileIn("0123456789", min: 1)

    /// Parses a binary digit (0 or 1)
    public static let binaryDigit: Parser<ContiguousArray<CChar>, String> = elemIn("01")

    /// Parses a hexadecimal digit (0 to 15)
    public static let hexDigit: Parser<ContiguousArray<CChar>, String> = elemIn("01234567")

    // MARK: - Common characters

    public static let start: Parser<ContiguousArray<CChar>, String> = {
        let failure = ParseResult<ContiguousArray<CChar>, String>.failure(Errors.notTheEnd)

        return Parser<ContiguousArray<CChar>, String> { input, index in
            if index == 0 {
                return .success(output: "", input: input, next: index)
            } else {
                return failure
            }
        }
    }()

    public static let end: Parser<ContiguousArray<CChar>, String> = {
        let failure = ParseResult<ContiguousArray<CChar>, String>.failure(Errors.notTheEnd)
        return Parser<ContiguousArray<CChar>, String> { input, index in
            if index == input.endIndexWithoutTerminator {
                return .success(output: "", input: input, next: index)
            } else {
                return failure
            }
        }
    }()
}

extension String {
    init(cCharArray elems: ContiguousArray<CChar>) {
        self = ""
        elems.withUnsafeBufferPointer { ptr in
            self = String(cString: ptr.baseAddress!)
        }
    }
}

extension ContiguousArray where Element == CChar {
    var endIndexWithoutTerminator: Int { endIndex - 1 }
}
