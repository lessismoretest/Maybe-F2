import SwiftUI
import UniformTypeIdentifiers

@MainActor
class FileManagerViewModel: ObservableObject {
    @Published private(set) var files: [FileItem] = []
    @Published var selectedFileType: FileCategory = .all
    @Published private(set) var processStatus = ProcessStatus()
    @Published var previewingFile: FileItem?
    @Published var renameMode: RenameMode = .replace
    private var processingTask: Task<Void, Never>?
    
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
    
    func cancelProcessing() {
        processingTask?.cancel()
        processingTask = nil
        processStatus.stop()
        
        var updatedFiles = files
        for (index, file) in files.enumerated() where file.status == .processing {
            updatedFiles[index].status = .pending
            updatedFiles[index].error = "已取消"
        }
        files = updatedFiles
    }
    
    private func performRename(for index: Int) async throws {
        guard index < files.count else {
            print("无效的文件索引")
            throw ConversionError.conversionFailed("无效的文件索引")
        }
        
        let file = files[index]
        // 如果没有新文件名，使用原文件名（不带后缀）
        let newName = file.newName ?? (file.originalName as NSString).deletingPathExtension
        
        // 更新状态为处理中
        var updatedFiles = files
        updatedFiles[index].status = .processing
        files = updatedFiles
        
        let originalURL = file.url
        
        // 检查源文件是否存在
        guard FileManager.default.fileExists(atPath: originalURL.path) else {
            print("源文件不存在：\(originalURL.path)")
            throw ConversionError.invalidInputFile
        }
        
        print("开始处理文件：\(originalURL.path)")
        print("新文件名：\(newName)")
        print("选择的后缀：\(file.selectedExtension)")
        print("重命名模式：\(renameMode)")
        
        // 如果选择了新的后缀名，需要进行格式转换
        if !file.selectedExtension.isEmpty {
            do {
                // 检查目标文件夹是否可写
                let targetFolder = originalURL.deletingLastPathComponent()
                print("目标文件夹：\(targetFolder.path)")
                
                guard FileManager.default.isWritableFile(atPath: targetFolder.path) else {
                    print("目标文件夹没有写入权限")
                    throw ConversionError.targetFolderNotWritable
                }
                
                // 检查磁盘空间
                if let space = try? FileManager.default.attributesOfFileSystem(forPath: targetFolder.path)[.systemFreeSize] as? Int64,
                   let fileSize = try? FileManager.default.attributesOfItem(atPath: originalURL.path)[.size] as? Int64 {
                    if space < fileSize * 2 {
                        print("磁盘空间不足")
                        throw ConversionError.insufficientSpace
                    }
                }
                
                print("开始格式转换...")
                // 先进行格式转换
                let convertedURL = try await ConversionService.shared.convert(
                    input: originalURL,
                    to: file.selectedExtension
                )
                print("转换完成，临时文件：\(convertedURL.path)")
                
                // 然后重命名为目标名称
                let finalURL = convertedURL.deletingLastPathComponent()
                    .appendingPathComponent(newName)
                    .appendingPathExtension(file.selectedExtension)
                print("最终文件路径：\(finalURL.path)")
                
                if FileManager.default.fileExists(atPath: finalURL.path) {
                    print("目标文件已存在")
                    try? FileManager.default.removeItem(at: convertedURL)
                    throw ConversionError.targetFileExists(finalURL.lastPathComponent)
                }
                
                // 移动到最终位置
                try FileManager.default.moveItem(at: convertedURL, to: finalURL)
                print("文件移动完成")
                
                // 根据重命名模式决定是否删除原文件
                if renameMode == .replace {
                    print("删除原文件")
                    do {
                        if FileManager.default.fileExists(atPath: originalURL.path) {
                            try FileManager.default.removeItem(at: originalURL)
                            print("原文件删除成功")
                        } else {
                            print("原文件已不存在")
                        }
                    } catch {
                        print("删除原文件失败：\(error.localizedDescription)")
                    }
                }
                
                // 检查新文件是否存在
                guard FileManager.default.fileExists(atPath: finalURL.path) else {
                    throw ConversionError.conversionFailed("转换后的文件未找到")
                }
                
                // 更新文件列表
                updatedFiles = files
                updatedFiles[index].url = finalURL
                updatedFiles[index].status = .completed
                updatedFiles[index].error = nil
                files = updatedFiles
                print("文件列表更新完成")
            } catch {
                print("处理失败：\(error.localizedDescription)")
                // 更新错误状态
                updatedFiles = files
                updatedFiles[index].status = .error
                if let conversionError = error as? ConversionError {
                    updatedFiles[index].error = conversionError.errorDescription
                } else {
                    updatedFiles[index].error = error.localizedDescription
                }
                files = updatedFiles
                
                throw error
            }
        } else {
            // 如果没有选择新后缀名，只进行重命名
            let newURL = originalURL.deletingLastPathComponent()
                .appendingPathComponent(newName)
                .appendingPathExtension(originalURL.pathExtension)
            print("新文件路径：\(newURL.path)")
            
            if FileManager.default.fileExists(atPath: newURL.path) {
                print("目标文件已存在")
                throw ConversionError.targetFileExists(newURL.lastPathComponent)
            }
            
            // 检查文件权限
            if !FileManager.default.isWritableFile(atPath: originalURL.deletingLastPathComponent().path) {
                print("目标文件夹没有写入权限")
                throw ConversionError.targetFolderNotWritable
            }
            
            do {
                if renameMode == .createNew {
                    print("创建新文件")
                    try FileManager.default.copyItem(at: originalURL, to: newURL)
                } else {
                    print("替换原文件")
                    try FileManager.default.moveItem(at: originalURL, to: newURL)
                }
                print("文件操作完成")
                
                // 更新文件列表
                updatedFiles = files
                updatedFiles[index].url = newURL
                updatedFiles[index].status = .completed
                updatedFiles[index].error = nil
                files = updatedFiles
                print("文件列表更新完成")
            } catch {
                print("处理失败：\(error.localizedDescription)")
                // 更新错误状态
                updatedFiles = files
                updatedFiles[index].status = .error
                updatedFiles[index].error = error.localizedDescription
                files = updatedFiles
                
                throw error
            }
        }
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

    
    /**
     * 生成新文件名（不修改实际文件）
     */
    func generateNewNames() {
        let pendingFiles = files.enumerated().filter { 
            $0.element.status == .pending && $0.element.isSelected 
        }
        
        processStatus.start(totalCount: pendingFiles.count)
        
        processingTask = Task {
            for (index, _) in pendingFiles {
                if Task.isCancelled {
                    break
                }
                
                await generateNewName(at: index)
                processStatus.complete()
            }
            processStatus.stop()
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
        // 筛选需要处理的文件：已选中且（有新名称或新后缀）
        let filesToProcess = files.enumerated().filter { _, file in
            file.isSelected && (!file.selectedExtension.isEmpty || file.newName != nil)
        }.map { index, file in index }  // 只保留索引
        
        print("开始处理文件，总数：\(filesToProcess.count)")
        processStatus.start(totalCount: filesToProcess.count)
        
        processingTask = Task {
            for index in filesToProcess {
                if Task.isCancelled {
                    print("处理被取消")
                    break
                }
                
                do {
                    print("处理文件 \(index + 1)/\(filesToProcess.count)")
                    print("文件路径：\(files[index].url.path)")
                    print("新文件名：\(files[index].newName ?? "")")
                    print("新后缀：\(files[index].selectedExtension)")
                    try await performRename(for: index)
                    processStatus.complete()
                } catch {
                    print("处理失败：\(error.localizedDescription)")
                    var updatedFiles = files
                    updatedFiles[index].status = .error
                    updatedFiles[index].error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    files = updatedFiles
                    processStatus.complete()
                }
            }
            processStatus.stop()
            print("所有文件处理完成")
        }
    }
    
    /**
     * 检查是否有可以应用更改的文件
     */
    var hasCompletedFiles: Bool {
        files.contains { file in 
            file.isSelected && (
                file.status == .completed || 
                (file.status == .pending && (!file.selectedExtension.isEmpty || file.newName != nil))
            )
        }
    }
    
    /**
     * 获取筛选后的文件列表
     */
    var filteredFiles: [FileItem] {
        if selectedFileType == .all {
            return files
        }
        return files.filter { FileExtensions.category(for: $0.url.pathExtension) == selectedFileType }
    }
    
    /**
     * 获取每种文件类型的数量
     */
    var fileTypeCounts: [FileCategory: Int] {
        var counts: [FileCategory: Int] = [:]
        counts[.all] = files.count
        
        for file in files {
            let type = FileExtensions.category(for: file.url.pathExtension)
            counts[type, default: 0] += 1
        }
        
        return counts
    }

    func showPreview(for file: FileItem) {
        previewingFile = file
    }
    
    func hidePreview() {
        previewingFile = nil
    }

    /**
     * 修改文件的新名称
     */
    func updateNewName(for id: UUID, newName: String) {
        if let index = files.firstIndex(where: { $0.id == id }) {
            var updatedFiles = files
            updatedFiles[index].newName = newName
            // 如果已经是完成状态，改回待处理状态
            if updatedFiles[index].status == .completed {
                updatedFiles[index].status = .pending
            }
            files = updatedFiles
        }
    }
    
    /**
     * 修改文件的新后缀名
     */
    func updateExtension(for id: UUID, newExtension: String) {
        if let index = files.firstIndex(where: { $0.id == id }) {
            var updatedFiles = files
            updatedFiles[index].selectedExtension = newExtension
            // 如果已经是完成状态，改回待处理状态
            if updatedFiles[index].status == .completed {
                updatedFiles[index].status = .pending
            }
            files = updatedFiles
        }
    }

    // 根据选中的文件类型过滤文件
    func filteredFiles(_ files: [URL]) -> [URL] {
        guard selectedFileType != .all else { return files }
        return files.filter { FileExtensions.category(for: $0.pathExtension) == selectedFileType }
    }
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
