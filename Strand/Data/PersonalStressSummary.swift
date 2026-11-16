import Foundation
import WhoopStore

/// Both personal screens resolve the selected day, never the model's prior-day carry.
enum PersonalStressSummary {
    static func value(day: String, days: [DailyMetric], stored: [(day: String, value: Double)]) -> Double? {
        if let point = stored.last(where: { $0.day == day && $0.value.isFinite && (0...3).contains($0.value) }) {
            return point.value
        }
        let history = days.filter { $0.day <= day }.sorted { $0.day < $1.day }
        guard let selected = history.last, selected.day == day,
              selected.restingHr != nil || selected.avgHrv != nil else { return nil }
        let valid = stored.filter { $0.day <= day && $0.value.isFinite && (0...3).contains($0.value) }
        return StressModel(days: history, stored: valid)?.score
    }
}
