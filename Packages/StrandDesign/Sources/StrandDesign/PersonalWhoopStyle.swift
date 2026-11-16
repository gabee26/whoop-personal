import SwiftUI

/// Shared visual tokens for the personal iPhone presentation, based on user references.
public enum PersonalWhoopStyle {
    public static let top = Color(hex: "182536")
    public static let bottom = Color(hex: "080E18")
    public static let card = Color(hex: "202D3E")
    public static let inset = Color(hex: "202629")
    public static let track = Color(hex: "394247")
    public static let text = Color(hex: "F8FAFB")
    public static let secondary = Color(hex: "AFB5B8")
    public static let muted = Color(hex: "7F888D")
    public static let sleep = Color(hex: "8FA9F5")
    public static let effort = Color(hex: "16A5E3")
    public static let green = Color(hex: "00DCA0")
    public static let yellow = Color(hex: "F9D731")
    public static let red = Color(hex: "FF2246")
    public static let purple = Color(hex: "8562EF")
    public static let margin: CGFloat = 16
    public static let gap: CGFloat = 8
    public static let section: CGFloat = 20
    public static let radius: CGFloat = 12
    public static let cardPadding: CGFloat = 12
    public static let touchTarget: CGFloat = 44
    public static let homeRingSize: CGFloat = 88
    public static let gaugeHeight: CGFloat = 100
    public static let glassStroke: CGFloat = 0.75
    public static let glassShadow: CGFloat = 4
    public static let glassHighlight = Color.white.opacity(0.08)
    public static let glassShade = Color.black.opacity(0.16)
    public static let dockHeight: CGFloat = 56
    public static let ringWidth: CGFloat = 5
    public static let detailRingSize: CGFloat = 140
    public static let detailChartHeight: CGFloat = 160
    public static let body = Font.system(size: 13, weight: .regular)
    public static let label = Font.system(size: 10, weight: .semibold)
    public static let heading = Font.system(size: 19, weight: .semibold)
    public static let number = Font.system(size: 25, weight: .semibold).monospacedDigit()
    public static let icon = Font.system(size: 20, weight: .regular)
    public static let wordmark = Font.system(size: 19, weight: .light)
    public static let deviceIllustration = Font.system(size: 90, weight: .ultraLight)
    public static var background: LinearGradient {
        LinearGradient(colors: [top, bottom, bottom], startPoint: .top, endPoint: .bottom)
    }
    public static func recovery(_ value: Double?) -> Color {
        guard let value = PersonalMetricScale.percentage(value) else { return muted }
        return value >= 67 ? green : (value >= 34 ? yellow : red)
    }
}

