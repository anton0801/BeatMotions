import SwiftUI

// MARK: - Focus Mode
struct FocusModeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var sessionVM: SessionViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var selectedDuration: Double = 25
    @State private var selectedGenre: GenreType = .lofi
    @State private var appear = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.bgPrimary, Color(hex: "#0A1628")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Focus Mode")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.textInactive)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Timer Ring
                        FocusTimerRing(sessionVM: sessionVM)
                            .frame(height: 240)
                            .padding(.top, 10)

                        if !sessionVM.isTimerRunning {
                            // Session Time Picker
                            MixSectionCard(title: "Session Time: \(Int(selectedDuration)) min") {
                                Slider(value: $selectedDuration, in: 5...120, step: 5)
                                    .accentColor(.neonCyan)
                            }
                            .padding(.horizontal, 20)

                            // Sound Type
                            MixSectionCard(title: "Sound Type") {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(GenreType.allCases, id: \.self) { genre in
                                            GenrePill(genre: genre, isSelected: selectedGenre == genre) {
                                                withAnimation(.spring04) { selectedGenre = genre }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                            }
                            .padding(.horizontal, 20)

                            BMPrimaryButton(title: "Start Focus") {
                                sessionVM.startFocus(
                                    duration: selectedDuration * 60,
                                    mood: .focus,
                                    genre: selectedGenre
                                )
                                appState.setMood(.focus)
                            }
                            .padding(.horizontal, 20)
                        } else {
                            BMSecondaryButton(title: "Stop Session") {
                                sessionVM.stopFocus(completed: false, mood: .focus, genre: selectedGenre)
                            }
                            .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 32)
                    }
                    .opacity(appear ? 1 : 0)
                }
            }
        }
        .onAppear { withAnimation(.spring04.delay(0.1)) { appear = true } }
    }
}

struct FocusTimerRing: View {
    @ObservedObject var sessionVM: SessionViewModel
    @State private var rotationDegrees: Double = 0

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.neonCyan.opacity(0.1), lineWidth: 12)
                .frame(width: 190, height: 190)

            // Progress ring
            Circle()
                .trim(from: 0, to: sessionVM.timerProgress)
                .stroke(
                    LinearGradient(colors: [Color.neonCyan, Color.neonPurple], startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 190, height: 190)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1.0), value: sessionVM.timerProgress)

            // Glow dot on progress end
            Circle()
                .fill(Color.neonCyan)
                .frame(width: 14, height: 14)
                .neonGlow(color: .neonCyan, radius: 8)
                .offset(y: -95)
                .rotationEffect(.degrees(-90 + sessionVM.timerProgress * 360))
                .animation(.linear(duration: 1.0), value: sessionVM.timerProgress)

            // Center content
            VStack(spacing: 6) {
                if sessionVM.isTimerRunning {
                    Text(sessionVM.formattedTimer)
                        .font(.system(size: 42, weight: .bold, design: .monospaced))
                        .foregroundColor(.textPrimary)
                        .neonGlow(color: .neonCyan, radius: 4)
                    Text("Remaining")
                        .font(.system(size: 13))
                        .foregroundColor(.textInactive)
                } else {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 40))
                        .foregroundColor(.neonCyan)
                        .neonGlow(color: .neonCyan, radius: 10)
                    Text("Ready")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }
}

