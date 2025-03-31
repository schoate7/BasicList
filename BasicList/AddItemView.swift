//
//  AddItemView.swift
//  BasicList
//
//  Created by Stephen Choate on 2/23/25.
//

import Foundation
import PhotosUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct AddItemView: View {
    let orderIndex: Int
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Binding var taskList: [TaskItem]
    
    //TaskItem properties
    @State private var newTaskItem: TaskItem
    @State private var title: String = ""
    @State private var details: String = ""
    @State private var completedStatus: Bool = false
    @State private var priorityRating: TaskPriority = TaskPriority.normal
    @State private var dueDate: Date = Date()

    //Local variables
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var showDatePicker: Bool = false
    @State private var isDocumentPickerPresented: Bool = false
    
    init(index: Int, taskList: Binding<[TaskItem]>){
        self.orderIndex = index
        self.newTaskItem = TaskItem(createdDate: Date(), taskTitle: "", taskDetails: "", orderIndex: -1, taskPriority: .normal)
        self._taskList = taskList
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = .current
        return formatter
    }
    
    private var timeStamp = Date()
    
    var dueDateButtonLabel: String {
        showDatePicker ? "Remove Due Date" : "Set Due Date"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Title")) {
                    TextField("Enter title", text: $title)
                }
                
                Section(header: Text("Details")) {
                    TextEditor(text: $details)
                        .frame(minHeight: 150)
                        .cornerRadius(8)
                }
                
                Section(header: Text("Completed")) {
                    Picker("Completed", selection: $completedStatus) {
                        Text("Not Completed").tag(false)
                        Text("Completed").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $priorityRating) {
                        Text("Low").tag(TaskPriority.low)
                        Text("Normal").tag(TaskPriority.normal)
                        Text("High").tag(TaskPriority.high)
                    }
                }
                
                Section(header: Text("Due Date")) {
                    Button(dueDateButtonLabel, action: {
                        withAnimation {
                            showDatePicker.toggle()
                        }
                    })
                    if showDatePicker {
                        DatePicker("Date", selection: $dueDate, displayedComponents: [.date])
                    }
                }
                Section(header: Text("Add Attachments")) {
                    PhotosPicker("Select Image", selection: $selectedImages, matching: .images)
                        .onChange(of: selectedImages) { newPhotos, oldPhotos in
                            Task {
                                await processSelectedImages(task: newTaskItem, newPhotos: selectedImages)
                                try? modelContext.save()
                            }
                        }
                    Button("Select Document") {
                        withAnimation { selectDocument() }
                    }
                }
                
                if !newTaskItem.imageData.isEmpty{
                    Section(header: Text("Selected Images")){
                        HStack(){
                            ForEach(newTaskItem.imageData, id: \.id) {img in
                                if let image = UIImage(data: img.photoData){
                                    ZStack(alignment: .topTrailing){
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 100)
                                            .cornerRadius(8)
                                        DeleteImageButton().onTapGesture(perform:{ deleteImage(taskItem: newTaskItem, imageToRemove:img)
                                        })
                                    }
                                }
                            }
                        }
                    }
                }
                
                if !newTaskItem.documentURLs.isEmpty{
                    Section(header: Text("Selected Documents")){
                        VStack(alignment: .leading){
                            ForEach(newTaskItem.documentURLs, id: \.url){ document in
                                if let url = URL(string: document.url){
                                    DeleteDocumentButton(url: url).onTapGesture(perform:
                                        {
                                        deleteDocument(task: newTaskItem, documentToRemove: url)
                                    })
                                }
                            }
                        }
                    }
                }
                
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTaskItem()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $isDocumentPickerPresented) {
                DocumentPickerWrapper(task: newTaskItem, modelContext: modelContext)
            }
        }
    }
            
    private func saveTaskItem() {
        let maxOrder = taskList.map(\.orderIndex).max() ?? 0
        newTaskItem.taskTitle = title
        newTaskItem.taskDetails = details
        newTaskItem.orderIndex = maxOrder + 1
        newTaskItem.priorityRating = priorityRating
        newTaskItem.dueDate = (showDatePicker ? dueDate : nil)
        
        modelContext.insert(newTaskItem)
    }
    
    private func selectDocument() {
        isDocumentPickerPresented = true
    }
}

/*
 #Preview {
 AddItemView(index: 0)
 }
 */
