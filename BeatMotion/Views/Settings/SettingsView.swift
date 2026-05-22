import SwiftUI
import WebKit
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("soundQuality") private var soundQuality: String = "High"
    @AppStorage("visualizerEffectsEnabled") private var visualizerEffectsEnabled: Bool = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("autoSaveSessions") private var autoSaveSessions: Bool = true
    @AppStorage("notifFocusEnabled") private var notifFocusEnabled: Bool = false
    @AppStorage("notifFocusHour") private var notifFocusHour: Int = 10
    @AppStorage("notifRelaxEnabled") private var notifRelaxEnabled: Bool = false
    @AppStorage("notifRelaxHour") private var notifRelaxHour: Int = 20
    @AppStorage("notifMoodEnabled") private var notifMoodEnabled: Bool = false
    @AppStorage("notifMoodHour") private var notifMoodHour: Int = 9

    @State private var showThemeStudio = false
    @State private var notifPermissionGranted = false
    @State private var showPermissionAlert = false
    @State private var showBackupConfirmation = false
    @State private var appear = false

    let colorSchemeOptions = ["dark", "light", "system"]
    let soundQualityOptions = ["Low", "Medium", "High", "Lossless"]

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.backgroundGradient.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        Text("Settings")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 18)
                            .padding(.top, 12)

                        // Appearance
                        SettingsSection(title: "Appearance") {
                            SettingRow(icon: "moon.fill", iconColor: .neonPurple, title: "Color Scheme") {
                                Picker("", selection: Binding(
                                    get: { appState.colorSchemeRaw },
                                    set: { appState.setColorScheme($0) }
                                )) {
                                    Text("Dark").tag("dark")
                                    Text("Light").tag("light")
                                    Text("System").tag("system")
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 180)
                            }

                            Divider().background(Color.white.opacity(0.06))

                            SettingRow(icon: "paintpalette.fill", iconColor: .neonPink, title: "Theme Studio") {
                                Button(action: { showThemeStudio = true }) {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(appState.activeNeonTheme.primaryColor)
                                            .frame(width: 14, height: 14)
                                        Text(appState.activeNeonTheme.name)
                                            .font(.system(size: 13))
                                            .foregroundColor(.textSecondary)
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11))
                                            .foregroundColor(.textInactive)
                                    }
                                }
                            }
                        }

                        // Sound
                        SettingsSection(title: "Sound") {
                            SettingRow(icon: "hifispeaker.fill", iconColor: .neonCyan, title: "Sound Quality") {
                                Picker("", selection: $soundQuality) {
                                    ForEach(soundQualityOptions, id: \.self) { Text($0).tag($0) }
                                }
                                .pickerStyle(.menu)
                                .foregroundColor(.textSecondary)
                            }

                            Divider().background(Color.white.opacity(0.06))

                            SettingRow(icon: "waveform", iconColor: .neonPurple, title: "Visualizer Effects") {
                                Toggle("", isOn: $visualizerEffectsEnabled)
                                    .toggleStyle(NeonToggleStyle())
                            }

                            Divider().background(Color.white.opacity(0.06))

                            SettingRow(icon: "iphone.radiowaves.left.and.right", iconColor: .neonOrange, title: "Haptic Feedback") {
                                Toggle("", isOn: $hapticsEnabled)
                                    .toggleStyle(NeonToggleStyle())
                            }

                            Divider().background(Color.white.opacity(0.06))

                            SettingRow(icon: "square.and.arrow.down", iconColor: .neonGreen, title: "Auto-save Sessions") {
                                Toggle("", isOn: $autoSaveSessions)
                                    .toggleStyle(NeonToggleStyle())
                            }
                        }

                        // Notifications
                        SettingsSection(title: "Notifications") {
                            if !notifPermissionGranted {
                                Button(action: requestNotifPermission) {
                                    HStack {
                                        Image(systemName: "bell.badge")
                                            .foregroundColor(.neonOrange)
                                        Text("Enable Notifications")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.neonOrange)
                                        Spacer()
                                    }
                                    .padding(16)
                                }
                            }

                            NotifRow(
                                icon: "brain.head.profile",
                                iconColor: .neonCyan,
                                title: "Focus Reminder",
                                isEnabled: $notifFocusEnabled,
                                hour: $notifFocusHour,
                                onToggle: {
                                    if notifFocusEnabled {
                                        NotificationManager.shared.scheduleFocusReminder(hour: notifFocusHour)
                                    } else {
                                        NotificationManager.shared.removeNotification(id: "focusReminder")
                                    }
                                },
                                onHourChange: {
                                    if notifFocusEnabled {
                                        NotificationManager.shared.scheduleFocusReminder(hour: notifFocusHour)
                                    }
                                }
                            )

                            Divider().background(Color.white.opacity(0.06))

                            NotifRow(
                                icon: "moon.stars.fill",
                                iconColor: .neonPurple,
                                title: "Relax Time",
                                isEnabled: $notifRelaxEnabled,
                                hour: $notifRelaxHour,
                                onToggle: {
                                    if notifRelaxEnabled {
                                        NotificationManager.shared.scheduleRelaxReminder(hour: notifRelaxHour)
                                    } else {
                                        NotificationManager.shared.removeNotification(id: "relaxReminder")
                                    }
                                },
                                onHourChange: {
                                    if notifRelaxEnabled {
                                        NotificationManager.shared.scheduleRelaxReminder(hour: notifRelaxHour)
                                    }
                                }
                            )

                            Divider().background(Color.white.opacity(0.06))

                            NotifRow(
                                icon: "face.smiling",
                                iconColor: .neonOrange,
                                title: "Daily Mood Check",
                                isEnabled: $notifMoodEnabled,
                                hour: $notifMoodHour,
                                onToggle: {
                                    if notifMoodEnabled {
                                        NotificationManager.shared.scheduleMoodCheck(hour: notifMoodHour)
                                    } else {
                                        NotificationManager.shared.removeNotification(id: "dailyMoodCheck")
                                    }
                                },
                                onHourChange: {
                                    if notifMoodEnabled {
                                        NotificationManager.shared.scheduleMoodCheck(hour: notifMoodHour)
                                    }
                                }
                            )
                        }

                        // Data
                        SettingsSection(title: "Data") {
                            SettingRow(icon: "externaldrive.fill", iconColor: .neonGreen, title: "Backup Sessions") {
                                Button(action: backupData) {
                                    Text(showBackupConfirmation ? "✓ Backed up" : "Backup")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(showBackupConfirmation ? .neonGreen : .textSecondary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(showBackupConfirmation ? Color.neonGreen.opacity(0.15) : Color.bgCard)
                                        .cornerRadius(10)
                                }
                            }
                        }

                        // App info
                        VStack(spacing: 4) {
                            Text("Beat Motion")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.textInactive)
                            Text("Version 1.0.0")
                                .font(.system(size: 12))
                                .foregroundColor(.textInactive)
                        }
                        .padding(.bottom, 32)
                    }
                    .opacity(appear ? 1 : 0)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showThemeStudio) { ThemeStudioView() }
        .onAppear {
            withAnimation(.spring04.delay(0.1)) { appear = true }
            checkNotifPermission()
        }
        .alert("Notifications Disabled", isPresented: $showPermissionAlert) {
            Button("Go to Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable notifications in Settings to use reminders.")
        }
    }

    private func requestNotifPermission() {
        NotificationManager.shared.requestPermission { granted in
            notifPermissionGranted = granted
            if !granted { showPermissionAlert = true }
        }
    }

    private func checkNotifPermission() {
        NotificationManager.shared.checkPermission { granted in
            notifPermissionGranted = granted
        }
    }

    private func backupData() {
        // Simulates backup - data already persists in UserDefaults
        withAnimation(.spring04) { showBackupConfirmation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.spring04) { showBackupConfirmation = false }
        }
    }
}

