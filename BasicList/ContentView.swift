//
//  ContentView.swift
//  BasicList
//
//  Created by Stephen Choate on 2/23/25.
//
//    TODO:
//    Search Bar: Let users filter tasks by keyword.
//    Hashtags

import SwiftUI
import SwiftData
import Foundation

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.undoManager) private var undoManager
    
    @Query private var tasks: [TaskItem]
    @State private var taskList: [TaskItem] = []
    @State private var selectedItem: TaskItem?
    @State private var editingTaskID: UUID?
    @State private var sortOption: SortOption = .byIndex
    @State private var groupOption: GroupOption = .none
    
    @State private var isHamburgerActive: Bool = false
    @State private var editMode: EditMode = .inactive
    @State private var showingAddItem = false
    @State private var showCompleted: Bool = false
    @State private var showingDetailView: Bool = false
    @State private var isSortingDisabled: Bool = false
    
    private var isEditingDisabled: Bool{
        sortOption != .byIndex || groupOption != .none
    }
    
    private var showCompletedLabel: String{
        showCompleted ? "Hide Completed" : "Show Completed"
    }
    
    private var sortedTaskList: [TaskItem] {
        sortTasks()
    }
    
    private var groupedTasks: [(key: String, value: [TaskItem])]{
        let filtered = sortedTaskList.filter { showCompleted || !$0.isComplete }
        
        switch groupOption {
        case .none:
            return [("All Tasks", filtered)]
        case .priority:
            let groups = Dictionary(grouping: filtered) { task in
                switch task.priorityRating {
                case .high: return "High"
                case .normal: return "Normal"
                case .low: return "Low"
                }
            }
            let desiredOrder = ["High", "Normal", "Low"]
            return groups.sorted { lhs, rhs in
                desiredOrder.firstIndex(of: lhs.key)! < desiredOrder.firstIndex(of: rhs.key)!
            }
        case .completion:
            let groups = Dictionary(grouping: filtered) { $0.isComplete ? "Completed" : "Incomplete" }
            let desiredOrder = ["Incomplete", "Completed"]
            return groups.sorted { lhs, rhs in
                desiredOrder.firstIndex(of: lhs.key)! < desiredOrder.firstIndex(of: rhs.key)!
            }
        case .pastDue:
            let now = Date()
            let groups = Dictionary(grouping: filtered) {
                if $0.isComplete { return "Completed" }
                else if let due = $0.dueDate, due < now { return "Past Due" }
                else if let upcoming = $0.dueDate, upcoming > now {return "Upcoming"}
                else { return "Unscheduled" }
            }
            let desiredOrder = ["Past Due", "Upcoming", "Unscheduled", "Completed"]
            return groups.sorted { lhs, rhs in
                desiredOrder.firstIndex(of: lhs.key)! < desiredOrder.firstIndex(of: rhs.key)!
            }
        }
    }
     

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(groupedTasks, id: \.key) { group in
                    Section(header: HStack{
                        Image(systemName: groupHeaderIcon(for: group.key))
                        Text(group.key)
                    }){
                        ForEach(group.value){item in
                            NavigationLink(destination: TaskDetailView(taskList: $taskList, task: item, showingDetailView: $showingDetailView)) {
                                HStack{
                                    Image(systemName: item.priorityIcon).foregroundStyle(item.priorityColor)
                                    if let dueDate = item.dueDate{
                                        VStack{
                                            HStack{
                                                Text(item.taskTitle)
                                                    .bold()
                                                Spacer()
                                            }
                                            HStack{
                                                Text("Due:")
                                                    .foregroundStyle(dueDate < Date() && !item.isComplete ? .red : .secondary)
                                                Text(dueDate, format: .dateTime.month().day().year())
                                                    .foregroundStyle(dueDate < Date() && !item.isComplete ? .red : .secondary)
                                                Spacer()
                                            }
                                        }
                                    }else{
                                        Text(item.taskTitle)
                                            .bold()
                                        Spacer()
                                    }
                                    HStack{
                                        if !item.taskDetails.isEmpty {
                                            Image(systemName: "text.quote").foregroundStyle(.gray)
                                                .padding(.trailing, 5)
                                        }
                                        if !item.documentURLs.isEmpty || !item.imageData.isEmpty {
                                            Image(systemName: "paperclip").foregroundStyle(.gray)
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
                                    .cornerRadius(8)
                                }
                            }
                            
                            .frame(height: 45)
                            .onTapGesture{
                                selectedItem = item
                                showingDetailView = true
                            }
                            .onAppear{
                                taskList = tasks
                            }
                        }
                    }
                }
                .onMove(perform: sortOption == .byIndex ? moveTask: nil)
                .onDelete(perform: deleteTask)
            }
            .navigationTitle("My Tasks")
            .environment(\.editMode, $editMode)
            .toolbar{
                ToolbarItemGroup(placement: .topBarLeading){
                    Menu{
                        Button(action: {}){
                            Text("Current: \(groupOption.rawValue)")
                                .bold()
                        }
                        .disabled(true)
                        Divider()
                        
                        ForEach(GroupOption.allCases, id: \.self){ option in
                            Button(action:{
                                groupOption = option
                                sortForGroupTasks()
                            }){
                                HStack{
                                    Image(systemName: groupImageName(for: option))
                                    Text(option.rawValue)
                                }
                            }
                        }
                    } label: {
                        VStack{
                            Image(systemName: "square.grid.3x3.fill")
                                .font(.system(size:20))
                            Text("Group")
                                .font(.caption)
                        }
                    }
                }
                
                ToolbarItemGroup(placement: .topBarTrailing){
                    Menu {
                        Button(action: {}) {
                            Text("Current: \(sortOption.rawValue)")
                        }
                        .id("currentButton")
                        .disabled(true)
                        Divider()
                        
                        ControlGroup {
                            
                            Button(action: {
                                sortOption = .byIndex
                            }){
                                VStack{
                                    Image(systemName: sortImageName(for: .byIndex))
                                    Text("My Order")
                                }
                                .padding(.vertical, 10)
                            }
                            .id("menuOrderButton")
                            
                            Button(action: {
                                sortOption = .dueSoonest
                            }){
                                VStack{
                                    Image(systemName: sortImageName(for: .dueSoonest))
                                    Text("Due Date")
                                }
                                .padding(.vertical, 10)
                            }
                            
                            Button(action: {
                                sortOption = .priorityHighest
                            }){
                                VStack(spacing: 4){
                                    Image(systemName: sortImageName(for: .priorityHighest))
                                    Text("Priority")
                                }
                                .padding(.vertical, 10)
                            }
                        }
                        
                        
                        ForEach(SortOption.allCases, id: \.self) { option in
                            if(option != .byIndex && option != .dueSoonest && option != .priorityHighest){
                                Button(action: {
                                    sortOption = option
                                }) {
                                    HStack {
                                        Image(systemName: sortImageName(for: option))
                                        Text(option.rawValue)
                                    }
                                }
                            }
                        }
                    }
                    label: {
                        VStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 20))
                            Text("Sort")
                                .font(.caption)
                        }
                    }
                    .disabled(isSortingDisabled)
                }
            }
            .toolbar{
                ToolbarItemGroup(placement: .bottomBar){
                    
                    Button(action: {
                        undoManager?.undo()
                    })
                    {
                        VStack{
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 20))
                            Text("Undo")
                                .font(.caption)
                        }
                    }
                    .disabled(!(undoManager?.canUndo ?? false))
                    Spacer()
                    
                    Button(action: {
                        showCompleted.toggle()
                    }){
                        VStack{
                            Image(systemName: showCompleted ?  "checklist.unchecked" : "checklist")
                                .font(.system(size: 20))
                            Text(showCompletedLabel)
                                .font(.caption)
                        }
                    }
                    Spacer()
                    
                    Button(action: {
                        editMode = (editMode == .active) ? .inactive : .active
                    }) {
                        VStack{
                            Image(systemName: editMode == .active ? "checkmark" : "square.and.pencil")
                                .font(.system(size: 20))
                            Text("Edit List")
                                .font(.caption)
                        }
                    }
                    .disabled(isEditingDisabled)
                    Spacer()
                    
                    Button(action: {
                        showingAddItem = true
                    }){
                        VStack{
                            Image(systemName: "plus")
                                .font(.system(size: 20))
                            Text("Add Task")
                                .font(.caption)
                        }
                    }
                }
            }
        } detail: {
            if let selectedItem = selectedItem {
                Text("Item at \(selectedItem.createdDate, format: Date.FormatStyle(date: .numeric, time: .standard))")
            } else {
                Text("Select an item")
            }
        }
        .sheet(isPresented: $showingAddItem){
            AddItemView(index: tasks.count, taskList: $taskList)
        }
    }

    
    private func toggleTaskCompletion(_ task: TaskItem) {
        withAnimation {
            let previousState = task.isComplete
            task.isComplete.toggle()
            try? modelContext.save()

            undoManager?.registerUndo(withTarget: task) { t in
                t.isComplete = previousState
                try? modelContext.save()
            }
            undoManager?.setActionName("Toggle Completion")
        }
    }
    
    private func sortForGroupTasks() {
        switch (groupOption){
        case(.pastDue):
            sortOption = .dueSoonest
            isSortingDisabled = true
        case(.priority):
            sortOption = .dueSoonest
            isSortingDisabled = true
        case(.completion):
            sortOption = .dueSoonest
            isSortingDisabled = true
        default:
            sortOption = .byIndex
            isSortingDisabled = false
        }
    }
    
    private func sortTasks() -> [TaskItem]{
        switch (sortOption){
        case(.byIndex):
            return tasks.sorted { $0.orderIndex < $1.orderIndex }
        case(.dueSoonest):
            return tasks.sorted { $0.dueDate ?? Date.distantFuture < $1.dueDate ?? Date.distantFuture }
        case(.titleAscending):
            return tasks.sorted { $0.taskTitle < $1.taskTitle }
        case(.priorityHighest):
            return tasks.sorted { $0.priorityRank > $1.priorityRank }
        case(.createdAscending):
            return tasks.sorted { $0.createdDate < $1.createdDate }
        case(.updatedAscending):
            return tasks.sorted { $0.modifiedDate < $1.modifiedDate }
        }
    }
    
    enum SortOption: String, CaseIterable {
        case byIndex = "My Order"
        case dueSoonest = "Due Soonest"
        case priorityHighest = "Highest Priority"
        case createdAscending = "Created (Oldest)"
        //case createdDescending = "Created (Newest)"
        case updatedAscending = "Updated (Oldest)"
        //case updatedDescending = "Updated (Most Recent)"
        case titleAscending = "Title (A-Z)"
        //case titleDescending = "Title (Z-A)"
    }
    
    enum GroupOption: String, CaseIterable {
        case none = "All Tasks"
        case pastDue = "Due Date"
        case priority = "Priority"
        case completion = "Status"
    }
    
    private func sortImageName(for option: SortOption) -> String {
        switch option {
        case .byIndex: return "line.horizontal.3"
        case .dueSoonest: return "calendar.badge.clock"
        case .priorityHighest: return "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90"
        case .createdAscending: return "clock.arrow.trianglehead.counterclockwise.rotate.90"
        case .updatedAscending: return "arrow.uturn.left.circle"
        case .titleAscending: return "textformat.abc"
        }
    }
    
    private func groupImageName(for option: GroupOption) -> String{
        switch option {
        case .none: return "list.bullet"
        case .priority : return "exclamationmark.circle"
        case .completion : return "checkmark.circle"
        case .pastDue : return "clock"
        }
    }
    
    private func groupHeaderIcon(for key: String) -> String {
        switch key {
        case "High": return "arrow.up.square.fill"
        case "Medium", "Normal": return "minus.square.fill"
        case "Low": return "arrow.down.square.fill"
        case "Completed": return "checkmark.square.fill"
        case "Incomplete": return "square"
        case "Past Due": return "calendar.badge.exclamationmark"
        case "Upcoming": return "calendar.badge.clock"
        case "Unscheduled": return "calendar"
        default: return "list.bullet.rectangle.fill"
        }
    }
    
    private func bindingForTask(_ task: TaskItem) -> Binding<String> {
        return Binding(
            get: { task.taskTitle },
            set: { newValue in
                let oldValue = task.taskTitle
                task.taskTitle = newValue
                try? modelContext.save()

                undoManager?.registerUndo(withTarget: task) { t in
                    t.taskTitle = oldValue
                    try? modelContext.save()
                }
                undoManager?.setActionName("Rename Task")
            }
        )
    }

    private func deleteTask(offsets: IndexSet) {
        withAnimation {
            let sortedTasks = tasks.sorted { $0.orderIndex < $1.orderIndex }
            let deletedTasks = offsets.map { sortedTasks[$0] }

            for task in deletedTasks {
                modelContext.delete(task)
            }
            try? modelContext.save()

            undoManager?.registerUndo(withTarget: modelContext) { context in
                for task in deletedTasks {
                    context.insert(task)
                }
                try? context.save()
            }
            undoManager?.setActionName("Delete Task")
        }
    }
    
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
