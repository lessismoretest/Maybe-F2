import SwiftUI

struct FileTypeFilterView: View {
    @ObservedObject var viewModel: FileManagerViewModel
    
    var body: some View {
        Picker("文件类型", selection: $viewModel.selectedFileType) {
            ForEach(FileType.allCases, id: \.self) { type in
                Label(type.rawValue + (viewModel.fileTypeCounts[type].map { " (\($0))" } ?? ""), 
                      systemImage: type.icon)
                    .tag(type)
            }
        }
        .pickerStyle(.menu)
        .frame(maxWidth: 200)
    }
} 