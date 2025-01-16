import SwiftUI

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
                    case .ai:
                        AISettingsView(settingsManager: settingsManager)
                            .navigationTitle("AI 设置")
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

// AI 设置视图
struct AISettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @State private var tempSettings: Settings
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        _tempSettings = State(initialValue: settingsManager.settings)
    }
    
    var body: some View {
        Form {
            Section(header: Text("AI 模型设置")) {
                HStack {
                    Text("选择模型")
                    Spacer()
                    Picker("", selection: $tempSettings.aiModel) {
                        ForEach(AIModel.allCases, id: \.self) { model in
                            Text(model.rawValue).tag(model)
                        }
                    }
                    .frame(width: 200)
                    .onChange(of: tempSettings.aiModel) { _ in
                        updateSettings()
                    }
                }
                
                HStack {
                    Text("API Key")
                    Spacer()
                    SecureField("", text: $tempSettings.apiKey)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)
                        .onSubmit {
                            updateSettings()
                        }
                }
            }
            
            Section(header: Text("提示词模板")) {
                ForEach(Array(tempSettings.promptTemplates.keys), id: \.self) { fileType in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(fileType.rawValue)
                            .font(.subheadline)
                        TextEditor(text: Binding(
                            get: { tempSettings.promptTemplates[fileType] ?? "" },
                            set: { newValue in
                                tempSettings.promptTemplates[fileType] = newValue
                                updateSettings()
                            }
                        ))
                        .frame(height: 100)
                        .font(.body)
                        .cornerRadius(6)
                    }
                }
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
            Section(header: Text("主题")) {
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
            }
            
            Section(header: Text("通用")) {
                Toggle("开机自动启动", isOn: $tempSettings.launchAtLogin)
                    .onChange(of: tempSettings.launchAtLogin) { _ in
                        updateSettings()
                    }
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

// 格式转换状态视图
struct FormatConversionListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedStatus: ConversionStatus = .all
    
    private enum ConversionStatus: String, CaseIterable {
        case all = "全部"
        case supported = "已支持"
        case developing = "开发中"
        
        var color: Color {
            switch self {
            case .all: return .secondary
            case .supported: return .green
            case .developing: return .yellow
            }
        }
    }
    
    private struct ConversionItem: Identifiable {
        let id = UUID()
        let fromFormat: String
        let toFormat: String
        let isImplemented: Bool
    }
    
    private var conversionList: [ConversionItem] {
        var items: [ConversionItem] = []
        let formats = ImageFormat.allCases
        
        for fromFormat in formats {
            for toFormat in formats where fromFormat != toFormat {
                let isImplemented = ConversionService.shared.canConvert(
                    from: fromFormat.rawValue,
                    to: toFormat.rawValue
                )
                items.append(ConversionItem(
                    fromFormat: fromFormat.rawValue,
                    toFormat: toFormat.rawValue,
                    isImplemented: isImplemented
                ))
            }
        }
        
        return items
    }
    
    private var filteredList: [ConversionItem] {
        var filtered = conversionList
        
        // 应用搜索过滤
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.fromFormat.localizedCaseInsensitiveContains(searchText) ||
                $0.toFormat.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 应用状态过滤
        switch selectedStatus {
        case .supported:
            filtered = filtered.filter { $0.isImplemented }
        case .developing:
            filtered = filtered.filter { !$0.isImplemented }
        case .all:
            break
        }
        
        return filtered
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索和筛选区域
            HStack {
                // 搜索框
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("搜索格式...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // 状态筛选
                Picker("", selection: $selectedStatus) {
                    ForEach(ConversionStatus.allCases, id: \.self) { status in
                        HStack {
                            if status != .all {
                                Circle()
                                    .fill(status.color)
                                    .frame(width: 8, height: 8)
                            }
                            Text(status.rawValue)
                        }
                        .tag(status)
                    }
                }
                .frame(width: 100)
            }
            .padding()
            
            // 列表头部
            HStack {
                Text("原格式")
                    .frame(width: 100)
                Text("目标格式")
                    .frame(width: 100)
                Text("状态")
                    .frame(width: 100)
            }
            .foregroundColor(.secondary)
            .font(.caption)
            .padding(.horizontal)
            
            Divider()
            
            // 列表内容
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(filteredList) { item in
                        HStack {
                            Text(item.fromFormat.uppercased())
                                .frame(width: 100)
                            Text("→")
                                .foregroundColor(.secondary)
                            Text(item.toFormat.uppercased())
                                .frame(width: 100)
                            Circle()
                                .fill(item.isImplemented ? Color.green : Color.yellow)
                                .frame(width: 8, height: 8)
                                .help(item.isImplemented ? "已支持" : "开发中")
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(width: 400, height: 500)
    }
}

// 关于视图
struct AboutSettingsView: View {
    @State private var showingConversionList = false
    
    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }
    
    var body: some View {
        Form {
            Section(header: Text("关于")) {
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
                
                Button("格式转换清单") {
                    showingConversionList = true
                }
                .sheet(isPresented: $showingConversionList) {
                    FormatConversionListView()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// 设置分类枚举
enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "通用设置"
    case ai = "AI 设置"
    case about = "关于"
    
    var id: String { rawValue }
    
    var title: String { rawValue }
    
    var iconName: String {
        switch self {
        case .general: return "gearshape"
        case .ai: return "brain"
        case .about: return "info.circle"
        }
    }
}

// 外观模式枚举
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
} 