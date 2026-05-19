import SwiftUI

// MARK: - Color Palette
extension Color {
    // Backgrounds
    static let bgPrimary    = Color(hex: "#070B1F")
    static let bgDeep       = Color(hex: "#111827")
    static let bgPurple     = Color(hex: "#1E1B4B")
    static let bgCard       = Color(hex: "#1E293B")

    // Neon Colors
    static let neonPurple   = Color(hex: "#8B5CF6")
    static let neonPink     = Color(hex: "#EC4899")
    static let neonCyan     = Color(hex: "#22D3EE")
    static let neonOrange   = Color(hex: "#F97316")
    static let neonGreen    = Color(hex: "#10B981")

    // Glow
    static let glowPurple   = Color(hex: "#8B5CF6").opacity(0.4)
    static let glowPink     = Color(hex: "#EC4899").opacity(0.35)
    static let glowCyan     = Color(hex: "#22D3EE").opacity(0.35)

    // Text
    static let textPrimary  = Color(hex: "#F8FAFC")
    static let textSecondary = Color(hex: "#CBD5F5")
    static let textInactive = Color(hex: "#64748B")

    // Button
    static let btnPrimary   = Color(hex: "#8B5CF6")
    static let btnSecondary = Color(hex: "#1E293B")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Gradients
extension LinearGradient {
    static let backgroundGradient = LinearGradient(
        colors: [Color.bgPrimary, Color.bgDeep, Color.bgPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let purplePink = LinearGradient(
        colors: [Color.neonPurple, Color.neonPink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let cyanPurple = LinearGradient(
        colors: [Color.neonCyan, Color.neonPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let orangePink = LinearGradient(
        colors: [Color.neonOrange, Color.neonPink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Mood Model
enum MoodType: String, CaseIterable, Codable {
    case focus   = "Focus"
    case chill   = "Chill"
    case energy  = "Energy"
    case night   = "Night"
    case happy   = "Happy"

    var icon: String {
        switch self {
        case .focus:  return "brain.head.profile"
        case .chill:  return "cloud.sun.fill"
        case .energy: return "bolt.fill"
        case .night:  return "moon.stars.fill"
        case .happy:  return "face.smiling.fill"
        }
    }

    var primaryColor: Color {
        switch self {
        case .focus:  return .neonCyan
        case .chill:  return .neonPurple
        case .energy: return .neonOrange
        case .night:  return .neonPink
        case .happy:  return .neonGreen
        }
    }

    var secondaryColor: Color {
        switch self {
        case .focus:  return .neonPurple
        case .chill:  return .neonPink
        case .energy: return .neonPink
        case .night:  return .neonPurple
        case .happy:  return .neonCyan
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [primaryColor, secondaryColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var description: String {
        switch self {
        case .focus:  return "Deep concentration"
        case .chill:  return "Relax & unwind"
        case .energy: return "High performance"
        case .night:  return "Wind down"
        case .happy:  return "Good vibes"
        }
    }

    var bpm: String {
        switch self {
        case .focus:  return "60–80 BPM"
        case .chill:  return "70–90 BPM"
        case .energy: return "120–140 BPM"
        case .night:  return "50–70 BPM"
        case .happy:  return "100–120 BPM"
        }
    }
}

// MARK: - Animation Spring
extension Animation {
    static let spring04 = Animation.spring(response: 0.4, dampingFraction: 0.7)
    static let spring03 = Animation.spring(response: 0.3, dampingFraction: 0.75)
}

// MARK: - View Modifiers
struct NeonGlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color, radius: radius / 2)
            .shadow(color: color, radius: radius)
    }
}

extension View {
    func neonGlow(color: Color, radius: CGFloat = 8) -> some View {
        modifier(NeonGlowModifier(color: color, radius: radius))
    }

    func cardStyle() -> some View {
        self
            .background(Color.bgCard.opacity(0.8))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            )
    }
}
