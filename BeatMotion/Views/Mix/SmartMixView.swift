import SwiftUI

struct SmartMixView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var playlistVM: PlaylistViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var selectedMood: MoodType = .focus
    @State private var selectedDuration: Double = 30
    @State private var selectedIntensity: IntensityLevel = .medium
    @State private var selectedGenre: GenreType = .lofi
    @State private var generatedPlaylist: Playlist?
    @State private var isGenerating = false
    @State private var savedConfirmation = false
    @State private var appear = false

    var body: some View {
        ZStack {
            LinearGradient.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Smart Mix")
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
                .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Mood picker
                        MixSectionCard(title: "Mood") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(MoodType.allCases, id: \.self) { mood in
                                        MoodPill(mood: mood, isSelected: selectedMood == mood) {
                                            withAnimation(.spring04) { selectedMood = mood }
                                        }
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }

                        // Duration slider
                        MixSectionCard(title: "Duration: \(Int(selectedDuration)) min") {
                            VStack(spacing: 8) {
                                Slider(value: $selectedDuration, in: 5...120, step: 5)
                                    .accentColor(.neonPurple)
                                HStack {
                                    Text("5 min")
                                        .font(.system(size: 11))
                                        .foregroundColor(.textInactive)
                                    Spacer()
                                    Text("2 hr")
                                        .font(.system(size: 11))
                                        .foregroundColor(.textInactive)
                                }
                            }
                        }

                        // Intensity picker
                        MixSectionCard(title: "Intensity") {
                            HStack(spacing: 10) {
                                ForEach(IntensityLevel.allCases, id: \.self) { level in
                                    SegmentPill(
                                        title: level.rawValue,
                                        isSelected: selectedIntensity == level,
                                        color: intensityColor(level)
                                    ) {
                                        withAnimation(.spring04) { selectedIntensity = level }
                                    }
                                }
                            }
                        }

                        // Genre picker
                        MixSectionCard(title: "Genre") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(GenreType.allCases, id: \.self) { genre in
                                    GenrePill(genre: genre, isSelected: selectedGenre == genre) {
                                        withAnimation(.spring04) { selectedGenre = genre }
                                    }
                                }
                            }
                        }

                        // Generated result
                        if let playlist = generatedPlaylist {
                            GeneratedMixCard(playlist: playlist)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        // Buttons
                        VStack(spacing: 12) {
                            BMPrimaryButton(title: isGenerating ? "Generating..." : "Generate Mix") {
                                generateMix()
                            }

                            if generatedPlaylist != nil {
                                BMSecondaryButton(title: savedConfirmation ? "✓ Saved!" : "Save Mix") {
                                    saveMix()
                                }
                            }
                        }
                        .padding(.bottom, 32)
                    }
                    .padding(.horizontal, 20)
                }
                .opacity(appear ? 1 : 0)
            }
        }
        .onAppear {
            selectedMood = appState.currentMood
            withAnimation(.spring04.delay(0.1)) { appear = true }
        }
    }

    private func generateMix() {
        isGenerating = true
        withAnimation(.easeOut(duration: 0.3)) { generatedPlaylist = nil }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let playlist = playlistVM.createSmartMix(
                mood: selectedMood,
                duration: selectedDuration * 60,
                intensity: selectedIntensity,
                genre: selectedGenre
            )
            withAnimation(.spring04) {
                generatedPlaylist = playlist
                isGenerating = false
            }
        }
    }

    private func saveMix() {
        guard let playlist = generatedPlaylist else { return }
        playlistVM.addPlaylist(playlist)
        withAnimation(.spring04) { savedConfirmation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            presentationMode.wrappedValue.dismiss()
        }
    }

    private func intensityColor(_ level: IntensityLevel) -> Color {
        switch level {
        case .low: return .neonCyan
        case .medium: return .neonPurple
        case .high: return .neonOrange
        }
    }
}

// MARK: - Sub-components
struct MixSectionCard<Content: View>: View {
    let title: String
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.textSecondary)
            content()
        }
        .padding(16)
        .cardStyle()
    }
}

struct MoodPill: View {
    let mood: MoodType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: mood.icon)
                    .font(.system(size: 13))
                Text(mood.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? mood.primaryColor : Color.bgCard)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? mood.primaryColor : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }
}

struct SegmentPill: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : .textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? color : Color.bgCard)
                .cornerRadius(10)
        }
    }
}

struct GenrePill: View {
    let genre: GenreType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(genre.rawValue)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? .white : .textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.neonPurple : Color.bgCard)
                .cornerRadius(10)
        }
    }
}

struct GeneratedMixCard: View {
    let playlist: Playlist

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(playlist.mood.gradient)
                    .frame(width: 54, height: 54)
                Image(systemName: "music.note.list")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.textPrimary)
                Text("\(playlist.genre.rawValue) · \(playlist.durationString) · \(playlist.trackCount) tracks")
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
                Text(playlist.intensity.rawValue + " intensity")
                    .font(.system(size: 12))
                    .foregroundColor(playlist.mood.primaryColor)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.bgCard.opacity(0.8))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(playlist.mood.primaryColor.opacity(0.3), lineWidth: 1)
        )
    }
}
