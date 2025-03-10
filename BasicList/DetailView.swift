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
    
    @State private var isEditing = false
    @State private var selectedImage: UIImage? = nil
    @State private var refreshTrigger: Bool = false
    @State var imageShowingFullScreen: Bool = false
    
    var task: TaskItem
    var completeStatus: Bool
    
    init (task: TaskItem){
        self.task = task
        self.completeStatus = task.isComplete
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(task.taskTitle)
                .font(.largeTitle)
                .bold()
            
            if !task.taskDetails.isEmpty {
                Text(task.taskDetails)
                    .font(.body.italic())
            }

            HStack {
                Text("Priority: ")
                    .font(.headline)
                Image(systemName: task.priorityIcon)
                    .foregroundColor(task.priorityColor)
                Text(task.priorityRating.description)
            }

            if let dueDate = task.dueDate {
                HStack{
                    Text("Due:").bold()
                    Text("\(dueDate, format: .dateTime.month().day().year())")
                        .foregroundColor(dueDate < Date() ? .red : .black)
                }
            }
            HStack{
                Text("Status:").bold()
                if completeStatus == true{
                    Text("Completed").foregroundStyle(.green)
                }else{
                    Text("Not Completed").foregroundStyle(.red)
                }
            }
            if !task.imageData.isEmpty && !task.documentURLs.isEmpty{
                
                
                Section(header: Text("Attachments:").font(.headline)) {
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
            
            let createdDate = task.createdDate
            Text("Created On: ").bold() + Text(createdDate.formatted(date: Date.FormatStyle.DateStyle.abbreviated, time: Date.FormatStyle.TimeStyle.shortened))
            
            let lastModifiedDate = task.modifiedDate
            Text("Last Modified: ").bold() + Text(lastModifiedDate.formatted(date: Date.FormatStyle.DateStyle.abbreviated, time: Date.FormatStyle.TimeStyle.shortened))

            Spacer()

            Button("Edit Task") {
                isEditing = true
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .sheet(isPresented: $isEditing) {
            EditItemView(task: task)
        }
    }
    
    private func openDocument(_ url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        refreshTrigger.toggle()
    }
}