// MARK: - Relax Mode
struct RelaxModeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var sessionVM: SessionViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var isRelaxing = false
    @State private var sleepMinutes: Double = 30
    @State private var appear = false
    @State private var wavePhase: Double = 0
    @State private var isWaving = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.bgPrimary, Color(hex: "#0F0B2A")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Relax Mode")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.textInactive)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Relax visual
                        RelaxWaveVisual(wavePhase: wavePhase, isActive: isRelaxing)
                            .frame(height: 160)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        // Status
                        if sessionVM.isSleepTimerActive {
                            VStack(spacing: 6) {
                                Text("Sleep Timer")
                                    .font(.system(size: 14))
                                    .foregroundColor(.textInactive)
                                Text(sessionVM.formattedSleepTimer)
                                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                                    .foregroundColor(.neonPurple)
                                    .neonGlow(color: .neonPurple, radius: 6)
                            }
                            .padding()
                            .cardStyle()
                            .padding(.horizontal, 20)
                        }

                        // Sleep timer slider
                        MixSectionCard(title: "Sleep Timer: \(Int(sleepMinutes)) min") {
                            Slider(value: $sleepMinutes, in: 5...120, step: 5)
                                .accentColor(.neonPurple)
                        }
                        .padding(.horizontal, 20)

                        VStack(spacing: 12) {
                            if !isRelaxing {
                                BMPrimaryButton(title: "Start Relax") {
                                    startRelax()
                                }
                            } else {
                                BMSecondaryButton(title: "Stop") {
                                    stopRelax()
                                }
                            }

                            if !sessionVM.isSleepTimerActive {
                                BMSecondaryButton(title: "Set Sleep Timer") {
                                    sessionVM.startSleepTimer(minutes: sleepMinutes)
                                }
                            } else {
                                BMSecondaryButton(title: "Cancel Sleep Timer") {
                                    sessionVM.cancelSleepTimer()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                    .opacity(appear ? 1 : 0)
                }
            }
        }
        .onAppear {
            withAnimation(.spring04.delay(0.1)) { appear = true }
            isWaving = true
            animateWave()
        }
        .onDisappear {
            isWaving = false
        }
    }

    private func animateWave() {
        guard isWaving else { return }
        withAnimation(.linear(duration: 0.05)) {
            wavePhase += 0.04
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if self.isWaving { self.animateWave() }
        }
    }

    private func startRelax() {
        isRelaxing = true
        appState.setMood(.chill)
        sessionVM.startSession(mood: .chill, mode: .relax, genre: .ambient, duration: 3600)
    }

    private func stopRelax() {
        isRelaxing = false
        sessionVM.stopSession()
    }
}

struct RelaxWaveVisual: View {
    let wavePhase: Double
    let isActive: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background gradient
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: [Color.neonPurple.opacity(0.08), Color.neonPink.opacity(0.05)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))

                Canvas { context, size in
                    let midY = size.height / 2
                    for wave in 0..<3 {
                        var path = Path()
                        let waveColors: [Color] = [.neonPurple, .neonPink, .neonCyan]
                        let amplitude: CGFloat = isActive ? CGFloat(30 - wave * 8) : CGFloat(15 - wave * 4)
                        let freq = Double(2 + wave)

                        path.move(to: CGPoint(x: 0, y: midY))
                        for x in stride(from: 0, to: size.width, by: 2) {
                            let normalX = x / size.width
                            let offset = sin(normalX * .pi * freq * 2 + wavePhase + Double(wave) * 0.8) * amplitude
                            path.addLine(to: CGPoint(x: x, y: midY + offset))
                        }
                        context.stroke(path, with: .color(waveColors[wave].opacity(0.7 - Double(wave) * 0.15)), lineWidth: CGFloat(2.5 - Double(wave) * 0.5))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Moon icon overlay
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.neonPink)
                            .neonGlow(color: .neonPink, radius: 8)
                            .padding(14)
                    }
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Energy Mode
struct EnergyModeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var sessionVM: SessionViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var isActive = false
    @State private var energyBoostData: [Double] = Array(repeating: 0, count: 20)
    @State private var appear = false
    @State private var boostTimer: Timer?
    @State private var currentBoost: Double = 0

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.bgPrimary, Color(hex: "#1A0B0B")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Energy Mode")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.textInactive)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Energy pulse indicator
                        EnergyPulseView(isActive: isActive, boostValue: currentBoost)
                            .frame(height: 200)

                        // Energy boost chart
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Energy Boost")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                Spacer()
                                Text(String(format: "%.0f%%", currentBoost))
                                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                                    .foregroundColor(.neonOrange)
                            }

                            EnergyLineChart(data: energyBoostData)
                                .frame(height: 80)
                        }
                        .padding(16)
                        .cardStyle()
                        .padding(.horizontal, 20)

                        VStack(spacing: 12) {
                            if !isActive {
                                BMPrimaryButton(title: "Start Energy Mode") {
                                    startEnergy()
                                }
                            } else {
                                BMSecondaryButton(title: "Stop") {
                                    stopEnergy()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                    .opacity(appear ? 1 : 0)
                }
            }
        }
        .onAppear { withAnimation(.spring04.delay(0.1)) { appear = true } }
        .onDisappear {
            boostTimer?.invalidate()
        }
    }

    private func startEnergy() {
        isActive = true
        appState.setMood(.energy)
        sessionVM.startSession(mood: .energy, mode: .energy, genre: .electronic, duration: 3600)
        boostTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation(.linear(duration: 0.4)) {
                self.currentBoost = Double.random(in: 50...95)
                self.energyBoostData.append(self.currentBoost)
                if self.energyBoostData.count > 20 { self.energyBoostData.removeFirst() }
            }
        }
    }

    private func stopEnergy() {
        isActive = false
        boostTimer?.invalidate()
        sessionVM.stopSession()
        withAnimation(.spring04) { currentBoost = 0 }
    }
}

