import Foundation

public enum UTF16Parser {
    // MARK: - strings

    public static let one = Parser<String.UTF16View, String.UTF16View.Index, String.UTF16View.Element> { source, Index in
        if Index < source.endIndex {
            return .success(result: source[Index], source: source, resultIndex: source.index(after: Index))
        } else {
            return .failure(Errors.noMoreSources)
        }
    }

    public static func string(_ string: String) -> Parser<String.UTF16View, String.UTF16View.Index, String> {
        return Parser<String.UTF16View, String.UTF16View.Index, String> { source, index in
            let len = string.utf16.count
            guard let endIndex = source.index(index, offsetBy: len, limitedBy: source.endIndex) else {
                return .failure(Errors.noMoreSources)
            }
            let subStr = String(source[index ..< endIndex])!
            if subStr == string {
                return .success(result: string, source: source, resultIndex: endIndex)
            } else {
                return .failure(Errors.unexpectedToken(expected: string, got: subStr))
            }
        }
    }

    public static func otherThan(_ string: String) -> Parser<String.UTF16View, String.UTF16View.Index, String.UTF16View.Element> {
        return Parser<String.UTF16View, String.UTF16View.Index, String.UTF16View.Element> { source, index in
            // TODO: Improve performance by comparing elements one by one
            let len = string.utf16.count
            guard let endIndex = source.index(index, offsetBy: len, limitedBy: source.endIndex) else {
                return .failure(Errors.noMoreSources)
            }
            let subStr = String(source[index ..< endIndex])!
            if subStr != string {
                return .success(result: source[index], source: source, resultIndex: source.index(after: index))
            } else {
                return .failure(Errors.unexpectedToken(expected: string, got: subStr))
            }
        }
    }

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

//    // MARK: - Whitespaces
//
//    /// Parses one space character
//    public static let whitespace = one.filter { $0.isWhitespace }
//
//    /// Parses at least one whitespace
//    public static let whitespaces = whitespace.rep(1)
}
