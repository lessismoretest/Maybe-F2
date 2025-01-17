import SwiftUI

struct FileTypeFilterView: View {
    @Binding var selectedType: FileCategory
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(FileCategory.allCases, id: \.self) { type in
                    Button(action: {
                        selectedType = type
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: type.icon)
                            Text(type.rawValue)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedType == type ? Color.accentColor : Color.clear)
                        .foregroundColor(selectedType == type ? .white : .primary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
} 