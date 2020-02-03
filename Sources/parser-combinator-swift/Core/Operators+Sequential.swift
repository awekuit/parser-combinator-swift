precedencegroup ParserMapPrecedenceGroup {
    associativity: left
    lowerThan: AdditionPrecedence, BitwiseShiftPrecedence, NilCoalescingPrecedence, DefaultPrecedence
}

/// ~ and ~>
precedencegroup ParserConjunctionGroup {
    associativity: left
    lowerThan: NilCoalescingPrecedence
    higherThan: ParserMapPrecedenceGroup, DefaultPrecedence
}

/// <~
precedencegroup ParserConjuctionRightGroup {
    associativity: left
    lowerThan: NilCoalescingPrecedence
    higherThan: ParserConjunctionGroup
}

infix operator ~: ParserConjunctionGroup
infix operator <~: ParserConjuctionRightGroup

/// Sequential conjunction of two parsers while ignoring the result of lhs
///
/// - Parameters:
///   - lhs: the first parser that has to succeed
///   - rhs: the second parser that has to succeed
/// - Returns: a parser that parses lhs, then rhs on the rest and returns the result of rhs
public func ~> <Source, Index, R1, R2>(lhs: Parser<Source, Index, R1>, rhs: @escaping @autoclosure () -> Parser<Source, Index, R2>) -> Parser<Source, Index, R2> {
    Parser { source, index in
        try lhs.parse(&source, index).flatMap { _, _, r1Index in
            try rhs().parse(&source, r1Index)
        }
    }
}

/// Sequential conjunction of two parsers while ignoring the result of rhs
///
/// - Parameters:
///   - lhs: the first parser that has to succeed
///   - rhs: the second parser that has to succeed
/// - Returns: a parser that parses lhs, then rhs on the rest and returns the result of lhs
public func <~ <Source, Index, R1, R2>(lhs: Parser<Source, Index, R1>, rhs: @escaping @autoclosure () -> Parser<Source, Index, R2>) -> Parser<Source, Index, R1> {
    Parser { source, index in
        try lhs.parse(&source, index).flatMap { r1, _, r1Index in
            try rhs().parse(&source, r1Index).map { _, _, _ in
                r1
            }
        }
    }
}

/// Sequential conjunction of lhs and rhs with combining of the results in a tuple
///
/// - Parameters:
///   - lhs: the first parser that has to succeed
///   - rhs: the second parser that has to succeed
/// - Returns: a parser that parses lhs, then rhs on the rest and returns a tuple of the combined results
public func ~ <Source, Index, R1, R2>(lhs: Parser<Source, Index, R1>, rhs: @escaping @autoclosure () -> Parser<Source, Index, R2>) -> Parser<Source, Index, (R1, R2)> {
    Parser { source, index in
        try lhs.parse(&source, index).flatMap { r1, _, r1Index in
            try rhs().parse(&source, r1Index).map { r2, _, _ in (r1, r2) }
        }
    }
}

/// Sequential conjunction of lhs and rhs with combining of the results in a tuple
///
/// - Parameters:
///   - lhs: the first parser that has to succeed
///   - rhs: the second parser that has to succeed
/// - Returns: a parser that parses lhs, then rhs on the rest and returns a tuple of the combined results
public func ~ <Source, Index, A, B, C>(lhs: Parser<Source, Index, (A, B)>, rhs: @escaping @autoclosure () -> Parser<Source, Index, C>) -> Parser<Source, Index, (A, B, C)> {
    Parser { source, index in
        try lhs.parse(&source, index).flatMap { r1, _, r1Index in
            try rhs().parse(&source, r1Index).map { r2, _, _ in (r1.0, r1.1, r2) }
        }
    }
}

/// Sequential conjunction of lhs and rhs with combining of the results in a tuple
///
/// - Parameters:
///   - lhs: the first parser that has to succeed
///   - rhs: the second parser that has to succeed
/// - Returns: a parser that parses lhs, then rhs on the rest and returns a tuple of the combined results
public func ~ <Source, Index, A, B, C>(lhs: Parser<Source, Index, C>, rhs: @escaping @autoclosure () -> Parser<Source, Index, (A, B)>) -> Parser<Source, Index, (C, A, B)> {
    Parser { source, index in
        try lhs.parse(&source, index).flatMap { r1, _, r1Index in
            try rhs().parse(&source, r1Index).map { r2, _, _ in (r1, r2.0, r2.1) }
        }
    }
}

