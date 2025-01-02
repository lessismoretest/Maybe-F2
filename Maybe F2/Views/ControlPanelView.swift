import SwiftUI

struct ControlPanelView: View {
    @ObservedObject var viewModel: FileManagerViewModel
    @ObservedObject var settingsManager: SettingsManager
    @State private var showingSettings = false
    
    var body: some View {
        HStack {
            // 左侧设置按钮
            Button(action: { showingSettings = true }) {
                HStack {
                    Image(systemName: "gear")
                    Text("设置")
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(settingsManager: settingsManager)
            }
            
            Spacer()
            
            // 重命名按钮组
            HStack(spacing: 8) {
                // AI 重命名按钮
                Button(action: {
                    viewModel.generateNewNames()
                }) {
                    Text("AI 重命名")
                        .frame(width: 100)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.selectedCount == 0 || !viewModel.files.contains { 
                    $0.isSelected && $0.status == .pending 
                })
                
                // 应用更改按钮
                Button(action: {
                    viewModel.applyChanges()
                }) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("应用更改")
                    }
                    .frame(width: 100)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(!viewModel.hasCompletedFiles)
            }
        }
    }
} 