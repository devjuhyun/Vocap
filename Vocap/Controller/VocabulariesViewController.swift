//
//  ViewController.swift
//  Vocap
//
//  Created by Juhyun Yun on 2023/03/03.
//

import UIKit
import RealmSwift

class VocabulariesViewController: UITableViewController, UITextFieldDelegate {
    //MARK: - Properties
    var vocabularies: Results<Vocabulary>?
    var filteredVocabularies: Results<Vocabulary>?
    let realm = try! Realm()
    var textField: UITextField!
    var searchController = UISearchController(searchResultsController: nil)
    var selectedCategory: Category? {
        didSet {
            loadVocabularies()
        }
    }
    
    var isFiltering: Bool {
        let searchController = self.navigationItem.searchController
        let isActive = searchController?.isActive ?? false
        let isSearchBarHasText = searchController?.searchBar.text?.isEmpty == false
        
        return isActive && isSearchBarHasText
    }
    
    //MARK: - IBOutlets
    @IBOutlet weak var addBtn: UIBarButtonItem!
    @IBOutlet weak var doneBtn: UIBarButtonItem!
    
    //MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // read database
        loadVocabularies()
        
        // table view configuration
        tableView.rowHeight = 70.0
        tableView.backgroundColor = UIColor.systemGroupedBackground
        
        // navigation properties
        doneBtn.isHidden = true
        
        // detecting empty area in UITableView when it is tapped
        let tap = UITapGestureRecognizer(target: self, action: #selector(tableTapped))
        self.tableView.addGestureRecognizer(tap)
        
        // configure searchbar
        navigationItem.searchController = searchController
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = "Search words"
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        
    }
    
    //MARK: - IBActions
    @IBAction func addBtnTapped(_ sender: Any) {
        addNewVocab()
    }
    
    @IBAction func doneBtnTapped(_ sender: Any) {
        let indexPath = IndexPath(row: vocabularies!.count-1, section: 0)
        
        if let cell = tableView.cellForRow(at: indexPath) as? VocabularyCell {
            if cell.vocabTextField.text == "" || cell.meaningTextField.text == "" {
                deleteVocabularies(at: indexPath.row)
            }
        }
        
        self.view.endEditing(true)
    }
    
