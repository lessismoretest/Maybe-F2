import SwiftUI

class SettingsManager: ObservableObject {
    @Published var settings: Settings {
        didSet {
            save()
            applySettings()
        }
    }
    @Published var selectedSection: SettingsSection = .aiModel
    
    private let settingsKey = "AppSettings"
    
    init() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let settings = try? JSONDecoder().decode(Settings.self, from: data) {
            self.settings = settings
        } else {
            self.settings = Settings()
        }
        applySettings()
    }
    
    func updateSettings(_ newSettings: Settings) {
        settings = newSettings
    }
    
    private func applySettings() {
        // 应用主题设置
        UserDefaults.standard.set(settings.appearanceMode.rawValue, forKey: "appearanceMode")
        
        // 应用开机启动设置
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            let launchServicesPlistPath = "Library/LaunchAgents/\(bundleIdentifier).plist"
            let plistURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(launchServicesPlistPath)
            
            if settings.launchAtLogin {
                // 创建启动项
                if let bundleURL = Bundle.main.bundleURL.absoluteURL as NSURL? {
                    let plistDictionary: [String: Any] = [
                        "Label": bundleIdentifier,
                        "ProgramArguments": [bundleURL.path!],
                        "RunAtLoad": true
                    ]
                    try? (plistDictionary as NSDictionary).write(to: plistURL)
                }
            } else {
                // 删除启动项
                try? FileManager.default.removeItem(at: plistURL)
            }
        }
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }
} 