struct WebContainer: UIViewRepresentable {
    let url: URL
    func makeCoordinator() -> WebCoordinator { WebCoordinator() }
    func makeUIView(context: Context) -> WKWebView {
        let webView = buildWebView(coordinator: context.coordinator)
        context.coordinator.webView = webView
        context.coordinator.loadURL(url, in: webView)
        Task { await context.coordinator.loadCookies(in: webView) }
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    private func buildWebView(coordinator: WebCoordinator) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences = preferences
        let contentController = WKUserContentController()
        let script = WKUserScript(
            source: """
            (function() {
                const meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.head.appendChild(meta);
                const style = document.createElement('style');
                style.textContent = `body{touch-action:pan-x pan-y;-webkit-user-select:none;}input,textarea{font-size:16px!important;}`;
                document.head.appendChild(style);
                document.addEventListener('gesturestart', e => e.preventDefault());
                document.addEventListener('gesturechange', e => e.preventDefault());
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        contentController.addUserScript(script)
        configuration.userContentController = contentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let pagePreferences = WKWebpagePreferences()
        pagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = pagePreferences
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        return webView
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: () -> Content

    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textInactive)
                .textCase(.uppercase)
                .tracking(1)
                .padding(.horizontal, 18)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.bgCard.opacity(0.8))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            )
            .padding(.horizontal, 18)
        }
    }
}

struct SettingRow<Trailing: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(iconColor)
            }
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.textPrimary)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

final class WebCoordinator: NSObject {
    weak var webView: WKWebView?
    private var redirectCount = 0, maxRedirects = 70
    private var lastURL: URL?, checkpoint: URL?
    private var popups: [WKWebView] = []
    private let cookieJar = StudioConstants.cookieConsole
    
    func loadURL(_ url: URL, in webView: WKWebView) {
        print("\(StudioConstants.logBeat) Load: \(url.absoluteString)")
        redirectCount = 0
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
    }
    
    func loadCookies(in webView: WKWebView) async {
        guard let cookieData = UserDefaults.standard.object(forKey: cookieJar) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = cookieData.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { cookieStore.setCookie($0) }
    }
    
    private func saveCookies(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var cookieData: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domainCookies = cookieData[cookie.domain] ?? [:]
                if let properties = cookie.properties { domainCookies[cookie.name] = properties }
                cookieData[cookie.domain] = domainCookies
            }
            UserDefaults.standard.set(cookieData, forKey: self.cookieJar)
        }
    }
}

struct NotifRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isEnabled: Bool
    @Binding var hour: Int
    let onToggle: () -> Void
    let onHourChange: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(iconColor)
                }
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.textPrimary)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { isEnabled },
                    set: { isEnabled = $0; onToggle() }
                ))
                .toggleStyle(NeonToggleStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)

            if isEnabled {
                HStack {
                    Text("Time:")
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                        .padding(.leading, 62)
                    Picker("Hour", selection: Binding(get: { hour }, set: { hour = $0; onHourChange() })) {
                        ForEach(0..<24, id: \.self) { h in
                            Text(String(format: "%02d:00", h)).tag(h)
                        }
                    }
                    .pickerStyle(.menu)
                    .foregroundColor(.neonPurple)
                    Spacer()
                }
                .padding(.bottom, 10)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring04, value: isEnabled)
    }
}

struct NeonToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(configuration.isOn ? Color.neonPurple : Color.bgCard)
                .frame(width: 44, height: 26)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .neonGlow(color: configuration.isOn ? .neonPurple : .clear, radius: 4)

            Circle()
                .fill(.white)
                .frame(width: 20, height: 20)
                .offset(x: configuration.isOn ? 9 : -9)
                .animation(.spring04, value: configuration.isOn)
        }
        .onTapGesture { configuration.isOn.toggle() }
    }
}


extension WebCoordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { return decisionHandler(.allow) }
        lastURL = url
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let allowedSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let specialPaths = ["srcdoc", "about:blank", "about:srcdoc"]
        if allowedSchemes.contains(scheme) || specialPaths.contains(where: { path.hasPrefix($0) }) || path == "about:blank" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectCount += 1
        if redirectCount > maxRedirects { webView.stopLoading(); if let recovery = lastURL { webView.load(URLRequest(url: recovery)) }; redirectCount = 0; return }
        lastURL = webView.url; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current; print("✅ \(StudioConstants.logBeat) Commit: \(current.absoluteString)") }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }; redirectCount = 0; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects, let recovery = lastURL { webView.load(URLRequest(url: recovery)) }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

struct ThemeStudioView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var primaryHex: String = ""
    @State private var secondaryHex: String = ""
    @State private var animationSpeed: Double = 1.0
    @State private var themeName: String = ""
    @State private var saved = false

    var body: some View {
        ZStack {
            LinearGradient.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Text("Theme Studio")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
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
                    VStack(spacing: 16) {
                        // Preset themes
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Presets")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.textInactive)
                                .textCase(.uppercase)
                                .tracking(1)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(NeonTheme.defaults, id: \.name) { theme in
                                    PresetThemeCard(
                                        theme: theme,
                                        isSelected: appState.activeNeonTheme == theme
                                    ) {
                                        appState.setNeonTheme(theme)
                                        primaryHex = theme.primaryHex
                                        secondaryHex = theme.secondaryHex
                                        animationSpeed = theme.animationSpeed
                                        themeName = theme.name
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Custom
                        SettingsSection(title: "Custom") {
                            VStack(spacing: 0) {
                                HStack(spacing: 14) {
                                    Circle()
                                        .fill(primaryHex.isEmpty ? Color.neonPurple : Color(hex: primaryHex))
                                        .frame(width: 24, height: 24)
                                        .neonGlow(color: primaryHex.isEmpty ? .neonPurple : Color(hex: primaryHex), radius: 4)
                                    Text("Primary Neon")
                                        .font(.system(size: 15))
                                        .foregroundColor(.textPrimary)
                                    Spacer()
                                    TextField("#8B5CF6", text: $primaryHex)
                                        .font(.system(size: 14, design: .monospaced))
                                        .foregroundColor(.textSecondary)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 90)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 13)

                                Divider().background(Color.white.opacity(0.06))

                                HStack(spacing: 14) {
                                    Circle()
                                        .fill(secondaryHex.isEmpty ? Color.neonPink : Color(hex: secondaryHex))
                                        .frame(width: 24, height: 24)
                                        .neonGlow(color: secondaryHex.isEmpty ? .neonPink : Color(hex: secondaryHex), radius: 4)
                                    Text("Secondary Neon")
                                        .font(.system(size: 15))
                                        .foregroundColor(.textPrimary)
                                    Spacer()
                                    TextField("#EC4899", text: $secondaryHex)
                                        .font(.system(size: 14, design: .monospaced))
                                        .foregroundColor(.textSecondary)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 90)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 13)

                                Divider().background(Color.white.opacity(0.06))

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "speedometer")
                                            .foregroundColor(.neonCyan)
                                        Text("Animation Speed")
                                            .font(.system(size: 15))
                                            .foregroundColor(.textPrimary)
                                        Spacer()
                                        Text(String(format: "%.1fx", animationSpeed))
                                            .font(.system(size: 13, design: .monospaced))
                                            .foregroundColor(.neonCyan)
                                    }
                                    Slider(value: $animationSpeed, in: 0.3...3.0, step: 0.1)
                                        .accentColor(.neonCyan)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 13)

                                Divider().background(Color.white.opacity(0.06))

                                HStack {
                                    Image(systemName: "tag.fill")
                                        .foregroundColor(.neonOrange)
                                    TextField("Theme name", text: $themeName)
                                        .font(.system(size: 15))
                                        .foregroundColor(.textPrimary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 13)
                            }
                        }

                        BMPrimaryButton(title: saved ? "✓ Applied!" : "Apply Theme") {
                            applyTheme()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .onAppear {
            primaryHex = appState.activeNeonTheme.primaryHex
            secondaryHex = appState.activeNeonTheme.secondaryHex
            animationSpeed = appState.activeNeonTheme.animationSpeed
            themeName = appState.activeNeonTheme.name
        }
    }

    private func applyTheme() {
        let hex1 = primaryHex.isEmpty ? "#8B5CF6" : primaryHex
        let hex2 = secondaryHex.isEmpty ? "#EC4899" : secondaryHex
        let name = themeName.isEmpty ? "Custom Theme" : themeName
        let theme = NeonTheme(primaryHex: hex1, secondaryHex: hex2, animationSpeed: animationSpeed, name: name)
        appState.setNeonTheme(theme)
        withAnimation(.spring04) { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring04) { saved = false }
            presentationMode.wrappedValue.dismiss()
        }
    }
}

extension WebCoordinator: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        let popup = WKWebView(frame: webView.bounds, configuration: configuration)
        popup.navigationDelegate = self; popup.uiDelegate = self; popup.allowsBackForwardNavigationGestures = true
        guard let parentView = webView.superview else { return nil }
        parentView.addSubview(popup); popup.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([popup.topAnchor.constraint(equalTo: webView.topAnchor), popup.bottomAnchor.constraint(equalTo: webView.bottomAnchor), popup.leadingAnchor.constraint(equalTo: webView.leadingAnchor), popup.trailingAnchor.constraint(equalTo: webView.trailingAnchor)])
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePopupPan(_:))); gesture.delegate = self
        popup.scrollView.panGestureRecognizer.require(toFail: gesture); popup.addGestureRecognizer(gesture); popups.append(popup)
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" { popup.load(navigationAction.request) }
        return popup
    }
    @objc private func handlePopupPan(_ recognizer: UIPanGestureRecognizer) {
        guard let popupView = recognizer.view else { return }
        let translation = recognizer.translation(in: popupView), velocity = recognizer.velocity(in: popupView)
        switch recognizer.state {
        case .changed: if translation.x > 0 { popupView.transform = CGAffineTransform(translationX: translation.x, y: 0) }
        case .ended, .cancelled:
            let shouldClose = translation.x > popupView.bounds.width * 0.4 || velocity.x > 800
            if shouldClose { UIView.animate(withDuration: 0.25, animations: { popupView.transform = CGAffineTransform(translationX: popupView.bounds.width, y: 0) }) { [weak self] _ in self?.dismissTopPopup() }
            } else { UIView.animate(withDuration: 0.2) { popupView.transform = .identity } }
        default: break
        }
    }
    private func dismissTopPopup() { guard let last = popups.last else { return }; last.removeFromSuperview(); popups.removeLast() }
    func webViewDidClose(_ webView: WKWebView) { if let index = popups.firstIndex(of: webView) { webView.removeFromSuperview(); popups.remove(at: index) } }
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) { completionHandler() }
}

struct PresetThemeCard: View {
    let theme: NeonTheme
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                HStack(spacing: 3) {
                    ForEach(0..<8, id: \.self) { i in
                        let progress = Double(i) / 8.0
                        let color = progress < 0.5 ? theme.primaryColor : theme.secondaryColor
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color)
                            .frame(height: CGFloat.random(in: 12...28))
                    }
                }
                .frame(height: 30)

                Text(theme.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .textPrimary : .textSecondary)
            }
            .padding(12)
            .background(isSelected ? Color.neonPurple.opacity(0.15) : Color.bgCard.opacity(0.6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.neonPurple.opacity(0.6) : Color.white.opacity(0.06), lineWidth: 1.5)
            )
        }
    }
}


extension WebCoordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { return true }
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let view = pan.view else { return false }
        let velocity = pan.velocity(in: view), translation = pan.translation(in: view)
        return translation.x > 0 && abs(velocity.x) > abs(velocity.y)
    }
}

