//
//  Vocabulary.swift
//  Vocap
//
//  Created by Juhyun Yun on 2023/03/03.
//

import Foundation
import RealmSwift

class Vocabulary: Object {
    @Persisted var vocab: String = ""
    @Persisted var meaning: String = ""
    @Persisted var example: String = ""
    @Persisted var wordClass: String = ""
    @Persisted var dateCreated: Date?
}

