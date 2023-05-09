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
    let realm = try! Realm()
    
    //MARK: - IBOutlets
    @IBOutlet weak var addBtn: UIBarButtonItem!
    
    
    //MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        loadCategories()
        
        tableView.rowHeight = 70
        tableView.backgroundColor = UIColor.systemGroupedBackground
    }
        
    //MARK: - IBActions
    @IBAction func addBtnPressed(_ sender: UIBarButtonItem) {
        presentAlert(button: "add", title: "새 카테고리")
    }
    
    //MARK: - Table View Delegate Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)
        
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        
        cell.textLabel?.text = categories?[indexPath.row].name
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .normal, title: "delete") { (UIContextualAction, UIView, success: @escaping (Bool) -> Void) in
            self.deleteCategories(at: indexPath.row)
            success(true)
        }
        let rename = UIContextualAction(style: .normal, title: nil) { ( UIContextualAction, UIView, success: @escaping (Bool) -> Void) in
            if let category = self.categories?[indexPath.row] {
                self.presentAlert(button: "edit", title: "카테고리 이름 변경", index: indexPath.row, text: category.name)
            }
            
            success(true)
        }
        
        delete.backgroundColor = .red
        delete.image = UIImage(systemName: "trash.fill")
        
        rename.backgroundColor = .orange
        rename.image = UIImage(systemName: "pencil")
        rename.title = "Rename"
        
        return UISwipeActionsConfiguration(actions:[delete, rename])
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
        
        let alert = UIAlertController(title: nil, message: "카테고리 속 단어가 모두 삭제됩니다.", preferredStyle: .actionSheet)
        
        let action = UIAlertAction(title: "카테고리 삭제", style: .default, handler: { UIAlertAction in
            if let category = self.categories?[indexPath] {
                do {
                    try self.realm.write {
                        self.realm.delete(category)
                    }
                } catch {
                    print("Error deleting categories, \(error)")
                }
                
                self.tableView.reloadData()
            }
        })
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler:{ (UIAlertAction)in
                
        }))
        
        action.setValue(UIColor.systemRed, forKey: "titleTextColor")
        
        alert.addAction(action)
                
        present(alert, animated: true)
        
    }
    
    
    func presentAlert(button: String, title: String, index: Int = 0, text: String = "") {
        var textField = UITextField()
        
        let alert = UIAlertController(title: title, message: "", preferredStyle: .alert)
        
        let save = UIAlertAction(title: "확인", style: .default) { UIAlertAction in
            
            if button == "add" {
                let category = Category()
                category.name = textField.text!
                
                self.saveCategories(category: category)
            } else if button == "edit" {
                try! self.realm.write {
                    self.categories?[index].name = textField.text!
                }
                self.tableView.reloadData()
            }
        }
        
        let cancel = UIAlertAction(title: "취소", style: .cancel) { UIAlertAction in
            
        }
        
        alert.addTextField { UITextField in
            textField = UITextField
            textField.placeholder = "Name"
            textField.text = text
        }
        
        alert.addAction(save)
        alert.addAction(cancel)
        
        present(alert, animated: true)
    }
    
}
