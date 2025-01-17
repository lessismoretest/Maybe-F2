import Foundation

struct Settings: Codable {
    // 外观设置
    var appearanceMode: AppearanceMode
    var launchAtLogin: Bool
    
    // AI 模型设置
    var aiModel: AIModel
    var apiKeys: [AIModel: String]
    var temperature: Double
    
    // 转换设置
    var conversionModels: [FileCategory: AIModel]
    var promptTemplates: [FileCategory: String]
    var formatConversions: [FormatConversion]
    
    // 重命名规则
    var renameRules: [RenameRule]
    
    init() {
        self.appearanceMode = .system
        self.launchAtLogin = false
        self.aiModel = .gemini_pro
        self.apiKeys = [:]
        self.conversionModels = [:]
        self.promptTemplates = [:]
        self.temperature = 0.7
        self.renameRules = []
        
        // 设置默认的提示词模板
        self.promptTemplates = [
            .image: "这是一张图片，请为其生成一个简短且具描述性的文件名，不要包含特殊字符",
            .text: "这是一个文本文件，请根据其内容生成一个简短且具描述性的文件名，不要包含特殊字符"
        ]
        
        // 生成所有可能的格式转换组合
        self.formatConversions = FormatConversion.generateAllPossibleConversions()
    }
    
    static var `default`: Settings {
        var settings = Settings()
        // 设置默认的转换模型
        for category in FileCategory.allCases {
            settings.conversionModels[category] = .gemini_pro
        }
        return settings
    }
} 