import Foundation

public class Parser<Input, Output> where Input: Collection {
    /// ParseFunction is the type of the wrapped function type
    public typealias ParseFunction = (Input, Input.Index) throws -> ParseResult<Input, Output>

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
    public func parse(_ input: Input, _ index: Input.Index) throws -> ParseResult<Input, Output> {
        try parseFunction(input, index)
    }

    /// just creates a parser that parses the given value as success
    ///
    /// - Parameter value: the result to produce
    /// - Returns: a parser that just produces this value as success
    public static func just<B>(_ value: B) -> Parser<Input, B> {
        Parser<Input, B> { input, index in
            .success(output: value, input: input, next: index)
        }
    }

    /// fail creates a parser that fails with the given error.
    ///
    /// - Parameter err: the error that should be used to fail
    /// - Returns: a parser that always fails
    public static func fail(error: ParseError) -> Parser<Input, Output> {
        Parser<Input, Output> { _, _ in .failure(error) }
    }

    /// Creates a parser that always fails with a GenericParseError.
    ///
    /// - Parameter message: the message to use for GenericParseError
    /// - Returns: a parser that always fails
    public static func fail(message: String) -> Parser<Input, Output> {
        Parser<Input, Output> { _, _ in .failure(GenericParseError(message: message)) }
    }

    /// Produce a new parser for every succeeded parsing process.
    ///
    /// - Parameter tranform: function that maps a parse result to a new parser
    /// - Returns: a new parser that combines both parse operations.
    public func flatMap<B>(_ tranform: @escaping (Output) throws -> Parser<Input, B>) -> Parser<Input, B> {
        Parser<Input, B> { input1, index1 in
            try self.parse(input1, index1).flatMap { output, input2, index2 in
                try tranform(output).parse(input2, index2)
            }
        }
    }

    /// Produce a new parser which calls f on each successful parsing operation.
    ///
    /// - Parameter transform: transforming function that maps from R to B
    /// - Returns: a new parser that calls f on each successful parsing operation
    public func map<B>(_ transform: @escaping (Output) throws -> B) -> Parser<Input, B> {
        Parser<Input, B> { input, index in
            try self.parse(input, index).map { output, _, _ in
                try transform(output)
            }
        }
    }

    public func filter(_ pred: @escaping (Output) -> Bool) -> Parser<Input, Output> {
        Parser<Input, Output> { input, index in
            let r1 = try self.parse(input, index)
            switch r1 {
            case let .success(output, _, _) where pred(output):
                return r1
            case .success:
                return .failure(Errors.filtered)
            case .failure:
                return r1
            }
        }
    }

    public static func passWith<A>(_ x: A) -> Parser<Input, A> {
        Parser.just(x)
    }

    public static func lazyOf<A>(_ p: @escaping @autoclosure () throws -> Parser<Input, A>) -> Parser<Input, A> {
        Parser<Input, A> { input, index in try p().parse(input, index) }
    }

    public static func memoizedLazyOf<A>(_ parser: @escaping @autoclosure () throws -> Parser<Input, A>, currentMemoCount count: Int, maxMemoCount max: Int) -> Parser<Input, A> {
        if count < max {
            var error: Error?
            var memo: Parser<Input, A>?
            do {
                memo = try parser()
            } catch let e {
                error = e
            }
            if let m = memo {
                return Parser<Input, A> { source, index in try m.parse(source, index) }
            } else {
                return Parser<Input, A> { _, _ in throw error! }
            }
        } else {
            return lazyOf(try parser())
        }
    }
}
