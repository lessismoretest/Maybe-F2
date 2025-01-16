import SwiftUI

struct FileExtensionPicker: View {
    let fileId: UUID
    let originalExtension: String
    @Binding var selectedExtension: String
    @State private var isHovered = false
    
    private var currentCategory: FileCategory {
        FileExtensions.category(for: originalExtension)
    }
    
    var body: some View {
        Menu {
            Button(action: {
                selectedExtension = ""
            }) {
                HStack {
                    Text("保持原格式")
                    Spacer()
                    if selectedExtension.isEmpty {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Divider()
            
            // 当前类别的格式（优先显示）
            if !currentCategory.extensions.isEmpty {
                ForEach(currentCategory.extensions, id: \.ext) { format in
                    Button(action: {
                        selectedExtension = format.ext
                    }) {
                        HStack {
                            Text(format.name)
                            Spacer()
                            if selectedExtension == format.ext {
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
                                selectedExtension = format.ext
                            }) {
                                HStack {
                                    Text(format.name)
                                    Spacer()
                                    if selectedExtension == format.ext {
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
                Text(selectedExtension.isEmpty ? "选择格式" : selectedExtension)
                    .foregroundColor(selectedExtension.isEmpty ? .secondary : .primary)
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 2)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isHovered ? Color.gray.opacity(0.1) : Color.clear)
            )
        }
        .menuStyle(.borderlessButton)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

extension FileCategory {
    var extensions: [(name: String, ext: String)] {
        FileExtensions.categoryExtensions[self] ?? []
    }
} 