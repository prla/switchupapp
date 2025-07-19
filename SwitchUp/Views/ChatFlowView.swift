import SwiftUI

struct ChatMessageView: View {
    let message: String
    let isUserMessage: Bool
    
    var body: some View {
        HStack {
            if isUserMessage {
                Spacer()
                
                // User message with light purple background and no border
                Text(message)
                    .font(.system(size: 18))
                    .padding(12)
                    .background(Color(red: 242/255, green: 243/255, blue: 255/255))
                    .cornerRadius(16)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
            } else {
                // Coach message as plain text
                Text(message)
                    .font(.system(size: 18))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                
                Spacer()
            }
        }
    }
}

struct ChatFlowView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @State private var userInput = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppTitleView()
                
                ZStack(alignment: .bottom) {
                    // Main content area
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(viewModel.messages.enumerated()), id: \.offset) { index, message in
                                    ChatMessageView(
                                        message: message,
                                        isUserMessage: index % 2 == 1
                                    )
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
                        // Quick prompts
                        if !viewModel.quickPrompts.isEmpty {
                            VStack(alignment: .trailing, spacing: 8) {
                                ForEach(viewModel.quickPrompts, id: \.self) { prompt in
                                    Button(action: {
                                        userInput = prompt
                                        sendMessage()
                                    }) {
                                        Text(prompt)
                                            .font(.system(size: 18))
                                            .padding(12)
                                            .background(Color(red: 245/255, green: 245/255, blue: 245/255))
                                            .cornerRadius(16)
                                            .padding(.horizontal, 4)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                        
                        // Input area
                        HStack(alignment: .bottom, spacing: 8) {
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
