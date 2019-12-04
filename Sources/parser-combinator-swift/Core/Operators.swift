prefix operator &&
prefix operator !

public func | <Source, Index, Result>(lhs: Parser<Source, Index, Result>, rhs: @escaping @autoclosure () throws -> Parser<Source, Index, Result>) -> Parser<Source, Index, Result> {
    return lhs.or(try rhs())
}

public prefix func && <Source, Index, Result>(lhs: Parser<Source, Index, Result>) -> Parser<Source, Index, ()> {
    return lhs.positiveLookahead
}

public prefix func ! <Source, Index, Result>(lhs: Parser<Source, Index, Result>) -> Parser<Source, Index, ()> {
    return lhs.negativeLookahead
}
