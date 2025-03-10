//
//  TaskDocument.swift
//  BasicList
//
//  Created by Stephen Choate on 3/2/25.
//

import Foundation
import SwiftData

@Model
class TaskDocument {
    var id: UUID = UUID()
    var url: String
    var task: TaskItem?

    init(url: String) {
        self.url = url
    }
}

func deleteDocument(task: TaskItem, documentToRemove dtr: URL){
    if let i = task.documentURLs.firstIndex(where: {$0.url == dtr.absoluteString}){
        task.documentURLs.remove(at: i)
    }
}
