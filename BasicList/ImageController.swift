//
//  ImageController.swift
//  BasicList
//
//  Created by Stephen Choate on 3/2/25.
//

import Foundation
import PhotosUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct DeleteImageButton: View {

    var body: some View {
        Button(action: {
        }) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
                .background(Color.white.opacity(0.7))
                .clipShape(Circle())
        }
    }
}

struct FullScreenImageView: View {
    let image: UIImage
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack {
                Text("Image View")
                Spacer()
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Spacer()
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
}

func processSelectedImages(task: TaskItem, newPhotos: [PhotosPickerItem]) async {
    for photo in newPhotos {
        if let data = try? await photo.loadTransferable(type: Data.self) {
            let newImage = TaskImage(photoData: data)
            task.imageData.append(newImage)
        }
    }
}

func deleteImage(taskItem: TaskItem, imageToRemove img: TaskImage){
    if let i = taskItem.imageData.firstIndex(where: { $0.id == img.id }) {
        taskItem.imageData.remove(at: i)
    }
}
