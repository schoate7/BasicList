//
//  TaskItem.swift
//  BasicList
//
//  Created by Stephen Choate on 2/23/25.
//

import Foundation
import SwiftData
import SwiftUICore

@Model
final class TaskItem {
    var id: UUID = UUID()
    var taskTitle: String = ""
    var taskDetails: String = ""
    var dueDate: Date?
    var createdDate: Date
    var modifiedDate: Date
    var isComplete: Bool = false
    var orderIndex: Int
    var priorityRating: TaskPriority
    var priorityIcon: String { priorityRating.icon }
    var priorityColor: Color { priorityRating.color}
    var priorityRank: Int { priorityRating.rank }
    var documentURLs: [TaskDocument] = []
    var imageData: [TaskImage] = []
    
    
    init(createdDate: Date, taskTitle: String, taskDetails: String, orderIndex: Int, taskPriority: TaskPriority, dueDate: Date? = nil) {
        self.createdDate = createdDate
        self.modifiedDate = createdDate
        self.taskTitle = taskTitle
        self.taskDetails = taskDetails
        self.orderIndex = orderIndex
        self.priorityRating = taskPriority
        self.dueDate = dueDate
    }
}

enum TaskPriority: String, Codable, CaseIterable{
    case low = "Low"
    case normal = "Normal"
    case high = "High"
    
    var rank: Int{
        switch self{
        case .low: return 0
        case .normal: return 1
        case .high: return 2
        }
    }
    
    var icon: String{
        switch self {
        case .low: return "arrow.down.square.fill"
        case .normal: return "minus.square.fill"
        case .high: return "arrow.up.square.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .normal: return .orange
        case .high: return .red
        }
    }
    
    var description: String{
        switch self{
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        }
    }
}
