import SwiftUI

struct FileItem: Identifiable {
    let id = UUID()
    var url: URL
    var originalName: String
    var newName: String?
    var status: FileStatus = .pending
    var error: String?
    var isSelected: Bool = false
    var selectedExtension: String = ""
    
    /// 获取原始文件的后缀名
    var originalExtension: String {
        (originalName as NSString).pathExtension
    }
    
    /// 获取新文件名的后缀名
    var newExtension: String {
        if !selectedExtension.isEmpty {
            return selectedExtension
        }
        guard let newName = newName else { return "" }
        return (newName as NSString).pathExtension
    }
    
    init(url: URL, isSelected: Bool = true) {
        self.url = url
        self.originalName = url.lastPathComponent
        self.isSelected = isSelected
    }
}

enum FileStatus {
    case pending
    case processing
    case completed
    case error
    
    var description: String {
        switch self {
        case .pending: return "等待中"
        case .processing: return "处理中"
        case .completed: return "已完成"
        case .error: return "错误"
        }
    }
    
    var iconName: String {
        switch self {
        case .pending: return "clock"
        case .processing: return "arrow.clockwise"
        case .completed: return "checkmark.circle"
        case .error: return "exclamationmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .gray
        case .processing: return .blue
        case .completed: return .green
        case .error: return .red
        }
    }
} 