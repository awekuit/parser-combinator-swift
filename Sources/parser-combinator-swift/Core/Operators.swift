prefix operator &&
prefix operator !

public func | <Source, Result>(lhs: Parser<Source, Result>, rhs: @escaping @autoclosure () throws -> Parser<Source, Result>) -> Parser<Source, Result> {
    lhs.or(try rhs())
}

public prefix func && <Source, Result>(lhs: Parser<Source, Result>) -> Parser<Source, Void> {
    lhs.positiveLookahead
}

public prefix func ! <Source, Result>(lhs: Parser<Source, Result>) -> Parser<Source, Void> {
    lhs.negativeLookahead
}
