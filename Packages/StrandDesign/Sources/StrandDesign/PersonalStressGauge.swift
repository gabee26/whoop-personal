import SwiftUI

/// Presentation of the existing 0–3 stress proxy. Missing values never draw a measured arc.
public struct PersonalStressGauge: View {
    public let value: Double?
    private typealias S = PersonalWhoopStyle
    public init(value: Double?) { self.value = value }
    private var valid: Double? {
        guard let value, value.isFinite, (0...3).contains(value) else { return nil }
        return value
    }
    private var tint: Color {
        guard let valid else { return S.muted }
        return valid < 1 ? S.effort : (valid < 2 ? S.yellow : S.red)
    }
    public var body: some View {
        VStack(spacing: S.gap) {
            ZStack(alignment: .bottom) {
                GeometryReader { proxy in
                    let side = min(proxy.size.width, S.gaugeHeight * 2)
                    ZStack {
                        Circle().trim(from: 0, to: 0.5).stroke(S.track, style: StrokeStyle(lineWidth: S.ringWidth, lineCap: .round))
                        if let valid {
                            Circle().trim(from: 0, to: CGFloat(valid / 6)).stroke(tint, style: StrokeStyle(lineWidth: S.ringWidth, lineCap: .round))
                        }
                    }
                    .rotationEffect(.degrees(180))
                    .frame(width: side, height: side)
                    .position(x: proxy.size.width / 2, y: side / 2)
                }
                VStack(spacing: S.gap) {
                    Text(valid.map { String(format: "%.1f", $0) } ?? "—").font(S.number)
                    Text(valid.map { $0 < 1 ? "BAIXO" : ($0 < 2 ? "MODERADO" : "ELEVADO") } ?? "SEM DADOS")
                        .font(S.label).foregroundStyle(S.secondary)
                }
            }.frame(height: S.gaugeHeight)
            HStack { Text("0"); Spacer(); Text("3") }.font(S.label).foregroundStyle(S.muted)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Stress estimado")
        .accessibilityValue(valid.map { String(format: "%.1f de 3", $0) } ?? "Sem dados")
    }
}
