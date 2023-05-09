//
//  DetailCell.swift
//  Vocap
//
//  Created by Juhyun Yun on 2023/03/30.
//

import UIKit

class DetailCell: UITableViewCell {
    
    var button: UIButton!
    var textView: UITextView!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        button = UIButton()
        button.contentHorizontalAlignment = .left
        button.setTitle("", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = contentView.backgroundColor
        textView.isScrollEnabled = false
        
        contentView.addSubview(button)
        contentView.addSubview(textView)
        
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 11),
            button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            button.bottomAnchor.constraint(equalTo: textView.topAnchor, constant: 0),
            button.heightAnchor.constraint(equalToConstant: 25),
            
            textView.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 0),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
                
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
