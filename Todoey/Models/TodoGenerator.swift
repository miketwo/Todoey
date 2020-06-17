//
//  TodoGenerator.swift
//  Todoey
//
//  Created by Michael Ricks-Aherne on 6/13/20.
//  Copyright © 2020 App Brewery. All rights reserved.
//

import Foundation
import UIKit

protocol ToDoGeneratorDelegate {
    func didReceiveNewTodo(_ sender: ToDoGenerator, newTodo: Item) // note that you must add a category to the ToDo item
    func didFailWithError(_ error: Error)
}

struct ToDoGenerator {
    var delegate: ToDoGeneratorDelegate?
    let url = "https://appideagenerator.com/call.php?1592073011128"    
    
    func generate() {
        performRequest(with: url)
    }
    
    private func performRequest(with urlString: String) {
        if let url = URL(string: urlString) {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: url){(data, resp, error) in
                if error != nil {
                    self.delegate?.didFailWithError(error!)
                    return
                }
                
                if let safeData = data {
                    if let decoded = self.decodeData(data: safeData) {
                        let item = Item()
                        item.title = decoded
                        item.done = false
                        self.delegate?.didReceiveNewTodo(self, newTodo: item)
                    }
                }
            }
            task.resume()
        }
    }
    
    private func decodeData(data: Foundation.Data) -> String? {
        let decoded = String(data: data, encoding: .utf8)
        let trimmed = decoded?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed
    }
}
