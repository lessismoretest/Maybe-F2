import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    
    var body: some View {
        NavigationSplitView {
            // 左侧导航栏
            List(SettingsSection.allCases, id: \.self, selection: $settingsManager.selectedSection) { section in
                NavigationLink(value: section) {
                    Label(section.title, systemImage: section.iconName)
                }
            }
            .navigationTitle("设置")
            .frame(width: 200)
            .listStyle(.sidebar)
        } detail: {
            // 右侧内容区
            VStack {
                Group {
                    switch settingsManager.selectedSection {
                    case .ai:
                        AISettingsView(settingsManager: settingsManager)
                            .navigationTitle("AI 设置")
                    case .appearance:
                        AppearanceSettingsView(appearanceMode: $appearanceMode)
                            .navigationTitle("外观设置")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                
                // 底部按钮
                HStack {
                    Spacer()
                    Button("完成") {
                        dismiss()
                    }
                    .keyboardShortcut(.return)
                }
                .padding()
            }
        }
        .frame(width: 800, height: 500)
    }
}

// AI 设置视图
struct AISettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    
    var body: some View {
        Form {
            Section("AI 模型设置") {
                Picker("选择模型", selection: $settingsManager.settings.aiModel) {
                    ForEach(AIModel.allCases, id: \.self) { model in
                        Text(model.rawValue).tag(model)
                    }
                }
                
                SecureField("API Key", text: $settingsManager.settings.apiKey)
                    .textFieldStyle(.roundedBorder)
            }
            
            Section("提示词模板") {
                ForEach(Array(settingsManager.settings.promptTemplates.keys), id: \.self) { fileType in
                    VStack(alignment: .leading) {
                        Text(fileType.rawValue)
                            .font(.headline)
                        TextEditor(text: Binding(
                            get: { settingsManager.settings.promptTemplates[fileType] ?? "" },
                            set: { settingsManager.settings.promptTemplates[fileType] = $0 }
                        ))
                        .frame(height: 100)
                        .font(.body)
                    }
                }
            }
        }
    }
}

// 外观设置视图
struct AppearanceSettingsView: View {
    @Binding var appearanceMode: AppearanceMode
    
    var body: some View {
        Form {
            Section("主题设置") {
                Picker("外观模式", selection: $appearanceMode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.description).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
}

// 设置分类枚举
enum SettingsSection: String, CaseIterable, Identifiable {
    case ai = "AI 设置"
    case appearance = "外观设置"
    
    var id: String { rawValue }
    
    var title: String { rawValue }
    
    var iconName: String {
        switch self {
        case .ai: return "brain"
        case .appearance: return "paintbrush"
        }
    }
}

// 外观模式枚举
enum AppearanceMode: String, CaseIterable, Identifiable {
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
} 