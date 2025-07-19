import SwiftUI

struct ChatFlowView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @State private var userInput = ""

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Main content area
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading) {
                            ForEach(viewModel.messages.indices, id: \.self) { index in
                                Text(viewModel.messages[index])
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .id(index)
                            }
                            // Add padding at the bottom to account for the input area
                            Spacer().frame(height: 60)
                        }
                        .padding(.horizontal)
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let lastIndex = viewModel.messages.indices.last {
                            withAnimation {
                                proxy.scrollTo(lastIndex, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Fixed bottom input area
                VStack(spacing: 0) {
                    // Input area
                    HStack(alignment: .bottom, spacing: 8) {
                        // Clear button (only visible when there's text)
                        if !userInput.isEmpty {
                            Button(action: {
                                withAnimation {
                                    userInput = ""
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .opacity(0.7)
                            }
                            .accessibilityLabel("Clear message")
                            .padding(.leading, 8)
                            .transition(.opacity)
                        }
                        
                        // Text input field
                        ZStack(alignment: .trailing) {
                            ExpandingTextEditor(text: $userInput, maxHeight: 44)
                                .frame(minHeight: 36, maxHeight: 44)
                                .padding(.trailing, 36)
                                .padding(.leading, 12)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color(.systemGray6))
                                )
                                .onSubmit {
                                    sendMessage()
                                }
                                .accessibilityHint("Type your message to the coach")
                            
                            // Send button
                            Button(action: sendMessage) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.black)
                                    .padding(8)
                            }
                            .disabled(isSendButtonDisabled)
                            .opacity(isSendButtonDisabled ? 0.5 : 1.0)
                            .accessibilityLabel("Send message")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground).ignoresSafeArea(.all, edges: .bottom))
                }
                .background(Color(.systemBackground).ignoresSafeArea(.all, edges: .bottom))
            }
            .navigationTitle("Coach")
            .onTapGesture {
                self.hideKeyboard()
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        self.hideKeyboard()
                    }
                }
            }
        }
    }
    
    private var isSendButtonDisabled: Bool {
        userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func sendMessage() {
        let trimmed = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        viewModel.sendUserMessage(trimmed)
        userInput = ""
    }
}

struct ExpandingTextEditor: View {
    @Binding var text: String
    @State private var textViewHeight: CGFloat = 36
    var maxHeight: CGFloat = 44
    
    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text("Type your message...")
                    .foregroundColor(.gray)
                    .padding(.leading, 5)
                    .padding(.top, 4)
            }
            TextEditor(text: $text)
                .frame(minHeight: 36, maxHeight: min(textViewHeight, maxHeight))
                .background(GeometryReader { geo in
                    Color.clear.onAppear {
                        textViewHeight = geo.size.height
                    }.onChange(of: text) { _ in
                        textViewHeight = geo.size.height
                    }
                })
                .padding(2)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
        }
    }
}
