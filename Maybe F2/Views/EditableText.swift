import SwiftUI

struct EditableText: View {
    let text: String
    let isEditable: Bool
    let onSubmit: (String) -> Void
    
    @State private var isEditing = false
    @State private var editingText: String = ""
    
    var body: some View {
        Group {
            if isEditing {
                TextField("", text: $editingText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        isEditing = false
                        if !editingText.isEmpty {
                            onSubmit(editingText)
                        }
                    }
                    .onExitCommand { // ESC 键处理
                        isEditing = false
                        editingText = text
                    }
            } else {
                Text(text)
                    .onTapGesture(count: 2) {
                        if isEditable {
                            editingText = text
                            isEditing = true
                        }
                    }
            }
        }
        .onChange(of: text) { newValue in
            if !isEditing {
                editingText = newValue
            }
        }
    }
} 