//
//  Category.swift
//  Vocap
//
//  Created by Juhyun Yun on 2023/04/12.
//

import Foundation
import RealmSwift

class Category: Object {
    @Persisted var name: String = ""
    
    @Persisted var vocabularies = List<Vocabulary>()
}
