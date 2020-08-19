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

    /// is returned when `atLeast(count:)` failed because the parser succeeded less than n
    case expectedAtLeast(count: Int)

    case unexpectedString(expected: String)

    case unexpectedCharacter(expected: Character)

    case unexpectedElement(expected: Int)

    case unsatisfiedPredicate

    case positiveLookaheadFailed

    case negativeLookaheadFailed

    case noMoreSource

    case notTheEnd

    case notTheStart

    case filtered

    case logged // FIXME:
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
        lhs.message == rhs.message
    }
}
