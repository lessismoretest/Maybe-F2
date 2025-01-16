import SwiftUI

struct ControlPanelView: View {
    @ObservedObject var viewModel: FileManagerViewModel
    @ObservedObject var settingsManager: SettingsManager
    @State private var batchExtension: String = ""
    
    private func updateSelectedFilesExtension(_ newExtension: String) {
        for file in viewModel.files where file.isSelected {
            viewModel.updateExtension(for: file.id, newExtension: newExtension)
        }
    }
    
    private var currentCategory: FileCategory? {
        guard let firstSelected = viewModel.files.first(where: { $0.isSelected }) else {
            return nil
        }
        return FileExtensions.category(for: firstSelected.originalExtension)
    }
    
    var body: some View {
        HStack {
            // 重命名模式选择
            Menu {
                ForEach(RenameMode.allCases, id: \.self) { mode in
                    Button(action: {
                        viewModel.renameMode = mode
                    }) {
                        HStack {
                            Label(mode.description, systemImage: mode.icon)
                            Spacer()
                            if viewModel.renameMode == mode {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label(viewModel.renameMode.description, systemImage: viewModel.renameMode.icon)
                    .foregroundColor(.primary)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 120)
            
            // 批量设置后缀
            Menu {
                Button(action: {
                    batchExtension = ""
                    updateSelectedFilesExtension("")
                }) {
                    HStack {
                        Text("保持原格式")
                        Spacer()
                        if batchExtension.isEmpty {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Divider()
                
                // 当前类别的格式（优先显示）
                if let category = currentCategory,
                   !category.extensions.isEmpty {
                    ForEach(category.extensions, id: \.ext) { format in
                        Button(action: {
                            batchExtension = format.ext
                            updateSelectedFilesExtension(format.ext)
                        }) {
                            HStack {
                                Text(format.name)
                                Spacer()
                                if batchExtension == format.ext {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    
                    Divider()
                }
                
                // 其他所有类别
                ForEach(FileCategory.allCases.filter { $0 != currentCategory }, id: \.self) { category in
                    if !category.extensions.isEmpty {
                        Menu(category.rawValue) {
                            ForEach(category.extensions, id: \.ext) { format in
                                Button(action: {
                                    batchExtension = format.ext
                                    updateSelectedFilesExtension(format.ext)
                                }) {
                                    HStack {
                                        Text(format.name)
                                        Spacer()
                                        if batchExtension == format.ext {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(batchExtension.isEmpty ? "批量设置格式" : batchExtension)
                        .foregroundColor(batchExtension.isEmpty ? .secondary : .primary)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .menuStyle(.borderlessButton)
            .frame(width: 120)
            
            Spacer()
            
            // 右侧重命名按钮
            Button(action: {
                if viewModel.processStatus.isProcessing {
                    viewModel.cancelProcessing()
                } else {
                    viewModel.generateNewNames()
                }
            }) {
                Text(viewModel.processStatus.isProcessing ? "停止" : "一键 AI 重命名")
                    .frame(width: 120)
            }
            .buttonStyle(.borderedProminent)
            .tint(viewModel.processStatus.isProcessing ? .red : .accentColor)
            .disabled(!viewModel.processStatus.isProcessing && 
                     (viewModel.selectedCount == 0 || !viewModel.files.contains { 
                         $0.isSelected && $0.status == .pending 
                     }))
            
            Button(action: {
                viewModel.applyChanges()
            }) {
                Text("应用更改")
                    .frame(width: 100)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.hasCompletedFiles)
        }
    }
} 