    //MARK: - Add New Vocabulary
    func addNewVocab() {
        let newVocabulary = Vocabulary()
        saveVocabularies(vocabulary: newVocabulary)
        tableView.reloadData()
        
        let indexPath = IndexPath(row: self.vocabularies!.count-1, section: 0)
        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let cell = self.tableView.cellForRow(at: indexPath) as? VocabularyCell {
                cell.vocabTextField.becomeFirstResponder()
            }
        }
    }
    
    func setBarButton(isEditing: Bool) {
        
        if isEditing {
            addBtn.isHidden = true
            doneBtn.isHidden = false
        } else {
            addBtn.isHidden = false
            doneBtn.isHidden = true
        }
        
    }
    
    //MARK: - TableView Delegate Methods
    @objc func tableTapped(tap:UITapGestureRecognizer) {
        let location = tap.location(in: self.tableView)
        let path = self.tableView.indexPathForRow(at: location)
        
        if path == nil {
            let indexPath = IndexPath(row: vocabularies!.count-1, section: 0)
            
            if let cell = tableView.cellForRow(at: indexPath) as? VocabularyCell {
                if cell.vocabTextField.text == "" || cell.meaningTextField.text == "" {
                    deleteVocabularies(at: indexPath.row)
                } else {
                    addNewVocab()
                }
            } else {
                addNewVocab()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isFiltering ? filteredVocabularies?.count ?? 1 : vocabularies?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VocabCell", for: indexPath) as! VocabularyCell
        guard let vocabulary = vocabularies?[indexPath.row] else {fatalError()}
        
        if isFiltering {
            if let filteredVocabulary = filteredVocabularies?[indexPath.row] {
                cell.vocabTextField.text = filteredVocabulary.vocab
                cell.meaningTextField.text = filteredVocabulary.meaning
            }
        } else {
            cell.vocabTextField.text = vocabulary.vocab
            cell.meaningTextField.text = vocabulary.meaning
        }
        
        cell.vocabTextField.autocapitalizationType = .none
        
        cell.vocabTextField.tag = indexPath.row * 2
        cell.meaningTextField.tag = cell.vocabTextField.tag + 1
        
        cell.vocabTextField.delegate = self
        cell.meaningTextField.delegate = self
        
        
        cell.vocabCallback = { str in
            // update data array when text in cell is edited
            try! self.realm.write {
                vocabulary.vocab = str
            }
        }
        
        cell.meaningCallback = { str in
            try! self.realm.write {
                vocabulary.meaning = str
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let delete = UIContextualAction(style: .normal, title: nil) { (UIContextualAction, UIView, success: @escaping (Bool) -> Void) in
            self.deleteVocabularies(at: indexPath.row)
            success(true)
        }
        
        delete.backgroundColor = .red
        delete.image = UIImage(systemName: "trash.fill")
        
        return UISwipeActionsConfiguration(actions:[delete])
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("ddd")
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? VocabularyCell else { fatalError() }

        if cell.vocabTextField.text != "" {
            performSegue(withIdentifier: "goToDetail", sender: indexPath.row)
        }
        
//        deleteVocabularies(at: indexPath.row)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let navigationController = segue.destination as? UINavigationController else { fatalError() }
        
        guard let detailViewController = navigationController.topViewController as? DetailViewController else { fatalError() }
        
        if let index = sender as? Int {
            detailViewController.selectedVocabulary = vocabularies?[index]
        }
    }
    
    //MARK: - Data Manipulation Methods
    func saveVocabularies(vocabulary: Vocabulary) {
        do {
            try realm.write {
                realm.add(vocabulary)
            }
        } catch {
            print("Error saving notes, \(error)")
        }
        
        tableView.reloadData()
    }
    
    func loadVocabularies() {
        vocabularies = realm.objects(Vocabulary.self)
        
        tableView.reloadData()
    }
    
    func deleteVocabularies(at indexPath: Int) {
        if let vocabulary = vocabularies?[indexPath] {
            do {
                try self.realm.write {
                    self.realm.delete(vocabulary)
                }
            } catch {
                print("Error deleting notes, \(error)")
            }
            tableView.reloadData()
        }
        
    }
    
    //MARK: - TextField Delegate Methods
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let tag = textField.tag
        let row = tag / 2
        
        guard let cell = textField.superview?.superview as? VocabularyCell else { fatalError() }
        
        if tag % 2 == 0 { // on vocabTF
            if textField.text == "" {
                textField.endEditing(true)
                deleteVocabularies(at: row)
            } else {
                cell.meaningTextField.becomeFirstResponder()
            }
        }
        
        if tag % 2 == 1 { // on meaningTF
            guard let vocabularies = vocabularies?.count else { fatalError() }
            let indexPath = IndexPath(row: row + 1, section: 0)
            
            if row < vocabularies - 1 {
                let nextCell = tableView.cellForRow(at: indexPath) as! VocabularyCell
                nextCell.vocabTextField.becomeFirstResponder()
            } else {
                if textField.text == "" {
                    deleteVocabularies(at: row)
                } else {
                    addNewVocab()
                    let nextCell = tableView.cellForRow(at: indexPath) as! VocabularyCell
                    nextCell.vocabTextField.becomeFirstResponder()
                }
            }
        }
        
        return true
        
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        setBarButton(isEditing: true)
        
        if let cell = textField.superview?.superview as? VocabularyCell {
            if textField == cell.vocabTextField {
                print("begin editing")
            } else if textField == cell.meaningTextField {
                print("begin editing")
            }
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        setBarButton(isEditing: false)
        if let cell = textField.superview?.superview as? VocabularyCell {
            if textField == cell.vocabTextField {
                print("end editing")
            } else if textField == cell.meaningTextField {
                print("end editing")
            }
        }
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if let cell = textField.superview?.superview as? VocabularyCell {
            if cell.vocabTextField.text == ""  {
                print("end editing")
            } else if textField == cell.meaningTextField {
                print("end editing")
            }
        }
        
        return true
    }
    
}

extension VocabulariesViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        
        filteredVocabularies = vocabularies?.filter("vocab CONTAINS[cd] %@", text).sorted(byKeyPath: "vocab", ascending: true)
        
        tableView.reloadData()
    }
    
    
}
