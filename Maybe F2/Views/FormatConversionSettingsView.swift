import SwiftUI
import os

private let logger = Logger(subsystem: "com.maybe.f2", category: "FormatConversionSettingsView")

/**
 * 格式转换设置视图的状态管理
 */
@MainActor
class FormatConversionSettingsViewModel: ObservableObject {
    @Published var isLoading = false
    let settingsManager: SettingsManager
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        
        if settingsManager.settings.formatConversions.isEmpty {
            Task {
                await generateConversions()
            }
        }
    }
    
    func generateConversions() async {
        isLoading = true
        let conversions = await Task.detached(priority: .userInitiated) {
            FormatConversion.generateAllPossibleConversions()
        }.value
        
        var settings = settingsManager.settings
        settings.formatConversions = conversions
        settingsManager.updateSettings(settings)
        isLoading = false
    }
}

/**
 * 格式转换设置视图
 * 用于配置不同文件格式之间的转换规则
 */
struct FormatConversionSettingsView: View {
    @StateObject private var viewModel: FormatConversionSettingsViewModel
    @State private var tempSettings: Settings
    @State private var selectedConversion: FormatConversion?
    @State private var searchText = ""
    @State private var selectedStatus: ConversionStatus = .all
    @State private var selectedConversions: Set<UUID> = []
    @State private var showingBatchConfig = false
    @State private var pendingConversion: FormatConversion?
    
