//
//  TaskPhoto.swift
//  BasicList
//
//  Created by Stephen Choate on 3/2/25.
//

import Foundation
import PhotosUI
import SwiftData


@Model
class TaskImage{
    var id: UUID = UUID()
    var photoData: Data
    var task: TaskItem?
    
    init(photoData: Data) {
        self.photoData = photoData
    }
}
