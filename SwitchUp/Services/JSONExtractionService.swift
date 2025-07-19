//
//  JSONExtractionService.swift
//  SwitchUp
//
//  Created by Paulo André on 12.07.25.
//

import Foundation

struct ParsedData: Codable {
    var goal: Goal?
    var strategy: Strategy?
    var weeklyPlan: WeeklyPlan?
}

class JSONExtractionService {
    static let shared = JSONExtractionService()
    private init() {}
    
    /// Extracts the first JSON snippet wrapped in ```json ... ``` from the LLM response text
    func extractJSONSnippet(from text: String) -> String? {
        let pattern = "```json\\s*([\\s\\S]*?)```"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        
        let range = NSRange(text.startIndex..., in: text)
        if let match = regex.firstMatch(in: text, options: [], range: range),
           let jsonRange = Range(match.range(at: 1), in: text) {
            return String(text[jsonRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return nil
    }
    
    /// Parses extracted JSON string into ParsedData model
    func parse(jsonString: String) -> ParsedData? {
        guard let data = jsonString.data(using: .utf8) else {
            print("Failed to convert JSON string to Data")
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode(ParsedData.self, from: data)
        } catch {
            print("JSON decoding error:", error)
            return nil
        }
    }
    
    /// Merges new parsed data into existing state, prioritizing new values when present
    func merge(parsed: ParsedData, existingGoal: Goal?, existingStrategy: Strategy?, existingPlan: WeeklyPlan?) -> (Goal?, Strategy?, WeeklyPlan?) {
        let mergedGoal = parsed.goal ?? existingGoal
        let mergedStrategy = parsed.strategy ?? existingStrategy
        let mergedPlan = parsed.weeklyPlan ?? existingPlan
        
        return (mergedGoal, mergedStrategy, mergedPlan)
    }
    
    func removeJSONSnippet(from text: String) -> String {
        let pattern = "```json[\\s\\S]*?```"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return text
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
