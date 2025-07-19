//
//  ChatMessage.swift
//  SwitchUp
//
//  Created by Paulo André on 12.07.25.
//

import Foundation

struct ChatMessage: Codable {
    let role: String  // "user" or "assistant" or "system"
    let content: String
}
