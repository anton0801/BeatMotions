import SwiftUI

struct StatsView: View {
    @EnvironmentObject var statsVM: StatsViewModel
    @EnvironmentObject var sessionVM: SessionViewModel
    @State private var showHistory = false
    @State private var appear = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.backgroundGradient.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Statistics")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Button(action: { showHistory = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 13))
                                Text("History")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.bgCard)
                            .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 16)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            // Period picker
                            PeriodPickerView(selectedPeriod: $statsVM.period)
                                .padding(.horizontal, 18)

                            // Summary cards
                            HStack(spacing: 12) {
                                StatCard(
                                    value: String(format: "%.0f", statsVM.totalMinutes),
                                    unit: "min",
                                    label: "Total Listened",
                                    icon: "headphones",
                                    color: .neonPurple
                                )
                                StatCard(
                                    value: "\(statsVM.totalFocusSessions)",
                                    unit: "sessions",
                                    label: "Focus Sessions",
                                    icon: "brain.head.profile",
                                    color: .neonCyan
                                )
                            }
                            .padding(.horizontal, 18)

                            StatCard(
                                value: String(format: "%.0f%%", statsVM.avgEnergy),
                                unit: "",
                                label: "Average Energy Score",
                                icon: "bolt.fill",
                                color: .neonOrange
                            )
                            .padding(.horizontal, 18)

                            // Minutes chart
                            ChartCard(
                                title: "Minutes Listened",
                                data: statsVM.minutesData(for: statsVM.period),
                                color: .neonPurple
                            )
                            .padding(.horizontal, 18)

                            // Energy chart
                            ChartCard(
                                title: "Energy Score",
                                data: statsVM.energyData(for: statsVM.period),
                                color: .neonOrange
                            )
                            .padding(.horizontal, 18)

                            // Mood usage
                            MoodUsageCard(moodUsage: statsVM.moodUsage)
                                .padding(.horizontal, 18)

                            Spacer(minLength: 20)
                        }
                        .opacity(appear ? 1 : 0)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showHistory) { HistoryView() }
        .onAppear { withAnimation(.spring04.delay(0.1)) { appear = true } }
    }
}

struct PeriodPickerView: View {
    @Binding var selectedPeriod: StatsViewModel.StatPeriod

    var body: some View {
        HStack(spacing: 0) {
            ForEach(StatsViewModel.StatPeriod.allCases, id: \.self) { period in
                Button(action: { withAnimation(.spring04) { selectedPeriod = period } }) {
                    Text(period.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selectedPeriod == period ? .white : .textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedPeriod == period ? Color.neonPurple : Color.clear)
                        .cornerRadius(10)
                }
            }
        }
        .padding(4)
        .background(Color.bgCard)
        .cornerRadius(14)
    }
}

struct StatCard: View {
    let value: String
    let unit: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(value)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.system(size: 12))
                            .foregroundColor(.textInactive)
                    }
                }
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .cardStyle()
    }
}

struct ChartCard: View {
    let title: String
    let data: [Double]
    let color: Color

    var maxVal: Double { data.max() ?? 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.textPrimary)

            HStack(alignment: .bottom, spacing: 3) {
                ForEach(Array(data.enumerated()), id: \.offset) { i, val in
                    let h = CGFloat(val / maxVal * 80 + 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.4)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(height: h)
                        .neonGlow(color: color, radius: 2)
                }
            }
            .frame(height: 90)
            .animation(.spring04, value: data.count)
        }
        .padding(16)
        .cardStyle()
    }
}

struct MoodUsageCard: View {
    let moodUsage: [(MoodType, Int)]

    var total: Int { moodUsage.reduce(0) { $0 + $1.1 } }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Mood Usage")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.textPrimary)

            if moodUsage.isEmpty {
                Text("No data yet")
                    .font(.system(size: 14))
                    .foregroundColor(.textInactive)
            } else {
                ForEach(moodUsage.prefix(5), id: \.0) { mood, count in
                    HStack(spacing: 12) {
                        Image(systemName: mood.icon)
                            .font(.system(size: 14))
                            .foregroundColor(mood.primaryColor)
                            .frame(width: 20)

                        Text(mood.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .frame(width: 60, alignment: .leading)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.bgCard)
                                    .frame(height: 8)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(mood.gradient)
                                    .frame(width: total > 0 ? geo.size.width * CGFloat(count) / CGFloat(total) : 0, height: 8)
                                    .animation(.spring04, value: count)
                            }
                        }
                        .frame(height: 8)

                        Text("\(count)")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.textInactive)
                            .frame(width: 24, alignment: .trailing)
                    }
                }
            }
        }
        .padding(16)
        .cardStyle()
    }
}

// MARK: - History View
struct HistoryView: View {
    @EnvironmentObject var sessionVM: SessionViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedMoodFilter: MoodType? = nil
    @State private var selectedModeFilter: MusicSession.SessionMode? = nil

    var filteredSessions: [MusicSession] {
        sessionVM.sessions.filter { session in
            let moodMatch = selectedMoodFilter == nil || session.mood == selectedMoodFilter
            let modeMatch = selectedModeFilter == nil || session.mode == selectedModeFilter
            return moodMatch && modeMatch
        }
    }

    var body: some View {
        ZStack {
            LinearGradient.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("History")
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
                .padding(.bottom, 12)

                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All Moods", isSelected: selectedMoodFilter == nil) {
                            selectedMoodFilter = nil
                        }
                        ForEach(MoodType.allCases, id: \.self) { mood in
                            FilterChip(title: mood.rawValue, isSelected: selectedMoodFilter == mood, color: mood.primaryColor) {
                                selectedMoodFilter = selectedMoodFilter == mood ? nil : mood
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All Modes", isSelected: selectedModeFilter == nil) {
                            selectedModeFilter = nil
                        }
                        ForEach(MusicSession.SessionMode.allCases, id: \.self) { mode in
                            FilterChip(title: mode.rawValue, isSelected: selectedModeFilter == mode) {
                                selectedModeFilter = selectedModeFilter == mode ? nil : mode
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 8)

                if filteredSessions.isEmpty {
                    Spacer()
                    Text("No sessions found")
                        .font(.system(size: 16))
                        .foregroundColor(.textInactive)
                    Spacer()
                } else {
                    List {
                        ForEach(filteredSessions) { session in
                            SessionRowCard(session: session)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 18, bottom: 4, trailing: 18))
                        }
                        .onDelete { offsets in
                            sessionVM.deleteSession(at: offsets)
                        }
                    }
                    .listStyle(.plain)
                    .background(Color.clear)
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = .neonPurple
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .white : .textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? color : Color.bgCard)
                .cornerRadius(20)
        }
    }
}
