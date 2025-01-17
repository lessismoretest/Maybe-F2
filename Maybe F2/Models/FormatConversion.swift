import Foundation

/**
 * 样式模式枚举
 */
enum StyleMode: String, Codable, CaseIterable {
    case professional = "专业"
    case normal = "正常"
    case creative = "创意"
    
    var temperature: Double {
        switch self {
        case .professional: return 0.3
        case .normal: return 0.7
        case .creative: return 1.0
        }
    }
}

/**
 * 实现方式枚举
 */
enum ImplementationMethod: String, Codable, CaseIterable {
    case imagemagick = "ImageMagick"
    case pdfkit = "PDFKit"
    case quartz = "Quartz"
    case openaiTTS = "OpenAI TTS"
    case geminiVision = "Gemini Vision"
    case local = "本地框架"
    case ai = "AI 模型"
    
    static func availableMethods(from source: String, to target: String) -> [ImplementationMethod] {
        let sourceCategory = FileExtensions.category(for: source)
        let targetCategory = FileExtensions.category(for: target)
        
        switch (sourceCategory, targetCategory) {
        case (.image, .image):
            return [.imagemagick, .local, .ai]
        case (.office, .text):
            return [.pdfkit, .local, .ai]
        case (.text, .office):
            return [.quartz, .local, .ai]
        case (.text, .audio):
            return [.openaiTTS, .ai]
        case (.image, _), (_, .image):
            return [.geminiVision, .ai]
        default:
            return [.ai]  // 默认至少支持AI转换
        }
    }
}

/**
 * 格式转换规则
 */
struct FormatConversion: Identifiable, Codable, Equatable {
    var id: UUID
    var sourceFormat: String
    var targetFormat: String
    var model: AIModel
    var prompt: String
    var implementation: String
    var selectedMethod: ImplementationMethod
    
    var isImplemented: Bool {
        Self.isImplementedConversion(from: sourceFormat, to: targetFormat)
    }
    
    init(sourceFormat: String, targetFormat: String) {
        self.id = UUID()
        self.sourceFormat = sourceFormat
        self.targetFormat = targetFormat
        self.model = .gemini_pro
        self.prompt = "将文件从\(sourceFormat)格式转换为\(targetFormat)格式"
        self.selectedMethod = Self.defaultImplementationMethod(from: sourceFormat, to: targetFormat)
        self.implementation = selectedMethod.rawValue
    }
    
    private static func defaultImplementationMethod(from source: String, to target: String) -> ImplementationMethod {
        let methods = ImplementationMethod.availableMethods(from: source, to: target)
        return methods.first ?? .ai
    }
    
    static func generateAllPossibleConversions() -> [FormatConversion] {
        var conversions: [FormatConversion] = []
        
        // 获取所有格式（不过滤重复的扩展名）
        let allFormats = FileExtensions.categoryExtensions.values
            .flatMap { $0 }
            .filter { !$0.ext.isEmpty }
        
        print("总格式数: \(allFormats.count)")
        
        // 生成所有可能的格式组合（包括自身到自身的转换）
        for source in allFormats {
            for target in allFormats {
                print("添加转换: \(source.ext) -> \(target.ext)")
                conversions.append(FormatConversion(
                    sourceFormat: source.ext,
                    targetFormat: target.ext
                ))
            }
        }
        
        print("总转换组合数: \(conversions.count)")
        return conversions
    }
    
    private static func isReasonableConversion(from source: String, to target: String) -> Bool {
        let sourceCategory = FileExtensions.category(for: source)
        let targetCategory = FileExtensions.category(for: target)
        
        // 跳过 .all 和 .other 类别
        if sourceCategory == .all || sourceCategory == .other ||
           targetCategory == .all || targetCategory == .other {
            return false
        }
        
        // 同类型格式之间可以互转
        if sourceCategory == targetCategory {
            return true
        }
        
        // 文本、文档、图像之间可以互转
        if (sourceCategory == .text || sourceCategory == .office || sourceCategory == .image) &&
           (targetCategory == .text || targetCategory == .office || targetCategory == .image) {
            return true
        }
        
        // 文本和文档可以转换为音频（文字转语音）
        if (sourceCategory == .text || sourceCategory == .office) && targetCategory == .audio {
            return true
        }
        
        // 音频可以转换为文本（语音转文字）
        if sourceCategory == .audio && (targetCategory == .text || targetCategory == .office) {
            return true
        }
        
        // 视频可以提取音频
        if sourceCategory == .video && targetCategory == .audio {
            return true
        }
        
        // 图像可以转换为文本（OCR）
        if sourceCategory == .image && (targetCategory == .text || targetCategory == .office) {
            return true
        }
        
        return false
    }
    
    private static func isImplementedConversion(from source: String, to target: String) -> Bool {
        // 获取支持的图片格式
        let supportedImageFormats = ["jpg", "jpeg", "png", "gif", "tiff"]
        
        // 只有在源格式和目标格式都是支持的图片格式时才返回 true
        return supportedImageFormats.contains(source.lowercased()) && 
               supportedImageFormats.contains(target.lowercased())
    }
} 