import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var isVisible = true

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            TabView(selection: $currentPage) {
                OnboardingPage1(onNext: { advance() }).tag(0)
                OnboardingPage2(onNext: { advance() }).tag(1)
                OnboardingPage3(onFinish: { finish() }).tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring04, value: currentPage)

            // Overlay controls
            VStack {
                HStack {
                    Spacer()
                    Button("Skip") {
                        finish()
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                .padding(.top, 8)

                Spacer()

                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? Color.neonPurple : Color.textInactive)
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring04, value: currentPage)
                    }
                }
                .padding(.bottom, 100)
            }
        }
        .opacity(isVisible ? 1 : 0)
        .onDisappear { isVisible = false }
    }

    private func advance() {
        withAnimation(.spring04) { currentPage += 1 }
    }

    private func finish() {
        withAnimation(.easeOut(duration: 0.3)) {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Page 1: Tap to burst particles
struct OnboardingPage1: View {
    let onNext: () -> Void
    @State private var particles: [BurstParticle] = []
    @State private var iconScale: CGFloat = 1.0
    @State private var tapCount = 0
    @State private var isVisible = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.bgPrimary, Color.bgDeep], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            // Particles
            ForEach(particles) { p in
                Circle()
                    .fill(p.color)
                    .frame(width: p.size, height: p.size)
                    .offset(x: p.x, y: p.y)
                    .opacity(p.opacity)
            }

            VStack(spacing: 32) {
                Spacer()

                Text("Choose your\nsound mood")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)

                Text("Select how you feel and get a\nmatching music setup.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)

                Spacer()

                // Tappable icon
                ZStack {
                    Circle()
                        .fill(Color.neonPurple.opacity(0.15))
                        .frame(width: 130, height: 130)

                    Image(systemName: "music.note.list")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.neonPurple)
                        .neonGlow(color: .neonPurple, radius: 10)
                }
                .scaleEffect(iconScale)
                .onTapGesture { burst() }

                Text(tapCount == 0 ? "Tap the icon!" : "✨ Feel the rhythm!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textInactive)
                    .animation(.spring04, value: tapCount)

                Spacer()

                BMPrimaryButton(title: "Next", action: onNext)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                isVisible = true
            }
        }
        .onDisappear { isVisible = false }
    }

    private func burst() {
        tapCount += 1
        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
            iconScale = 1.3
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring04) { iconScale = 1.0 }
        }
        let colors: [Color] = [.neonPurple, .neonPink, .neonCyan, .neonOrange]
        for _ in 0..<12 {
            let angle = Double.random(in: 0..<360)
            let dist = CGFloat.random(in: 60...140)
            var p = BurstParticle(
                x: 0, y: 0,
                color: colors.randomElement()!,
                size: CGFloat.random(in: 6...14),
                opacity: 1
            )
            particles.append(p)
            let id = p.id
            withAnimation(.easeOut(duration: 0.7)) {
                if let idx = particles.firstIndex(where: { $0.id == id }) {
                    particles[idx].x = cos(angle * .pi / 180) * dist
                    particles[idx].y = sin(angle * .pi / 180) * dist
                    particles[idx].opacity = 0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                particles.removeAll { $0.id == id }
            }
            _ = p // suppress warning
        }
    }
}

struct BurstParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var size: CGFloat
    var opacity: Double
}

