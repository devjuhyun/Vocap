//
//  VocabularyCell.swift
//  Vocap
//
//  Created by Juhyun Yun on 2023/03/07.
//
import UIKit

class VocabularyCell: UITableViewCell {
    let vocabTextField = UITextField()
    let meaningTextField = CustomTextField()
    
    // closure used to tell the controller that the text field has been edited
    var vocabCallback: ((String) ->())?
    var meaningCallback: ((String) ->())?
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    func commonInit() -> Void {
        vocabTextField.borderStyle = .none
        vocabTextField.placeholder = ""
        vocabTextField.translatesAutoresizingMaskIntoConstraints = false
        vocabTextField.font = UIFont.boldSystemFont(ofSize: 20)
        

        meaningTextField.borderStyle = .none
        meaningTextField.placeholder = "Add Definition"
        meaningTextField.translatesAutoresizingMaskIntoConstraints = false
        meaningTextField.font = UIFont.systemFont(ofSize: 15)

        contentView.addSubview(vocabTextField)
        contentView.addSubview(meaningTextField)

        let g = contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            vocabTextField.topAnchor.constraint(equalTo: g.topAnchor, constant: 0.0),
            vocabTextField.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 0.0),
            vocabTextField.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: 0.0),
            vocabTextField.bottomAnchor.constraint(equalTo: meaningTextField.topAnchor, constant: 0.0),
            meaningTextField.topAnchor.constraint(equalTo: vocabTextField.bottomAnchor, constant: 0.0),
            meaningTextField.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 0.0),
            meaningTextField.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: 0.0),
            meaningTextField.bottomAnchor.constraint(equalTo: g.bottomAnchor, constant: 0.0)
        ])

        vocabTextField.addTarget(self, action: #selector(self.vocabTextFieldEdited(_:)), for: .editingChanged)

        meaningTextField.addTarget(self, action: #selector(self.meaningTextFieldEdited(_:)), for: .editingChanged)
    }
    
    @objc func vocabTextFieldEdited(_ textField: UITextField) -> Void {
        // send newly edited text back to the controller
        vocabCallback?(textField.text ?? "")
    }
    
    @objc func meaningTextFieldEdited(_ textField: UITextField) -> Void {
        // send newly edited text back to the controller
        meaningCallback?(textField.text ?? "")
    }
    
}


// 한국어 키보드 https://velog.io/@leeesangheee/TextField-한국어-키보드로-설정하기
class CustomTextField: UITextField {

    private func getKeyboardLanguage() -> String? {
        return "ko-KR"
    }

    override var textInputMode: UITextInputMode? {
        if let language = getKeyboardLanguage() {
            for inputMode in UITextInputMode.activeInputModes {
                if inputMode.primaryLanguage! == language {
                    return inputMode
                }
            }
        }
        return super.textInputMode
    }

}
