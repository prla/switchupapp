//
//  WeeklyPlan.swift
//  SwitchUp
//
//  Created by Paulo André on 12.07.25.
//

import Foundation

struct WeeklyPlan: Codable {
    var startDate: Date?
    var days: [DayPlan]
}

struct DayPlan: Codable {
    var dayNumber: Int
    var focus: String
    var notes: String?
}
