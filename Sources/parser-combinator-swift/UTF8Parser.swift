import Foundation

public enum UTF8Parser {
    // MARK: - strings

    /// Parses a given String from a String.
    ///
    /// - Parameter string: the String which should be parsed
    /// - Returns: a parser that parses that String
    public static func string(_ string: String) -> Parser<String.UTF8View, String> {
        let view = string.utf8
        return Parser<String.UTF8View, String> { input, index in
            var i = index
            for e in view {
                guard i < input.endIndex else {
                    return .failure(Errors.noMoreSource)
                }
                guard e == input[i] else {
                    return .failure(GenericErrors.unexpectedToken(expected: e, got: input[i]))
                }
                i = input.index(after: i)
            }
            return .success(output: string, input: input, next: i)
        }
    }

    public static func elem(_ elem: String.UTF8View.Element) -> Parser<String.UTF8View, String.UTF8View.Element> {
        Parser<String.UTF8View, String.UTF8View.Element> { input, index in
            let e = input[index]
            if e == elem {
                return .success(output: elem, input: input, next: input.index(after: index))
            } else {
                return .failure(GenericErrors.unexpectedToken(expected: elem, got: e))
            }
        }
    }

    public static let one = Parser<String.UTF8View, String.UTF8View.Element> { input, index in
        if index < input.endIndex {
            return .success(output: input[index], input: input, next: input.index(after: index))
        } else {
            return .failure(Errors.noMoreSource)
        }
    }

    public static let char = Parser<String.UTF8View, Character> { input, index in
        guard index < input.endIndex else {
            return .failure(Errors.noMoreSource)
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
            return .failure(GenericParseError(message: "UTF8View to String encoding failed."))
        }
    }

    public static func elemPred(_ f: @escaping (String.UTF8View.Element) -> Bool) -> Parser<String.UTF8View, String> {
        Parser<String.UTF8View, String> { input, index in
            if index >= input.endIndex {
                return .failure(Errors.noMoreSource)
            }
            let c = input[index]
            if f(c) {
                if let output = String(bytes: [c], encoding: .utf8) {
                    return .success(output: output, input: input, next: input.index(after: index))
                } else {
                    return .failure(GenericParseError(message: "UTF8View to String encoding failed."))
                }
            } else {
                return .failure(GenericParseError(message: "[WIP]")) // TODO:
            }
        }
    }

    public static func elemWhilePred(_ f: @escaping (String.UTF8View.Element) -> Bool, min: Int, max: Int? = nil) -> Parser<String.UTF8View, String> {
        Parser<String.UTF8View, String> { input, index in
            var count = 0
            var i = index
            var buffer = ContiguousArray<String.UTF8View.Element>()
            loop: while max == nil || count < max!, i < input.endIndex, f(input[i]) {
                buffer.append(input[i])
                count += 1
                i = input.index(after: i)
            }
            if count >= min {
                if let output = String(buffer) {
                    return .success(output: output, input: input, next: i)
                } else {
                    return .failure(GenericParseError(message: "UTF8View to String encoding failed."))
                }
            } else {
                return .failure(Errors.expectedAtLeast(min, got: count))
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
        let errorMessage = "Did not match stringIn(\(xs))."
        let trie = Trie<String.UTF8View.Element, String>()
        xs.forEach { trie.insert($0, String($0)!) }

        return Parser<String.UTF8View, String> { input, index in
            var i: String.UTF8View.Index = index
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
                return .failure(GenericParseError(message: errorMessage))
            }
        }
    }

    public static func dictionaryIn<A>(_ dict: [String: A]) -> Parser<String.UTF8View, A> {
        let error = GenericParseError(message: "Did not match dictionaryIn(\(dict)).")
        let trie = Trie<String.UTF8View.Element, A>()
        dict.forEach { k, v in trie.insert(Array(k.utf8), v) }

        return Parser<String.UTF8View, A> { input, index in
            if let (res, i) = trie.contains(input, index) {
                return .success(output: res, input: input, next: i)
            } else {
                return .failure(error)
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

    public static let start: Parser<String.UTF8View, String> = Parser<String.UTF8View, String> { input, index in
        if index == input.startIndex {
            return .success(output: "", input: input, next: index)
        } else {
            return .failure(Errors.notTheEnd)
        }
    }

    public static let end: Parser<String.UTF8View, String> = Parser<String.UTF8View, String> { input, index in
        if index == input.endIndex {
            return .success(output: "", input: input, next: index)
        } else {
            return .failure(Errors.notTheEnd)
        }
    }
}

extension String {
    init?(_ arr: [String.UTF8View.Element]) {
        self.init(bytes: arr, encoding: .utf8)
    }

    init? (_ arr: ContiguousArray<String.UTF8View.Element>) {
        self.init(bytes: Array(arr), encoding: .utf8)
    }
}
