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

enum FileType: String, Codable {
    case image = "图片"
    case pdf = "PDF"
    case other = "其他"
    
    static func detect(from url: URL) -> FileType {
        switch url.pathExtension.lowercased() {
        case "jpg", "jpeg", "png", "gif", "webp":
            return .image
        case "pdf":
            return .pdf
        default:
            return .other
        }
    }
} 