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
    @Published var quickPrompts: [String] = []
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
            
            // Check if user wants to start a daily check-in
            if text.lowercased() == "daily check-in" && flowMode != .dailyCheckIn {
                startDailyCheckIn()
                return
            }
        }
        
        if flowMode == .dailyCheckIn {
            // End check-in after receiving the response
            endCheckIn()
        } else {
            callLLM()
        }
    }
    
    // MARK: Daily Check-In handling
    func startDailyCheckIn() {
        flowMode = .dailyCheckIn
        let initialMessage = "How did today go overall?"
        messages.append(initialMessage)
        conversationHistory.append(ChatMessage(role: "assistant", content: initialMessage))
        
        // Set quick prompts for the first question
        quickPrompts = [
            "😌️ Followed plan — feeling good",
            "😐 Mixed — some good, some off",
            "🚫 Not great — fell into old habits"
        ]
    }
    
    private func endCheckIn() {
        flowMode = .normal
        let newCheckIn = DailyCheckIn(
            id: UUID(),
            date: Date(),
            answers: [
                CheckInAnswer(
                    question: "How did today go overall?",
                    answer: messages.last ?? "",
                    coachFeedback: nil
                )
            ]
        )
        StorageService.shared.saveCheckIn(newCheckIn)
        quickPrompts = []
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
