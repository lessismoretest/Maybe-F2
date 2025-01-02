//
//  Maybe_F2App.swift
//  Maybe F2
//
//  Created by Less is more on 2025/1/2.
//

import SwiftUI

@main
struct Maybe_F2App: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .navigationTitle("Maybe F2")
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
        .defaultSize(width: 800, height: 600)
        .windowToolbarStyle(.unified)
        .defaultPosition(.center)
    }
}