/// Sequential conjunction of lhs and rhs with combining of the results in a tuple
///
/// - Parameters:
///   - lhs: the first parser that has to succeed
///   - rhs: the second parser that has to succeed
/// - Returns: a parser that parses lhs, then rhs on the rest and returns a tuple of the combined results
public func ~ <Source, Index, A, B, C, D>(lhs: Parser<Source, Index, (A, B, C)>, rhs: @escaping @autoclosure () -> Parser<Source, Index, D>) -> Parser<Source, Index, (A, B, C, D)> {
    Parser { source, index in
        try lhs.parse(&source, index).flatMap { r1, _, r1Index in
            try rhs().parse(&source, r1Index).map { r2, _, _ in (r1.0, r1.1, r1.2, r2) }
        }
    }
}

/// Sequential conjunction of lhs and rhs with combining of the results in a tuple
///
/// - Parameters:
///   - lhs: the first parser that has to succeed
///   - rhs: the second parser that has to succeed
/// - Returns: a parser that parses lhs, then rhs on the rest and returns a tuple of the combined results
public func ~ <Source, Index, A, B, C, D>(lhs: Parser<Source, Index, D>, rhs: @escaping @autoclosure () -> Parser<Source, Index, (A, B, C)>) -> Parser<Source, Index, (D, A, B, C)> {
    Parser { source, index in
        try lhs.parse(&source, index).flatMap { r1, _, r1Index in
            try rhs().parse(&source, r1Index).map { r2, _, _ in (r1, r2.0, r2.1, r2.2) }
        }
    }
}

/// Sequential conjunction of lhs and rhs with combining of the results in a tuple
///
/// - Parameters:
///   - lhs: the first parser that has to succeed
///   - rhs: the second parser that has to succeed
/// - Returns: a parser that parses lhs, then rhs on the rest and returns a tuple of the combined results
public func ~ <Source, Index, A, B, C, D, E>(lhs: Parser<Source, Index, (A, B, C, D)>, rhs: @escaping @autoclosure () -> Parser<Source, Index, E>) -> Parser<Source, Index, (A, B, C, D, E)> {
    Parser { source, index in
        try lhs.parse(&source, index).flatMap { r1, _, r1Index in
            try rhs().parse(&source, r1Index).map { r2, _, _ in (r1.0, r1.1, r1.2, r1.3, r2) }
        }
    }
}

/// Sequential conjunction of lhs and rhs with combining of the results in a tuple
///
/// - Parameters:
///   - lhs: the first parser that has to succeed
///   - rhs: the second parser that has to succeed
/// - Returns: a parser that parses lhs, then rhs on the rest and returns a tuple of the combined results
public func ~ <Source, Index, A, B, C, D, E>(lhs: Parser<Source, Index, E>, rhs: @escaping @autoclosure () -> Parser<Source, Index, (A, B, C, D)>) -> Parser<Source, Index, (E, A, B, C, D)> {
    Parser { source, index in
        try lhs.parse(&source, index).flatMap { r1, _, r1Index in
            try rhs().parse(&source, r1Index).map { r2, _, _ in (r1, r2.0, r2.1, r2.2, r2.3) }
        }
    }
}

/// Sequential conjunction of lhs and rhs with combining of the results in a tuple
///
/// - Parameters:
///   - lhs: the first parser that has to succeed
///   - rhs: the second parser that has to succeed
/// - Returns: a parser that parses lhs, then rhs on the rest and returns a tuple of the combined results
public func ~ <Source, Index, A, B, C, D, E, F>(lhs: Parser<Source, Index, (A, B, C, D, E)>, rhs: @escaping @autoclosure () -> Parser<Source, Index, F>) -> Parser<Source, Index, (A, B, C, D, E, F)> {
    Parser { source, index in
        try lhs.parse(&source, index).flatMap { r1, _, r1Index in
            try rhs().parse(&source, r1Index).map { r2, _, _ in (r1.0, r1.1, r1.2, r1.3, r1.4, r2) }
        }
    }
}

/// Sequential conjunction of lhs and rhs with combining of the results in a tuple
///
/// - Parameters:
///   - lhs: the first parser that has to succeed
///   - rhs: the second parser that has to succeed
/// - Returns: a parser that parses lhs, then rhs on the rest and returns a tuple of the combined results
public func ~ <Source, Index, A, B, C, D, E, F>(lhs: Parser<Source, Index, F>, rhs: @escaping @autoclosure () -> Parser<Source, Index, (A, B, C, D, E)>) -> Parser<Source, Index, (F, A, B, C, D, E)> {
    Parser { source, index in
        try lhs.parse(&source, index).flatMap { r1, _, r1Index in
            try rhs().parse(&source, r1Index).map { r2, _, _ in (r1, r2.0, r2.1, r2.2, r2.3, r2.4) }
        }
    }
}

