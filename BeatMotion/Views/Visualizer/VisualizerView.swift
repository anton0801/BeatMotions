import SwiftUI

struct VisualizerView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var sessionVM: SessionViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var isVisible = false
    @State private var barHeights: [CGFloat] = Array(repeating: 20, count: 50)
    @State private var phase: Double = 0
    @State private var centralWavePhase: Double = 0
    @State private var rhythmPulse: CGFloat = 1.0
    @State private var animationTimer: Timer?
    @State private var showColorPicker = false
    @State private var savedTheme = false

    private let barCount = 50

    var body: some View {
        ZStack {
            ZStack {
                Color.bgPrimary
                RadialGradient(
                    colors: [
                        appState.activeNeonTheme.primaryColor.opacity(sessionVM.isAudioPlaying ? 0.2 : 0.08),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 300
                )
            }
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.8), value: sessionVM.isAudioPlaying)

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.textInactive)
                    }
                    Spacer()
                    Text("Visualizer")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Text(appState.currentMood.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(appState.currentMood.primaryColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(appState.currentMood.primaryColor.opacity(0.15))
                        .cornerRadius(20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // Track name
                if !sessionVM.currentTrackName.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "music.note")
                            .font(.system(size: 12))
                            .foregroundColor(.textInactive)
                        Text(sessionVM.currentTrackName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                    .transition(.opacity)
                }

                // Central wave
                CentralWaveView(
                    phase: centralWavePhase,
                    isPlaying: sessionVM.isAudioPlaying,
                    primaryColor: appState.activeNeonTheme.primaryColor,
                    secondaryColor: appState.activeNeonTheme.secondaryColor
                )
                .frame(height: 80)
                .padding(.horizontal, 30)
                .scaleEffect(rhythmPulse)

                Spacer()

                // BPM / Level row
                HStack(spacing: 16) {
                    VStack(spacing: 3) {
                        Text(String(format: "%.0f", sessionVM.isAudioPlaying ? (60 + phase.truncatingRemainder(dividingBy: 40)) : 0))
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.textPrimary)
                        Text("BPM")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.textInactive)
                    }

                    Spacer()

                    Circle()
                        .fill(appState.activeNeonTheme.primaryColor)
                        .frame(width: 14, height: 14)
                        .neonGlow(color: appState.activeNeonTheme.primaryColor, radius: 8)
                        .scaleEffect(sessionVM.isAudioPlaying ? rhythmPulse : 1.0)

                    Spacer()

                    VStack(spacing: 3) {
                        Text(String(format: "%.0f%%", sessionVM.isAudioPlaying ? ((sin(phase) + 1) / 2 * 80 + 10) : 0))
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.textPrimary)
                        Text("Level")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.textInactive)
                    }
                }
                .padding(.horizontal, 50)

                Spacer()

                // Volume slider
                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.textInactive)
                        Slider(value: Binding(
                            get: { Double(sessionVM.audioVolume) },
                            set: { sessionVM.setVolume(Float($0)) }
                        ), in: 0...1)
                        .accentColor(appState.activeNeonTheme.primaryColor)
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.textInactive)
                    }
                    .padding(.horizontal, 30)
                }

                Spacer()

                // Bar visualizer
                GeometryReader { geo in
                    HStack(alignment: .bottom, spacing: 2) {
                        ForEach(0..<barCount, id: \.self) { i in
                            NeonBar(
                                height: barHeights[i],
                                index: i,
                                total: barCount,
                                primaryColor: appState.activeNeonTheme.primaryColor,
                                secondaryColor: appState.activeNeonTheme.secondaryColor,
                                isPlaying: sessionVM.isAudioPlaying
                            )
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
                }
                .frame(height: 140)
                .padding(.horizontal, 20)

                Spacer()

                // Controls
                HStack(spacing: 24) {
                    VisualizerButton(icon: "paintpalette.fill", label: "Color") {
                        showColorPicker = true
                    }

                    Button(action: togglePlayback) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [appState.activeNeonTheme.primaryColor, appState.activeNeonTheme.secondaryColor],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ))
                                .frame(width: 72, height: 72)
                                .shadow(color: appState.activeNeonTheme.primaryColor.opacity(0.5), radius: 16)

                            Image(systemName: sessionVM.isAudioPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.white)
                                .offset(x: sessionVM.isAudioPlaying ? 0 : 2)
                        }
                    }
                    .scaleEffect(sessionVM.isAudioPlaying ? 1.05 : 1.0)
                    .animation(.spring04, value: sessionVM.isAudioPlaying)

                    VisualizerButton(icon: "star.fill", label: "Save") {
                        saveTheme()
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .onAppear { isVisible = true }
        .onDisappear {
            isVisible = false
            stopAnimation()
        }
        .onChange(of: sessionVM.isAudioPlaying) { playing in
            if playing { startAnimation() } else { stopAnimation() }
        }
        .sheet(isPresented: $showColorPicker) { ThemeStudioView() }
        .overlay(
            Group {
                if savedTheme {
                    VStack {
                        Spacer()
                        Text("Theme Saved")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.neonPurple)
                            .cornerRadius(20)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        Spacer().frame(height: 120)
                    }
                }
            }
            .animation(.spring04, value: savedTheme)
        )
    }

    private func togglePlayback() {
        sessionVM.togglePlayPause(mood: appState.currentMood)
    }

    private func startAnimation() {
        guard isVisible else { return }
        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { _ in
            guard self.sessionVM.isAudioPlaying && self.isVisible else { return }
            let speed = self.appState.activeNeonTheme.animationSpeed
            self.phase += 0.08 * speed
            self.centralWavePhase += 0.1 * speed

            withAnimation(.linear(duration: 1.0 / 30.0)) {
                for i in 0..<self.barCount {
                    let angle = Double(i) / Double(self.barCount) * .pi * 6 + self.phase
                    let base = (sin(angle) + 1) / 2
                    let extra = (sin(angle * 2.1 + 0.5) + 1) / 4
                    self.barHeights[i] = CGFloat((base + extra) * 100 + 10)
                }
                self.rhythmPulse = CGFloat((sin(self.phase * 2) + 1) / 2 * 0.15 + 0.95)
            }
        }
    }

    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        withAnimation(.spring04) {
            barHeights = Array(repeating: 10, count: barCount)
            rhythmPulse = 1.0
        }
    }

    private func saveTheme() {
        withAnimation(.spring04) { savedTheme = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring04) { savedTheme = false }
        }
    }
}

