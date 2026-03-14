import Foundation
import HealthKit

@MainActor
@Observable
final class HealthKitService {
    var isAuthorized = false

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private let healthStore = HKHealthStore()
    private let workoutType = HKObjectType.workoutType()

    func requestAuthorization() async {
        guard isAvailable else { return }
        do {
            try await healthStore.requestAuthorization(toShare: [workoutType], read: [])
            checkAuthorizationStatus()
        } catch {
            print("HealthKit authorization error: \(error)")
        }
    }

    func checkAuthorizationStatus() {
        guard isAvailable else {
            isAuthorized = false
            return
        }
        isAuthorized = healthStore.authorizationStatus(for: workoutType) == .sharingAuthorized
    }

    func saveWorkout(startDate: Date, endDate: Date, waterTempCelsius: Double?) async throws {
        guard isAvailable, isAuthorized else { return }

        let config = HKWorkoutConfiguration()
        config.activityType = .other

        var metadata: [String: Any] = [
            HKMetadataKeyWorkoutBrandName: "Cold Plunge"
        ]
        if let temp = waterTempCelsius {
            metadata["WaterTemperatureCelsius"] = temp
        }

        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: config, device: .local())
        try await builder.beginCollection(at: startDate)
        try await builder.addMetadata(metadata)
        try await builder.endCollection(at: endDate)
        try await builder.finishWorkout()
    }
}
