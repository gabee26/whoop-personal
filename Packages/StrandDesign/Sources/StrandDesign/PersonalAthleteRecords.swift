import Foundation

/// Personal iOS journal data, separate from strap storage and physiological scores.
public struct PersonalAthleteCheckIn: Codable, Identifiable {
    public var id: String
    public var energy: Int
    public var fatigue: Int
    public var sleepQuality: Int
    public var soreness: [String: Int]
    public var notes: String
    public init(day: String, energy: Int = 3, fatigue: Int = 3, sleepQuality: Int = 3,
                soreness: [String: Int] = [:], notes: String = "") {
        id = day; self.energy = energy; self.fatigue = fatigue
        self.sleepQuality = sleepQuality; self.soreness = soreness; self.notes = notes
    }
}

/// Planned sessions never contribute to completed perceived load.
public struct PersonalAthleteSession: Codable, Identifiable {
    public var id: UUID
    public var date: Date
    public var kind: String
    public var minutes: Int
    public var completed: Bool
    public var exertion: Int?
    public var notes: String
    public init(id: UUID = UUID(), date: Date = Date(), kind: String = "Guarda-redes",
                minutes: Int = 60, completed: Bool = false, exertion: Int? = nil, notes: String = "") {
        self.id = id; self.date = date; self.kind = kind; self.minutes = minutes
        self.completed = completed; self.exertion = exertion; self.notes = notes
    }
    public var perceivedLoad: Int? {
        guard completed, (1...600).contains(minutes), let exertion, (1...10).contains(exertion) else { return nil }
        return minutes * exertion
    }
}

/// Versioned export envelope; invalid imports must never replace the current journal.
public struct PersonalAthleteArchive: Codable {
    public var version = 1
    public var checkIns: [PersonalAthleteCheckIn] = []
    public var sessions: [PersonalAthleteSession] = []
    public init() {}
    public func validate() throws {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        guard version == 1, checkIns.count <= 50000, sessions.count <= 50000,
              Set(checkIns.map(\.id)).count == checkIns.count,
              Set(sessions.map(\.id)).count == sessions.count else { throw ValidationError.invalid }
        for item in checkIns {
            guard let date = formatter.date(from: item.id), formatter.string(from: date) == item.id,
                  (1...5).contains(item.energy), (1...5).contains(item.fatigue),
                  (1...5).contains(item.sleepQuality), item.notes.count <= 4000,
                  item.soreness.count <= 30,
                  item.soreness.allSatisfy({ !$0.key.isEmpty && $0.key.count <= 80 && (0...10).contains($0.value) })
            else { throw ValidationError.invalid }
        }
        for item in sessions {
            guard item.date.timeIntervalSince1970.isFinite, !item.kind.isEmpty, item.kind.count <= 80,
                  (1...600).contains(item.minutes), item.notes.count <= 4000,
                  item.exertion.map({ (1...10).contains($0) }) ?? true
            else { throw ValidationError.invalid }
        }
    }
    public enum ValidationError: Error { case invalid }
}

/// Descriptive arithmetic only: missing nights stay missing, and surplus is not banked.
public enum PersonalAthleteSummary {
    /// A descriptive baseline, never a readiness classifier. Missing values are not zeros.
    public static func referenceMean(_ values: [Double], minimumCount: Int = 7) -> Double? {
        let valid = values.filter { $0.isFinite && $0 > 0 }
        guard minimumCount > 0, valid.count >= minimumCount else { return nil }
        let result = valid.reduce(0, +) / Double(valid.count)
        return result.isFinite ? result : nil
    }
    public static func sleepGap(hours: [Double], target: Double) -> Double? {
        guard target.isFinite, target > 0 else { return nil }
        let valid = hours.filter { $0.isFinite && $0 > 0 && $0 <= 24 }
        guard !valid.isEmpty else { return nil }
        return valid.reduce(0) { $0 + max(0, target - $1) }
    }
    public static func bedtime(wake: Date, sleepHours: Double, bufferMinutes: Int) -> Date? {
        guard sleepHours.isFinite, (4...12).contains(sleepHours), (0...120).contains(bufferMinutes) else { return nil }
        return wake.addingTimeInterval(-(sleepHours * 3600 + Double(bufferMinutes) * 60))
    }
}
