import Foundation

/// Read-only presentation statistics; never feeds the scoring or storage pipelines.
public struct PersonalComparisonSummary {
    public struct Pair {
        public let day: String
        public let reference: Double
        public let local: Double
        public var difference: Double { local - reference }
    }
    public let pairs: [Pair]
    public let referenceOnly: Int
    public let localOnly: Int
    public var meanAbsoluteDifference: Double? {
        guard !pairs.isEmpty else { return nil }
        return pairs.reduce(0) { $0 + abs($1.difference) / Double(pairs.count) }
    }
    public var meanDifference: Double? {
        guard !pairs.isEmpty else { return nil }
        return pairs.reduce(0) { $0 + $1.difference / Double(pairs.count) }
    }

    public init(reference: [String: Double], local: [String: Double]) {
        let a = reference.filter { $0.value.isFinite }
        let b = local.filter { $0.value.isFinite }
        let common = Set(a.keys).intersection(b.keys).sorted()
        pairs = common.compactMap { day in
            guard let reference = a[day], let local = b[day], (local - reference).isFinite else { return nil }
            return Pair(day: day, reference: reference, local: local)
        }
        referenceOnly = Set(a.keys).subtracting(b.keys).count
        localOnly = Set(b.keys).subtracting(a.keys).count
    }
}