/// Sequential conjunction of lhs and rhs with combining of the results in a tuple
///
/// - Parameters:
///   - lhs: the first parser that has to succeed
///   - rhs: the second parser that has to succeed
/// - Returns: a parser that parses lhs, then rhs on the rest and returns a tuple of the combined results
public func ~ <Source, Index, A, B, C, D, E, F, G>(lhs: Parser<Source, Index, (A, B, C, D, E, F)>, rhs: @escaping @autoclosure () -> Parser<Source, Index, G>) -> Parser<Source, Index, (A, B, C, D, E, F, G)> {
    Parser { source, index in
        try lhs.parse(&source, index).flatMap { r1, _, r1Index in
            try rhs().parse(&source, r1Index).map { r2, _, _ in (r1.0, r1.1, r1.2, r1.3, r1.4, r1.5, r2) }
        }
    }
}

/// Sequential conjunction of lhs and rhs with combining of the results in a tuple
///
/// - Parameters:
///   - lhs: the first parser that has to succeed
///   - rhs: the second parser that has to succeed
/// - Returns: a parser that parses lhs, then rhs on the rest and returns a tuple of the combined results
public func ~ <Source, Index, A, B, C, D, E, F, G>(lhs: Parser<Source, Index, G>, rhs: @escaping @autoclosure () -> Parser<Source, Index, (A, B, C, D, E, F)>) -> Parser<Source, Index, (G, A, B, C, D, E, F)> {
    Parser { source, index in
        try lhs.parse(&source, index).flatMap { r1, _, r1Index in
            try rhs().parse(&source, r1Index).map { r2, _, _ in (r1, r2.0, r2.1, r2.2, r2.3, r2.4, r2.5) }
        }
    }
}

/// Sequential conjunction of lhs and rhs with combining of the results in a tuple
///
/// - Parameters:
///   - lhs: the first parser that has to succeed
///   - rhs: the second parser that has to succeed
/// - Returns: a parser that parses lhs, then rhs on the rest and returns a tuple of the combined results
public func ~ <Source, Index, A, B, C, D, E, F, G, H>(lhs: Parser<Source, Index, (A, B, C, D, E, F, G)>, rhs: @escaping @autoclosure () -> Parser<Source, Index, H>) -> Parser<Source, Index, (A, B, C, D, E, F, G, H)> {
    Parser { source, index in
        try lhs.parse(&source, index).flatMap { r1, _, r1Index in
            try rhs().parse(&source, r1Index).map { r2, _, _ in (r1.0, r1.1, r1.2, r1.3, r1.4, r1.5, r1.6, r2) }
        }
    }
}

/// Sequential conjunction of lhs and rhs with combining of the results in a tuple
///
/// - Parameters:
///   - lhs: the first parser that has to succeed
///   - rhs: the second parser that has to succeed
/// - Returns: a parser that parses lhs, then rhs on the rest and returns a tuple of the combined results
public func ~ <Source, Index, A, B, C, D, E, F, G, H>(lhs: Parser<Source, Index, H>, rhs: @escaping @autoclosure () -> Parser<Source, Index, (A, B, C, D, E, F, G)>) -> Parser<Source, Index, (H, A, B, C, D, E, F, G)> {
    Parser { source, index in
        try lhs.parse(&source, index).flatMap { r1, _, r1Index in
            try rhs().parse(&source, r1Index).map { r2, _, _ in (r1, r2.0, r2.1, r2.2, r2.3, r2.4, r2.5, r2.6) }
        }
    }
}

/// Sequential conjunction of lhs and rhs with combining of the results in a tuple
///
/// - Parameters:
///   - lhs: the first parser that has to succeed
///   - rhs: the second parser that has to succeed
/// - Returns: a parser that parses lhs, then rhs on the rest and returns a tuple of the combined results
public func ~ <Source, Index, A, B, C, D, E, F, G, H, I>(lhs: Parser<Source, Index, (A, B, C, D, E, F, G, H)>, rhs: @escaping @autoclosure () -> Parser<Source, Index, I>) -> Parser<Source, Index, (A, B, C, D, E, F, G, H, I)> {
    Parser { source, index in
        try lhs.parse(&source, index).flatMap { r1, _, r1Index in
            try rhs().parse(&source, r1Index).map { r2, _, _ in (r1.0, r1.1, r1.2, r1.3, r1.4, r1.5, r1.6, r1.7, r2) }
        }
    }
}

