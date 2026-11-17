import SwiftUI

/// Shared tokens and original vector hardware artwork for device settings.
public enum PersonalDeviceStyle {
    public static let top = Color(hex: "39464D")
    public static let bottom = Color(hex: "0B1012")
    public static let surface = Color(hex: "22282B")
    public static let hardware = Color(hex: "101416")
    public static let metal = Color(hex: "596064")
    public static let margin: CGFloat = 20
    public static let headerGap: CGFloat = 28
    public static let heroHeight: CGFloat = 270
    public static let buttonHeight: CGFloat = 54
    public static let buttonRadius: CGFloat = 4
    public static let bottomSpace: CGFloat = 100
    public static let tracking: CGFloat = 1.2
    public static let title = Font.system(size: 14, weight: .bold)
    public static let heading = Font.system(size: 15, weight: .bold)
    public static let caption = Font.system(size: 10, weight: .bold)
    public static let body = Font.system(size: 14, weight: .medium)
    public static let symbol = Font.system(size: 24, weight: .light)
    public static var background: LinearGradient {
        LinearGradient(colors: [top, bottom, bottom], startPoint: .top, endPoint: .bottom)
    }
}

public struct PersonalDeviceArtwork: View {
    public let connected: Bool
    public init(connected: Bool) { self.connected = connected }
    public var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 390, y: size.height / 270)
            let phone = Path(roundedRect: CGRect(x: 283, y: 0, width: 155, height: 260), cornerRadius: 18)
            context.fill(phone, with: .color(PersonalDeviceStyle.hardware))
            context.stroke(phone, with: .color(PersonalDeviceStyle.metal), lineWidth: 1)
            context.fill(Path(roundedRect: CGRect(x: 288, y: 5, width: 145, height: 250), cornerRadius: 14), with: .color(PersonalDeviceStyle.surface))
            var strap = context
            strap.translateBy(x: 43, y: 140)
            strap.rotate(by: .degrees(-21))
            let band = Path(roundedRect: CGRect(x: -47, y: -125, width: 94, height: 250), cornerRadius: 35)
            strap.fill(band, with: .color(PersonalDeviceStyle.hardware))
            strap.clip(to: band)
            for y in stride(from: -125, through: 125, by: 3) {
                var weave = Path()
                weave.move(to: CGPoint(x: -47, y: CGFloat(y)))
                weave.addLine(to: CGPoint(x: 47, y: CGFloat(y + 12)))
                strap.stroke(weave, with: .color(PersonalDeviceStyle.metal.opacity(0.35)), lineWidth: 1)
            }
            let sensor = Path(roundedRect: CGRect(x: -51, y: -103, width: 102, height: 143), cornerRadius: 22)
            strap.fill(sensor, with: .linearGradient(Gradient(colors: [PersonalDeviceStyle.metal, PersonalDeviceStyle.hardware, PersonalDeviceStyle.surface]), startPoint: CGPoint(x: -51, y: 0), endPoint: CGPoint(x: 51, y: 0)))
            strap.stroke(sensor, with: .color(PersonalDeviceStyle.metal), lineWidth: 1)
            strap.fill(Path(roundedRect: CGRect(x: -48, y: 7, width: 96, height: 33), cornerRadius: 5), with: .linearGradient(Gradient(colors: [PersonalDeviceStyle.metal, PersonalDeviceStyle.surface]), startPoint: CGPoint(x: 0, y: 7), endPoint: CGPoint(x: 0, y: 40)))
            var link = Path()
            link.move(to: CGPoint(x: 137, y: 130))
            link.addLine(to: CGPoint(x: 264, y: 130))
            context.stroke(link, with: .color(PersonalWhoopStyle.muted), style: StrokeStyle(lineWidth: 1.5, dash: [2, 3]))
            let badge = Path(ellipseIn: CGRect(x: 184, y: 114, width: 32, height: 32))
            context.fill(badge, with: .color(PersonalDeviceStyle.bottom))
            context.stroke(badge, with: .color(connected ? PersonalWhoopStyle.green : PersonalWhoopStyle.red), lineWidth: 1.5)
            context.draw(Text(Image(systemName: connected ? "checkmark" : "xmark")).font(PersonalDeviceStyle.body).foregroundColor(PersonalWhoopStyle.text), at: CGPoint(x: 200, y: 130))
        }.accessibilityHidden(true)
    }
}
