import Foundation

enum SampleDataGenerator {
    static func generateSampleGoal() -> Goal {
        return Goal(
            text: "Improve overall health and energy levels",
            why: "To have more energy for my family and be more productive at work",
            createdAt: Date()
        )
    }
    
    // Add other sample data generation methods here
    
    static func generateSamplePlan() -> (Goal, Strategy, WeeklyPlan) {
        let goal = generateSampleGoal()
        // Add strategy and plan generation
        let strategy = Strategy(
            dailyStructure: "Sample daily structure",
            foodPreferences: "Sample food preferences",
            movement: "Sample movement plan",
            recovery: "Sample recovery plan"
        )
        let plan = WeeklyPlan(
            startDate: Date(),
            days: []
        )
        return (goal, strategy, plan)
    }
}
