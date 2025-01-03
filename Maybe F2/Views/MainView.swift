import SwiftUI

struct MainView: View {
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var viewModel: FileManagerViewModel
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    
    init() {
        let settingsManager = SettingsManager()
        _settingsManager = StateObject(wrappedValue: settingsManager)
        _viewModel = StateObject(wrappedValue: FileManagerViewModel(settingsManager: settingsManager))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 文件列表区域
            FileListView(viewModel: viewModel)
            
            Divider()
            
            // 操作区域
            ControlPanelView(viewModel: viewModel, settingsManager: settingsManager)
                .frame(height: 60)
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
        .preferredColorScheme(appearanceMode.colorScheme)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

extension AppearanceMode {
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
} 