struct EnergyPulseView: View {
    let isActive: Bool
    let boostValue: Double
    @State private var pulse1: CGFloat = 1.0
    @State private var pulse2: CGFloat = 1.0

    var body: some View {
        ZStack {
            if isActive {
                Circle()
                    .stroke(Color.neonOrange.opacity(0.15), lineWidth: 2)
                    .frame(width: 180, height: 180)
                    .scaleEffect(pulse1)
                    .animation(Animation.easeOut(duration: 1.2).repeatForever(autoreverses: false), value: pulse1)

                Circle()
                    .stroke(Color.neonOrange.opacity(0.1), lineWidth: 1)
                    .frame(width: 150, height: 150)
                    .scaleEffect(pulse2)
                    .animation(Animation.easeOut(duration: 1.6).repeatForever(autoreverses: false).delay(0.4), value: pulse2)
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.neonOrange.opacity(0.4), Color.neonPink.opacity(0.2), Color.clear],
                        center: .center, startRadius: 0, endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .scaleEffect(isActive ? 1 + boostValue / 500 : 0.8)
                .animation(.spring04, value: boostValue)

            Image(systemName: "bolt.fill")
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(.neonOrange)
                .neonGlow(color: .neonOrange, radius: 16)
                .scaleEffect(isActive ? 1.1 : 1.0)
                .animation(isActive ? Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true) : .default, value: isActive)
        }
        .onAppear {
            if isActive {
                pulse1 = 1.6
                pulse2 = 1.8
            }
        }
        .onChange(of: isActive) { active in
            pulse1 = active ? 1.6 : 1.0
            pulse2 = active ? 1.8 : 1.0
        }
    }
}

struct EnergyLineChart: View {
    let data: [Double]

    var body: some View {
        GeometryReader { geo in
            if data.count > 1 {
                let maxVal = data.max() ?? 100
                let minVal = data.min() ?? 0
                let range = max(maxVal - minVal, 1)

                Canvas { context, size in
                    var path = Path()
                    let stepX = size.width / CGFloat(data.count - 1)

                    for (i, val) in data.enumerated() {
                        let x = CGFloat(i) * stepX
                        let normalized = (val - minVal) / range
                        let y = size.height - CGFloat(normalized) * size.height
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }

                    context.stroke(
                        path,
                        with: .linearGradient(
                            Gradient(colors: [.neonOrange, .neonPink]),
                            startPoint: CGPoint(x: 0, y: size.height / 2),
                            endPoint: CGPoint(x: size.width, y: size.height / 2)
                        ),
                        lineWidth: 2.5
                    )
                }
            }
        }
    }
}
