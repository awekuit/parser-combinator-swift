import Foundation

public class Parser<Source, Result> where Source: Collection {
    /// ParseFunction is the type of the wrapped function type
    public typealias ParseFunction = (Source, Source.Index) throws -> ParseResult<Source, Result>

    /// The wrapped function, call to start the parsing process.
    private let parseFunction: ParseFunction

    /// Initialize a parser with the given wrapping function.
    ///
    /// - Parameter parse: A function that describes how to parse from T to R
    public init(parse: @escaping ParseFunction) {
        parseFunction = parse
    }

    /// Start the parsing with that parser
    ///
    /// - Parameter input: the token sequence that should be parsed
    /// - Returns: the result of the parsing operation
    public func parse(_ source: Source, _ index: Source.Index) throws -> ParseResult<Source, Result> {
        try parseFunction(source, index)
    }

    /// just creates a parser that parses the given value as success
    ///
    /// - Parameter value: the result to produce
    /// - Returns: a parser that just produces this value as success
    public static func just<B>(_ value: B) -> Parser<Source, B> {
        Parser<Source, B> { tokens, index in
            .success(result: value, source: tokens, next: index)
        }
    }

    /// fail creates a parser that fails with the given error.
    ///
    /// - Parameter err: the error that should be used to fail
    /// - Returns: a parser that always fails
    public static func fail(error: ParseError) -> Parser<Source, Result> {
        Parser<Source, Result> { _, _ in .failure(error) }
    }

    /// Creates a parser that always fails with a GenericParseError.
    ///
    /// - Parameter message: the message to use for GenericParseError
    /// - Returns: a parser that always fails
    public static func fail(message: String) -> Parser<Source, Result> {
        Parser<Source, Result> { _, _ in .failure(GenericParseError(message: message)) }
    }

    /// Produce a new parser for every succeeded parsing process.
    ///
    /// - Parameter tranform: function that maps a parse result to a new parser
    /// - Returns: a new parser that combines both parse operations.
    public func flatMap<B>(_ tranform: @escaping (Result) throws -> Parser<Source, B>) -> Parser<Source, B> {
        Parser<Source, B> { source1, index1 in
            try self.parse(source1, index1).flatMap { result, source2, index2 in
                try tranform(result).parse(source2, index2)
            }
        }
    }

    /// Produce a new parser which calls f on each successful parsing operation.
    ///
    /// - Parameter transform: transforming function that maps from R to B
    /// - Returns: a new parser that calls f on each successful parsing operation
    public func map<B>(_ transform: @escaping (Result) throws -> B) -> Parser<Source, B> {
        Parser<Source, B> { source1, index1 in
            try self.parse(source1, index1).map { result, _, _ in
                try transform(result)
            }
        }
    }

    public func filter(_ pred: @escaping (Result) -> Bool) -> Parser<Source, Result> {
        Parser<Source, Result> { source, index in
            let r1 = try self.parse(source, index)
            switch r1 {
            case let .success(result, _, _) where pred(result):
                return r1
            case .success:
                return .failure(Errors.filtered)
            case .failure:
                return r1
            }
        }
    }

    public static func passWith<A>(_ x: A) -> Parser<Source, A> {
        Parser.just(x)
    }

    public static func rule<A>(_ p: @escaping @autoclosure () throws -> Parser<Source, A>) -> Parser<Source, A> {
        Parser<Source, A> { source, index in try p().parse(source, index) }
    }
}
