//
//  DocumentPickerDelegate.swift
//  BasicList
//
//  Created by Stephen Choate on 2/28/25.
//

import SwiftData
import UniformTypeIdentifiers
import SwiftUI

class DocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
    var task: TaskItem
    var modelContext: ModelContext

    init(task: TaskItem, modelContext: ModelContext) {
        self.task = task
        self.modelContext = modelContext
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            let newDocument = TaskDocument(url: url.absoluteString)
            self.task.documentURLs.append(newDocument)
        }
        try? self.modelContext.save()
    }
}
