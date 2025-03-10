//
//  DocumentPickerWrapper.swift
//  BasicList
//
//  Created by Stephen Choate on 2/28/25.
//

import Foundation
import SwiftData
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct DocumentPickerWrapper: UIViewControllerRepresentable {
    var task: TaskItem
    var modelContext: ModelContext
    var updateCount: Binding<Int>?

    func makeCoordinator() -> Coordinator {
        if let updateCount = updateCount{
            return Coordinator(task: task, modelContext: modelContext, updateCounter: updateCount)
        }else{
            return Coordinator(task: task, modelContext: modelContext)
        }
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [
            UTType.pdf, UTType.text, UTType.image
        ])
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // No update.
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var task: TaskItem
        var modelContext: ModelContext
        var internalUpdateCounter: Binding<Int>?

        init(task: TaskItem, modelContext: ModelContext, updateCounter: Binding<Int>? = nil) {
            self.task = task
            self.modelContext = modelContext
            self.internalUpdateCounter = updateCounter
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            for url in urls {
                if let movedDocumentURL = moveFileToDocumentStore(url: url) {
                    let newDocument = TaskDocument(url: movedDocumentURL.absoluteString)
                    self.task.documentURLs.append(newDocument)
                }
            }
            try? self.modelContext.save()
            controller.dismiss(animated: true)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("Document picker cancelled.")
        }
        
        func moveFileToDocumentStore(url: URL) -> URL?{
            let fileManager = FileManager.default
            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            
            let destinationURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)

            
            do{
                if fileManager.fileExists(atPath: destinationURL.path){
                    internalUpdateCounter?.wrappedValue += 1
                    return destinationURL
                }else{
                    try fileManager.copyItem(at: url, to: destinationURL)
                    internalUpdateCounter?.wrappedValue += 1
                    return destinationURL
                }
              }catch{
                    return nil
            }
        }
    }
}

struct DeleteDocumentButton: View {
    var url: URL
    
    var body: some View {
        Button(action: {}) {
            Image(systemName: "document.circle.fill")
            Text(url.lastPathComponent)
                .foregroundStyle(.blue)
        }.padding(6)
    }
}
