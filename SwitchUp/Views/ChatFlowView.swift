import SwiftUI

struct ChatFlowView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var userInput = ""

    var body: some View {
        VStack {
            ScrollView {
                ForEach(viewModel.messages, id: \.self) { msg in
                    Text(msg)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            HStack {
                TextField("Type your message...", text: $userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Send") {
                    let trimmed = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    viewModel.sendUserMessage(trimmed)
                    userInput = ""
                }
            }
            .padding()
        }
        .padding()
    }
}
