import SwiftUI
import UniformTypeIdentifiers

@MainActor
class FileManagerViewModel: ObservableObject {
    @Published private(set) var files: [FileItem] = []
    @Published var selectedFileType: FileType = .all
    private let settingsManager: SettingsManager
    private let aiService: AIService
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        self.aiService = AIService(settingsManager: settingsManager)
    }
    
    func handleDroppedFiles(_ providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { [weak self] item, error in
                guard let self = self,
                      let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                
                Task { @MainActor in
                    self.addFile(url)
                }
            }
        }
    }
    
    func openFilePickerDialog() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        if panel.runModal() == .OK {
            Task { @MainActor in
                for url in panel.urls {
                    addFile(url)
                }
            }
        }
    }
    
    private func addFile(_ url: URL) {
        let fileItem = FileItem(url: url)
        if !files.contains(where: { $0.id == fileItem.id }) {
            files.append(fileItem)
        }
    }
    
    func renameAllFiles() {
        let pendingFiles = files.enumerated().filter { 
            $0.element.status == .pending && $0.element.isSelected 
        }
        
        Task {
            for (index, _) in pendingFiles {
                await renameFile(at: index)
            }
        }
    }
    
    private func renameFile(at index: Int) async {
        guard index < files.count else { return }
        
        var updatedFiles = files
        updatedFiles[index].status = .processing
        files = updatedFiles
        
        do {
            let newName = try await aiService.generateFileName(for: files[index])
            
            guard index < files.count else { return }
            updatedFiles = files
            updatedFiles[index].newName = newName
            updatedFiles[index].status = .completed
            files = updatedFiles
            
            try await performRename(for: index)
            
        } catch {
            guard index < files.count else { return }
            updatedFiles = files
            updatedFiles[index].status = .error
            updatedFiles[index].error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            files = updatedFiles
        }
    }
    
    private func performRename(for index: Int) async throws {
        guard index < files.count,
              let newName = files[index].newName else { return }
        
        let originalURL = files[index].url
        let newURL = originalURL.deletingLastPathComponent()
            .appendingPathComponent(newName)
            .appendingPathExtension(originalURL.pathExtension)
        
        if FileManager.default.fileExists(atPath: newURL.path) {
            throw RenameError.fileExists
        }
        
        try FileManager.default.moveItem(at: originalURL, to: newURL)
        
        var updatedFiles = files
        updatedFiles[index].url = newURL
        files = updatedFiles
    }
    
    /**
     * 切换文件选中状态
     */
    func toggleSelection(for id: UUID) {
        if let index = files.firstIndex(where: { $0.id == id }) {
            files[index].isSelected.toggle()
        }
    }
    
    /**
     * 获取选中的文件数量
     */
    var selectedCount: Int {
        files.filter { $0.isSelected }.count
    }
    
    /**
     * 删除选中的文件
     */
    func deleteSelectedFiles() {
        files.removeAll { $0.isSelected }
    }
    
    /**
     * 全选/取消全选
     */
    func toggleSelectAll() {
        let allSelected = files.allSatisfy { $0.isSelected }
        files = files.map { file in
            var file = file
            file.isSelected = !allSelected
            return file
        }
    }
<<<<<<< HEAD
    
    /**
     * 生成新文件名（不修改实际文件）
     */
    func generateNewNames() {
        let pendingFiles = files.enumerated().filter { 
            $0.element.status == .pending && $0.element.isSelected 
        }
        
        Task {
            for (index, _) in pendingFiles {
                await generateNewName(at: index)
            }
        }
    }
    
    private func generateNewName(at index: Int) async {
        guard index < files.count else { return }
        
        var updatedFiles = files
        updatedFiles[index].status = .processing
        files = updatedFiles
        
        do {
            let newName = try await aiService.generateFileName(for: files[index])
            
            guard index < files.count else { return }
            updatedFiles = files
            updatedFiles[index].newName = newName
            updatedFiles[index].status = .completed
            files = updatedFiles
        } catch {
            guard index < files.count else { return }
            updatedFiles = files
            updatedFiles[index].status = .error
            updatedFiles[index].error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            files = updatedFiles
        }
    }
    
    /**
     * 应用更改（实际重命名文件）
     */
    func applyChanges() {
        let completedFiles = files.enumerated().filter { 
            $0.element.status == .completed && $0.element.isSelected 
        }
        
        Task {
            for (index, _) in completedFiles {
                do {
                    try await performRename(for: index)
                } catch {
                    var updatedFiles = files
                    updatedFiles[index].status = .error
                    updatedFiles[index].error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    files = updatedFiles
                }
            }
        }
    }
    
    /**
     * 检查是否有可以应用更改的文件
     */
    var hasCompletedFiles: Bool {
        files.contains { $0.isSelected && $0.status == .completed }
    }
    
    /**
     * 获取筛选后的文件列表
     */
    var filteredFiles: [FileItem] {
        if selectedFileType == .all {
            return files
        }
        return files.filter { FileType.detect(from: $0.url) == selectedFileType }
    }
    
    /**
     * 获取每种文件类型的数量
     */
    var fileTypeCounts: [FileType: Int] {
        var counts: [FileType: Int] = [:]
        counts[.all] = files.count
        
        for file in files {
            let type = FileType.detect(from: file.url)
            counts[type, default: 0] += 1
        }
        
        return counts
    }
=======
>>>>>>> parent of dbfeeb3 (增加应用更改按钮)
}

enum RenameError: LocalizedError {
    case fileExists
    
    var errorDescription: String? {
        switch self {
        case .fileExists:
            return "目标文件已存在"
        }
    }
} 