struct NeonBar: View {
    let height: CGFloat
    let index: Int
    let total: Int
    let primaryColor: Color
    let secondaryColor: Color
    let isPlaying: Bool

    var color: Color {
        let t = Double(index) / Double(total)
        return t < 0.5 ? primaryColor : secondaryColor
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color.opacity(0.85))
            .frame(height: max(4, height))
            .neonGlow(color: color, radius: isPlaying ? 4 : 0)
    }
}

struct CentralWaveView: View {
    let phase: Double
    let isPlaying: Bool
    let primaryColor: Color
    let secondaryColor: Color

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let midY = size.height / 2
                var path1 = Path()
                var path2 = Path()

                path1.move(to: CGPoint(x: 0, y: midY))
                path2.move(to: CGPoint(x: 0, y: midY))

                for x in stride(from: 0, to: size.width, by: 2) {
                    let normalX = x / size.width
                    let y1 = midY + sin(normalX * .pi * 6.0 + phase) * (isPlaying ? 30 : 8)
                    let y2 = midY + sin(normalX * .pi * 4.0 + phase + 1.0) * (isPlaying ? 20 : 5)
                    path1.addLine(to: CGPoint(x: x, y: y1))
                    path2.addLine(to: CGPoint(x: x, y: y2))
                }

                context.stroke(path1, with: .color(primaryColor.opacity(0.9)), lineWidth: 2.5)
                context.stroke(path2, with: .color(secondaryColor.opacity(0.6)), lineWidth: 1.5)
            }
        }
    }
}

struct BeatMotionsConsentView: View {
    let viewModel: BeatMotionsViewModel
    
    
    private var subtitleText: some View {
        Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
            .font(.system(size: 13, weight: .heavy, design: .rounded))
            .foregroundColor(.white.opacity(0.7))
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.acceptConsent()
            } label: {
                Image("beaty")
                    .resizable()
                    .frame(width: 300, height: 55)
            }
            
            Button {
                viewModel.skipConsent()
            } label: {
                Image("beat_sk")
                    .resizable()
                    .frame(width: 278, height: 38)
            }
        }
        .padding(.horizontal, 12)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image("beat_motions_app")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .opacity(0.8)
                
                if geometry.size.width < geometry.size.height {
                    VStack(spacing: 12) {
                        Spacer()
                        titleText
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                        subtitleText
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                        actionButtons
                    }
                    .padding(.bottom, 24)
                } else {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 12) {
                            Spacer()
                            titleText
                                .padding(.horizontal, 12)
                            subtitleText
                                .padding(.horizontal, 12)
                        }
                        Spacer()
                        VStack {
                            Spacer()
                            actionButtons
                        }
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var titleText: some View {
        Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
            .font(.system(size: 24, weight: .black, design: .rounded))
            .foregroundColor(.white)
    }
    
}

struct VisualizerButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(.textSecondary)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.textInactive)
            }
        }
        .frame(width: 64, height: 64)
    }
}
