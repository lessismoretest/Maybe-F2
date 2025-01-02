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
            
            // 右侧重命名按钮
            Button(action: {
                viewModel.renameAllFiles()
            }) {
                Text("一键重命名")
                    .frame(width: 100)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.selectedCount == 0 || !viewModel.files.contains { 
                $0.isSelected && $0.status == .pending 
            })
        }
    }
} 