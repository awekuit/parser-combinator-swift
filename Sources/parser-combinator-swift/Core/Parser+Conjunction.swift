extension Parser {
    public var typeErased: Parser<Source, Index, Void> {
        Parser<Source, Index, Void> { source, index in
            switch try self.parse(source, index) {
            case let .success(_, _, resultIndex):
                return .success(result: (), source: source, resultIndex: resultIndex)
            case let .failure(err):
                return .failure(err)
            }
        }
    }

    public var optional: Parser<Source, Index, Result?> {
        (map { $0 }) | Parser.just(nil)
    }

    public func or(_ other: @escaping @autoclosure () throws -> Parser<Source, Index, Result>) -> Parser<Source, Index, Result> {
        Parser { source, index in
            let result = try self.parse(source, index)
            switch result {
            case .failure:
                return try other().parse(source, index)
            default:
                return result
            }
        }
    }

    public func rep(_ min: Int, _ max: Int? = nil) -> Parser<Source, Index, [Result]> {
        Parser<Source, Index, [Result]> { source, index in
            var results = ContiguousArray<Result>()
            var i = index
            var count = 0

            loop: while max == nil || count < max! {
                switch try self.parse(source, i) {
                case let .success(result, _, resultIndex):
                    results.append(result)
                    i = resultIndex
                    count += 1
                case .failure:
                    break loop
                }
            }

            if count >= min {
                return .success(result: Array(results), source: source, resultIndex: i)
            } else {
                return .failure(Errors.repeatFailed(min: min, max: max, count: count))
            }
        }
    }

    public func rep1sep<R2>(sep: Parser<Source, Index, R2>) -> Parser<Source, Index, [Result]> {
        (self ~ (sep ~> self).rep(0)).map { head, tail in
            var result = ContiguousArray<Result>()
            result += [head]
            result += tail
            return Array(result)
        }
    }

    public var positiveLookahead: Parser<Source, Index, Void> {
        Parser<Source, Index, Void> { source, index in
            let r = try self.parse(source, index)
            switch r {
            case .success: return .success(result: (), source: source, resultIndex: index)
            case .failure: return .failure(Errors.positiveLookaheadFailed)
            }
        }
    }

    public var negativeLookahead: Parser<Source, Index, Void> {
        Parser<Source, Index, Void> { source, index in
            switch try self.parse(source, index) {
            case .success:
                return .failure(Errors.negativeLookaheadFailed)
            case .failure:
                return .success(result: (), source: source, resultIndex: index)
            }
        }
    }
}
