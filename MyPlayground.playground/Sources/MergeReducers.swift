public func mergeReducer<S, A>(reducers: ((S, A)->S)... ) -> (S, A) -> S {
    return { s, a in
        reducers.reduce(s, combine: {$1($0, a)})
    }
}