    init(settingsManager: SettingsManager) {
        _viewModel = StateObject(wrappedValue: FormatConversionSettingsViewModel(settingsManager: settingsManager))
        _tempSettings = State(initialValue: settingsManager.settings)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("正在生成格式转换列表...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 搜索和筛选区域
                HStack(spacing: 16) {
                    // 搜索框
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("搜索格式转换...", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                    
                    // 状态筛选
                    Picker("状态", selection: $selectedStatus) {
                        ForEach(ConversionStatus.allCases, id: \.self) { status in
                            Text(status.description).tag(status)
                        }
                    }
                    .frame(width: 120)
                    .help("按状态筛选格式转换")
                    
                    Spacer()
                    
                    // 批量配置按钮
                    if !selectedConversions.isEmpty {
                        Button(action: {
                            showingBatchConfig = true
                        }) {
                            Label("批量配置 (\(selectedConversions.count))", systemImage: "slider.horizontal.3")
                        }
                        .help("为选中的格式配置统一的实现方式")
                    }
                }
                .padding([.horizontal, .top])
                .padding(.bottom, 8)
                
                Divider()
                
                // 统计信息
                VStack(spacing: 4) {
                    HStack {
                        Text("共 \(tempSettings.formatConversions.count) 种格式转换")
                            .foregroundColor(.secondary)
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("已实现 \(tempSettings.formatConversions.filter { $0.isImplemented }.count) 种")
                            .foregroundColor(.green)
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("开发中 \(tempSettings.formatConversions.filter { !$0.isImplemented }.count) 种")
                            .foregroundColor(.orange)
                    }
                    
                    HStack(spacing: 8) {
                        Text("文本(\(FileExtensions.categoryExtensions[.text]?.count ?? 0)种)")
                        Text("图像(\(FileExtensions.categoryExtensions[.image]?.count ?? 0)种)")
                        Text("音频(\(FileExtensions.categoryExtensions[.audio]?.count ?? 0)种)")
                        Text("视频(\(FileExtensions.categoryExtensions[.video]?.count ?? 0)种)")
                        Text("文档(\(FileExtensions.categoryExtensions[.office]?.count ?? 0)种)")
                        Text("压缩(\(FileExtensions.categoryExtensions[.archive]?.count ?? 0)种)")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                .font(.caption)
                .padding(.vertical, 8)
                
                Divider()
                
                // 列表头部
                HStack(spacing: 0) {
                    Toggle("", isOn: .constant(false))
                        .opacity(0)
                        .frame(width: 30)
                    
                    ForEach([
                        ("源格式", 150),
                        ("目标格式", 150),
                        ("状态", 100),
                        ("操作", 40)
                    ], id: \.0) { title, width in
                        Text(title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: CGFloat(width), alignment: title == "操作" ? .trailing : .leading)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                
                if filteredConversions.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("没有找到匹配的格式转换")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredConversions) { conversion in
                                ConversionRow(
                                    conversion: conversion,
                                    isSelected: selectedConversions.contains(conversion.id),
                                    onSelect: { isSelected in
                                        if isSelected {
                                            selectedConversions.insert(conversion.id)
                                        } else {
                                            selectedConversions.remove(conversion.id)
                                        }
                                    },
                                    showConfig: {
                                        NSLog("点击配置按钮: \(conversion.sourceFormat) -> \(conversion.targetFormat)")
                                        pendingConversion = conversion
                                    }
                                )
                                Divider()
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: pendingConversion) { newValue in
            if let conversion = newValue {
                NSLog("准备显示配置: \(conversion.sourceFormat) -> \(conversion.targetFormat)")
                selectedConversion = conversion
                pendingConversion = nil
            }
        }
        .sheet(item: $selectedConversion) { conversion in
            let binding = Binding(
                get: {
                    NSLog("获取转换配置: \(conversion.sourceFormat) -> \(conversion.targetFormat)")
                    if let index = tempSettings.formatConversions.firstIndex(where: { $0.id == conversion.id }) {
                        return tempSettings.formatConversions[index]
                    }
                    return conversion
                },
                set: { newValue in
                    NSLog("更新转换配置: \(newValue.sourceFormat) -> \(newValue.targetFormat)")
                    if let index = tempSettings.formatConversions.firstIndex(where: { $0.id == newValue.id }) {
                        tempSettings.formatConversions[index] = newValue
                        updateSettings()
                    }
                }
            )
            
            ConversionConfigSheet(
                conversion: binding,
                onDismiss: { 
                    NSLog("关闭配置弹窗")
                    selectedConversion = nil
                }
            )
        }
        .onChange(of: showingBatchConfig) { newValue in
            print("showingModelConfig 改变: \(newValue)")
        }
        .sheet(isPresented: $showingBatchConfig) {
            BatchConfigSheet(
                conversions: $tempSettings.formatConversions,
                selectedIds: selectedConversions,
                onDismiss: {
                    showingBatchConfig = false
                    updateSettings()
                }
            )
        }
    }
    
    private func updateSettings() {
        NSLog("更新设置")
        Task { @MainActor in
            viewModel.settingsManager.updateSettings(tempSettings)
        }
    }
    
    private var filteredConversions: [FormatConversion] {
        var conversions = tempSettings.formatConversions
        
        // 应用搜索过滤
        if !searchText.isEmpty {
            conversions = conversions.filter { conversion in
                let sourceExt = conversion.sourceFormat.uppercased()
                let targetExt = conversion.targetFormat.uppercased()
                
                return sourceExt.localizedCaseInsensitiveContains(searchText) ||
                       targetExt.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 应用状态过滤
        if selectedStatus != .all {
            conversions = conversions.filter { conversion in
                switch selectedStatus {
                case .implemented:
                    return conversion.isImplemented
                case .developing:
                    return !conversion.isImplemented
                case .all:
                    return true
                }
            }
        }
        
        // 排序
        return conversions.sorted { lhs, rhs in
            let lhsCategory = FileExtensions.category(for: lhs.sourceFormat)
            let rhsCategory = FileExtensions.category(for: rhs.sourceFormat)
            
            if lhsCategory != rhsCategory {
                return lhsCategory.rawValue < rhsCategory.rawValue
            }
            
            if lhs.sourceFormat != rhs.sourceFormat {
                return lhs.sourceFormat.uppercased() < rhs.sourceFormat.uppercased()
            }
            
            return lhs.targetFormat.uppercased() < rhs.targetFormat.uppercased()
        }
    }
}

// MARK: - 辅助视图

/**
 * 转换状态
 */
enum ConversionStatus: CaseIterable {
    case all
    case implemented
    case developing
    
    var description: String {
        switch self {
        case .all: return "全部"
        case .implemented: return "已支持"
        case .developing: return "开发中"
        }
    }
}

/**
 * 单个转换配置行
 */
private struct ConversionRow: View {
    let conversion: FormatConversion
    let isSelected: Bool
    let onSelect: (Bool) -> Void
    let showConfig: () -> Void
    
    private var sourceCategory: FileCategory {
        FileExtensions.category(for: conversion.sourceFormat)
    }
    
    private var targetCategory: FileCategory {
        FileExtensions.category(for: conversion.targetFormat)
    }
    
    private var sourceExt: String {
        conversion.sourceFormat.uppercased()
    }
    
    private var targetExt: String {
        conversion.targetFormat.uppercased()
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // 选择框
            Toggle("", isOn: Binding(
                get: { isSelected },
                set: { onSelect($0) }
            ))
            .toggleStyle(.checkbox)
            .frame(width: 30)
            
            // 源格式
            HStack(spacing: 4) {
                Image(systemName: sourceCategory.icon)
                    .foregroundColor(.secondary)
                Text(sourceExt)
                    .font(.system(.body, design: .monospaced))
            }
            .frame(width: 150, alignment: .leading)
            
            // 目标格式
            HStack(spacing: 4) {
                Image(systemName: targetCategory.icon)
                    .foregroundColor(.secondary)
                Text(targetExt)
                    .font(.system(.body, design: .monospaced))
            }
            .frame(width: 150, alignment: .leading)
            
            // 状态指示
            HStack(spacing: 4) {
                Circle()
                    .fill(conversion.isImplemented ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(conversion.isImplemented ? "已支持" : "开发中")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            // 配置按钮
            Button(action: showConfig) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("配置参数")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .contextMenu {
            Button(action: showConfig) {
                Label("配置", systemImage: "slider.horizontal.3")
            }
        }
    }
}

/**
 * 转换配置弹窗
 */
private struct ConversionConfigSheet: View {
    @Binding var conversion: FormatConversion
    let onDismiss: () -> Void
    
    private var sourceCategory: FileCategory {
        FileExtensions.category(for: conversion.sourceFormat)
    }
    
    private var targetCategory: FileCategory {
        FileExtensions.category(for: conversion.targetFormat)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            Text("格式转换配置")
                .font(.headline)
                .padding()
            
            Divider()
            
            // 内容区域
            Form {
                // 基本信息
                Section {
                    HStack {
                        Text("源格式")
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: sourceCategory.icon)
                                .foregroundColor(.secondary)
                            Text(conversion.sourceFormat.uppercased())
                        }
                    }
                    
                    HStack {
                        Text("目标格式")
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: targetCategory.icon)
                                .foregroundColor(.secondary)
                            Text(conversion.targetFormat.uppercased())
                        }
                    }
                } header: {
                    Label("基本信息", systemImage: "info.circle")
                }
                
                // 实现方式
                Section {
                    Picker("选择实现", selection: $conversion.selectedMethod) {
                        ForEach(ImplementationMethod.availableMethods(from: conversion.sourceFormat, to: conversion.targetFormat), id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                } header: {
                    Label("实现方式", systemImage: "wrench.and.screwdriver")
                } footer: {
                    Text("选择合适的实现方式来处理格式转换")
                }
                
                // AI模型设置(仅当选择AI实现时显示)
                if conversion.selectedMethod == .ai {
                    Section {
                        Picker("使用模型", selection: $conversion.model) {
                            ForEach(AIModel.allCases, id: \.self) { model in
                                Text(model.fullName).tag(model)
                            }
                        }
                        
                        TextEditor(text: $conversion.prompt)
                            .frame(height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    } header: {
                        Label("AI模型", systemImage: "brain")
                    } footer: {
                        Text("提示词用于指导AI模型如何执行格式转换")
                    }
                }
            }
            .formStyle(.grouped)
            
            Divider()
            
            // 底部按钮
            HStack {
                Button("取消", role: .cancel, action: onDismiss)
                Spacer()
                Button("完成") {
                    conversion.implementation = conversion.selectedMethod.rawValue
                    onDismiss()
                }
            }
            .padding()
        }
        .frame(width: 500, height: 500)
    }
}

/**
 * 批量配置弹窗
 */
private struct BatchConfigSheet: View {
    @Binding var conversions: [FormatConversion]
    let selectedIds: Set<UUID>
    let onDismiss: () -> Void
    @State private var selectedMethod: ImplementationMethod = .ai
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            Text("批量配置")
                .font(.headline)
                .padding()
            
            Divider()
            
            // 内容区域
            Form {
                Section {
                    Picker("实现方式", selection: $selectedMethod) {
                        ForEach(ImplementationMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                } footer: {
                    Text("将为选中的 \(selectedIds.count) 个格式转换统一设置实现方式")
                }
            }
            .formStyle(.grouped)
            
            Divider()
            
            // 底部按钮
            HStack {
                Button("取消", role: .cancel, action: onDismiss)
                Spacer()
                Button("应用") {
                    // 更新选中的转换
                    for id in selectedIds {
                        if let index = conversions.firstIndex(where: { $0.id == id }) {
                            conversions[index].selectedMethod = selectedMethod
                            conversions[index].implementation = selectedMethod.rawValue
                        }
                    }
                    onDismiss()
                }
            }
            .padding()
        }
        .frame(width: 300, height: 200)
    }
} 