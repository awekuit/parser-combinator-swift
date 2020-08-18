extension Parser {
    public var typeErased: Parser<Input, Void> {
        Parser<Input, Void> { input, index in
            switch try self.parse(input, index) {
            case let .success(_, _, nextIndex):
                return .success(output: (), input: input, next: nextIndex)
            case let .failure(err):
                return .failure(err)
            }
        }
    }

    public var optional: Parser<Input, Output?> {
        (map { $0 }) | Parser.just(nil)
    }

    public func or(_ other: Parser<Input, Output>) -> Parser<Input, Output> {
        Parser { input, index in
            let output = try self.parse(input, index)
            switch output {
            case .failure:
                return try other.parse(input, index)
            default:
                return output
            }
        }
    }

    public func rep(_ min: Int, _ max: Int? = nil) -> Parser<Input, [Output]> {
        Parser<Input, [Output]> { input, index in
            var outputs = ContiguousArray<Output>()
            var i = index

            loop: while max == nil || outputs.count < max! {
                switch try self.parse(input, i) {
                case let .success(output, _, nextIndex):
                    outputs.append(output)
                    i = nextIndex
                case .failure:
                    break loop
                }
            }

            if outputs.count >= min {
                return .success(output: Array(outputs), input: input, next: i)
            } else {
                return .failure(Errors.repeatFailed(min: min, max: max, count: outputs.count))
            }
        }
    }

    public func rep1sep<R2>(sep: Parser<Input, R2>) -> Parser<Input, [Output]> {
        (self ~ (sep ~> self).rep(0)).map { head, tail in
            var outputs = ContiguousArray<Output>()
            outputs += [head]
            outputs += tail
            return Array(outputs)
        }
    }

    public var positiveLookahead: Parser<Input, Void> {
        Parser<Input, Void> { input, index in
            let r = try self.parse(input, index)
            switch r {
            case .success: return .success(output: (), input: input, next: index)
            case .failure: return .failure(Errors.positiveLookaheadFailed)
            }
        }
    }

    public var negativeLookahead: Parser<Input, Void> {
        Parser<Input, Void> { input, index in
            switch try self.parse(input, index) {
            case .success:
                return .failure(Errors.negativeLookaheadFailed)
            case .failure:
                return .success(output: (), input: input, next: index)
            }
        }
    }
}
