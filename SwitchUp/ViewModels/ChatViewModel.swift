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
    private var currentCheckInAnswers: [String] = []
    
    private enum CheckInState {
        case notStarted
        case inProgress(questionCount: Int, context: String)
        case completed
    }
    
    private var checkInState: CheckInState = .notStarted
    private var maxCheckInQuestions = 3 // Will ask 3 questions
    
    // Store generated follow-up questions
    private var generatedFollowUpQuestions: [String] = []
    
    func startConversation(_ initialMessage: String) {
        guard messages.isEmpty else { return }
        print("starting conversation")
        messages = [initialMessage]
        conversationHistory = [ChatMessage(role: "assistant", content: initialMessage)]
    }
    
    func sendUserMessage(_ text: String) {
        guard !text.isEmpty else { return }
        
        // Add user message to chat
        messages.append(text)
        conversationHistory.append(ChatMessage(role: "user", content: text))
        
        // Check for special commands
        if text.lowercased() == "sample plan" {
            generateSamplePlan()
            return
        }
        
        // Handle check-in flow
        if flowMode == .dailyCheckIn {
            processCheckInAnswer(text)
        } else if text.lowercased() == "daily check-in" {
            startDailyCheckIn()
        } else {
            callLLM()
        }
    }
    
    // MARK: Daily Check-In handling
    func startDailyCheckIn() {
        flowMode = .dailyCheckIn
        checkInState = .inProgress(questionCount: 0, context: "")
        currentCheckInAnswers = []
        
        // Simple first question
        let firstQuestion = "How was today?"
        
        // Quick response options
        quickPrompts = [
            "✅ Followed the plan",
            "🔀 Mixed",
            "❌ Fell off"
        ]
        
        messages.append(firstQuestion)
        conversationHistory.append(ChatMessage(role: "assistant", content: firstQuestion))
    }
    
    private func processCheckInAnswer(_ answer: String) {
        // Add the answer to our tracking array
        currentCheckInAnswers.append(answer)
        
        // Clear quick responses after first answer
        if currentCheckInAnswers.count == 1 {
            quickPrompts = []
        }
        
        // If we've processed all follow-up questions, end the check-in
        if currentCheckInAnswers.count > generatedFollowUpQuestions.count + 1 {
            endDailyCheckIn()
            return
        }
        
        // If we need more questions, generate them
        if currentCheckInAnswers.count == 1 {
            generateFollowUpQuestions()
        } else {
            // Ask the next follow-up question
            let nextQuestionIndex = currentCheckInAnswers.count - 2 // -1 for initial answer, -1 for 0-based index
            if nextQuestionIndex < generatedFollowUpQuestions.count {
                let nextQuestion = generatedFollowUpQuestions[nextQuestionIndex]
                messages.append(nextQuestion)
                conversationHistory.append(ChatMessage(role: "assistant", content: nextQuestion))
            } else {
                endDailyCheckIn()
            }
        }
    }
    
    private func generateFollowUpQuestions() {
        Task {
            let goal = StorageService.shared.loadGoal()
            let strategy = StorageService.shared.loadStrategy()
            let weeklyPlan = StorageService.shared.loadWeeklyPlan()
            
            // Get today's focus from weekly plan if available
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
            let dayNumber = calendar.dateComponents([.day], from: startOfWeek, to: today).day! + 1
            let todayFocus = weeklyPlan?.days.first { $0.dayNumber == dayNumber }
            
            // Prepare context for LLM with all previous answers
            let context = """
            User's Goal:
            - What: \(goal?.text ?? "Not set")
            - Why it matters: \(goal?.why ?? "Not specified")
            
            Their Strategy:
            - Daily Structure: \(strategy?.dailyStructure ?? "Not specified")
            - Food Preferences: \(strategy?.foodPreferences ?? "Not specified")
            - Movement Plan: \(strategy?.movement ?? "Not specified")
            - Recovery Approach: \(strategy?.recovery ?? "Not specified")
            
            Today's Focus: \(todayFocus?.focus ?? "No specific focus set")
            
            User's initial response: "\(currentCheckInAnswers.first ?? "")"
            
            Generate 2-3 specific follow-up questions that:
            1. Are directly relevant to the user's goals and today's focus
            2. Help the user reflect on their day and progress
            3. Are concise (1 sentence each)
            4. Use a warm, supportive tone
            5. Vary in focus (e.g., one about challenges, one about wins, one about learning)
            
            Format your response with each question on a new line, prefixed with "Q: "
            """
            
            let systemMessage = ChatMessage(role: "system", content: "You are a thoughtful coach helping users reflect on their day in the context of their health and wellness goals.")
            let userMessage = ChatMessage(role: "user", content: context)
            
            LLMService.shared.sendMessage(conversation: [systemMessage, userMessage]) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        // Parse the response to extract questions
                        let questions = response.components(separatedBy: "\n")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                            .filter { $0.hasPrefix("Q: ") }
                            .map { String($0.dropFirst(3).trimmingCharacters(in: .whitespaces)) }
                            .filter { !$0.isEmpty }
                        
                        guard !questions.isEmpty else {
                            self.useFallbackQuestions()
                            return
                        }
                        
                        self.generatedFollowUpQuestions = questions
                        
                        // Ask the first follow-up question
                        if let firstQuestion = questions.first {
                            self.messages.append(firstQuestion)
                            self.conversationHistory.append(ChatMessage(role: "assistant", content: firstQuestion))
                        } else {
                            self.useFallbackQuestions()
                        }
                        
                    case .failure(_):
                        self.useFallbackQuestions()
                    }
                }
            }
        }
    }
    
    private func useFallbackQuestions() {
        // Fallback questions if LLM fails or returns no questions
        generatedFollowUpQuestions = [
            "What was one small win you had today related to your goals?",
            "What's one thing you'd like to do differently tomorrow?",
            "How can you set yourself up for success with your goals tomorrow?"
        ]
        
        if let firstQuestion = generatedFollowUpQuestions.first {
            messages.append(firstQuestion)
            conversationHistory.append(ChatMessage(role: "assistant", content: firstQuestion))
        } else {
            endDailyCheckIn()
        }
    }
    
    private func endDailyCheckIn() {
        // Clear any state
        generatedFollowUpQuestions = []
        
        // Add a closing message
        let closingMessage = "Thanks for checking in! I'll see you tomorrow for another update."
        messages.append(closingMessage)
        conversationHistory.append(ChatMessage(role: "assistant", content: closingMessage))
        
        // Reset the check-in state
        checkInState = .notStarted
        flowMode = .normal
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
    
    private func generateSamplePlan() {
        // Create sample goal
        let sampleGoal = Goal(
            text: "Improve overall health and energy levels",
            why: "To have more energy for my family and be more productive at work",
            createdAt: Date()
        )
        
        // Create sample strategy
        let sampleStrategy = Strategy(
            dailyStructure: "Wake up at 6:30 AM, work from 9 AM to 5 PM with a 1-hour lunch break, wind down after 9 PM",
            foodPreferences: "Mediterranean diet with plenty of vegetables, lean proteins, and healthy fats. Limit processed foods and added sugars.",
            movement: "30-minute morning walk, 3 strength training sessions per week, and stretching before bed",
            recovery: "7-8 hours of sleep, 10-minute meditation in the morning, and digital detox after 8 PM"
        )
        
        // Create sample weekly plan
        let days = [
            DayPlan(dayNumber: 1, focus: "Hydration and movement", notes: "Start with a morning walk and track water intake"),
            DayPlan(dayNumber: 2, focus: "Meal prep", notes: "Prepare healthy meals for the week"),
            DayPlan(dayNumber: 3, focus: "Strength training", notes: "Focus on form and consistency"),
            DayPlan(dayNumber: 4, focus: "Mindfulness", notes: "Practice 10 minutes of meditation"),
            DayPlan(dayNumber: 5, focus: "Social connection", notes: "Plan a healthy meal with friends or family"),
            DayPlan(dayNumber: 6, focus: "Active recovery", notes: "Gentle yoga or stretching"),
            DayPlan(dayNumber: 7, focus: "Reflection", notes: "Review the week and plan for the next one")
        ]
        let sampleWeeklyPlan = WeeklyPlan(startDate: Date(), days: days)
        
        // Save all samples
        StorageService.shared.saveGoal(sampleGoal)
        StorageService.shared.saveStrategy(sampleStrategy)
        StorageService.shared.saveWeeklyPlan(sampleWeeklyPlan)
        
        // Notify the user
        let successMessage = "✅ Sample plan generated successfully! You can now view your new goal, strategy, and weekly plan."
        messages.append(successMessage)
        conversationHistory.append(ChatMessage(role: "assistant", content: successMessage))
    }
}
