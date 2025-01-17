import SwiftUI

/**
 * 外观模式枚举
 */
enum AppearanceMode: String, CaseIterable, Identifiable, Codable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .light: return "浅色"
        case .dark: return "深色"
        case .system: return "跟随系统"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
} 