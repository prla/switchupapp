//
//  HealthService.swift
//  SwitchUp
//
//  Created by Paulo André on 13.07.25.
//

import HealthKit

class HealthService {
    static let shared = HealthService()
    private let healthStore = HKHealthStore()

    // Types you want to read
    private let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    private let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    private let rhrType = HKObjectType.quantityType(forIdentifier: .restingHeartRate)!
    
    // Call this to ensure you have permission — prompts only if needed
    func ensureAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        // Check current authorization status for all needed types
        let sleepStatus = healthStore.authorizationStatus(for: sleepType)
        let hrvStatus = healthStore.authorizationStatus(for: hrvType)
        let rhrStatus = healthStore.authorizationStatus(for: rhrType)

        // If all are authorized (sharingStatus = .sharingAuthorized), no need to request again
        if sleepStatus == .sharingAuthorized &&
           hrvStatus == .sharingAuthorized &&
           rhrStatus == .sharingAuthorized {
            completion(true, nil)
            return
        }

        // Otherwise, request authorization
        let readTypes: Set = [sleepType, hrvType, rhrType]
        healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
            completion(success, error)
        }
    }

    // Request permissions
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        let readTypes: Set = [sleepType, hrvType, rhrType]
        healthStore.requestAuthorization(toShare: [], read: readTypes, completion: completion)
    }

    // Fetch recent sleep samples
    func fetchLatestSleepData(completion: @escaping (TimeInterval?) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date(), options: [])

        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 0, sortDescriptors: nil) { _, samples, error in
            guard error == nil, let samples = samples as? [HKCategorySample] else {
                completion(nil)
                return
            }

            // iOS 16+ asleep states set
            let asleepValues: Set<Int> = [
                HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                HKCategoryValueSleepAnalysis.asleepREM.rawValue
            ]

            // Sum durations of all asleep phases
            let totalSleep = samples
                .filter { asleepValues.contains($0.value) }
                .reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }

            completion(totalSleep)
        }

        healthStore.execute(query)
    }

    // Fetch latest HRV
    func fetchLatestHRV(completion: @escaping (HKQuantitySample?, Error?) -> Void) {
        let query = HKSampleQuery(sampleType: hrvType, predicate: nil, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, samples, error in
            completion(samples?.first as? HKQuantitySample, error)
        }
        healthStore.execute(query)
    }

    // Fetch latest Resting Heart Rate
    func fetchLatestRHR(completion: @escaping (HKQuantitySample?, Error?) -> Void) {
        let query = HKSampleQuery(sampleType: rhrType, predicate: nil, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, samples, error in
            completion(samples?.first as? HKQuantitySample, error)
        }
        healthStore.execute(query)
    }
    
    // Fetch all three data points and combine results
    func fetchBasicHealthSummary(completion: @escaping (String) -> Void) {
        var sleepSummary = "no sleep data"
        var rhrSummary = "no resting heart rate data"
        var hrvSummary = "no HRV data"

        let group = DispatchGroup()

        group.enter()
        fetchLatestSleepData { totalSleepSeconds in
            if let totalSleep = totalSleepSeconds, totalSleep > 0 {
                let hours = Int(totalSleep / 3600)
                sleepSummary = "last night you slept approximately \(hours) hours"
            }
            group.leave()
        }

        group.enter()
        fetchLatestRHR { sample, _ in
            if let sample = sample {
                let bpm = Int(sample.quantity.doubleValue(for: HKUnit(from: "count/min")))
                rhrSummary = "your resting heart rate yesterday was \(bpm) bpm"
            }
            group.leave()
        }

        group.enter()
        fetchLatestHRV { sample, _ in
            if let sample = sample {
                let ms = Int(sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)))
                hrvSummary = "your last HRV measurement was \(ms) ms"
            }
            group.leave()
        }

        group.notify(queue: .main) {
            let summary = "\(sleepSummary). \(rhrSummary). \(hrvSummary)."
            completion(summary)
        }
    }
}
