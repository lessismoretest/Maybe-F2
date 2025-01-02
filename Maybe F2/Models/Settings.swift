import Foundation

struct Settings: Codable {
    var aiModel: AIModel = .gemini
    var apiKey: String = ""
    var promptTemplates: [FileType: String] = [
        .image: "这是一张图片，请为其生成一个简短且具描述性的文件名，不要包含特殊字符",
        .pdf: "这是一个PDF文件，请根据其内容生成一个简短且具描述性的文件名，不要包含特殊字符"
    ]
}

enum AIModel: String, Codable, CaseIterable {
    case gemini = "Gemini"
    
    var apiEndpoint: String {
        switch self {
        case .gemini:
            return "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent"
        }
    }
}

enum FileType: String, Codable, CaseIterable {
    case all = "全部"
    case image = "图片"
    case pdf = "PDF"
    case document = "文档"
    case video = "视频"
    case audio = "音频"
    case other = "其他"
    
    static func detect(from url: URL) -> FileType {
        switch url.pathExtension.lowercased() {
        case "jpg", "jpeg", "png", "gif", "webp", "heic":
            return .image
        case "pdf":
            return .pdf
        case "doc", "docx", "txt", "rtf", "pages", "md":
            return .document
        case "mp4", "mov", "avi", "mkv":
            return .video
        case "mp3", "wav", "aac", "m4a":
            return .audio
        default:
            return .other
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "doc"
        case .image: return "photo"
        case .pdf: return "doc.text"
        case .document: return "doc.text"
        case .video: return "film"
        case .audio: return "music.note"
        case .other: return "questionmark.folder"
        }
    }
} 