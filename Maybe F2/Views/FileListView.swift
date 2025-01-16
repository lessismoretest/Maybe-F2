import SwiftUI
import Quartz

class PreviewPanelController: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate, ObservableObject {
    @Published var url: URL?
    
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        return url != nil ? 1 : 0
    }
    
    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        return url as QLPreviewItem?
    }
}

struct FileListView: View {
    @ObservedObject var viewModel: FileManagerViewModel
    @State private var selectedFileId: UUID?
    @StateObject private var previewController = PreviewPanelController()
    @State private var isHovering = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 文件列表区域
            ZStack {
                if viewModel.files.isEmpty {
                    // 空状态拖拽区域
                    VStack(spacing: 16) {
                        Text("\u{1F4E5}")
                            .font(.system(size: 48))
                        Text("拖拽文件到这里或点击选择文件")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                            .foregroundColor(isHovering ? .blue : .gray)
                    )
                    .padding()
                    .onTapGesture {
                        viewModel.openFilePickerDialog()
                    }
                } else {
                    // 文件列表
                    VStack(spacing: 0) {
                        Table(viewModel.filteredFiles, selection: $selectedFileId) {
                            TableColumn("选择") { file in
                                Toggle("", isOn: Binding(
                                    get: { file.isSelected },
                                    set: { _ in viewModel.toggleSelection(for: file.id) }
                                ))
                            }
                            .width(40)
                            
                            TableColumn("") { file in
                                IconView(url: file.url)
                                    .onTapGesture {
                                        showQuickLook(for: file.url)
                                    }
                            }
                            .width(30)
                            
                            TableColumn("原文件名", value: \.originalName)
                            
                            TableColumn("新文件名") { file in
                                EditableText(
                                    text: file.newName ?? (file.originalName as NSString).deletingPathExtension,
                                    onSubmit: { newName in
                                        viewModel.updateNewName(for: file.id, newName: newName)
                                    }
                                )
                                .foregroundColor(file.newName == nil ? .secondary : .primary)
                            }
                            
                            TableColumn("新后缀") { file in
                                FileExtensionPicker(
                                    fileId: file.id,
                                    originalExtension: file.originalExtension,
                                    selectedExtension: Binding(
                                        get: { file.selectedExtension },
                                        set: { newValue in
                                            viewModel.updateExtension(for: file.id, newExtension: newValue)
                                        }
                                    )
                                )
                            }
                            .width(100)
                            
                            TableColumn("状态") { file in
                                StatusView(status: file.status, error: file.error)
                            }
                        }
                        
                        if viewModel.processStatus.isProcessing {
                            Divider()
                            ProcessProgressView(
                                status: viewModel.processStatus,
                                onCancel: viewModel.cancelProcessing
                            )
                        }
                        
                        // 底部工具栏
                        if !viewModel.filteredFiles.isEmpty {
                            Divider()
                            HStack {
                                Button(action: viewModel.toggleSelectAll) {
                                    Text(viewModel.selectedCount == viewModel.filteredFiles.count ? "取消全选" : "全选")
                                }
                                
                                if viewModel.selectedCount > 0 {
                                    Button(role: .destructive, action: viewModel.deleteSelectedFiles) {
                                        Label("删除选中", systemImage: "trash")
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color(NSColor.controlBackgroundColor))
                        }
                    }
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isHovering) { providers in
            viewModel.handleDroppedFiles(providers)
            return true
        }
        .onKeyPress(.space) { 
            if let selectedId = selectedFileId,
               let selectedFile = viewModel.filteredFiles.first(where: { $0.id == selectedId }) {
                showQuickLook(for: selectedFile.url)
                return .handled
            }
            return .ignored
        }
    }
    
    private func showQuickLook(for url: URL) {
        previewController.url = url
        
        if let panel = QLPreviewPanel.shared() {
            if panel.isVisible {
                panel.orderOut(nil)
            } else {
                panel.dataSource = previewController
                panel.delegate = previewController
                panel.makeKeyAndOrderFront(nil)
            }
        }
    }
}

// 文件图标视图
private struct IconView: View {
    let url: URL
    @State private var icon: NSImage?
    
    var body: some View {
        Group {
            if let icon = icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
            } else {
                Color.clear.frame(width: 16, height: 16)
            }
        }
        .onAppear {
            icon = NSWorkspace.shared.icon(forFile: url.path)
        }
    }
}

struct StatusView: View {
    let status: FileStatus
    let error: String?
    
    var body: some View {
        HStack {
            Image(systemName: status.iconName)
            Text(error ?? status.description)
                .lineLimit(1)
        }
        .foregroundColor(status.color)
        .help(error ?? status.description)
    }
} 