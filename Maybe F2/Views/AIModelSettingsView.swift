import SwiftUI

/**
 * AI 模型设置视图
 */
struct AIModelSettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @State private var tempSettings: Settings
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        _tempSettings = State(initialValue: settingsManager.settings)
    }
    
    var body: some View {
        Form {
            Section {
                // AI 模型选择
                Picker("使用模型", selection: $tempSettings.aiModel) {
                    ForEach(AIModel.allCases, id: \.self) { model in
                        Text(model.fullName).tag(model)
                    }
                }
                .onChange(of: tempSettings.aiModel) { _ in
                    updateSettings()
                }
                
                // API Key 配置
                SecureField("API Key", text: Binding(
                    get: { tempSettings.apiKeys[tempSettings.aiModel] ?? "" },
                    set: { 
                        tempSettings.apiKeys[tempSettings.aiModel] = $0
                        updateSettings()
                    }
                ))
            } header: {
                Label("AI 模型", systemImage: "cpu")
            } footer: {
                Text("请设置相应模型的 API Key")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }
    
    private func updateSettings() {
        Task { @MainActor in
            settingsManager.updateSettings(tempSettings)
        }
    }
} 