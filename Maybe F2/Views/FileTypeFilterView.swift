import SwiftUI

struct FileTypeFilterView: View {
    @ObservedObject var viewModel: FileManagerViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(FileType.allCases, id: \.self) { type in
                    FilterButton(
                        type: type,
                        count: viewModel.fileTypeCounts[type] ?? 0,
                        isSelected: viewModel.selectedFileType == type,
                        action: { viewModel.selectedFileType = type }
                    )
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 36)
    }
}

private struct FilterButton: View {
    let type: FileType
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: type.icon)
                Text(type.rawValue)
                if count > 0 {
                    Text("(\(count))")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
} 