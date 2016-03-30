//
//  ViewController.swift
//  Redux
//
//  Created by Kyle Fang on 3/14/16.
//  Copyright © 2016 Kyle Fang. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

struct Todo {
    var id:Int
    var name:String
    var completed:Bool
}

enum Visibility : Int {
    case Active = 0
    case Completed = 1
    case All = 2
}

enum TodoAction {
    case AddTodo(String)
    case ToggleTodo(Int)
    case UpdateVisibility(Visibility)
}


let todoReducer:(Todo, TodoAction) -> Todo = { s, a in
    guard case .ToggleTodo(let index) = a where s.id == index else { return s }
    return Todo(id: s.id, name: s.name, completed: !s.completed)
}

typealias TodosReducer = ([Todo], TodoAction) -> [Todo]

let addTodos:TodosReducer = { s, a in
    guard case .AddTodo(let n) = a else { return s }
    return s + [ Todo(id: s.count, name: n, completed: false) ]
}

let toggleTodo:TodosReducer = { s, a in
    return s.map({
        todoReducer($0, a)
    })
}

let todosReducer = combineReducer(addTodos, toggleTodo)

let visibilityReducer: (Visibility, TodoAction) -> Visibility =  { s, a in
    guard case .UpdateVisibility(let v) = a else { return s }
    return v
}

struct TodoApp {
    let todos:[Todo]
    let visibility:Visibility
}

extension TodoApp {
    var visibleTodos:[Todo] {
        switch self.visibility {
        case .All: return todos
        case .Completed: return todos.filter({$0.completed})
        case .Active: return todos.filter({!$0.completed})
        }
    }
}

let todoAppReducer: (TodoApp, TodoAction) -> TodoApp = { s, a in
    return TodoApp(todos: todosReducer(s.todos, a), visibility: visibilityReducer(s.visibility, a))
}

let store = Store(state: TodoApp(todos: [], visibility: .Active), reducer: todoAppReducer)

class TodoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var switchToggle: UISegmentedControl!
    @IBOutlet weak var inputField: UITextField!
    
    var dataSource:[Todo] {
        return store.state.visibleTodos
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        let todo = dataSource[indexPath.row]
        cell.textLabel?.text = todo.name
        cell.textLabel?.textColor = todo.completed ? UIColor.lightGrayColor() : UIColor.blackColor()
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        store.dispatch(.ToggleTodo(dataSource[indexPath.row].id))
    }
    
    private let disposeBag = DisposeBag()
    
    var reduxDisposables:[()->Void] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.inputField.rx_controlEvent(.EditingDidEndOnExit)
            .withLatestFrom(self.inputField.rx_text)
            .filter({!$0.isEmpty})
            .doOnNext({[unowned self] _ in
                self.inputField.text = ""
            })
            .subscribeNext({
                store.dispatch(.AddTodo($0))
            })
            .addDisposableTo(self.disposeBag)
        
        reduxDisposables.append(
            store.subscribe({ data in
                self.tableView.reloadData()
                self.switchToggle.selectedSegmentIndex = data.visibility.rawValue ?? 0
            })
        )
        
        self.switchToggle.rx_value
            .skip(1)
            .map({
                Visibility(rawValue: $0) ?? .Active
            })
            .subscribeNext({
                store.dispatch(.UpdateVisibility($0))
            })
            .addDisposableTo(self.disposeBag)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    deinit {
        self.reduxDisposables.forEach({$0()})
    }
}

