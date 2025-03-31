//
//  DetailView.swift
//  BasicList
//
//  Created by Stephen Choate on 2/25/25.
//

import SwiftUI

struct TaskDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Binding var showingDetailView: Bool
    @Binding var taskList: [TaskItem]
    
    @State private var selectedImage: UIImage? = nil
    @State private var refreshTrigger: Bool = false
    @State private var changeCount: Int = 0
    @State private var selectedDate: Date = Date()
    @State private var selectedPriority: TaskPriority = .normal

    @State private var isEditing = false
    @State private var imageShowingFullScreen: Bool = false
    @State private var showingDatePicker = false
    @State private var showingDateConfirmation: Bool = false
    @State private var showingCompleteConfirmation: Bool = false
    @State private var showingPriorityPicker = false
    @State private var showingDeleteConfirmation: Bool = false
    
    var task: TaskItem
    var completeStatus: Bool
    
    init (taskList: Binding<[TaskItem]>, task: TaskItem, showingDetailView: Binding<Bool>){
        self.task = task
        self.completeStatus = task.isComplete
        self._showingDetailView = showingDetailView
        self._taskList = taskList
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(task.taskTitle)
                .font(.largeTitle)
                .bold()
            
            Divider()
            HStack(){
                VStack{
                    Image(systemName: task.priorityIcon)
                        .foregroundColor(completeStatus ? .secondary : task.priorityColor)
                    Text("Priority")
                        .font(.headline)
                        Text(task.priorityRating.description)
                        .foregroundColor(completeStatus ? .secondary : .primary)
                }
                .onTapGesture {
                    showingPriorityPicker = true
                }
                
                Spacer()
                VStack{
                    if let dueDate = task.dueDate{
                        let overdue = dueDate < Date() && !completeStatus
                        Image(systemName: overdue ? "calendar.badge.exclamationmark" : completeStatus ? "calendar.badge.checkmark" : "calendar.badge.clock")
                                .foregroundStyle(overdue ? .red : completeStatus ? .secondary : .orange)
                        Text(overdue ? "Overdue" : completeStatus ? "Was Due" : "Due Date").bold()
                            Text("\(dueDate, format: .dateTime.month().day().year())")
                                .foregroundStyle(overdue ? .red : completeStatus ? .secondary : .primary)
                    }else{
                            Image(systemName: "calendar")
                                .foregroundStyle(.secondary)
                            Text("Due Date").bold()
                            Text("None")
                                .foregroundStyle(.secondary)
                    }
                }
                .onTapGesture{
                    if let currentDueDate = task.dueDate {
                        showingDateConfirmation = true
                        selectedDate = currentDueDate
                    }else{
                        showingDatePicker = true
                    }
                }
                
                Spacer()
                VStack{
                    Image(systemName: "checkmark.square.fill")
                        .foregroundStyle(completeStatus ? .green : .orange)
                    Text("Status").bold()
                    Text(completeStatus ? "Complete" : "Incomplete")
                        .foregroundStyle(.primary)
                }
                .onTapGesture {
                    showingCompleteConfirmation = true
                    changeCount += 1
                }
            }
            
            if !task.taskDetails.isEmpty {
                Divider()
                HStack{
                    Image(systemName: "text.quote")
                    Text("Details").bold()
                }
                Text(task.taskDetails).italic()
            }
            
            if !task.imageData.isEmpty && !task.documentURLs.isEmpty{
                Divider()
                Section() {
                    HStack{
                        Image(systemName: "paperclip")
                            .foregroundStyle(.primary)
                        Text("Attachments").bold()
                    }
                    if !task.imageData.isEmpty {
                        HStack() {
                            ForEach(task.imageData, id: \.id) { imageData in
                                if let image = UIImage(data: imageData.photoData){
                                    ZStack(alignment: .topTrailing){
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 100)
                                            .cornerRadius(8)
                                            .onTapGesture{
                                                selectedImage = image
                                                imageShowingFullScreen = true
                                                print("Tapped image")
                                                
                                            }
                                            .fullScreenCover(isPresented: $imageShowingFullScreen){
                                                if let selectedImage = selectedImage {
                                                    FullScreenImageView(image: selectedImage, isPresented: $imageShowingFullScreen)
                                                        .id(UUID())
                                                }
                                            }
                                    }
                                }
                            }
                        }
                    }
                    
                    if !task.documentURLs.isEmpty {
                        VStack(alignment: .leading) {
                            ForEach(task.documentURLs, id: \.url) { document in
                                if let url = URL(string: document.url) {
                                    Button {
                                        openDocument(url)
                                    } label: {
                                        Image(systemName: "document.circle.fill")
                                        Text(url.lastPathComponent)
                                            .foregroundColor(.blue)
                                    }.padding(6)
                                }
                            }
                        }
                    }
                }
            }
            
            Spacer()
            Divider()
            let createdDate = task.createdDate
            let lastModifiedDate = task.modifiedDate
            
            VStack(alignment: .leading, spacing: 0){
                Text("Created: ").bold() + Text(createdDate.formatted(date: Date.FormatStyle.DateStyle.abbreviated, time: Date.FormatStyle.TimeStyle.shortened))
                Text("Modified: ").bold() + Text(lastModifiedDate.formatted(date: Date.FormatStyle.DateStyle.abbreviated, time: Date.FormatStyle.TimeStyle.shortened))
            }
            .font(.footnote)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .sheet(isPresented: $isEditing) {
            EditItemView(task: task)
        }
        .toolbar{
            ToolbarItemGroup(placement: .bottomBar){
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    showingDeleteConfirmation = true
                }){
                    VStack{
                        Image(systemName: "trash")
                            .font(.system(size:20))
                        Text("Delete")
                            .font(.caption)
                    }
                    .foregroundStyle(.red)
                }
                Spacer()
                
                Button(action: {
                    isEditing = true
                }){
                    VStack{
                        Image(systemName: "square.and.pencil")
                            .font(.system(size:20))
                        Text("Edit")
                            .font(.caption)
                    }
                }
                
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            VStack {
                DatePicker(
                    "Pick a Date",
                    selection: $selectedDate,
                    in: Date().addingTimeInterval(86400)...,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()

                Divider()
                
                HStack{
                    Spacer()
                    Button("Cancel"){
                        showingDatePicker = false
                    }
                    .foregroundStyle(.red)
                    Spacer()
                    Button("Done") {
                        task.dueDate = selectedDate
                        changeCount += 1
                        showingDatePicker = false
                    }
                    Spacer()
                }
            }
            .presentationDetents([.medium])
        }
        
        .sheet(isPresented: $showingPriorityPicker) {
            VStack(spacing: 0) {
                Picker("Priority", selection: $selectedPriority) {
                    ForEach(TaskPriority.allCases, id: \.self) { priority in
                        Text(priority.rawValue.capitalized).tag(priority)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .frame(maxHeight: 150)

                Divider()

                HStack {
                    Button("Cancel") {
                        showingPriorityPicker = false
                    }
                    .foregroundStyle(.red)

                    Spacer()

                    Button("Done") {
                        task.priorityRating = selectedPriority
                        changeCount += 1
                        showingPriorityPicker = false
                    }
                    .disabled(selectedPriority == task.priorityRating)
                }
                .padding()
            }
            .padding(.top)
            .presentationDetents([.height(250)])
        }
        .confirmationDialog(task.isComplete ? "Change to Incomplete?" : "Change to Complete?", isPresented: $showingCompleteConfirmation, titleVisibility: .visible){
            Button("Cancel", role: .cancel){}
            
            Button("Change"){
                task.isComplete.toggle()
                refreshTrigger.toggle()
                changeCount += 1
            }
        }
        
        .confirmationDialog("Clear Due Date or Select New Due Date?", isPresented: $showingDateConfirmation, titleVisibility: .visible){
            Button("Cancel", role: .cancel){}
            
            Button("Clear Due Date"){
                task.dueDate = nil
                refreshTrigger.toggle()
                changeCount += 1
            }
            
            Button("Change Due Date"){
                showingDatePicker = true
            }
        }
        
        .confirmationDialog("Are you sure you want to delete this task?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                withAnimation{
                    deleteTask(taskList: &taskList, taskToDelete: task)
                }
                showingDetailView = false
                showingDeleteConfirmation = false
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        }
        
        .onDisappear(){
            showingDetailView = false
            if(changeCount > 0){
                task.modifiedDate = Date()
                try? modelContext.save()
            }
        }
    }
    
    private func deleteTask(taskList: inout [TaskItem], taskToDelete: TaskItem){
        if let index = taskList.firstIndex(where: { $0.id == taskToDelete.id }) {
            taskList.remove(at: index)
        }
        modelContext.delete(taskToDelete)
        try? modelContext.save()
    }

    
    private func openDocument(_ url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        refreshTrigger.toggle()
    }
}
