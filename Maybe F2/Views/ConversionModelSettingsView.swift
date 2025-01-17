import SwiftUI

/**
 * 转换模型设置视图
 */
struct ConversionModelSettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @State private var tempSettings: Settings
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        _tempSettings = State(initialValue: settingsManager.settings)
    }
    
    var body: some View {
        Form {
            // AI 模型设置
            Section(header: Text("AI 模型")) {
                Picker("使用模型", selection: $tempSettings.aiModel) {
                    ForEach(AIModel.allCases, id: \.self) { model in
                        Text(model.fullName).tag(model)
                    }
                }
                .onChange(of: tempSettings.aiModel) { _ in
                    updateSettings()
                }
                
                SecureField("API Key", text: apiKeyBinding)
                    .textFieldStyle(.roundedBorder)
            }
            
            // 文件类型设置
            Section(header: Text("文件类型设置")) {
                ConversionSettingsContent(tempSettings: $tempSettings, updateSettings: updateSettings)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var apiKeyBinding: Binding<String> {
        Binding(
            get: { tempSettings.apiKeys[tempSettings.aiModel] ?? "" },
            set: { newValue in
                var updatedKeys = tempSettings.apiKeys
                updatedKeys[tempSettings.aiModel] = newValue
                tempSettings.apiKeys = updatedKeys
                updateSettings()
            }
        )
    }
    
    private func updateSettings() {
        Task { @MainActor in
            settingsManager.updateSettings(tempSettings)
        }
    }
}

/**
 * 转换设置内容视图
 */
private struct ConversionSettingsContent: View {
    @Binding var tempSettings: Settings
    let updateSettings: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            TableHeaderView()
            Divider()
            TableContentView(tempSettings: $tempSettings, updateSettings: updateSettings)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

/**
 * 表格头部视图
 */
private struct TableHeaderView: View {
    var body: some View {
        HStack {
            Text("文件类型")
                .frame(width: 100, alignment: .leading)
            Text("使用模型")
                .frame(width: 200, alignment: .leading)
            Text("提示词")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
        .font(.headline)
    }
}

/**
 * 表格内容视图
 */
private struct TableContentView: View {
    @Binding var tempSettings: Settings
    let updateSettings: () -> Void
    
    private var sortedFileTypes: [FileCategory] {
        FileCategory.allCases.dropFirst().sorted { $0.rawValue < $1.rawValue }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(sortedFileTypes.enumerated()), id: \.element) { index, type in
                    FileTypeSettingRow(
                        fileType: type,
                        model: modelBinding(for: type),
                        promptTemplate: promptBinding(for: type)
                    )
                    
                    if index < sortedFileTypes.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .frame(height: 300)
    }
    
    private func modelBinding(for fileType: FileCategory) -> Binding<AIModel> {
        Binding(
            get: { tempSettings.conversionModels[fileType] ?? .gemini_pro },
            set: { newValue in
                var updatedModels = tempSettings.conversionModels
                updatedModels[fileType] = newValue
                tempSettings.conversionModels = updatedModels
                updateSettings()
            }
        )
    }
    
    private func promptBinding(for fileType: FileCategory) -> Binding<String> {
        Binding(
            get: { tempSettings.promptTemplates[fileType] ?? "" },
            set: { newValue in
                var updatedTemplates = tempSettings.promptTemplates
                updatedTemplates[fileType] = newValue
                tempSettings.promptTemplates = updatedTemplates
                updateSettings()
            }
        )
    }
}

/**
 * 单个文件类型的设置行
 */
private struct FileTypeSettingRow: View {
    let fileType: FileCategory
    @Binding var model: AIModel
    @Binding var promptTemplate: String
    
    var body: some View {
        HStack {
            // 文件类型
            HStack(spacing: 4) {
                Image(systemName: fileType.icon)
                    .foregroundColor(.secondary)
                Text(fileType.rawValue)
            }
            .frame(width: 100, alignment: .leading)
            
            // 模型选择
            Picker("", selection: $model) {
                ForEach(AIModel.allCases, id: \.self) { model in
                    Text(model.rawValue).tag(model)
                }
            }
            .frame(width: 200)
            
            // 提示词输入
            TextField("提示词", text: $promptTemplate)
                .textFieldStyle(.roundedBorder)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
} 