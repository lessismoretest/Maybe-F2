import Foundation
import AppKit

class AIService {
    let settingsManager: SettingsManager
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }
    
    func generateFileName(for file: FileItem) async throws -> String {
        let model = settingsManager.settings.aiModel
        guard let apiKey = settingsManager.settings.apiKeys[model], !apiKey.isEmpty else {
            throw AIError.noAPIKey
        }
        
        let fileType = FileExtensions.category(for: file.url.pathExtension)
        guard let prompt = settingsManager.settings.promptTemplates[fileType] else {
            throw AIError.noPromptTemplate
        }
        
        let urlString = "\(model.apiEndpoint)?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw AIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 准备请求体
        var parts: [[String: Any]] = []
        
        // 添加提示词
        parts.append(["text": prompt])
        
        // 如果是图片，添加图片数据
        if fileType == .image {
            if let imageData = try? await loadImageData(from: file.url) {
                let base64Image = imageData.base64EncodedString()
                parts.append([
                    "inline_data": [
                        "mime_type": "image/jpeg",
                        "data": base64Image
                    ]
                ])
            }
        }
        
        // 添加原文件名
        parts.append([
            "text": """
            原文件名：\(file.originalName)
            请根据图片内容生成一个标题，不要包含特殊字符。
            """
        ])
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": parts
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw AIError.httpError(statusCode: httpResponse.statusCode)
            }
            
            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
            
            guard let suggestion = geminiResponse.candidates.first?.content.parts.first?.text else {
                throw AIError.noSuggestion
            }
            
            return cleanFileName(suggestion.trimmingCharacters(in: .whitespacesAndNewlines))
        } catch {
            throw AIError.networkError(error)
        }
    }
    
    private func loadImageData(from url: URL) async throws -> Data {
        guard let image = NSImage(contentsOf: url) else {
            throw AIError.invalidFileContent
        }
        
        // 将图片转换为 JPEG 数据
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw AIError.invalidFileContent
        }
        
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let imageData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) else {
            throw AIError.invalidFileContent
        }
        
        // 检查图片大小是否超过限制（例如 4MB）
        if imageData.count > 4 * 1024 * 1024 {
            // 需要压缩图片
            guard let compressedData = compressImage(imageData) else {
                throw AIError.invalidFileContent
            }
            return compressedData
        }
        
        return imageData
    }
    
    private func compressImage(_ imageData: Data) -> Data? {
        var compression: CGFloat = 0.8
        var compressedData = imageData
        
        while compressedData.count > 4 * 1024 * 1024 && compression > 0.1 {
            compression -= 0.1
            if let image = NSImage(data: imageData),
               let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
                if let data = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: compression]) {
                    compressedData = data
                }
            }
        }
        
        return compressedData
    }
    
    private func cleanFileName(_ name: String) -> String {
        let illegalCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return name.components(separatedBy: illegalCharacters).joined()
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}

enum AIError: LocalizedError {
    case noAPIKey
    case noPromptTemplate
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case noSuggestion
    case networkError(Error)
    case invalidFileContent
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "请在设置中输入 API Key"
        case .noPromptTemplate:
            return "未找到对应的提示词模板"
        case .invalidURL:
            return "无效的 API URL"
        case .invalidResponse:
            return "无效的服务器响应"
        case .httpError(let statusCode):
            return "HTTP 错误: \(statusCode)"
        case .noSuggestion:
            return "AI 未返回有效的文件名建议"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .invalidFileContent:
            return "无法读取文件内容"
        }
    }
}

// Gemini API 响应模型
struct GeminiResponse: Codable {
    let candidates: [Candidate]
}

struct Candidate: Codable {
    let content: Content
}

struct Content: Codable {
    let parts: [Part]
}

struct Part: Codable {
    let text: String
} 