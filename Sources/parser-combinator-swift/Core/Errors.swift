public protocol ParseError: Swift.Error {}

public enum Errors: ParseError {
    /// is thrown when `.unwrap()` is called on a failed ParseResult
    case unwrappedFailedResult

    /// is thrown when `error()` is called on a succeeded ParseResult
    case errorFromSuccessfulResult

    /// is thrown when an error is thrown due to the default value
    case fallbackFailed

    /// is returned when `Parser.or` is called on an empty collection of parsers
    case conjunctionOfEmptyCollection

    /// is returned when `atLeastOnce` failed because the parser succeeded not at all
    case expectedAtLeastOnce

    /// is returned when `atLeast(count:)` failed because the parser succeeded less than n
    case expectedAtLeast(Int, got: Int)

    /// is returned when `exactly(count:)` failed because the parser succeeded less than or more than n
    case expectedExactly(Int, got: Int)

    case repeatFailed(min: Int, max: Int?, count: Int)

    case unexpectedString(expected: String, got: String)

    case unexpectedCharacter(expected: Character, got: Character)

    case positiveLookaheadFailed

    case negativeLookaheadFailed

    case noMoreSources

    case notTheEnd

    case notTheStart

    case filtered

    case logged // FIXME:
}

// TODO: Rename
public enum GenericErrors<A>: ParseError {
    case unexpectedToken(expected: A, got: A)
}

/// A generic error that occured while parsing
public struct GenericParseError: ParseError, Equatable {
    /// the message of the error
    public let message: String

    /// Compare two instances of GenericParseError
    ///
    /// - Parameters:
    ///   - lhs: the first error to compare with
    ///   - rhs: the second error to compare with
    /// - Returns: true if both messages are equal, false otherwise
    public static func == (lhs: GenericParseError, rhs: GenericParseError) -> Bool {
        return lhs.message == rhs.message
    }
}
