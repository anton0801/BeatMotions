import SwiftUI
import Combine
import Network

struct SplashView: View {
    @State private var isAnimating = false
    @State private var showTitle = false
    @State private var bgPulse = false
    @State private var networkMonitor = NWPathMonitor()
    @State private var wavePhase: Double = 0
    @State private var wavePhase2: Double = .pi / 3
    @State private var wavePhase3: Double = .pi * 2 / 3
    @StateObject private var viewModel = BeatMotionsViewModel()
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var cancellables = Set<AnyCancellable>()
    @State private var exitScale: CGFloat = 1.0
    @State private var exitOpacity: Double = 1.0

    private let displayDuration: Double = 30.0

    var body: some View {
        NavigationView {
            ZStack {
                // Layer 1: Background gradient
                LinearGradient(
                    colors: [Color.bgPrimary, Color.bgDeep, bgPulse ? Color.bgPurple : Color(hex: "#0D0B2A")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .animation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: bgPulse)
                
                GeometryReader { geo in
                    Image("beating_load")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .ignoresSafeArea()
                        .blur(radius: 5)
                        .opacity(0.2)
                }
                .ignoresSafeArea()

                NavigationLink(
                    destination: BeatMotionsWebView().navigationBarHidden(true),
                    isActive: $viewModel.navigateToWeb
                ) { EmptyView() }
                
                NavigationLink(
                    destination: RootView().navigationBarBackButtonHidden(true),
                    isActive: $viewModel.navigateToMain
                ) { EmptyView() }
                
                // Layer 2: Neon wave bars (thematic element)
                if isAnimating {
                    GeometryReader { geo in
                        NeonBarsLayer(
                            wavePhase: wavePhase,
                            wavePhase2: wavePhase2,
                            wavePhase3: wavePhase3,
                            size: geo.size
                        )
                        .opacity(isAnimating ? 1 : 0)
                    }
                    .ignoresSafeArea()
                }

                // Radial glow center
                RadialGradient(
                    colors: [Color.neonPurple.opacity(0.25), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 200
                )
                .ignoresSafeArea()

                // Layer 3: Logo + Title
                VStack(spacing: 16) {
                    // Animated audio waveform icon
                    ZStack {
                        Circle()
                            .fill(Color.neonPurple.opacity(0.15))
                            .frame(width: 110, height: 110)
                            .scaleEffect(isAnimating ? 1.15 : 0.95)
                            .animation(Animation.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: isAnimating)

                        Circle()
                            .stroke(Color.neonPurple.opacity(0.4), lineWidth: 1.5)
                            .frame(width: 130, height: 130)
                            .scaleEffect(isAnimating ? 1.2 : 0.9)
                            .animation(Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: isAnimating)

                        Image(systemName: "waveform")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.neonPurple)
                            .neonGlow(color: .neonPurple, radius: 12)
                    }

                    VStack(spacing: 6) {
                        Text("Beat Motion")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                            .neonGlow(color: .neonPurple, radius: 6)

                        Text("Feel your rhythm")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.textSecondary)
                            .tracking(3)
                            .textCase(.uppercase)
                    }
                }
                .scaleEffect(logoScale * exitScale)
                .opacity(logoOpacity * exitOpacity)
            }
            .onDisappear {
                isAnimating = false
                bgPulse = false
                showTitle = false
                wavePhase = 0
                wavePhase2 = .pi / 3
                wavePhase3 = .pi * 2 / 3
                logoScale = 0.5
                logoOpacity = 0
            }
            .fullScreenCover(isPresented: $viewModel.showPermissionPrompt) {
                BeatMotionsConsentView(viewModel: viewModel)
            }
            .onAppear {
                setupStreams()
                setupNetworkMonitoring()
                startAnimation()
                viewModel.boot()
            }
            .fullScreenCover(isPresented: $viewModel.showOfflineView) {
                OfflineView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func setupStreams() {
        NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { data in
                viewModel.ingestAttribution(data)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { data in
                viewModel.ingestDeeplinks(data)
            }
            .store(in: &cancellables)
    }

    private func startAnimation() {
        // Phase 1: bg builds (0-0.6s)
        withAnimation(.easeIn(duration: 0.6)) {
            bgPulse = true
        }
        // Phase 2: waves animate (0.6-1.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isAnimating = true
            startWaveAnimation()
        }
        // Phase 3: logo appears (1.4-2.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
        // Phase 4: exit (2.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) {
            withAnimation(.easeIn(duration: 0.4)) {
                exitScale = 1.4
                exitOpacity = 0
            }
        }
    }

    private func startWaveAnimation() {
        guard isAnimating else { return }
        withAnimation(Animation.linear(duration: 0.05)) {
            wavePhase += 0.08
            wavePhase2 += 0.06
            wavePhase3 += 0.10
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if self.isAnimating { self.startWaveAnimation() }
        }
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { path in
            Task { @MainActor in
                viewModel.networkConnectivityChanged(path.status == .satisfied)
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }
    
}

struct NeonBarsLayer: View {
    let wavePhase: Double
    let wavePhase2: Double
    let wavePhase3: Double
    let size: CGSize

    private let barCount = 40

    var body: some View {
        ZStack {
            // Bottom band - cyan
            HStack(spacing: 3) {
                ForEach(0..<barCount, id: \.self) { i in
                    let height = barHeight(for: i, phase: wavePhase, scale: 60)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.neonCyan.opacity(0.6))
                        .frame(width: (size.width / CGFloat(barCount)) - 3, height: height)
                        .neonGlow(color: .neonCyan, radius: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .position(x: size.width / 2, y: size.height * 0.72)

            // Middle band - purple
            HStack(spacing: 3) {
                ForEach(0..<barCount, id: \.self) { i in
                    let height = barHeight(for: i, phase: wavePhase2, scale: 80)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.neonPurple.opacity(0.7))
                        .frame(width: (size.width / CGFloat(barCount)) - 3, height: height)
                        .neonGlow(color: .neonPurple, radius: 5)
                }
            }
            .frame(maxWidth: .infinity)
            .position(x: size.width / 2, y: size.height * 0.78)

            // Top band - pink
            HStack(spacing: 3) {
                ForEach(0..<barCount, id: \.self) { i in
                    let height = barHeight(for: i, phase: wavePhase3, scale: 50)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.neonPink.opacity(0.6))
                        .frame(width: (size.width / CGFloat(barCount)) - 3, height: height)
                        .neonGlow(color: .neonPink, radius: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .position(x: size.width / 2, y: size.height * 0.84)
        }
    }

    private func barHeight(for index: Int, phase: Double, scale: Double) -> CGFloat {
        let angle = (Double(index) / Double(barCount)) * .pi * 4 + phase
        let value = (sin(angle) + 1) / 2
        return CGFloat(value * scale + 8)
    }
}

