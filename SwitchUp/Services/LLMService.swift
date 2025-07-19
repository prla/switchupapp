//
//  LLMService.swift
//  SwitchUp
//
//  Created by Paulo André on 12.07.25.
//

import Foundation

let systemPrompt = """
You are SwitchUp, an AI coach helping users clarify their goals, create strategies, and build weekly plans.

- Guide the user conversationally, asking one question or giving one suggestion at a time.
- When you have new or updated data about the user’s goal, strategy, or weekly plan, output a json block like:

```json
{
  "goal": {
    "text": "Get fitter",
    "why": "Have more energy"
  },
  "strategy": {
    "dailyStructure": "Wake up at 7am, work 9-5",
    "foodPreferences": "Low carb, vegetarian",
    "movement": "Cycling 3x a week",
    "recovery": "Sleep 8 hours nightly"
  },
  "weeklyPlan": {
    "days": [
      {"dayNumber": 1, "focus": "Light cardio and hydration"},
      {"dayNumber": 2, "focus": "Balanced meals and 30-minute walk"}
    ]
  }
}
```
- Always only output one JSON snippet per message.
- If you ask a question, place it before or after the JSON snippet.
- If there is no new data to update, respond conversationally without JSON.

Start by greeting the user and asking about their main goal.
"""

class LLMService {
    static let shared = LLMService()
    private init() {
        guard apiKey != nil else {
            print("Failed to load API key")
            return
        }
    }
    
    private var apiKey: String? {
        guard
            let path = Bundle.main.path(forResource: "Config", ofType: "plist")
        else {
            print("Config.plist not found in bundle")
            return nil
        }
        
        guard
            let dict = NSDictionary(contentsOfFile: path),
            let key = dict["OpenAIAPIKey"] as? String, !key.isEmpty
        else {
            print("OpenAIAPIKey missing or empty in Config.plist")
            return nil
        }
        return key
    }
        
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    
    func sendMessage(conversation: [ChatMessage], completion: @escaping (Result<String, Error>) -> Void) {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            completion(.failure(NSError(domain: "LLMService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing OpenAI API Key"])))
            return
        }
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(String(describing: apiKey))", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "model": "gpt-4.1-mini",
            "messages": conversation.map { ["role": $0.role, "content": $0.content] },
            "temperature": 0.7
        ] as [String : Any]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: 0)))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(.success(content))
                } else {
                    completion(.failure(NSError(domain: "InvalidResponse", code: 0)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}
