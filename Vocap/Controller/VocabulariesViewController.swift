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
    let realm = try! Realm()
    var vocabularies: Results<Vocabulary>?
    var filteredVocabularies: Results<Vocabulary>?
    var selectedVocabularies: [Vocabulary]?
    var indexs: [Int]? = []
    
    var label = UILabel(frame: .zero)
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
    @IBOutlet weak var selectBtn: UIBarButtonItem!
    @IBOutlet weak var moveBtn: UIBarButtonItem!
    @IBOutlet weak var deleteBtn: UIBarButtonItem!
    
    //MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        createLableInToolbar()
        
        // read database
        loadVocabularies()
        
        // table view configuration
        tableView.rowHeight = 70.0
        tableView.backgroundColor = UIColor.systemGroupedBackground
        tableView.allowsSelection = false
        
        // navigation properties
        doneBtn.isHidden = true
        moveBtn.isHidden = true
        deleteBtn.isHidden = true
        
        // detecting empty area in UITableView when it is tapped
        let tap = UITapGestureRecognizer(target: self, action: #selector(tableTapped))
        self.tableView.addGestureRecognizer(tap)
        tap.cancelsTouchesInView = false // 롱터치? 해야 셀 선택되는거 막아줌
        
        // configure searchbar
        navigationItem.searchController = searchController
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = "Search words"
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        navigationItem.title = selectedCategory?.name

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        deleteEmptyCell()
    }
    
    //MARK: - functions
    func createLableInToolbar() {
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let rightSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        label.text = "0 Words"
        label.font = UIFont.systemFont(ofSize: 13)
        label.textAlignment = .center
        label.textColor = .label
        label.adjustsFontSizeToFitWidth = true
        let customBarButton = UIBarButtonItem(customView: label)
        setToolbarItems([moveBtn, space, customBarButton, rightSpace, deleteBtn], animated: false)
    }
    
    
    //MARK: - IBActions
    @IBAction func addBtnTapped(_ sender: Any) {
        addNewVocab()
    }
    
    @IBAction func doneBtnTapped(_ sender: Any) {
        deleteEmptyCell()
        
        if tableView.isEditing {
            setBarButton()
            tableView.setEditing(false, animated: true)
        }
        
        self.view.endEditing(true)
        tableView.reloadData()
        
    }
    
    func deleteEmptyCell() {
        let indexPath = IndexPath(row: vocabularies!.count-1, section: 0)
        
        if let cell = tableView.cellForRow(at: indexPath) as? VocabularyCell {
            if cell.vocabTextField.text == "" || cell.meaningTextField.text == "" {
                deleteVocabularies(at: indexPath.row)
            }
        }
    }
    
    @IBAction func selectBtnTapped(_ sender: UIBarButtonItem) {
        if tableView.cellForRow(at: IndexPath(row: 0, section: 0)) == nil {
            return
        }
        
        tableView.allowsSelectionDuringEditing = true
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.setEditing(true, animated: true)
        label.text = "0 Words"
        setBarButton()
    }
    
    @IBAction func moveBtnTapped(_ sender: UIBarButtonItem) {
        getSelectedVocabs()
        performSegue(withIdentifier: "goToSelection", sender: self)
    }
    
    @IBAction func deleteBtnTapped(_ sender: UIBarButtonItem) {
        getSelectedVocabs()
        
        if let selectedVocabularies {
            do {
                try realm.write {
                    realm.delete(selectedVocabularies)
                }
            } catch {
                ("Error deleting vocabs: \(error.localizedDescription)")
            }
            tableView.reloadData()
        }
        
        
        if tableView.isEditing {
            setBarButton()
            tableView.setEditing(false, animated: true)
        }
        
        self.view.endEditing(true)

    }
    
    
    func getSelectedVocabs() {
        if let selectedRows = tableView.indexPathsForSelectedRows {
            let indexs = selectedRows.map{ $0[1] }.sorted()
            if isFiltering {
                if let filteredVocabularies {
                    selectedVocabularies = indexs.map{ filteredVocabularies[$0] }
                }
            } else {
                if let vocabularies {
                    selectedVocabularies = indexs.map{ vocabularies[$0] }
                }
            }
        }
        
        getIndexs()
    }
    
    func getIndexs() {
        indexs = []
        
        if let selectedVocabularies {
            for vocab in selectedVocabularies {
                if let index = selectedCategory?.vocabs.index(of: vocab) {
                    indexs?.append(index)
                }
            }
            indexs?.sort()
        }
    }
    
    
    
    
    
    //MARK: - Add New Vocabulary
    func addNewVocab() {
        deleteEmptyCell()
        
        if searchController.isActive {
            searchController.isActive = false
        }
        
        
        if tableView.isEditing {
            return
        }
        
        let newVocabulary = Vocabulary()
        newVocabulary.dateCreated = Date()
        saveVocabularies(vocabulary: newVocabulary)
        tableView.reloadData()
        
        let indexPath = IndexPath(row: vocabularies!.count-1, section: 0)
        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let cell = self.tableView.cellForRow(at: indexPath) as? VocabularyCell {
                cell.vocabTextField.becomeFirstResponder()
            }
        }
    }
    
    func setBarButton() {
        addBtn.isHidden = !addBtn.isHidden
        doneBtn.isHidden = !doneBtn.isHidden
        selectBtn.isHidden = !selectBtn.isHidden
        
        if tableView.isEditing {
            deleteBtn.isHidden = !deleteBtn.isHidden
            moveBtn.isHidden = !moveBtn.isHidden
        }
    }
    
    //MARK: - TableView Delegate Methods
    @objc func tableTapped(tap:UITapGestureRecognizer) {
        let location = tap.location(in: self.tableView)
        let path = self.tableView.indexPathForRow(at: location)
        
        if path == nil {
            if addBtn.isHidden {
                deleteEmptyCell()
            } else {
                addNewVocab()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        label.text = "0 Words"
        
        return isFiltering ? filteredVocabularies?.count ?? 1 : vocabularies?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VocabCell", for: indexPath) as! VocabularyCell
        guard let vocabulary = vocabularies?[indexPath.row] else {fatalError()}
        
        if isFiltering {
            if let filteredVocabulary = filteredVocabularies?[indexPath.row] {
                label.text = "\(filteredVocabularies?.count ?? 0) Words"
                cell.vocabTextField.text = filteredVocabulary.vocab
                cell.meaningTextField.text = filteredVocabulary.meaning
            }
        } else {
            label.text = "\(vocabularies?.count ?? 0) Words"
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
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? VocabularyCell else { fatalError() }
        
        if cell.vocabTextField.text != "" {
            performSegue(withIdentifier: "goToDetail", sender: indexPath.row)
        }
    
        //        deleteVocabularies(at: indexPath.row)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let nextNav = segue.destination as? UINavigationController else { fatalError() }
        
        if let detailViewController = nextNav.topViewController as? DetailViewController {
            if let index = sender as? Int {
                detailViewController.selectedVocabulary = vocabularies?[index]
            }
        }
                
        if let selectionVC = nextNav.topViewController as? SelectionViewController {
            selectionVC.selectedVocabs = selectedVocabularies
            selectionVC.selectedCategory = selectedCategory
            selectionVC.indexs = indexs
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        changeToolbarItems()
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        changeToolbarItems()
    }

    func changeToolbarItems() {
        let a = tableView.indexPathsForSelectedRows
        
        moveBtn.isEnabled = true
        deleteBtn.isEnabled = true
        
        if a == nil {
            moveBtn.isEnabled = false
            deleteBtn.isEnabled = false
            label.text = "0 Words"
        } else {
            label.text = "\(a!.count) Words"
        }
    }
    
    
    
    //MARK: - Data Manipulation Methods
    func saveVocabularies(vocabulary: Vocabulary) {
        do {
            try realm.write {
                selectedCategory?.vocabs.append(vocabulary)
            }
        } catch {
            print("Error saving notes, \(error)")
        }
        
        tableView.reloadData()
    }
    
    func loadVocabularies() {
        vocabularies = selectedCategory?.vocabs.sorted(byKeyPath: "dateCreated", ascending: true)
        
        tableView.reloadData()
    }
    
    func deleteVocabularies(at indexPath: Int) {
        if let vocabulary = vocabularies?[indexPath] {
            do {
                try realm.write {
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
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        setBarButton()
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if tableView.isEditing {
            return false
        }
        
        setBarButton()
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
