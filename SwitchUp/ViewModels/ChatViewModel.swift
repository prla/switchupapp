//
//  ChatViewModel.swift
//  SwitchUp
//
//  Created by Paulo André on 12.07.25.
//

import Foundation

enum FlowMode {
    case normal
    case dailyCheckIn
}

struct DailyCheckIn: Codable, Identifiable {
    let id: UUID
    let date: Date
    let answers: [CheckInAnswer]
}

struct CheckInAnswer: Codable {
    let question: String
    let answer: String
    let coachFeedback: String?
}

class ChatViewModel: ObservableObject {
    @Published var messages: [String] = []
    private var conversationHistory: [ChatMessage] = []
    private var flowMode: FlowMode = .normal
    
    // Store check-in questions (optional: you can also get these dynamically from LLM)
    private var checkInQuestions: [String] = []
    private var currentQuestionIndex: Int = 0
    private var currentCheckInAnswers: [CheckInAnswer] = []
        
    func startConversation(_ initialMessage: String) {
        guard messages.isEmpty else { return }
        print("starting conversation")
        messages = [initialMessage]
        conversationHistory = [ChatMessage(role: "assistant", content: initialMessage)]
    }
    
    func sendUserMessage(_ text: String) {
        if !text.isEmpty {
            messages.append(text)
            conversationHistory.append(ChatMessage(role: "user", content: text))
        }
        
        if flowMode == .dailyCheckIn {
            handleCheckInAnswer(text)
        } else {
            callLLM()
        }
    }
    
    // MARK: Daily Check-In handling
    func startDailyCheckIn() {
        flowMode = .dailyCheckIn
        currentQuestionIndex = 0
        messages.append("Starting your daily check-in!")
        conversationHistory.append(ChatMessage(role: "assistant", content: "Starting your daily check-in!"))
        
        let prompt = """
        You are a helpful health coach. Generate 3 concise daily check-in questions for the user to track their progress on their goal and strategy. Provide only the questions as a JSON array, like:
        ["Did you follow your plan today?", "How was your energy level?", "Any wins or obstacles?"]
        """
        
        let systemMessage = ChatMessage(role: "system", content: prompt)
        LLMService.shared.sendMessage(conversation: [systemMessage]) { [weak self] result in
            switch result {
            case .success(let response):
                if let questions = self?.extractQuestions(from: response) {
                    DispatchQueue.main.async {
                        self?.checkInQuestions = questions
                        self?.askNextCheckInQuestion()
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.messages.append("Error generating check-in questions: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func extractQuestions(from response: String) -> [String]? {
        let data = response.data(using: .utf8) ?? Data()
        return try? JSONDecoder().decode([String].self, from: data)
    }
    
    func askNextCheckInQuestion() {
        guard currentQuestionIndex < checkInQuestions.count else {
            endCheckIn()
            return
        }
        
        let question = checkInQuestions[currentQuestionIndex]
        messages.append(question)
        conversationHistory.append(ChatMessage(role: "assistant", content: question))
    }
    
    private func handleCheckInAnswer(_ answer: String) {
        let question = checkInQuestions[currentQuestionIndex]
        currentQuestionIndex += 1

        let feedbackPrompt = """
        The user answered the daily check-in question: "\(question)" with: "\(answer)".
        Provide a concise, encouraging coaching response.
        """

        let systemMessage = ChatMessage(role: "system", content: feedbackPrompt)
        LLMService.shared.sendMessage(conversation: [systemMessage]) { [weak self] result in
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    self?.appendBotMessage(response)
                    self?.currentCheckInAnswers.append(CheckInAnswer(question: question, answer: answer, coachFeedback: response))
                    self?.askNextCheckInQuestion()
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.appendBotMessage("Error generating coaching feedback: \(error.localizedDescription)")
                    self?.currentCheckInAnswers.append(CheckInAnswer(question: question, answer: answer, coachFeedback: nil))
                    self?.askNextCheckInQuestion()
                }
            }
        }
    }

    private func appendBotMessage(_ text: String) {
        messages.append(text)
        conversationHistory.append(ChatMessage(role: "assistant", content: text))
    }

    private func endCheckIn() {
        flowMode = .normal
        appendBotMessage("Thanks for checking in! Keep up the great work.")
        
        let newCheckIn = DailyCheckIn(id: UUID(), date: Date(), answers: currentCheckInAnswers)
        StorageService.shared.saveCheckIn(newCheckIn)
        currentCheckInAnswers.removeAll()
    }



    
    // MARK: LLM-related functions
    private func callLLM() {
        // Prepare messages with the system prompt first
        let systemMessage = ChatMessage(role: "system", content: systemPrompt)
        var messagesToSend = [systemMessage]
        messagesToSend.append(contentsOf: conversationHistory)
        
        LLMService.shared.sendMessage(conversation: messagesToSend) { [weak self] result in
            switch result {
            case .success(let responseText):
                DispatchQueue.main.async {
                    self?.handleLLMResponse(responseText)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.messages.append("Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func handleLLMResponse(_ responseText: String) {
        // Extract JSON snippet and get cleaned text without JSON
        let jsonString = JSONExtractionService.shared.extractJSONSnippet(from: responseText)
        let cleanedText = JSONExtractionService.shared.removeJSONSnippet(from: responseText)
        
        // Append only the cleaned conversational text to chat
        if !cleanedText.isEmpty {
            messages.append(cleanedText)
            conversationHistory.append(ChatMessage(role: "assistant", content: cleanedText))
        }
        
        // Parse and save structured data if JSON present
        if let jsonString = jsonString,
           let parsedData = JSONExtractionService.shared.parse(jsonString: jsonString) {
            
            let existingGoal = StorageService.shared.loadGoal()
            let existingStrategy = StorageService.shared.loadStrategy()
            let existingPlan = StorageService.shared.loadWeeklyPlan()
            
            let (mergedGoal, mergedStrategy, mergedPlan) = JSONExtractionService.shared.merge(
                parsed: parsedData,
                existingGoal: existingGoal,
                existingStrategy: existingStrategy,
                existingPlan: existingPlan
            )
            
            if let goal = mergedGoal {
                print("Saving goal: \(goal.text)")
                StorageService.shared.saveGoal(goal)
            }
            if let strategy = mergedStrategy {
                StorageService.shared.saveStrategy(strategy)
            }
            if let plan = mergedPlan {
                StorageService.shared.saveWeeklyPlan(plan)
            }
        }
    }
}
