import SwiftUI

// MARK: - Soft Sage Palette (Direction B)

public enum ChildlockColorHex {
    // Primary palette
    public static let forestSage = "3F6B58"
    public static let forestDeep = "2A4D3F"
    public static let terracotta = "C97E5C"
    public static let honeyWarm = "B89B4F"
    public static let lavender = "A89BC7"

    // Neutrals
    public static let bone = "F2F1EC"
    public static let white = "FFFFFF"
    public static let surfaceMuted = "E8E6DF"
    public static let ink = "1F2421"
    public static let inkSoft = "4F574F"
    public static let inkMute = "8A8F88"
    public static let inkFaint = "C5C8C2"

    // Shield (child lock-in)
    public static let shieldBg = "1B2420"
    public static let shieldInk = "F2F1EC"

    // Semantic tints
    public static let primarySoft = "D9E5DD"
    public static let accentSoft = "F1DFD2"
    public static let warnSoft = "EAE0C5"
}

public enum ChildlockColor {
    // Core
    public static let primary = Color(hex: ChildlockColorHex.forestSage)
    public static let primaryDeep = Color(hex: ChildlockColorHex.forestDeep)
    public static let primarySoft = Color(hex: ChildlockColorHex.primarySoft)
    public static let accent = Color(hex: ChildlockColorHex.terracotta)
    public static let accentSoft = Color(hex: ChildlockColorHex.accentSoft)

    // Surfaces
    public static let background = Color(hex: ChildlockColorHex.bone)
    public static let surface = Color(hex: ChildlockColorHex.white)
    public static let surfaceMuted = Color(hex: ChildlockColorHex.surfaceMuted)

    // Text
    public static let textPrimary = Color(hex: ChildlockColorHex.ink)
    public static let textSecondary = Color(hex: ChildlockColorHex.inkSoft)
    public static let textMuted = Color(hex: ChildlockColorHex.inkMute)
    public static let textFaint = Color(hex: ChildlockColorHex.inkFaint)

    // Semantic
    public static let success = Color(hex: ChildlockColorHex.forestSage)
    public static let warning = Color(hex: ChildlockColorHex.honeyWarm)
    public static let warnSoft = Color(hex: ChildlockColorHex.warnSoft)
    public static let info = Color(hex: ChildlockColorHex.terracotta)
    public static let reward = Color(hex: ChildlockColorHex.honeyWarm)
    public static let memory = Color(hex: ChildlockColorHex.lavender)

    // Shield
    public static let shieldBg = Color(hex: ChildlockColorHex.shieldBg)
    public static let shieldInk = Color(hex: ChildlockColorHex.shieldInk)

    // Legacy aliases for backward compatibility
    public static let border = Color(hex: ChildlockColorHex.surfaceMuted)
}

// MARK: - Spacing

public enum ChildlockSpacing {
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let section: CGFloat = 48
}

// MARK: - Radius

public enum ChildlockRadius {
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 14
    public static let lg: CGFloat = 20
    public static let xl: CGFloat = 28
    public static let pill: CGFloat = 999
    // Legacy aliases
    public static let control: CGFloat = 14
    public static let card: CGFloat = 20
    public static let panel: CGFloat = 28
}

// MARK: - Shadows

public enum ChildlockShadow {
    public static let sm = ShadowStyle(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
    public static let md = ShadowStyle(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    public static let lg = ShadowStyle(color: .black.opacity(0.08), radius: 32, x: 0, y: 12)
}

public struct ShadowStyle: Sendable {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat
}

public extension View {
    func childlockShadow(_ style: ShadowStyle) -> some View {
        shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}

// MARK: - Typography

public enum ChildlockTypography {
    // Display (headers, hero numbers)
    public static let display = Font.system(size: 32, weight: .bold, design: .default)
    public static let displayLarge = Font.system(size: 36, weight: .bold, design: .default)

    // Titles
    public static let title = Font.system(size: 28, weight: .bold, design: .default)
    public static let subtitle = Font.system(size: 22, weight: .semibold, design: .default)

    // Body
    public static let body = Font.system(size: 15, weight: .regular, design: .default)
    public static let bodyBold = Font.system(size: 15, weight: .semibold, design: .default)

    // Small
    public static let caption = Font.system(size: 13, weight: .regular, design: .default)
    public static let label = Font.system(size: 11, weight: .semibold, design: .default)

    // Child challenge text (rounded for friendliness)
    public static let childDisplay = Font.system(size: 64, weight: .semibold, design: .rounded)
    public static let childTitle = Font.system(size: 26, weight: .semibold, design: .rounded)
    public static let childBody = Font.system(size: 24, weight: .medium, design: .rounded)
    public static let childNumber = Font.system(size: 44, weight: .semibold, design: .rounded)

    // Parent stats
    public static let stat = Font.system(size: 22, weight: .bold, design: .default)
    public static let statLarge = Font.system(size: 34, weight: .bold, design: .default)
}

// MARK: - Avatar Colors

public enum ChildlockAvatarColor {
    public static let fox = Color(hex: "F4A07A")
    public static let rose = Color(hex: "E8A1B5")
    public static let bear = Color(hex: "C9A57E")
    public static let sage = Color(hex: "8FB39E")
    public static let lavender = Color(hex: "A89BC7")
    public static let honey = Color(hex: "E0B85A")

    public static let all: [Color] = [fox, rose, bear, sage, lavender, honey]
}

// MARK: - Card Modifier

public struct ChildlockCardModifier: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
            .padding(ChildlockSpacing.lg - 2)
            .background(ChildlockColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.card))
            .childlockShadow(ChildlockShadow.sm)
    }
}

public extension View {
    func childlockCard() -> some View {
        modifier(ChildlockCardModifier())
    }
}

// MARK: - Button Styles

public struct ChildlockPrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: ChildlockRadius.pill)
                    .fill(ChildlockColor.primary.opacity(configuration.isPressed ? 0.85 : 1.0))
                    .shadow(color: ChildlockColor.primary.opacity(0.25), radius: 8, y: 3)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

public struct ChildlockSecondaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(ChildlockColor.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: ChildlockRadius.pill)
                    .fill(Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ChildlockRadius.pill)
                    .stroke(ChildlockColor.textFaint, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Color Extensions

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
