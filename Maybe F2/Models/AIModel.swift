import Foundation

/**
 * AI模型枚举
 */
enum AIModel: String, Codable, CaseIterable {
    case gemini_pro = "Gemini Pro"
    case gemini_pro_vision = "Gemini Pro Vision"
    case gemini_ultra = "Gemini Ultra"
    case gpt4 = "GPT-4"
    case gpt4_turbo = "GPT-4 Turbo"
    case gpt3_5_turbo = "GPT-3.5 Turbo"
    
    var fullName: String {
        switch self {
        case .gemini_pro:
            return "Gemini-1.5-pro"
        case .gemini_pro_vision:
            return "Gemini-1.5-pro-vision"
        case .gemini_ultra:
            return "Gemini-1.5-ultra"
        case .gpt4:
            return "gpt-4"
        case .gpt4_turbo:
            return "gpt-4-turbo-preview"
        case .gpt3_5_turbo:
            return "gpt-3.5-turbo"
        }
    }
    
    var apiEndpoint: String {
        switch self {
        case .gemini_pro, .gemini_pro_vision, .gemini_ultra:
            return "https://generativelanguage.googleapis.com/v1beta/models/\(fullName):generateContent"
        case .gpt4, .gpt4_turbo, .gpt3_5_turbo:
            return "https://api.openai.com/v1/chat/completions"
        }
    }
} 