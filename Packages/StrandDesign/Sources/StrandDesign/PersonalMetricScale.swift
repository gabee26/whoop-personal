/// Display-only conversions for the personal iPhone UI. Stored NOOP values stay unchanged.
public enum PersonalMetricScale {
    /// NOOP's current strain output and imported Day Strain are stored on 0...100.
    /// Rescaling changes the axis, not the underlying model or its accuracy.
    public static func effort(_ stored: Double?) -> Double? {
        percentage(stored).map { $0 * 21.0 / 100.0 }
    }

    /// Invalid values remain missing instead of being clamped into plausible scores.
    public static func percentage(_ value: Double?) -> Double? {
        guard let value, value.isFinite, (0...100).contains(value) else { return nil }
        return value
    }
}
