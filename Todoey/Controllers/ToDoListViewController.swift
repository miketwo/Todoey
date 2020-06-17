//
//  ViewController.swift
//  Todoey
//
//  Created by Philipp Muellauer on 02/12/2019.
//  Copyright © 2019 App Brewery. All rights reserved.
//

import UIKit
import RealmSwift

class ToDoListViewController: UITableViewController {
    var todoItems: Results<Item>?
    var doneItems: Results<Item>?
    var selectedCategory: Category? {
        didSet {
            print("loading items")
            loadItems()
        }
    }
    var todoGenerator = ToDoGenerator()
    let realm = try! Realm()
    
    @IBOutlet weak var searchBarOutlet: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        todoGenerator.delegate = self
        
    }
    
    @IBAction func refreshPulled(_ sender: UIRefreshControl) {
        generateNewTodo()
        sender.endRefreshing()
    }
    
    //MARK: - TableView Datasource Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoItems?.count ?? 1
    }
    
    
    @IBAction func trashBtnPressed(_ sender: UIBarButtonItem) {
//        guard let touch = event.allTouches?.first else { return }
  
//        if touch.tapCount == 1 {
            // Handle tap
            print("Clearing done items")
               try! realm.write {
                   doneItems?.forEach({ (item) in
                       realm.delete(item)
                   })
               }
               refresh()
//        } else if touch.tapCount == 0 {
//            // Handle long press
//            print("Long press!")
//        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath)
        if let todo = todoItems?[indexPath.row] {
            formatCellText(cell: cell, todo: todo)
        } else {
            cell.textLabel?.text = "No Todo"
        }
        return cell
    }

    
    func formatCellText(cell: UITableViewCell, todo: Item) {
        // Reset the labels
        // Note that the order matters here. See: https://stackoverflow.com/a/58631165
        cell.textLabel?.attributedText = nil
        cell.textLabel?.text = nil
        
        // Fill in values
        cell.textLabel?.text = todo.title
        cell.textLabel?.strikeThrough(todo.done)
        cell.accessoryType = todo.done ? .checkmark : .none
        cell.textLabel?.highlight(text: searchBarOutlet.text ?? "")
    }
    
    //MARK: - TableView Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        let todo = todoItems![indexPath.row]
        try! realm.write {
            todo.toggle()
        }
        
        formatCellText(cell: cell, todo: todo)
    }
    
    //MARK: - Add New Items
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        let alert = configureAddDialog()
        present(alert, animated: true, completion: nil)
    }
    
    
    func configureAddDialog() -> UIAlertController {
        let alert = UIAlertController(title: "Add new Todoey Item", message: "", preferredStyle: .alert)
        var textField : UITextField?
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Buy milk and eggs"
            textField = alertTextField
        }
        
        alert.addAction(UIAlertAction(title: "Add Item", style: .default) { (action) in
            if let newTodo = textField?.text {
                if newTodo.count > 0 {
                    self.addTodo(newTodo)
                    self.refresh()
                }
            }
        })
        
        return alert
    }
    
    func configureEraseAllDialog() -> UIAlertController {
        let alert = UIAlertController(title: "Erase all Todos?", message: "", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "ERASE", style: .destructive) { (action) in
            print("BOOM!")
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        return alert
    }
    
    func addTodo(_ title:String) {
        let item = Item()
        item.title = title
        item.done = false
        addTodo(item)
    }
    
    func addTodo(_ item:Item) {
        DispatchQueue.main.async {
            do {
                try self.realm.write {
                    self.selectedCategory?.items.append(item)
                }
            } catch {
                print("Error adding todo to Realm")
            }
            self.refresh()
        }
    }
    
    //MARK: - Persistence
    func refresh() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func combinePredicates(predicates: NSPredicate?...) -> NSCompoundPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates.compactMap{$0})
    }
    
    func loadItems(with predicate: NSPredicate? = nil, sorting: NSSortDescriptor? = nil) {
        todoItems = selectedCategory?.items.sorted(byKeyPath: "title", ascending: true)
        doneItems = selectedCategory?.items
            .filter("done == true")
            .sorted(byKeyPath: "title", ascending: true)
        refresh()
    }
}

//MARK: - Search Bar Methods
extension ToDoListViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        DispatchQueue.main.async {
            searchBar.resignFirstResponder()
        }
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count == 0 {
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        } else {
            let predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchBar.text!)
            let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
            loadItems(with: predicate, sorting: sortDescriptor)
        }
    }
    
}

//MARK: - ToDo Generator
extension ToDoListViewController: ToDoGeneratorDelegate {
    func generateNewTodo() {
        todoGenerator.generate()
    }
    
    func didReceiveNewTodo(_ sender: ToDoGenerator, newTodo: Item) {
        self.addTodo(newTodo)
    }
    
    func didFailWithError(_ error: Error) {
        print(error)
    }
}

extension UILabel {
    
    func strikeThrough(_ isStrikeThrough:Bool) {
        if isStrikeThrough {
            if let lblText = self.text {
                let attributeString =  NSMutableAttributedString(string: lblText)
                attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0,attributeString.length))
                self.attributedText = attributeString
            }
        } else {
            // Clear the strikethrough in 2 different ways...
            if let attributedStringText = self.attributedText {
                let txt = attributedStringText.string
                self.attributedText = nil
                self.text = txt
            }
        }
    }
    
    func highlight(text highlightText: String) {
        if let initialText = self.attributedText {
            let attrString: NSMutableAttributedString = NSMutableAttributedString(attributedString: initialText)
            let range: NSRange = (initialText.string as NSString).range(of: highlightText , options:NSString.CompareOptions.caseInsensitive)
            attrString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: range)
            attrString.addAttribute(NSAttributedString.Key.font, value: UIFont.boldSystemFont(ofSize: 16), range: range)
            self.attributedText = attrString
        }
    }
}

