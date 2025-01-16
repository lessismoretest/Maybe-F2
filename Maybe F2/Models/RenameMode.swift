import Foundation

/// 重命名模式
enum RenameMode: String, CaseIterable {
    /// 生成新文件
    case createNew = "生成新文件"
    /// 替换原文件
    case replace = "替换原文件"
    
    var description: String {
        rawValue
    }
    
    var icon: String {
        switch self {
        case .createNew: return "doc.badge.plus"
        case .replace: return "arrow.triangle.2.circlepath"
        }
    }
} 