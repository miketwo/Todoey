//
//  Item.swift
//  Todoey
//
//  Created by Michael Ricks-Aherne on 6/15/20.
//  Copyright © 2020 App Brewery. All rights reserved.
//

import Foundation
import RealmSwift

class Item: Object {
    @objc dynamic var title: String = ""
    @objc dynamic var done: Bool = false
    var parentCategory = LinkingObjects(fromType: Category.self, property: "items")
    
    func toggle() {
        done = !done
    }
}
