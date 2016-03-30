//
//  Redux.swift
//  Redux
//
//  Created by Kyle Fang on 3/21/16.
//  Copyright © 2016 Kyle Fang. All rights reserved.
//

import Foundation

class Store<State, Action> {
    
    typealias Reducer = (State, Action) -> State
    typealias Subscriber = State -> Void
    typealias Disposable = () -> Void
    
    private(set) var state: State
    let reducer: Reducer
    
    var subscribers = [Subscriber?]()
    
    init(state:State, reducer: Reducer) {
        self.state = state
        self.reducer = reducer
    }
    
    func dispatch(action:Action) {
        self.state = reducer(state, action)
        self.subscribers.forEach({
            $0?(self.state)
        })
    }
    
    func subscribe(subscriber:Subscriber) -> Disposable {
        subscribers.append(subscriber)
        let index = subscribers.endIndex
        return { [weak self] in
            self?.subscribers[index] = nil
        }
    }
}

func combineReducer<S, A>(reducers:((S, A) -> S)...) -> (S, A) -> S {
    return { (s, a) in
        reducers.reduce(s, combine: {$1($0, a)})
    }
}
