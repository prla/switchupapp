//
//  ProfileView.swift
//  SwitchUp
//
//  Created by Paulo André on 13.07.25.
//

import SwiftUI

struct ProfileView: View {
    @State private var goal: Goal?
    @State private var strategy: Strategy?
    @State private var weeklyPlan: WeeklyPlan?
    @State private var checkIns: [DailyCheckIn] = []

    var body: some View {
        NavigationStack {
            List {
                Section("Goal") {
                    if let goal = goal {
                        Text(goal.text)
                            .font(.headline)
                        Text(goal.why)
                            .font(.subheadline)
                    } else {
                        Text("No goal set yet.")
                            .foregroundColor(.secondary)
                    }
                }

                Section("Strategy") {
                    if let strategy = strategy {
                        Text("Daily structure: \(strategy.dailyStructure)")
                        Text("Food preferences: \(strategy.foodPreferences)")
                        Text("Movement: \(strategy.movement)")
                        Text("Recovery: \(strategy.recovery)")
                    } else {
                        Text("No strategy set yet.")
                            .foregroundColor(.secondary)
                    }
                }

                Section("Weekly Plan") {
                    if let plan = weeklyPlan {
                        ForEach(plan.days, id: \.dayNumber) { day in
                            VStack(alignment: .leading) {
                                Text("Day \(day.dayNumber): \(day.focus)")
                                    .bold()
                                if let notes = day.notes {
                                    Text(notes)
                                        .italic()
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } else {
                        Text("No weekly plan set yet.")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Past Check-Ins") {
                    if checkIns.isEmpty {
                        Text("No check-ins recorded yet.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(checkIns) { checkIn in
                            DisclosureGroup("\(formattedDate(checkIn.date))") {
                                ForEach(checkIn.answers, id: \.question) { answer in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Q: \(answer.question)")
                                            .fontWeight(.semibold)
                                        Text("A: \(answer.answer)")
                                        if let feedback = answer.coachFeedback {
                                            Text("Coach: \(feedback)")
                                                .italic()
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .listStyle(.insetGrouped)
            .task {
                loadData()
            }
        }
    }
    
    func loadData() {
        goal = StorageService.shared.loadGoal()
        strategy = StorageService.shared.loadStrategy()
        weeklyPlan = StorageService.shared.loadWeeklyPlan()
        checkIns = StorageService.shared.loadCheckIns()
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

