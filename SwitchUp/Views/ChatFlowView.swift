import SwiftUI

struct ChatFlowView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @State private var userInput = ""

    var body: some View {
        NavigationStack {
            VStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading) {
                            ForEach(viewModel.messages.indices, id: \.self) { index in
                                Text(viewModel.messages[index])
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .id(index)  // Assign unique ID per message
                            }
                        }
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let lastIndex = viewModel.messages.indices.last {
                            withAnimation {
                                proxy.scrollTo(lastIndex, anchor: .bottom)
                            }
                        }
                    }
                }
                
                HStack {
                    ExpandingTextEditor(text: $userInput)
                        .frame(minHeight: 40, maxHeight: 120)

                    Button("Send") {
                        let trimmed = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        viewModel.sendUserMessage(trimmed)
                        userInput = ""
                    }
                }
                .padding()

                Button("Start Daily Check-In") {
                    viewModel.startDailyCheckIn()
                }
                .padding(.top)
            }
            .padding()
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
}

struct ExpandingTextEditor: View {
    @Binding var text: String
    @State private var textViewHeight: CGFloat = 40

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text("Type your message...")
                    .foregroundColor(.gray)
                    .padding(.leading, 5)
                    .padding(.top, 8)
            }
            TextEditor(text: $text)
                .frame(minHeight: 40, maxHeight: min(textViewHeight, 120)) // expand up to 120 pts
                .background(GeometryReader { geo in
                    Color.clear.onAppear {
                        textViewHeight = geo.size.height
                    }.onChange(of: text) { _ in
                        textViewHeight = geo.size.height
                    }
                })
                .padding(4)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5)))
        }
    }
}


