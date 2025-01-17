import SwiftUI

struct MainView: View {
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var viewModel: FileManagerViewModel
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @State private var showingSettings = false
    
    init() {
        let settingsManager = SettingsManager()
        _settingsManager = StateObject(wrappedValue: settingsManager)
        _viewModel = StateObject(wrappedValue: FileManagerViewModel(settingsManager: settingsManager))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            HStack {
                FileTypeFilterView(selectedType: $viewModel.selectedFileType)
                Spacer()
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gear")
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView(settingsManager: settingsManager)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            // 文件列表区域
            FileListView(viewModel: viewModel)
            
            Divider()
            
            // 底部操作区域
            ControlPanelView(viewModel: viewModel, settingsManager: settingsManager)
                .frame(height: 60)
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
        .preferredColorScheme(appearanceMode.colorScheme)
        .onChange(of: settingsManager.settings.appearanceMode) { newMode in
            appearanceMode = newMode
        }
        .onAppear {
            appearanceMode = settingsManager.settings.appearanceMode
        }
    }
} 