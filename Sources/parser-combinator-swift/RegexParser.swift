
import Foundation

// swiftlint:disable type_name
/// A shortcut to RegexParser
public typealias R = RegexParser

/// A parser that parses Strings with a given regular expression
public final class RegexParser: Parser<String, String> {
    /// Possible errors while using RegexParser
    public enum Error: ParseError {
        /// Pattern does not match the input (at the beginning)
        ///
        /// - pattern: the pattern that was used
        /// - input: the input that failed on the pattern
        case doesNotMatch(pattern: String)

        /// Regular expression is invalid (could not be evaluated by NSRegularExpression)
        case invalidRegex(String)
    }

    /// The pattern of the parser
    public let regex: String

    // FIXME: improve performance
    /// Initialize a new RegexParser with a regular expression
    ///
    /// - Parameter regex: the regular expression to use
    public init(_ regex: String) {
        self.regex = regex
        let nsRegex = try? NSRegularExpression(pattern: regex, options: [])
        let invalidRegex = ParseResult<String, String>.failure(Error.invalidRegex(regex))
        let doesNotMatch = ParseResult<String, String>.failure(Error.doesNotMatch(pattern: regex))
        super.init { input, index in
            guard let nsRegex = nsRegex else {
                return invalidRegex
            }
            let str = String(input[index...])
            let matches = nsRegex.matches(in: str, options: [.anchored], range: NSRange(location: 0, length: str.count))
            guard let first = matches.first else {
                return doesNotMatch
            }

            let end = first.range.location + first.range.length
            let match = String(str.prefix(end))
            return .success(output: match, input: input, next: input.index(index, offsetBy: end))
        }
    }
}

extension String {
    // swiftlint:disable identifier_name
    /// Returns a RegexParser with self as the pattern
    public var r: RegexParser {
        RegexParser(self)
    }
}
