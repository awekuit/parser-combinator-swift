public enum ParseResult<Input, Output> where Input: Collection { // where Source: Sequence, Index: Hashable {
    /// Parse was successful.
    case success(output: Output, input: Input, next: Input.Index)

    /// Parse was not successful.
    case failure(ParseError)

    /// Transforms the result with f, if successful.
    ///
    /// - Parameter transform: a function to use to transform result
    /// - Returns: ParseResult with transformed result or fail with unchanged error.
    public func map<B>(_ transform: (Output, Input, Input.Index) throws -> B) throws -> ParseResult<Input, B> {
        switch self {
        case let .success(output, input, nextIndex):
            return .success(output: try transform(output, input, nextIndex), input: input, next: nextIndex)
        case let .failure(err):
            return .failure(err)
        }
    }

    /// Create a new ParseResult for the result.
    ///
    /// - Parameter transform: a function that takes a result and returns a parse result
    /// - Returns: the value that was produced by f if self was success or still fail if not
    public func flatMap<B>(_ transform: (Output, Input, Input.Index) throws -> ParseResult<Input, B>) throws -> ParseResult<Input, B> {
        switch self {
        case let .success(output, input, nextIndex):
            return try transform(output, input, nextIndex)
        case let .failure(err):
            return .failure(err)
        }
    }

    /// Checks whether or not the result is successful
    ///
    /// - Returns: true if successful
    public func isSuccess() -> Bool {
        guard case .success = self else {
            return false
        }
        return true
    }

    /// Checks whether or not the result is failed
    ///
    /// - Returns: true if failed
    public func isFailed() -> Bool {
        guard case .failure = self else {
            return false
        }
        return true
    }

    /// Unwraps the result from the success case.
    ///
    /// - Returns: the result if success
    /// - Throws: Errors.unwrappedFailedResult if not successful
    public func unwrap() throws -> Output {
        switch self {
        case let .success(output, _, _):
            return output
        default:
            throw Errors.unwrappedFailedResult
        }
    }

    /// Unwraps the wrapped result and uses fallback if .fail
    ///
    /// - Parameter fallback: the fallback value to use if parse failed
    /// - Returns: either the parse result or fallback
    public func unwrap(fallback: @autoclosure () -> Output) -> Output {
        (try? unwrap()) ?? fallback()
    }

    public func index() throws -> Input.Index {
        switch self {
        case let .success(_, _, index):
            return index
        default:
            throw Errors.unwrappedFailedResult
        }
    }

    /// Unwraps the error if not successful
    ///
    /// - Returns: the parsing error if not successful
    /// - Throws: Errors.errorFromSuccessfulResult if successful
    public func error() throws -> ParseError {
        switch self {
        case let .failure(err):
            return err
        default:
            throw Errors.errorFromSuccessfulResult
        }
    }
}

// public func ==<T, Index, R>(lhs: ParseResult<T, Index, R>, rhs: ParseResult<T, Index, R>) -> Bool where T: Equatable, R: Equatable {
//    switch (lhs, rhs) {
//    case let (.success(res1, src1, idx1), .success(res2, src2, idx2)):
//        return res1 == res2 && src1 == src2 && idx1.hashValue == idx2.hashValue
//    case (.fail, .fail):
//        return true
//    default:
//        return false
//    }
// }
