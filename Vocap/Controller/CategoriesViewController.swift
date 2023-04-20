//
//  CategoriesViewController.swift
//  Vocap
//
//  Created by Juhyun Yun on 2023/04/12.
//

import UIKit
import RealmSwift

class CategoriesViewController: UITableViewController {
    
    //MARK: - Properties
    var categories: Results<Category>?
    var realm = try! Realm()
    
    //MARK: - IBOutlets
    @IBOutlet weak var addBtn: UIBarButtonItem!
    
    
    //MARK: - View Life Cycler
    override func viewDidLoad() {
        super.viewDidLoad()
        loadCategories()
    }
    
    //MARK: - IBActions
    @IBAction func addBtnPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        let alert = UIAlertController(title: "Add New Category", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add", style: .default) { UIAlertAction in
            let category = Category()
            category.name = textField.text!
            
            self.saveCategories(category: category)
        }
        
        alert.addTextField { UITextField in
            textField = UITextField
            textField.placeholder = "Create New Category"
        }
        
        alert.addAction(action)
        
        present(alert, animated: true)
    }
    
    //MARK: - Table View Delegate Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)
        
        cell.textLabel?.text = categories?[indexPath.row].name
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .normal, title: nil) { (UIContextualAction, UIView, success: @escaping (Bool) -> Void) in
            self.deleteCategories(at: indexPath.row)
            success(true)
        }
        
        delete.backgroundColor = .red
        delete.image = UIImage(systemName: "trash.fill")
        
        return UISwipeActionsConfiguration(actions:[delete])
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "goToVocab", sender: indexPath)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! VocabulariesViewController
        
        if let indexPath = tableView.indexPathForSelectedRow {
            destinationVC.selectedCategory = categories?[indexPath.row]
        }
    }
    
    //MARK: - Data Manipulation Methods
    func saveCategories(category: Category) {
        do {
            try realm.write {
                realm.add(category)
            }
        } catch {
            print("Error saving a category, \(error)")
        }
        
        tableView.reloadData()
    }
    
    func loadCategories() {
        categories = realm.objects(Category.self)
        
        tableView.reloadData()
    }
    
    func deleteCategories(at indexPath: Int) {
        if let category = categories?[indexPath] {
            do {
                try self.realm.write {
                    self.realm.delete(category)
                }
            } catch {
                print("Error deleting categories, \(error)")
            }
            
            tableView.reloadData()
        }
        
    }
    
}
