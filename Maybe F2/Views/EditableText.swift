import SwiftUI

struct EditableText: View {
    let text: String
    let onSubmit: (String) -> Void
    @State private var isEditing = false
    @State private var editingText: String = ""
    
    var body: some View {
        Group {
            if isEditing {
                TextField("", text: $editingText, onCommit: {
                    isEditing = false
                    onSubmit(editingText)
                })
                .textFieldStyle(.plain)
                .onAppear {
                    editingText = text
                }
            } else {
                Text(text)
                    .onTapGesture {
                        isEditing = true
                    }
            }
        }
    }
} 