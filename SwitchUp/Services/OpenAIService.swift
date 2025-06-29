import Foundation

class OpenAIService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private var conversationHistory: [[String: String]] = []
        
    init() {
        self.apiKey = Config.openAIAPIKey
        // Initialize with system prompt
        conversationHistory.append(["role": "system", "content": """
        You are a thoughtful, emotionally intelligent personal coach helping a user begin their SwitchUp journey. Your role is to help them clarify a meaningful goal, reflect on how they want to feel, and guide them toward creating a flexible 7-day experiment to explore what helps.

        When you sense the user is ready to commit to an experiment (they've expressed clear intent or commitment to start), play the experiment back to the user in a concise way.

        Look for signs of commitment like:
        - Expressing readiness to start
        - Agreeing to try something new
        - Showing enthusiasm about beginning
        - Using future-oriented language about starting
        - Confirming they want to proceed

        Your tone is warm, curious, and collaborative. Think more like a coach or therapist than a productivity guru.

        Your goals are:
        - Help the user feel heard and understood
        - Develop a shared sense of purpose or change they want to explore
        - Guide them toward a concrete, flexible 7-day experiment that reflects their reality
        - Recognize when they're ready to commit and present the experiment details
        
        Use the user's language, allow messiness, and avoid sounding like a health app.
        """])
    }
    
    func sendMessage(message: String) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // Add user message to history
        conversationHistory.append(["role": "user", "content": message])
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Always include the full conversation history
        let parameters: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": conversationHistory,
            "temperature": 0.7
        ]
                
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        
        conversationHistory.append(["role": "assistant", "content": content])
        return content
    }
    
    func resetConversation() {
        conversationHistory = []
    }
}