/// Sequential conjunction of lhs and rhs with combining of the results in a tuple
///
/// - Parameters:
///   - lhs: the first parser that has to succeed
///   - rhs: the second parser that has to succeed
/// - Returns: a parser that parses lhs, then rhs on the rest and returns a tuple of the combined results
public func ~ <Source, Index, A, B, C, D, E, F, G, H, I>(lhs: Parser<Source, Index, I>, rhs: @escaping @autoclosure () -> Parser<Source, Index, (A, B, C, D, E, F, G, H)>) -> Parser<Source, Index, (I, A, B, C, D, E, F, G, H)> {
    Parser { source, index in
        try lhs.parse(&source, index).flatMap { r1, _, r1Index in
            try rhs().parse(&source, r1Index).map { r2, _, _ in (r1, r2.0, r2.1, r2.2, r2.3, r2.4, r2.5, r2.6, r2.7) }
        }
    }
}

/// Sequential conjunction of lhs and rhs with combining of the results in a tuple
///
/// - Parameters:
///   - lhs: the first parser that has to succeed
///   - rhs: the second parser that has to succeed
/// - Returns: a parser that parses lhs, then rhs on the rest and returns a tuple of the combined results
public func ~ <Source, Index, A, B, C, D, E, F, G, H, I, J>(lhs: Parser<Source, Index, (A, B, C, D, E, F, G, H, I)>, rhs: @escaping @autoclosure () -> Parser<Source, Index, J>) -> Parser<Source, Index, (A, B, C, D, E, F, G, H, I, J)> {
    Parser { source, index in
        try lhs.parse(&source, index).flatMap { r1, _, r1Index in
            try rhs().parse(&source, r1Index).map { r2, _, _ in (r1.0, r1.1, r1.2, r1.3, r1.4, r1.5, r1.6, r1.7, r1.8, r2) }
        }
    }
}

/// Sequential conjunction of lhs and rhs with combining of the results in a tuple
///
/// - Parameters:
///   - lhs: the first parser that has to succeed
///   - rhs: the second parser that has to succeed
/// - Returns: a parser that parses lhs, then rhs on the rest and returns a tuple of the combined results
public func ~ <Source, Index, A, B, C, D, E, F, G, H, I, J>(lhs: Parser<Source, Index, J>, rhs: @escaping @autoclosure () -> Parser<Source, Index, (A, B, C, D, E, F, G, H, I)>) -> Parser<Source, Index, (J, A, B, C, D, E, F, G, H, I)> {
    Parser { source, index in
        try lhs.parse(&source, index).flatMap { r1, _, r1Index in
            try rhs().parse(&source, r1Index).map { r2, _, _ in (r1, r2.0, r2.1, r2.2, r2.3, r2.4, r2.5, r2.6, r2.7, r2.8) }
        }
    }
}

/// Sequential conjunction of lhs and rhs with combining of the results in a tuple
///
/// - Parameters:
///   - lhs: the first parser that has to succeed
///   - rhs: the second parser that has to succeed
/// - Returns: a parser that parses lhs, then rhs on the rest and returns a tuple of the combined results
public func ~ <Source, Index, A, B, C, D, E, F, G, H, I, J, K>(lhs: Parser<Source, Index, (A, B, C, D, E, F, G, H, I, J)>, rhs: @escaping @autoclosure () -> Parser<Source, Index, K>) -> Parser<Source, Index, (A, B, C, D, E, F, G, H, I, J, K)> {
    Parser { source, index in
        try lhs.parse(&source, index).flatMap { r1, _, r1Index in
            try rhs().parse(&source, r1Index).map { r2, _, _ in (r1.0, r1.1, r1.2, r1.3, r1.4, r1.5, r1.6, r1.7, r1.8, r1.9, r2) }
        }
    }
}

/// Sequential conjunction of lhs and rhs with combining of the results in a tuple
///
/// - Parameters:
///   - lhs: the first parser that has to succeed
///   - rhs: the second parser that has to succeed
/// - Returns: a parser that parses lhs, then rhs on the rest and returns a tuple of the combined results
public func ~ <Source, Index, A, B, C, D, E, F, G, H, I, J, K>(lhs: Parser<Source, Index, K>, rhs: @escaping @autoclosure () -> Parser<Source, Index, (A, B, C, D, E, F, G, H, I, J)>) -> Parser<Source, Index, (K, A, B, C, D, E, F, G, H, I, J)> {
    Parser { source, index in
        try lhs.parse(&source, index).flatMap { r1, _, r1Index in
            try rhs().parse(&source, r1Index).map { r2, _, _ in (r1, r2.0, r2.1, r2.2, r2.3, r2.4, r2.5, r2.6, r2.7, r2.8, r2.9) }
        }
    }
}
