//
//  CategoryViewController.swift
//  Todoey
//
//  Created by Michael Ricks-Aherne on 6/14/20.
//  Copyright © 2020 App Brewery. All rights reserved.
//

import UIKit
import RealmSwift

class CategoryViewController: UITableViewController {
    
    var categoryList: Results<Category>?
    let realm = try! Realm()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadCategories()
    }
    
    //MARK: - TableView Datasource Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categoryList?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.categoryCellIdentifier, for: indexPath)
        let category = categoryList?[indexPath.row]
        formatCellText(cell: cell, category: category)
        return cell
    }
    
    func formatCellText(cell: UITableViewCell, category: Category?) {
        // Reset the labels
        // Note that the order matters here. See: https://stackoverflow.com/a/58631165
        cell.textLabel?.attributedText = nil
        cell.textLabel?.text = nil
        
        // Fill in values
        cell.textLabel?.text = category?.name ?? "No Categories added yet"
    }
    
    //MARK: - TableView Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: K.segueCategoryToItems, sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - Swipe to Delete
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            //guard let cell = tableView.cellForRow(at: indexPath) else { return }
            print("swipe to wipe!")
            try! realm.write {
                realm.delete((categoryList?[indexPath.row])!)
            }
            loadCategories()
        }
    }
    
    //MARK: - Add New Items
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Add new Todoey Category", message: "", preferredStyle: .alert)
        var textField : UITextField?
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Groceries / Work / Home"
            textField = alertTextField
        }
        
        alert.addAction(UIAlertAction(title: "Add Category", style: .default) { (action) in
            if let newCategory = textField?.text {
                if newCategory.count > 0 {
                    self.addCategory(newCategory)
                }
            }
        })
        present(alert, animated: true, completion: nil)
    }
    
    func addCategory(_ name:String) {
        let category = Category()
        category.name = name
        addCategory(category)
    }
    
    func addCategory(_ category:Category) {
        
        saveCategories(category: category)
        loadCategories()
    }
    
    //MARK: - Persistence
    func saveCategories(category: Category) {
        do {
            try realm.write {
                realm.add(category)
            }
            print("Saved categories.")
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    func refresh() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func loadCategories() {
        categoryList = realm.objects(Category.self)
        refresh()
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case K.segueCategoryToItems:
            if let vc = segue.destination as? ToDoListViewController {
                if let indexPath = self.tableView.indexPathForSelectedRow {
                    print("Setting category")
                    vc.selectedCategory = categoryList?[indexPath.row]
                }
            }
            
        default:
            print("Do nothing")
        }
    }
}
