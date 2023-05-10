//
//  detailViewController.swift
//  Vocap
//
//  Created by Juhyun Yun on 2023/03/30.
//

import UIKit
import RealmSwift

class DetailViewController: UITableViewController {
    //MARK: - Properties
    let realm = try! Realm()
    var selectedVocabulary: Vocabulary?
    var i = 0 // 품사 버튼 타이틀 조절
    
    //MARK: - IBOutlet
    @IBOutlet weak var doneBtn: UIBarButtonItem!
    @IBOutlet weak var vocabLabel: UILabel!
    
    //MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        vocabLabel.text = selectedVocabulary?.vocab
        tableView.register(DetailCell.self, forCellReuseIdentifier: "DetailCell")
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableView.automaticDimension
        tableView.keyboardDismissMode = .onDrag
        
        doneBtn.isHidden = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tableTapped))
        self.tableView.addGestureRecognizer(tap)        
    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let navVC = presentingViewController as? UINavigationController {
            if let firstVC = navVC.viewControllers[1] as? VocabulariesViewController {
                    firstVC.tableView.reloadData()
            }
        }
    }
    
    //MARK: - IBActions
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true)
    }
    @IBAction func doneBtnClicked(_ sender: UIBarButtonItem) {
        self.view.endEditing(true)
    }
    
    //MARK: - TableView Delegate Methods
    @objc func tableTapped(tap:UITapGestureRecognizer) {
        let location = tap.location(in: self.tableView)
        let path = self.tableView.indexPathForRow(at: location)
        
        if path == nil {
            self.view.endEditing(true)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath) as! DetailCell
        
        cell.textView.delegate = self
        
        if let vocabulary = selectedVocabulary {
            if indexPath.row == 0 {
                cell.button.setTitle("의미", for: .normal)
                cell.textView.text = vocabulary.meaning
//                cell.button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)

            } else if indexPath.row == 1 {
                
                cell.button.setTitle("예문", for: .normal)
                cell.textView.text = vocabulary.example

                
                if cell.textView.text.isEmpty {
                    cell.textView.text = "Add your example"
                    cell.textView.textColor = UIColor.lightGray
                } else if cell.textView.text == "Add your example" {
                    cell.textView.textColor = UIColor.lightGray
                }
            }            
        }
                
        return cell
    }
    
//    @objc func buttonTapped(_ sender: UIButton) {
//        let btntitles = ["동사", "명사", "형용사", "부사"]
//
//        if i < 3 {
//            i += 1
//        } else {
//            i = 0
//        }
//
//        sender.setTitle(btntitles[i], for: .normal)
//
//        guard let vocabulary = selectedVocabulary else { fatalError() }
//
//        try! realm.write {
//            vocabulary.wordClass = btntitles[i]
//        }
//    }
    
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
    
}

//MARK: - TextView Delegate Methods
extension DetailViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        UIView.setAnimationsEnabled(false)
        tableView.beginUpdates()
        tableView.endUpdates()
        UIView.setAnimationsEnabled(true)
    }
    
// return 버튼 누르면 편집 종료하는 메소드
//    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//        if text == "\n" {
//            textView.resignFirstResponder()
//            return false
//        }
//        return true
//    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        doneBtn.isHidden = true
        
        guard let vocabulary = selectedVocabulary else { fatalError() }
        guard let cell = textView.superview?.superview as? DetailCell else { fatalError() }
        
        if let indexPath = tableView.indexPath(for: cell) {
            if indexPath.row == 0 {
                try! realm.write {
                    vocabulary.meaning = textView.text
                }
            } else if indexPath.row == 1 {
                
                if textView.text.isEmpty {
                    textView.text = "Add your example"
                    textView.textColor = UIColor.lightGray
                }
                
                try! realm.write {
                    vocabulary.example = textView.text
                }
            }
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        doneBtn.isHidden = false
        
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.label
        }
    }
}

