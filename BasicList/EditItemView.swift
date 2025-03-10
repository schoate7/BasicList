//
//  EditTaskView.swift
//  BasicList
//
//  Created by Stephen Choate on 2/25/25.
//

import Foundation
import PhotosUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct EditItemView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    //TaskItem properties
    @State private var taskTitle: String
    @State private var taskDetails: String
    @State private var dueDate: Date?
    @State private var taskPriority: TaskPriority
    @State private var isComplete: Bool
    
    //Local variables
    @State private var taskItem: TaskItem
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var isDocumentPickerPresented: Bool = false
    @State private var selectedDocumentCount: Int = 0
    @State private var refreshTrigger: Bool = false
    @State var changedAttributeCount = 0

    init(task: TaskItem) {
        _taskTitle = State(initialValue: task.taskTitle)
        _taskDetails = State(initialValue: task.taskDetails)
        _dueDate = State(initialValue: task.dueDate)
        _taskPriority = State(initialValue: task.priorityRating)
        _isComplete = State(initialValue: task.isComplete)
        self.taskItem = task
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Task Title")) {
                    TextField("Enter task title", text: $taskTitle)
                }

                Section(header: Text("Details")) {
                    TextEditor(text: $taskDetails)
                        .frame(minHeight: 100)
                }
                
                Section (header: Text("Completed")){
                    Picker("Completed", selection: $isComplete) {
                        Text("Not Completed").tag(false)
                        Text("Completed").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Priority")){
                    Picker("Priority", selection: $taskPriority){
                        Text("Low").tag(TaskPriority.low)
                        Text("Normal").tag(TaskPriority.normal)
                        Text("High").tag(TaskPriority.high)
                    }
                }

                Section(header: Text("Due Date")) {
                    DatePicker(
                        dueDate == nil ? "Set Due Date" : "Due Date",
                        selection: Binding(
                            get: { dueDate ?? Date() },
                            set: { newValue in dueDate = newValue }
                        ),
                        displayedComponents: [.date]
                    )
                    if dueDate != nil {
                        Button("Clear Due Date") {
                            withAnimation { dueDate = nil }
                        }
                        .disabled(dueDate == nil)
                    }
                }

                Section(header: Text("Add Attachments")) {
                    PhotosPicker("Select Image", selection: $selectedImages, matching: .images)
                        .onChange(of: selectedImages) { oldImages, newImages in
                            Task {
                                await processSelectedImages(task: taskItem, newPhotos: selectedImages)
                                if(newImages != oldImages){
                                    changedAttributeCount += 1
                                }
                                try? modelContext.save()
                                refreshTrigger.toggle()
                            }
                        }
                    Button("Select Document") {
                        withAnimation { selectDocument() }
                    }
                }
                
                
                    if !taskItem.imageData.isEmpty {
                        Section(header: Text("Images")) {
                        HStack() {
                            ForEach(taskItem.imageData, id: \.id) { imageData in
                                if let image = UIImage(data: imageData.photoData){
                                    ZStack(alignment: .topTrailing){
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 100)
                                            .cornerRadius(8)
                                        DeleteImageButton().onTapGesture(perform: {
                                            deleteImage(taskItem: taskItem, imageToRemove: imageData)
                                        })
                                    }
                                }
                            }
                        }
                    }
                }
                if !taskItem.documentURLs.isEmpty {
                    Section(header: Text("Documents")) {
                        VStack(alignment: .leading) {
                            ForEach(taskItem.documentURLs, id: \.url) { document in
                                if let url = URL(string: document.url){
                                    DeleteDocumentButton(url: url).onTapGesture(perform: {
                                        deleteDocument(task: taskItem, documentToRemove: url)
                                    })
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Task")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { updateTaskItem() }
                        .bold()
                }
            }
            .sheet(isPresented: $isDocumentPickerPresented) {
                DocumentPickerWrapper(task: taskItem, modelContext: modelContext, updateCount: $changedAttributeCount)
            }
        }
    }

    private func updateTaskItem() {
        
        if taskTitle != taskItem.taskTitle {
            taskItem.taskTitle = taskTitle
            changedAttributeCount += 1
        }
        if taskDetails != taskItem.taskDetails {
            taskItem.taskDetails = taskDetails
            changedAttributeCount += 1
        }
        if dueDate != taskItem.dueDate {
            taskItem.dueDate = dueDate
            changedAttributeCount += 1
        }
        if taskPriority != taskItem.priorityRating{
            taskItem.priorityRating = taskPriority
            changedAttributeCount += 1
        }
        if isComplete != taskItem.isComplete {
            taskItem.isComplete = isComplete
            changedAttributeCount += 1
        }
        
        if changedAttributeCount > 0 {
            taskItem.modifiedDate = Date()
        }

        try? modelContext.save()
        dismiss()
    }
    
    private func selectDocument() {
        isDocumentPickerPresented = true
    }
}
