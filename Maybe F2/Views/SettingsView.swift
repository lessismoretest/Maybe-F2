import SwiftUI

enum SettingsSection: String, CaseIterable {
    case general = "通用"
    case aiModel = "AI模型"
    case renameModel = "重命名模型"
    case formatConversion = "格式转换"
    case about = "关于"
    
    var title: String { rawValue }
    
    var iconName: String {
        switch self {
        case .general: return "gear"
        case .aiModel: return "brain"
        case .renameModel: return "pencil"
        case .formatConversion: return "arrow.triangle.2.circlepath"
        case .about: return "info.circle"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss
    
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
                    case .general:
                        GeneralSettingsView(settingsManager: settingsManager)
                            .navigationTitle("通用设置")
                    case .aiModel:
                        AIModelSettingsView(settingsManager: settingsManager)
                            .navigationTitle("AI模型设置")
                    case .renameModel:
                        RenameSettingsView(settingsManager: settingsManager)
                            .navigationTitle("重命名模型")
                    case .formatConversion:
                        FormatConversionSettingsView(settingsManager: settingsManager)
                            .navigationTitle("格式转换")
                    case .about:
                        AboutSettingsView()
                            .navigationTitle("关于")
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

// 通用设置视图
struct GeneralSettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @State private var tempSettings: Settings
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        _tempSettings = State(initialValue: settingsManager.settings)
    }
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("外观模式")
                    Spacer()
                    Picker("", selection: $tempSettings.appearanceMode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.description).tag(mode)
                        }
                    }
                    .frame(width: 200)
                    .onChange(of: tempSettings.appearanceMode) { _ in
                        updateSettings()
                    }
                }
            } header: {
                Label("主题", systemImage: "paintbrush")
            }
            
            Section {
                Toggle("开机自动启动", isOn: $tempSettings.launchAtLogin)
                    .onChange(of: tempSettings.launchAtLogin) { _ in
                        updateSettings()
                    }
            } header: {
                Label("通用", systemImage: "gearshape")
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func updateSettings() {
        Task { @MainActor in
            settingsManager.updateSettings(tempSettings)
        }
    }
}

// 关于视图
struct AboutSettingsView: View {
    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("版本")
                    Spacer()
                    Text(versionString)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("开发者")
                    Spacer()
                    Text("Less is more")
                        .foregroundColor(.secondary)
                }
                
                Link("github.com/lessismoretest/Maybe-F2", destination: URL(string: "https://github.com/lessismoretest/Maybe-F2")!)
                    .foregroundColor(.blue)
            } header: {
                Label("关于", systemImage: "info.circle")
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
} 