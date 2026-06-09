import SwiftUI

// MARK: - Color Palette
extension Color {
    // Backgrounds
    static let bgPrimary   = Color(hex: "#0F172A")
    static let bgDeep      = Color(hex: "#111827")
    static let bgSoft      = Color(hex: "#1A1F2E")
    static let cardBg      = Color(hex: "#1E293B")
    static let cardHover   = Color(hex: "#263244")
    static let divider     = Color(hex: "#334155")

    // Accents
    static let accentYellow      = Color(hex: "#FACC15")
    static let accentYellowActive = Color(hex: "#EAB308")
    static let accentYellowLight  = Color(hex: "#FDE047")
    static let accentOrange      = Color(hex: "#F97316")
    static let accentOrangeSoft  = Color(hex: "#FB923C")
    static let accentOrangeLight = Color(hex: "#FDBA74")
    static let accentBlue        = Color(hex: "#3B82F6")
    static let accentBlueSoft    = Color(hex: "#60A5FA")

    // Status
    static let statusGood    = Color(hex: "#22C55E")
    static let statusActive  = Color(hex: "#3B82F6")
    static let statusWarning = Color(hex: "#FACC15")
    static let statusError   = Color(hex: "#EF4444")

    // Text
    static let textPrimary   = Color(hex: "#F8FAFC")
    static let textSecondary = Color(hex: "#CBD5E1")
    static let textInactive  = Color(hex: "#64748B")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:(a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Typography
extension Font {
    static let displayLarge  = Font.system(size: 34, weight: .black, design: .rounded)
    static let displayMedium = Font.system(size: 28, weight: .bold, design: .rounded)
    static let displaySmall  = Font.system(size: 22, weight: .bold, design: .rounded)
    static let headlineLarge = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let headlineSmall = Font.system(size: 15, weight: .semibold, design: .rounded)
    static let bodyLarge     = Font.system(size: 16, weight: .regular, design: .rounded)
    static let bodySmall     = Font.system(size: 14, weight: .regular, design: .rounded)
    static let caption       = Font.system(size: 12, weight: .medium, design: .rounded)
    static let label         = Font.system(size: 11, weight: .semibold, design: .rounded)
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headlineLarge)
            .foregroundColor(.bgPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.accentYellow)
                    .shadow(color: Color(hex: "#FACC15").opacity(0.35), radius: 12, x: 0, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headlineLarge)
            .foregroundColor(.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.cardBg)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.divider, lineWidth: 1))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct DangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headlineLarge)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.statusError))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct IconButtonStyle: ButtonStyle {
    var color: Color = .accentYellow
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(color)
            .padding(10)
            .background(Circle().fill(color.opacity(0.15)))
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Card View
struct TNCard<Content: View>: View {
    var content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }
    var body: some View {
        content()
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBg))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.divider, lineWidth: 1))
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: ToolStatus
    var body: some View {
        Text(status.displayName)
            .font(.label)
            .foregroundColor(status.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(status.color.opacity(0.18)))
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionTitle: String = "See All"
    var body: some View {
        HStack {
            Text(title)
                .font(.headlineLarge)
                .foregroundColor(.textPrimary)
            Spacer()
            if let action = action {
                Button(actionTitle, action: action)
                    .font(.caption)
                    .foregroundColor(.accentYellow)
            }
        }
    }
}

// MARK: - Custom TextField
struct TNTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.textInactive)
                    .frame(width: 20)
            }
            TextField("", text: $text)
                .placeholder(when: text.isEmpty) {
                    Text(placeholder).foregroundColor(.textInactive)
                }
                .font(.bodyLarge)
                .foregroundColor(.textPrimary)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.bgSoft))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.divider, lineWidth: 1))
    }
}

extension View {
    func placeholder<Content: View>(when shouldShow: Bool, @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: .leading) {
            if shouldShow { placeholder() }
            self
        }
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.textInactive)
            Text(title)
                .font(.headlineLarge)
                .foregroundColor(.textPrimary)
            Text(subtitle)
                .font(.bodySmall)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
            }
            Text(value)
                .font(.displaySmall)
                .foregroundColor(.textPrimary)
            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardBg))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.3), lineWidth: 1))
    }
}
