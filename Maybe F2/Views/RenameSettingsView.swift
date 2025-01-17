import SwiftUI

/**
 * 重命名设置视图
 * 用于配置不同文件类型的重命名模型和提示词
 */
struct RenameSettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @State private var tempSettings: Settings
    @State private var showingConfigSheet = false
    @State private var selectedCategory: FileCategory?
    @State private var pendingCategory: FileCategory?
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        _tempSettings = State(initialValue: settingsManager.settings)
    }
    
    var body: some View {
        Form {
            Section {
                ForEach(FileCategory.allCases.dropFirst(), id: \.self) { category in
                    FileTypeRow(
                        category: category,
                        model: Binding(
                            get: { tempSettings.conversionModels[category] ?? .gemini_pro },
                            set: { 
                                tempSettings.conversionModels[category] = $0
                                updateSettings()
                            }
                        ),
                        promptTemplate: Binding(
                            get: { tempSettings.promptTemplates[category] ?? "" },
                            set: { 
                                tempSettings.promptTemplates[category] = $0
                                updateSettings()
                            }
                        ),
                        showConfig: {
                            NSLog("点击配置按钮: \(category.rawValue)")
                            pendingCategory = category
                        }
                    )
                }
            } header: {
                Label("文件类型设置", systemImage: "doc.badge.gearshape")
            } footer: {
                Text("为不同类型的文件配置使用的模型和提示词模板")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .onChange(of: pendingCategory) { newValue in
            if let category = newValue {
                NSLog("准备显示配置: \(category.rawValue)")
                selectedCategory = category
                showingConfigSheet = true
                pendingCategory = nil
            }
        }
        .sheet(isPresented: $showingConfigSheet) {
            if let category = selectedCategory {
                ParameterConfigSheet(
                    category: category,
                    model: Binding(
                        get: { 
                            NSLog("获取模型配置: \(category.rawValue)")
                            return tempSettings.conversionModels[category] ?? .gemini_pro 
                        },
                        set: { 
                            NSLog("更新模型配置: \(category.rawValue)")
                            tempSettings.conversionModels[category] = $0
                            updateSettings()
                        }
                    ),
                    promptTemplate: Binding(
                        get: { 
                            NSLog("获取提示词配置: \(category.rawValue)")
                            return tempSettings.promptTemplates[category] ?? "" 
                        },
                        set: { 
                            NSLog("更新提示词配置: \(category.rawValue)")
                            tempSettings.promptTemplates[category] = $0
                            updateSettings()
                        }
                    ),
                    onDismiss: {
                        NSLog("关闭配置弹窗")
                        showingConfigSheet = false
                        selectedCategory = nil
                    }
                )
            }
        }
    }
    
    private func updateSettings() {
        NSLog("更新设置")
        Task { @MainActor in
            settingsManager.updateSettings(tempSettings)
        }
    }
}

/**
 * 文件类型设置行
 * 显示单个文件类型的配置选项，包括：
 * - 文件类型图标和名称
 * - 支持的文件后缀
 * - AI 模型选择
 * - 参数配置按钮
 */
struct FileTypeRow: View {
    let category: FileCategory
    @Binding var model: AIModel
    @Binding var promptTemplate: String
    let showConfig: () -> Void
    
    var body: some View {
        HStack {
            // 文件类型图标和名称
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .foregroundColor(.secondary)
                Text(category.rawValue)
            }
            .frame(width: 120, alignment: .leading)
            
            // 文件后缀
            Text(category.extensions.map { $0.name }.joined(separator: ", "))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 200, alignment: .leading)
            
            // 使用模型选择
            Picker("", selection: $model) {
                ForEach(AIModel.allCases, id: \.self) { model in
                    Text(model.fullName).tag(model)
                }
            }
            .frame(width: 150)
            
            Spacer()
            
            // 配置按钮
            Button(action: showConfig) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("配置参数")
        }
        .padding(.vertical, 4)
    }
}

/**
 * 参数配置弹窗
 * 用于配置文件类型的重命名参数：
 * - 使用模型
 * - 提示词模板
 */
struct ParameterConfigSheet: View {
    let category: FileCategory
    @Binding var model: AIModel
    @Binding var promptTemplate: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            Text("重命名配置")
                .font(.headline)
                .padding()
            
            Divider()
            
            // 内容区域
            Form {
                // 基本信息
                Section {
                    HStack {
                        Text("文件类型")
                        Spacer()
                        Text(category.rawValue)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("支持格式")
                        Spacer()
                        Text(category.extensions.map { $0.name }.joined(separator: ", "))
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                } header: {
                    Label("基本信息", systemImage: "info.circle")
                }
                
                // AI模型设置
                Section {
                    Picker("使用模型", selection: $model) {
                        ForEach(AIModel.allCases, id: \.self) { model in
                            Text(model.fullName).tag(model)
                        }
                    }
                } header: {
                    Label("AI模型", systemImage: "brain")
                }
                
                // 提示词设置
                Section {
                    TextEditor(text: $promptTemplate)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                } header: {
                    Label("提示词", systemImage: "text.bubble")
                } footer: {
                    Text("提示词用于指导AI模型如何根据文件内容生成描述性的文件名")
                }
            }
            .formStyle(.grouped)
            
            Divider()
            
            // 底部按钮
            HStack {
                Button("取消", role: .cancel, action: onDismiss)
                Spacer()
                Button("完成", action: onDismiss)
            }
            .padding()
        }
        .frame(width: 500, height: 500)
    }
} 
