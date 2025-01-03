import SwiftUI

struct DropZoneView: View {
    @ObservedObject var viewModel: FileManagerViewModel
    @State private var isHovering = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundColor(isHovering ? .blue : .gray)
                .background(Color.gray.opacity(0.1))
            
            VStack {
                Text("\u{1F4E5}")
                    .font(.system(size: 48))
                Text("拖拽文件到这里或点击选择文件")
                    .font(.headline)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isHovering) { providers in
            viewModel.handleDroppedFiles(providers)
            return true
        }
        .onTapGesture {
            viewModel.openFilePickerDialog()
        }
    }
} 