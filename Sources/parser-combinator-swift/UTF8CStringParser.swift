import Foundation

public enum UTF8CStringParser {
    // MARK: - strings

    /// Parses a given String from a String.
    ///
    /// - Parameter string: the String which should be parsed
    /// - Returns: a parser that parses that String
    public static func string(_ string: String) -> Parser<ContiguousArray<CChar>, String> {
        let cs = string.utf8CString.dropLast() // FIXME: 添字アクセスで制限した方が速いかも。比較する
        return Parser<ContiguousArray<CChar>, String> { source, index in
            var i = index
            for c in cs {
                guard i < source.endIndexWithoutTerminator else {
                    return .failure(Errors.noMoreSource)
                }
                guard c == source[i] else {
                    return .failure(GenericErrors.unexpectedToken(expected: c, got: source[i]))
                }
                i += 1
            }
            return .success(result: string, source: source, next: i)
        }
    }

    public static func elem(_ elem: CChar) -> Parser<ContiguousArray<CChar>, CChar> {
        Parser<ContiguousArray<CChar>, CChar> { source, index in
            let c = source[index]
            if c == elem {
                return .success(result: elem, source: source, next: index + 1)
            } else {
                return .failure(GenericErrors.unexpectedToken(expected: elem, got: c))
            }
        }
    }

    public static let one = Parser<ContiguousArray<CChar>, CChar> { source, index in
        if index < source.endIndexWithoutTerminator {
            return .success(result: source[index], source: source, next: index + 1)
        } else {
            return .failure(Errors.noMoreSource)
        }
    }

    public static let char = Parser<ContiguousArray<CChar>, Character> { source, index in
        guard index < source.endIndexWithoutTerminator else {
            return .failure(Errors.noMoreSource)
        }
        var buffer = ContiguousArray<CChar>(arrayLiteral: source[index])
        var i = index + 1
        loop: while i < source.endIndexWithoutTerminator, UTF8.isContinuation(UInt8(bitPattern: source[i])) {
            buffer.append(source[i])
            i += 1
        }
        buffer.append(0) // NULL Terminated
        var result = String(cCharArray: buffer)
        return .success(result: Character(result), source: source, next: i)
    }

    public static func elemPred(_ f: @escaping (CChar) -> Bool) -> Parser<ContiguousArray<CChar>, String> {
        Parser<ContiguousArray<CChar>, String> { source, index in
            if index >= source.endIndexWithoutTerminator {
                return .failure(Errors.noMoreSource)
            }
            let c = source[index]
            if f(c) {
                let buffer = ContiguousArray<CChar>(arrayLiteral: c, 0) // 0 is NULL Terminated
                return .success(result: String(cCharArray: buffer), source: source, next: index + 1)
            } else {
                return .failure(GenericParseError(message: "[WIP]")) // TODO:
            }
        }
    }

    public static func elemWhilePred(_ f: @escaping (CChar) -> Bool, min: Int, max: Int? = nil) -> Parser<ContiguousArray<CChar>, String> {
        Parser<ContiguousArray<CChar>, String> { source, index in
            var count = 0
            var i = index
            var buffer = ContiguousArray<CChar>()
            loop: while max == nil || count < max!, i < source.endIndexWithoutTerminator, f(source[i]) {
                buffer.append(source[i])
                count += 1
                i += 1
            }
            buffer.append(0) // NULL Terminated
            if count >= min {
                return .success(result: String(cCharArray: buffer), source: source, next: i)
            } else {
                return .failure(Errors.expectedAtLeast(min, got: count))
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

    public static func stringIn(_ xs: String...) -> Parser<ContiguousArray<CChar>, String> { stringIn(Set(xs)) }

    public static func stringIn(_ xs: [String]) -> Parser<ContiguousArray<CChar>, String> { stringIn(Set(xs)) }

    public static func stringIn(_ xs: Set<String>) -> Parser<ContiguousArray<CChar>, String> {
        let errorMessage = "Did not match stringIn(\(xs))."
        let trie = Trie<CChar, String>()
        xs.forEach { trie.insert(Array($0.utf8CString).dropLast(), $0) }

        return Parser<ContiguousArray<CChar>, String> { source, index in
            var i: Int = index
            var currentNode = trie.root
            var matched = false // FIXME: Remove this var if that is possible.
            loop: while i < source.endIndexWithoutTerminator {
                let elem = source[i]
                i += 1
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

    public static func dictionaryIn<A>(_ dict: [String: A]) -> Parser<ContiguousArray<CChar>, A> {
        let error = GenericParseError(message: "Did not match dictionaryIn(\(dict)).")
        let trie = Trie<CChar, A>()
        dict.forEach { k, v in trie.insert(Array(k.utf8CString).dropLast(), v) }

        return Parser<ContiguousArray<CChar>, A> { source, index in
            if let (res, i) = trie.contains(source, index) {
                return .success(result: res, source: source, next: i)
            } else {
                return .failure(error)
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

    public static let start: Parser<ContiguousArray<CChar>, String> = Parser<ContiguousArray<CChar>, String> { source, index in
        if index == 0 {
            return .success(result: "", source: source, next: index)
        } else {
            return .failure(Errors.notTheEnd)
        }
    }

    public static let end: Parser<ContiguousArray<CChar>, String> = Parser<ContiguousArray<CChar>, String> { source, index in
        if index == source.endIndexWithoutTerminator {
            return .success(result: "", source: source, next: index)
        } else {
            return .failure(Errors.notTheEnd)
        }
    }
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
