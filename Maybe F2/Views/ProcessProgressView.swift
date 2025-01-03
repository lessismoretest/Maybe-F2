import SwiftUI

struct ProcessProgressView: View {
    let status: ProcessStatus
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("处理进度：\(Int(status.progress * 100))%")
                    .font(.headline)
                
                Spacer()
                
                if let timeRemaining = status.estimatedTimeRemaining {
                    Text("预计剩余时间：\(timeRemaining.formattedTime)")
                        .foregroundColor(.secondary)
                }
                
                Button(role: .destructive, action: onCancel) {
                    Text("取消")
                }
                .disabled(!status.isProcessing)
            }
            
            ProgressView(value: status.progress)
                .progressViewStyle(.linear)
            
            HStack {
                Text("\(status.completedCount)/\(status.totalCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
} 