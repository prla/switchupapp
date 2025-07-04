import SwiftUI

struct Message: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let isCommitPrompt: Bool
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
}

struct AICoachView: View {
    @EnvironmentObject var userProfile: UserProfile
    @State private var messageText = ""
    @State private var messages: [Message] = [
        Message(content: "What brings you to SwitchUp today?", isUser: false, isCommitPrompt: false)
    ]
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var cachedExperimentText: String?
    
    @FocusState private var isTextFieldFocused: Bool
    
    private let openAIService = OpenAIService()
   
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                            }
                            .padding(.vertical, 16)

                            if let lastMessage = messages.last, lastMessage.isCommitPrompt {
                                Button("Yes, I'm in") {
                                    commitExperiment()    
                                }
                                .buttonStyle(.bordered)
                                .tint(.blue)    
                            }
                        }
                        .padding(.horizontal)
                    }
                    .onChange(of: messages.count) {
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input area
                VStack(spacing: 0) {
                    HStack(alignment: .bottom) {
                        TextField("Message AI Coach...", text: $messageText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(1...5)
                            .submitLabel(.send)
                            .focused($isTextFieldFocused)
                            .onSubmit(sendMessage)
                        
                        Button(action: sendMessage) {
                            if isLoading {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.blue)
                            }
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                    }
                    .padding()
                }
            }
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    private func sendMessage() {
        let userMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMessage.isEmpty else { return }

        // Add user message to conversation
        let newUserMessage = Message(content: userMessage, isUser: true, isCommitPrompt: false)
        messages.append(newUserMessage)
        messageText = ""
                
        // Show loading indicator
        isLoading = true
        
        Task {
            do {
                let response = try await openAIService.sendMessage(message: userMessage)

                let commitPromptToken = "[[COMMIT_PROMPT]]"
                let experimentToken = "[[EXPERIMENT]]"

                let isCommitPrompt = response.contains(commitPromptToken)
                let hasExperiment = response.contains(experimentToken)

                let cleanedResponse = response
                    .replacingOccurrences(of: commitPromptToken, with: "")
                    .replacingOccurrences(of: experimentToken, with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if isCommitPrompt && hasExperiment {
                    cachedExperimentText = response
                }
                
                // Update UI on main thread
                await MainActor.run {
                    messages.append(Message(content: cleanedResponse, isUser: false, isCommitPrompt: isCommitPrompt))
                    isLoading = false
                }
                                
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
            isTextFieldFocused = true
        }
    }

    private func commitExperiment() {
        guard let raw = cachedExperimentText else { return }

        guard let titleLine = raw.split(separator: "\n").first(where: { $0.starts(with: "Title:") }) else { return }
        let title = titleLine.replacingOccurrences(of: "Title:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)

        let parts = raw
            .components(separatedBy: "\n")
            .filter { $0.starts(with: "- ") }
            .map { $0.replacingOccurrences(of: "- ", with: "").trimmingCharacters(in: .whitespacesAndNewlines) }

        let experiment = Experiment(
            title: title,
            parts: parts,
            startDate: Date(),
            checkInDates: []
        )
        
        userProfile.activeExperiment = experiment

        messages.append(Message(content: "Awesome. You’re all set. I’ll check in with you daily.", isUser: false, isCommitPrompt: false))

        cachedExperimentText = nil
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                Text(message.content)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(ChatBubble(isFromCurrentUser: true))
            } else {
                Text(message.content)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .clipShape(ChatBubble(isFromCurrentUser: false))
                Spacer()
            }
        }
        .padding(.horizontal, 8)
    }
}

struct ChatBubble: Shape {
    var isFromCurrentUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                              byRoundingCorners: [.topLeft, .topRight, isFromCurrentUser ? .bottomLeft : .bottomRight],
                              cornerRadii: CGSize(width: 16, height: 16))
        return Path(path.cgPath)
    }
}

#Preview {
    AICoachView()
}
