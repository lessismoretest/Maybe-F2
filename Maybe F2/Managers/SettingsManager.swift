import SwiftUI

class SettingsManager: ObservableObject {
    @Published var settings: Settings {
        didSet {
            save()
        }
    }
    @Published var selectedSection: SettingsSection = .ai
    
    private let settingsKey = "AppSettings"
    
    init() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let settings = try? JSONDecoder().decode(Settings.self, from: data) {
            self.settings = settings
        } else {
            self.settings = Settings()
        }
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }
} 