// MARK: - Page 2: Drag gesture
struct OnboardingPage2: View {
    let onNext: () -> Void
    @State private var dragOffset: CGSize = .zero
    @State private var isVisible = false
    @State private var ringScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.bgDeep, Color.bgPrimary], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Text("Control your\nrhythm")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)

                Text("Use focus, energy and relax modes\nduring the day.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(isVisible ? 1 : 0)

                Spacer()

                // Draggable equalizer element
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(
                                [Color.neonCyan, Color.neonPurple, Color.neonPink][i].opacity(0.3),
                                lineWidth: 1.5
                            )
                            .frame(width: CGFloat(80 + i * 40), height: CGFloat(80 + i * 40))
                            .scaleEffect(ringScale)
                    }

                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color.neonPurple, Color.neonPink], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 70, height: 70)
                            .shadow(color: .neonPurple.opacity(0.5), radius: 12)

                        Image(systemName: "slider.horizontal.3")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .foregroundColor(.white)
                    }
                    .offset(dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let maxDist: CGFloat = 50
                                let x = max(-maxDist, min(maxDist, value.translation.width))
                                let y = max(-maxDist, min(maxDist, value.translation.height))
                                dragOffset = CGSize(width: x, height: y)
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    ringScale = 1 + abs(x + y) / 500
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.spring04) {
                                    dragOffset = .zero
                                    ringScale = 1.0
                                }
                            }
                    )
                }
                .frame(height: 200)

                Text("Drag to control the energy")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textInactive)

                Spacer()

                BMPrimaryButton(title: "Next", action: onNext)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.spring04.delay(0.2)) { isVisible = true }
        }
        .onDisappear { isVisible = false }
    }
}

// MARK: - Page 3: Scroll-driven wave
struct OnboardingPage3: View {
    let onFinish: () -> Void
    @State private var isVisible = false
    @State private var waveOffset: CGFloat = 0
    @State private var isWaving = false
    @State private var scrollProgress: Double = 0

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.bgPurple, Color.bgPrimary], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Text("Watch the\nneon flow")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)

                Text("Color lines react to your audio\nand session progress.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(isVisible ? 1 : 0)

                Spacer()

                // Animated neon bars preview
                ScrollingWavePreview(waveOffset: waveOffset)
                    .frame(height: 120)
                    .padding(.horizontal, 20)

                // Scroll gesture area
                GeometryReader { geo in
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.bgCard.opacity(0.5))
                        Text("← Slide to preview →")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.textInactive)
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { val in
                                waveOffset = val.translation.width / 30
                            }
                            .onEnded { _ in
                                withAnimation(.spring04) { waveOffset = 0 }
                            }
                    )
                }
                .frame(height: 44)
                .padding(.horizontal, 40)

                Spacer()

                BMPrimaryButton(title: "Start Now", action: onFinish)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.spring04.delay(0.2)) { isVisible = true }
            startWave()
        }
        .onDisappear {
            isWaving = false
            isVisible = false
        }
    }

    private func startWave() {
        guard !isWaving else { return }
        isWaving = true
    }
}

struct ScrollingWavePreview: View {
    let waveOffset: CGFloat
    @State private var phase: Double = 0
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<35, id: \.self) { i in
                let h = barHeight(for: i)
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor(for: i))
                    .frame(width: 6, height: h)
                    .neonGlow(color: barColorRaw(for: i), radius: 4)
            }
        }
        .onAppear {
            isAnimating = true
            animate()
        }
        .onDisappear { isAnimating = false }
    }

    private func animate() {
        guard isAnimating else { return }
        withAnimation(.linear(duration: 0.05)) {
            phase += 0.1 + Double(waveOffset) * 0.02
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if isAnimating { animate() }
        }
    }

    private func barHeight(for i: Int) -> CGFloat {
        let angle = Double(i) / 35.0 * .pi * 4 + phase
        return CGFloat((sin(angle) + 1) / 2 * 80 + 20)
    }

    private func barColorRaw(for i: Int) -> Color {
        let colors: [Color] = [.neonPurple, .neonPink, .neonCyan, .neonOrange]
        return colors[i % colors.count]
    }

    private func barColor(for i: Int) -> Color {
        barColorRaw(for: i).opacity(0.8)
    }
}

// MARK: - Shared Button
struct BMPrimaryButton: View {
    let title: String
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(colors: [Color.neonPurple, Color.neonPink],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(14)
                .shadow(color: .neonPurple.opacity(0.4), radius: 12, y: 4)
        }
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.spring04) { isPressed = true } }
                .onEnded { _ in withAnimation(.spring04) { isPressed = false } }
        )
    }
}

struct BMSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.btnSecondary)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
    }
}
