import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .dashboard

    enum Tab: String, CaseIterable {
        case dashboard = "house.fill"
        case playlists = "music.note.list"
        case visualizer = "waveform"
        case stats = "chart.bar.fill"
        case settings = "gearshape.fill"

        var label: String {
            switch self {
            case .dashboard: return "Home"
            case .playlists: return "Playlists"
            case .visualizer: return "Visualizer"
            case .stats: return "Stats"
            case .settings: return "Settings"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.bgPrimary.ignoresSafeArea()

            // Content
            Group {
                switch selectedTab {
                case .dashboard:  DashboardView()
                case .playlists:  PlaylistsView()
                case .visualizer: VisualizerView()
                case .stats:      StatsView()
                case .settings:   SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 80)

            // Custom tab bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: MainTabView.Tab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTabView.Tab.allCases, id: \.self) { tab in
                TabBarItem(tab: tab, isSelected: selectedTab == tab) {
                    withAnimation(.spring04) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            ZStack {
                Color.bgDeep.opacity(0.95)
                Color.bgPurple.opacity(0.3)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.4), radius: 20, y: -4)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

struct TabBarItem: View {
    let tab: MainTabView.Tab
    let isSelected: Bool
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.neonPurple.opacity(0.2))
                            .frame(width: 44, height: 32)
                    }
                    Image(systemName: tab.rawValue)
                        .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .neonPurple : .textInactive)
                        .neonGlow(color: isSelected ? .neonPurple : .clear, radius: 6)
                }
                Text(tab.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .neonPurple : .textInactive)
            }
            .frame(maxWidth: .infinity)
        }
        .scaleEffect(isPressed ? 0.88 : 1.0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.spring04) { isPressed = true } }
                .onEnded { _ in withAnimation(.spring04) { isPressed = false } }
        )
    }
}