/// One material per surface; accessibility preferences remove transparency without hiding content.
public struct PersonalGlassSurface: View {
    public var radius: CGFloat
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    public init(radius: CGFloat = PersonalWhoopStyle.radius) { self.radius = radius }
    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        ZStack {
            if reduceTransparency || contrast == .increased {
                shape.fill(PersonalWhoopStyle.card)
            } else {
                shape.fill(.ultraThinMaterial)
                shape.fill(LinearGradient(colors: [PersonalWhoopStyle.card.opacity(0.7), PersonalWhoopStyle.top.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            shape.strokeBorder(LinearGradient(colors: [PersonalWhoopStyle.glassHighlight, .white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: PersonalWhoopStyle.glassStroke)
        }.shadow(color: PersonalWhoopStyle.glassShade, radius: PersonalWhoopStyle.glassShadow, y: 6)
    }
}

public struct PersonalWhoopCard<Content: View>: View {
    private let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View {
        content.frame(maxWidth: .infinity, alignment: .leading)
            .padding(PersonalWhoopStyle.cardPadding)
            .background(PersonalGlassSurface())
    }
}

public struct PersonalWhoopRing: View {
    let title: String
    let value: Double?
    let maximum: Double
    let color: Color
    public init(_ title: String, value: Double?, maximum: Double = 100, color: Color) {
        self.title = title; self.value = value; self.maximum = maximum; self.color = color
    }
    private var validValue: Double? {
        guard maximum.isFinite, maximum > 0, let value, value.isFinite,
              value >= 0, value <= maximum else { return nil }
        return value
    }
    public var body: some View {
        VStack(spacing: PersonalWhoopStyle.gap) {
            ZStack {
                Circle().stroke(PersonalWhoopStyle.track, lineWidth: PersonalWhoopStyle.ringWidth)
                if let value = validValue {
                    Circle().trim(from: 0, to: CGFloat(min(1, max(0, value / maximum))))
                        .stroke(color, style: StrokeStyle(lineWidth: PersonalWhoopStyle.ringWidth, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                Text(validValue.flatMap { $0.isFinite ? (maximum == 100 ? "\(Int($0.rounded()))%" : String(format: "%.1f", $0)) : nil } ?? (maximum == 100 ? "--%" : "--"))
                    .font(PersonalWhoopStyle.number).minimumScaleFactor(0.6).lineLimit(1)
            }.aspectRatio(1, contentMode: .fit)
            HStack(spacing: 3) {
                Text(title).tracking(1)
                Image(systemName: "chevron.right").foregroundStyle(PersonalWhoopStyle.muted)
            }.font(PersonalWhoopStyle.label).lineLimit(1).minimumScaleFactor(0.65)
        }.foregroundStyle(PersonalWhoopStyle.text)
    }
}

public struct PersonalWhoopDock: View {
    @Binding var selection: Int
    let coach: () -> Void
    let coachEnabled: Bool
    public init(selection: Binding<Int>, coachEnabled: Bool = true, coach: @escaping () -> Void) {
        self._selection = selection; self.coach = coach; self.coachEnabled = coachEnabled
    }
    public var body: some View {
        HStack(spacing: PersonalWhoopStyle.gap) {
            HStack(spacing: 0) {
                item(0, "Início", "house")
                item(1, "Saúde", "heart.text.square")
                item(2, "Plano", "checkmark.circle")
                item(4, "Mais", "line.3.horizontal")
            }.frame(maxWidth: .infinity)
                .background(PersonalGlassSurface(radius: PersonalWhoopStyle.dockHeight / 2))
            Button(action: coach) {
                Text("W").font(PersonalWhoopStyle.wordmark)
                    .frame(width: 35, height: 35)
                    .overlay(Circle().stroke(LinearGradient(colors: [PersonalWhoopStyle.purple, PersonalWhoopStyle.effort], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5))
                    .frame(width: PersonalWhoopStyle.dockHeight, height: PersonalWhoopStyle.dockHeight)
                    .background(PersonalGlassSurface())
            }.disabled(!coachEnabled).opacity(coachEnabled ? 1 : 0.4)
                .accessibilityLabel(coachEnabled ? "Abrir Coach" : "Coach desativado nas definições")
        }.foregroundStyle(PersonalWhoopStyle.text).buttonStyle(.plain)
            .padding(.horizontal, PersonalWhoopStyle.gap).padding(.bottom, 6)
    }
    private func item(_ tag: Int, _ title: String, _ icon: String) -> some View {
        Button { selection = tag } label: {
            VStack(spacing: 4) {
                Image(systemName: icon).font(PersonalWhoopStyle.icon)
                Text(title).font(.system(size: 11, weight: .medium))
            }.frame(maxWidth: .infinity).frame(height: PersonalWhoopStyle.dockHeight)
                .foregroundStyle(selection == tag ? PersonalWhoopStyle.text : PersonalWhoopStyle.muted)
        }.accessibilityAddTraits(selection == tag ? .isSelected : [])
    }
}

#Preview {
    ZStack {
        PersonalWhoopStyle.background.ignoresSafeArea()
        PersonalWhoopCard { PersonalWhoopRing("SONO", value: nil, color: PersonalWhoopStyle.sleep) }
            .padding()
    }
}
