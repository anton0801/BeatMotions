import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var sessionVM: SessionViewModel
    @EnvironmentObject var playlistVM: PlaylistViewModel
    @State private var showMoodSelector = false
    @State private var showSmartMix = false
    @State private var showVisualizer = false
    @State private var showFocusMode = false
    @State private var energyData: [Double] = []
    @State private var appear = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.backgroundGradient.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Good \(timeGreeting())")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.textSecondary)
                                Text("Beat Motion")
                                    .font(.system(size: 26, weight: .bold, design: .rounded))
                                    .foregroundColor(.textPrimary)
                            }
                            Spacer()
                            Button(action: { showMoodSelector = true }) {
                                ZStack {
                                    Circle()
                                        .fill(appState.currentMood.primaryColor.opacity(0.15))
                                        .frame(width: 46, height: 46)
                                    Image(systemName: appState.currentMood.icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(appState.currentMood.primaryColor)
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 12)

                        // Current Mood Card
                        CurrentMoodCard(mood: appState.currentMood)
                            .padding(.horizontal, 18)
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 20)

                        // Today Stats Row
                        HStack(spacing: 12) {
                            StatMiniCard(icon: "play.fill", value: "\(sessionVM.todaySessionCount)", label: "Sessions", color: .neonCyan)
                            StatMiniCard(icon: "clock.fill", value: "\(Int(sessionVM.todayMinutes))m", label: "Listened", color: .neonPurple)
                            StatMiniCard(icon: "flame.fill", value: "\(sessionVM.currentStreak)d", label: "Streak", color: .neonOrange)
                        }
                        .padding(.horizontal, 18)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)

                        // Quick Action Buttons
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                QuickActionButton(
                                    title: "Start Mix",
                                    icon: "shuffle",
                                    gradient: LinearGradient.purplePink
                                ) { showSmartMix = true }

                                QuickActionButton(
                                    title: "Focus Mode",
                                    icon: "brain.head.profile",
                                    gradient: LinearGradient.cyanPurple
                                ) { showFocusMode = true }
                            }
                            HStack(spacing: 12) {
                                QuickActionButton(
                                    title: "Open Visualizer",
                                    icon: "waveform",
                                    gradient: LinearGradient.orangePink
                                ) { showVisualizer = true }

                                QuickActionButton(
                                    title: "Add Playlist",
                                    icon: "plus.circle.fill",
                                    gradient: LinearGradient(
                                        colors: [Color.neonGreen, Color.neonCyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                ) { showSmartMix = true }
                            }
                        }
                        .padding(.horizontal, 18)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)

                        // Energy by Day Chart
                        EnergyChartCard(data: energyData)
                            .padding(.horizontal, 18)
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 20)

                        // Recent Sessions
                        if !sessionVM.sessions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Sessions")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                    .padding(.horizontal, 18)

                                ForEach(sessionVM.sessions.prefix(3)) { session in
                                    SessionRowCard(session: session)
                                        .padding(.horizontal, 18)
                                }
                            }
                            .opacity(appear ? 1 : 0)
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.top, 4)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showMoodSelector) { MoodSelectorView() }
        .sheet(isPresented: $showSmartMix) { SmartMixView() }
        .sheet(isPresented: $showVisualizer) { VisualizerView() }
        .sheet(isPresented: $showFocusMode) { FocusModeView() }
        .onAppear {
            withAnimation(.spring04.delay(0.1)) { appear = true }
            energyData = Array(repeating: 0, count: 7).map { _ in Double.random(in: 30...90) }
        }
    }

    private func timeGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "morning"
        case 12..<17: return "afternoon"
        case 17..<22: return "evening"
        default: return "night"
        }
    }
}

// MARK: - Sub-components
struct CurrentMoodCard: View {
    let mood: MoodType
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(mood.primaryColor.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .scaleEffect(pulse ? 1.1 : 1.0)
                    .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulse)

                Image(systemName: mood.icon)
                    .font(.system(size: 26))
                    .foregroundColor(mood.primaryColor)
                    .neonGlow(color: mood.primaryColor, radius: 8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Current Mood")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textInactive)
                Text(mood.rawValue)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                Text(mood.description)
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Text(mood.bpm)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(mood.primaryColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(mood.primaryColor.opacity(0.15))
                .cornerRadius(8)
        }
        .padding(16)
        .cardStyle()
        .onAppear { pulse = true }
        .onDisappear { pulse = false }
    }
}

struct StatMiniCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .neonGlow(color: color, radius: 5)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.textInactive)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .cardStyle()
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let gradient: LinearGradient
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(gradient)
            .cornerRadius(14)
            .shadow(color: Color.neonPurple.opacity(0.25), radius: 8, y: 3)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.spring04) { isPressed = true } }
                .onEnded { _ in withAnimation(.spring04) { isPressed = false } }
        )
    }
}

struct EnergyChartCard: View {
    let data: [Double]
    let labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Energy by Day")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.textPrimary)

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(data.enumerated()), id: \.offset) { i, value in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color.neonPurple, Color.neonPink],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .frame(height: CGFloat(value / 100 * 80) + 8)
                            .neonGlow(color: .neonPurple, radius: 3)
                        Text(i < labels.count ? labels[i] : "")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.textInactive)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100)
            .animation(.spring04, value: data)
        }
        .padding(16)
        .cardStyle()
    }
}

struct SessionRowCard: View {
    let session: MusicSession

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(session.mood.primaryColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: session.mood.icon)
                    .font(.system(size: 18))
                    .foregroundColor(session.mood.primaryColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(session.mood.rawValue + " · " + session.mode.rawValue)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text(session.genre.rawValue + " · " + session.durationString)
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Text(session.date.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 11))
                .foregroundColor(.textInactive)
        }
        .padding(14)
        .cardStyle()
    }
}

extension MusicSession {
    var durationString: String {
        let mins = Int(duration) / 60
        return "\(mins) min"
    }
}
