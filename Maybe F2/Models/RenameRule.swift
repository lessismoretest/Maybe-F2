import Foundation

/**
 * 重命名规则
 */
struct RenameRule: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var fileType: FileCategory
    var model: AIModel
    var prompt: String
    var implementation: String
    var selectedMethod: ImplementationMethod
    
    init(
        id: UUID = UUID(),
        name: String = "",
        fileType: FileCategory = .image,
        model: AIModel = .gemini_pro,
        prompt: String = "",
        implementation: String = "",
        selectedMethod: ImplementationMethod = .ai
    ) {
        self.id = id
        self.name = name
        self.fileType = fileType
        self.model = model
        self.prompt = prompt
        self.implementation = implementation
        self.selectedMethod = selectedMethod
    }
    
    static func == (lhs: RenameRule, rhs: RenameRule) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.fileType == rhs.fileType &&
        lhs.model == rhs.model &&
        lhs.prompt == rhs.prompt &&
        lhs.implementation == rhs.implementation &&
        lhs.selectedMethod == rhs.selectedMethod
    }
} 