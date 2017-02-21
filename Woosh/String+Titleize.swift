//
//  String+Titleize.swift
//  Woosh
//
//  Created by Keaton Burleson on 2/21/17.
//  Copyright © 2017 Keaton Burleson. All rights reserved.
//

import Foundation
let SMALL_WORDS = ["a", "al", "y", "o", "la", "el", "las", "los", "de", "del"]

extension String {
    var titleized:String {
        var words = self.lowercased().characters.split(separator: " ").map { String($0) }
        words[0] = words[0].capitalized(with: Locale.current)
        for i in 1..<words.count {
            if !SMALL_WORDS.contains(words[i]) {
                words[i] = words[i].localizedCapitalized
            }
        }
        return words.joined(separator: " ")
    }
}
