import SwiftUI

struct FileListView: View {
    @ObservedObject var viewModel: FileManagerViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // 文件类型筛选器
            FileTypeFilterView(viewModel: viewModel)
                .padding(.vertical, 8)
            
            Divider()
            
            // 工具栏
            HStack {
                Button(action: viewModel.toggleSelectAll) {
                    Text(viewModel.selectedCount == viewModel.filteredFiles.count ? "取消全选" : "全选")
                }
                .disabled(viewModel.filteredFiles.isEmpty)
                
                Spacer()
                
                if viewModel.selectedCount > 0 {
                    Button(role: .destructive, action: viewModel.deleteSelectedFiles) {
                        Label("删除选中", systemImage: "trash")
                    }
                }
            }
            .padding(.horizontal)
            
            // 文件列表
            Table(viewModel.filteredFiles) {
                TableColumn("选择") { file in
                    Toggle("", isOn: Binding(
                        get: { file.isSelected },
                        set: { _ in viewModel.toggleSelection(for: file.id) }
                    ))
                }
                .width(40)
                
                TableColumn("原文件名", value: \.originalName)
                TableColumn("AI 重命名结果") { file in
                    Text(file.newName ?? "等待重命名...")
                        .foregroundColor(file.newName == nil ? .gray : .primary)
                }
                TableColumn("状态") { file in
                    StatusView(status: file.status, error: file.error)
                }
            }
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
        }
        .foregroundColor(status.color)
        .help(error ?? status.description)
    }
} 