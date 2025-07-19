//
//  StorageService.swift
//  SwitchUp
//
//  Created by Paulo André on 12.07.25.
//

import Foundation

class StorageService {
    static let shared = StorageService()
    private init() {}
    
    private func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // MARK: - Goal
    private func goalFileURL() -> URL {
        documentsDirectory().appendingPathComponent("goal.json")
    }
    
    func saveGoal(_ goal: Goal) {
        do {
            let data = try JSONEncoder().encode(goal)
            try data.write(to: goalFileURL())
            print("goal saved successfully.")
        } catch {
            print("Error saving goal: \(error)")
        }
    }
    
    func loadGoal() -> Goal? {
        do {
            let data = try Data(contentsOf: goalFileURL())
            return try JSONDecoder().decode(Goal.self, from: data)
        } catch {
            if (error as NSError).code == NSFileReadNoSuchFileError {
                print("goal.json not found — likely first launch.")
            } else {
                print("Error loading goal:", error)
            }
            return nil
        }
    }
    
    // MARK: - Strategy
    private func strategyFileURL() -> URL {
        documentsDirectory().appendingPathComponent("strategy.json")
    }
    
    func saveStrategy(_ strategy: Strategy) {
        do {
            let data = try JSONEncoder().encode(strategy)
            try data.write(to: strategyFileURL())
        } catch {
            print("Error saving strategy: \(error)")
        }
    }
    
    func loadStrategy() -> Strategy? {
        do {
            let data = try Data(contentsOf: strategyFileURL())
            return try JSONDecoder().decode(Strategy.self, from: data)
        } catch {
            if (error as NSError).code == NSFileReadNoSuchFileError {
                print("strategy.json not found — likely first launch.")
            } else {
                print("Error loading strategy:", error)
            }
            return nil
        }
    }
    
    // MARK: - WeeklyPlan
    private func weeklyPlanFileURL() -> URL {
        documentsDirectory().appendingPathComponent("weeklyPlan.json")
    }
    
    func saveWeeklyPlan(_ plan: WeeklyPlan) {
        do {
            let data = try JSONEncoder().encode(plan)
            try data.write(to: weeklyPlanFileURL())
        } catch {
            print("Error saving weekly plan: \(error)")
        }
    }
    
    func loadWeeklyPlan() -> WeeklyPlan? {
        do {
            let data = try Data(contentsOf: weeklyPlanFileURL())
            return try JSONDecoder().decode(WeeklyPlan.self, from: data)
        } catch {
            if (error as NSError).code == NSFileReadNoSuchFileError {
                print("weeklyPlan.json not found — likely first launch.")
            } else {
                print("Error loading weekly plan:", error)
            }
            return nil
        }
    }
    
    // MARK: - Daily Check-Ins
    func saveCheckIn(_ checkIn: DailyCheckIn) {
        var existing = loadCheckIns()
        existing.append(checkIn)
        saveCheckIns(existing)
    }

    func loadCheckIns() -> [DailyCheckIn] {
        guard let url = checkInsFileURL(),
              let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([DailyCheckIn].self, from: data)) ?? []
    }

    private func saveCheckIns(_ checkIns: [DailyCheckIn]) {
        guard let url = checkInsFileURL() else { return }
        try? JSONEncoder().encode(checkIns).write(to: url)
    }

    private func checkInsFileURL() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("dailyCheckIns.json")
    }

}
