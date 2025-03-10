//
//  ContentView.swift
//  BasicList
//
//  Created by Stephen Choate on 2/23/25.
//

import SwiftUI
import SwiftData
import Foundation

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var tasks: [TaskItem]
    @State private var selectedItem: TaskItem?
    @State private var editingTaskID: UUID?
    @State private var sortOption: SortOption = .byIndex
    
    @State private var isHamburgerActive: Bool = false
    @State private var showingAddItem = false
    @State private var showCompleted: Bool = true
    
    private var showCompletedLabel: String{
        showCompleted ? "Hide Completed" : "Show Completed"
    }
    
    private var sortedTaskList: [TaskItem] {
        sortTasks()
    }

    var body: some View {
        NavigationSplitView {
            HStack{
                Button(showCompletedLabel){
                    showCompleted.toggle()
                }.padding(10)
                Spacer()
                Picker("Sort By", selection: $sortOption){
                    ForEach(SortOption.allCases, id: \.self){
                        option in Text(option.rawValue).tag(option)
                    }
                }
            }
            List {
                ForEach(sortedTaskList.filter({showCompleted || !$0.isComplete})) { item in
                    NavigationLink(destination: TaskDetailView(task: item)) {
                        HStack{
                            Image(systemName: item.priorityIcon).foregroundStyle(item.priorityColor)
                            if item.dueDate == nil {
                                Text(item.taskTitle)
                                    .bold()
                            }
                            VStack {
                                if item.dueDate != nil {
                                    HStack{
                                        Text(item.taskTitle)
                                            .bold()
                                        Spacer()
                                    }
                                }
                                 
                                HStack{
                                    if let dueDate = item.dueDate {
                                        Text("Due:")
                                            .foregroundStyle(dueDate < Date() ? .red : .gray)
                                        Text(dueDate, format: .dateTime.month().day().year())
                                            .foregroundStyle(dueDate < Date() ? .red : .gray)
                                    }
                                    Spacer()
                                }
                            }
                            HStack{
                                if !item.taskDetails.isEmpty {
                                    Image(systemName: "text.quote").foregroundStyle(.gray)
                                        .padding(.trailing, 5)
                                }
                                Button(action: {
                                    toggleTaskCompletion(item)
                                }) {
                                    Image(systemName: item.isComplete ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(item.isComplete ? .green : .gray)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(0)
                            .background(selectedItem == item ? Color.blue.opacity(0.2) : Color.clear)
                            .cornerRadius(8)
                        }
                    }
                    .frame(height: 45)
                }
                .onMove(perform: sortOption == .byIndex ? moveTask: nil)
                .onDelete(perform: deleteTask)
                    
            }
            .navigationTitle("My Tasks")

            .toolbar {
                var activeEditing: Bool {
                    sortOption != .byIndex
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton().disabled(activeEditing)
                }
                ToolbarItem {
                    Button(action: {showingAddItem = true}) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddItem){
                AddItemView(index: tasks.count)
            }
        } detail: {
            if let selectedItem = selectedItem {
                Text("Item at \(selectedItem.createdDate, format: Date.FormatStyle(date: .numeric, time: .standard))")
            } else {
                Text("Select an item")
            }
        }
    }
    
    /*
     
     */
    private func toggleTaskCompletion(_ task: TaskItem) {
        withAnimation {
            task.isComplete.toggle()
            try? modelContext.save()
        }
    }
    
    /*
     
     */
    private func sortTasks() -> [TaskItem]{
        switch (sortOption){
        case(.byIndex):
            return tasks.sorted { $0.orderIndex < $1.orderIndex }
        case(.dueSoonest):
            return tasks.sorted { $0.dueDate ?? Date.distantFuture < $1.dueDate ?? Date.distantFuture }
        case(.titleAscending):
            return tasks.sorted { $0.taskTitle < $1.taskTitle }
        case(.titleDescending):
            return tasks.sorted { $0.taskTitle > $1.taskTitle}
        case(.priorityHighest):
            return tasks.sorted { $0.priorityRank > $1.priorityRank }
        case(.priorityLowest):
            return tasks.sorted { $0.priorityRank < $1.priorityRank }
        case(.createdAscending):
            return tasks.sorted { $0.createdDate < $1.createdDate }
        case(.createdDescending):
            return tasks.sorted { $0.createdDate > $1.createdDate }
        case(.updatedAscending):
            return tasks.sorted { $0.modifiedDate < $1.modifiedDate }
        case(.updatedDescending):
            return tasks.sorted { $0.modifiedDate > $1.modifiedDate }
        }
    }
    
    /*
     
     */
    enum SortOption: String, CaseIterable {
        case byIndex = "My Order"
        case dueSoonest = "Due Soonest"
        case priorityHighest = "Priority (Highest)"
        case priorityLowest = "Priority (Lowest)"
        case createdAscending = "Created (Oldest)"
        case createdDescending = "Created (Newest)"
        case updatedAscending = "Updated (Oldest)"
        case updatedDescending = "Updated (Most Recent)"
        case titleAscending = "Title (A-Z)"
        case titleDescending = "Title (Z-A)"
    }
    
    /*
     
     */
    private func bindingForTask(_ task: TaskItem) -> Binding<String> {
        return Binding(
            get: { task.taskTitle },
            set: { newValue in
                task.taskTitle = newValue
                try? modelContext.save()
            }
        )
    }

    /*
     
     */
    private func deleteTask(offsets: IndexSet) {
        withAnimation {
            let sortedTasks = tasks.sorted { $0.orderIndex < $1.orderIndex }
            for index in offsets {
                modelContext.delete(sortedTasks[index])
            }

            try? modelContext.save()
        }
    }
    
    /*
     moveTask - Enables drag & drop re-ordering of list, saves changed order to context
     */
    private func moveTask(from source: IndexSet, to destination: Int) {
        var mutableTasks = tasks.sorted { $0.orderIndex < $1.orderIndex }
        mutableTasks.move(fromOffsets: source, toOffset: destination)

        for (index, task) in mutableTasks.enumerated() {
            task.orderIndex = index
        }

        try? modelContext.save()
    }
}

/*
#Preview {
    ContentView()
        .modelContainer(for: TaskItem.self, inMemory: true)
}
*/
