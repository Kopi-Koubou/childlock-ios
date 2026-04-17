import SwiftUI

public enum ChildlockColorHex {
    public static let sunriseOrange = "F2994A"
    public static let coralWarm = "EB5757"
    public static let honeyGold = "F2C94C"
    public static let leafGreen = "6FCF97"
    public static let skyCalm = "56CCF2"
    public static let lavenderSoft = "BB6BD9"

    public static let cream = "FFF8F0"
    public static let warmWhite = "FEFCF9"
    public static let sand = "E8DDD3"
    public static let warmGray = "828282"
    public static let charcoal = "333333"
    public static let deepBrown = "1A1A1A"
}

public enum ChildlockColor {
    public static let accent = Color(hex: ChildlockColorHex.sunriseOrange)
    public static let accentSoft = Color(hex: ChildlockColorHex.honeyGold).opacity(0.28)
    public static let background = Color(hex: ChildlockColorHex.cream)
    public static let surface = Color(hex: ChildlockColorHex.warmWhite)
    public static let border = Color(hex: ChildlockColorHex.sand)
    public static let textPrimary = Color(hex: ChildlockColorHex.deepBrown)
    public static let textSecondary = Color(hex: ChildlockColorHex.warmGray)
    public static let success = Color(hex: ChildlockColorHex.leafGreen)
    public static let warning = Color(hex: ChildlockColorHex.coralWarm)
    public static let info = Color(hex: ChildlockColorHex.skyCalm)
    public static let reward = Color(hex: ChildlockColorHex.honeyGold)
    public static let memory = Color(hex: ChildlockColorHex.lavenderSoft)
}

public enum ChildlockSpacing {
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let section: CGFloat = 48
}

public enum ChildlockRadius {
    public static let control: CGFloat = 8
    public static let card: CGFloat = 12
    public static let panel: CGFloat = 16
}

public enum ChildlockTypography {
    public static let title = Font.system(size: 28, weight: .bold, design: .rounded)
    public static let subtitle = Font.system(size: 20, weight: .semibold, design: .rounded)
    public static let body = Font.system(size: 16, weight: .regular, design: .rounded)
    public static let caption = Font.system(size: 13, weight: .medium, design: .rounded)
}

public struct ChildlockCardModifier: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
            .padding(ChildlockSpacing.md)
            .background(ChildlockColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: ChildlockRadius.card)
                    .stroke(ChildlockColor.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.card))
    }
}

public extension View {
    func childlockCard() -> some View {
        modifier(ChildlockCardModifier())
    }
}

public struct ChildlockPrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ChildlockTypography.body.weight(.semibold))
            .foregroundStyle(ChildlockColor.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: ChildlockRadius.control)
                    .fill(ChildlockColor.accent.opacity(configuration.isPressed ? 0.82 : 1.0))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

public struct ChildlockSecondaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ChildlockTypography.body.weight(.semibold))
            .foregroundStyle(ChildlockColor.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: ChildlockRadius.control)
                    .fill(ChildlockColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ChildlockRadius.control)
                    .stroke(ChildlockColor.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

public extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue = Double(value & 0xFF) / 255.0

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1.0)
    }
}

#if canImport(UIKit)
import UIKit

public extension UIColor {
    convenience init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red = CGFloat((value >> 16) & 0xFF) / 255.0
        let green = CGFloat((value >> 8) & 0xFF) / 255.0
        let blue = CGFloat(value & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
#endif
