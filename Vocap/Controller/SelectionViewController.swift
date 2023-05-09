//
//  SelectionViewController.swift
//  Vocap
//
//  Created by Juhyun Yun on 2023/05/01.
//

import UIKit
import RealmSwift

class SelectionViewController: UITableViewController {
    
    //MARK: - Properties
    var categories: Results<Category>?
    var selectedCategory: Category?
    var selectedVocabs: [Vocabulary]?
    var indexs: [Int]?
        
    let realm = try! Realm()
    
    //MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 50
        tableView.backgroundColor = UIColor.systemGroupedBackground

        loadCategories()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let navVC = presentingViewController as? UINavigationController {
            if let firstVC = navVC.viewControllers[0] as? CategoriesViewController {
                firstVC.tableView.reloadData()
            }
            if let secondVC = navVC.viewControllers[1] as? VocabulariesViewController {
                secondVC.tableView.reloadData()
            }
        }
    }
    
    //MARK: - IBActions
    @IBAction func cancelBtnPressed(_ sender: Any) {
        navigationController?.dismiss(animated: true)
    }
    
    @IBAction func addBtnPressed(_ sender: UIBarButtonItem) {
        presentAlert(button: "add", title: "새 카테고리")
    }
    
    //MARK: - TableView Delegate Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SelectionCell", for: indexPath)
        
        cell.textLabel?.text = categories?[indexPath.row].name
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "카테고리 목록"
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        try! realm.write {
            if let indexs = indexs {
                let indexSet = IndexSet(indexs)
                selectedCategory?.vocabs.remove(atOffsets: indexSet)
            }
            
            if let selectedVocabs {
                categories?[indexPath.row].vocabs.append(objectsIn: selectedVocabs)
            }
        }
                
        navigationController?.dismiss(animated: true)
        
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
    
    //MARK: - Functions
    func presentAlert(button: String, title: String) {
        var textField = UITextField()
        
        let alert = UIAlertController(title: title, message: "", preferredStyle: .alert)
        
        let save = UIAlertAction(title: "확인", style: .default) { UIAlertAction in
            let category = Category()
            category.name = textField.text!
            self.saveCategories(category: category)
        }
        
        alert.addTextField { UITextField in
            textField = UITextField
            textField.placeholder = "Name"
        }
        
        alert.addAction(save)
        
        present(alert, animated: true)
    }
    
    
}

