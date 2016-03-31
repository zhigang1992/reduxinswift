//: ### Data Structure
struct Todo {
    let id: Int
    let name: String
    let completed: Bool
}

enum Visibility : Int {
    case Active
    case Completed
    case All
}

struct TodoApp {
    let todos: [Todo]
    let visibility: Visibility
    let isLoading: Bool
}

enum Action {
    case AddTodo(String)
    case Toggle(Int)
    case SetVisibility(Visibility)
    case StartLoading
    case Loaded([Todo])
}

//: ### Reducers
let addTodo: ([Todo], Action) -> [Todo] = { todos, action in
    guard case .AddTodo(let name) = action else { return todos }
    let newTodo = Todo(id: todos.count, name: name, completed: false)
    return todos + [newTodo]
}

let toggleTodo: ([Todo], Action) -> [Todo] = { todos, action in
    guard case .Toggle(let index) = action else { return todos }
    return todos.map({
        guard $0.id == index else { return $0 }
        return Todo(id: $0.id, name: $0.name, completed: !$0.completed)
    })
}

let todoReducer = mergeReducer(addTodo, toggleTodo)

let visibilityReducer: (Visibility, Action) -> Visibility = { s, a in
    guard case .SetVisibility(let v) = a else { return s }
    return v
}

let startLoading: (TodoApp, Action) -> TodoApp = { s, a in
    guard case .StartLoading = a else { return s }
    return TodoApp(
        todos: s.todos,
        visibility: s.visibility,
        isLoading: true
    )
}

let remoteTodoReducer: (TodoApp, Action) -> TodoApp = { s, a in
    guard case .Loaded(let newTodos) = a else { return s }
    return TodoApp(
        todos: newTodos,
        visibility: s.visibility,
        isLoading: false
    )
}

let syncReducer: (TodoApp, Action) -> TodoApp = { s, a in
    return TodoApp(
        todos: todoReducer(s.todos, a),
        visibility: visibilityReducer(s.visibility, a),
        isLoading: s.isLoading
    )
}

let appReducer = mergeReducer(
    remoteTodoReducer, startLoading, syncReducer
)
//: ### Store
let initialState = TodoApp(
    todos: [],
    visibility: .Active,
    isLoading: false
)

let store = Store(state: initialState, reducer: appReducer)
store.subscribe({
    print($0)
})


extension Store {
    func dispatch(actionCreator: ((Action)->Void, ()->State)->Void) {
        actionCreator(self.dispatch, {self.state})
    }
}

import XCPlayground
XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

func loadRemoteTodos(dispatcher:Action->Void, getState:()->TodoApp) {
    guard !getState().isLoading else { return }
    dispatcher(.StartLoading)
    delay(2, closure: {
        let remoteTodo = Todo(id: 0, name: "Async todo", completed: false)
        dispatcher(.Loaded([remoteTodo]))
    })
}

store.dispatch(loadRemoteTodos)

