import SwiftUI

struct PlaylistsView: View {
    @EnvironmentObject var playlistVM: PlaylistViewModel
    @EnvironmentObject var appState: AppState
    @State private var showCreateMix = false
    @State private var editingPlaylist: Playlist?
    @State private var showTrackNotes = false
    @State private var appear = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.backgroundGradient.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Playlists")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Button(action: { showTrackNotes = true }) {
                            Image(systemName: "note.text")
                                .font(.system(size: 20))
                                .foregroundColor(.textSecondary)
                                .padding(8)
                                .background(Color.bgCard)
                                .cornerRadius(10)
                        }
                        Button(action: { showCreateMix = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.neonPurple)
                                .neonGlow(color: .neonPurple, radius: 4)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 16)

                    if playlistVM.playlists.isEmpty {
                        Spacer()
                        EmptyStateView(
                            icon: "music.note.list",
                            title: "No Playlists Yet",
                            subtitle: "Create your first smart mix",
                            buttonTitle: "Create Mix",
                            action: { showCreateMix = true }
                        )
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(playlistVM.playlists) { playlist in
                                    PlaylistCard(
                                        playlist: playlist,
                                        onEdit: { editingPlaylist = playlist },
                                        onFavorite: { playlistVM.toggleFavorite(playlist) }
                                    )
                                    .padding(.horizontal, 18)
                                    .opacity(appear ? 1 : 0)
                                    .offset(y: appear ? 0 : 20)
                                }
                            }
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showCreateMix) { SmartMixView() }
        .sheet(item: $editingPlaylist) { playlist in
            EditPlaylistView(playlist: playlist)
        }
        .sheet(isPresented: $showTrackNotes) { TrackNotesView() }
        .onAppear {
            withAnimation(.spring04.delay(0.1)) { appear = true }
        }
    }
}

struct PlaylistCard: View {
    let playlist: Playlist
    let onEdit: () -> Void
    let onFavorite: () -> Void
    @State private var isPressed = false

    let cardColors: [[Color]] = [
        [.neonPurple, .neonPink],
        [.neonCyan, .neonPurple],
        [.neonOrange, .neonPink],
        [.neonGreen, .neonCyan]
    ]

    var colors: [Color] {
        cardColors[min(playlist.colorIndex, cardColors.count - 1)]
    }

    var body: some View {
        HStack(spacing: 14) {
            // Color block
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    colors: colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: playlist.mood.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.textPrimary)
                HStack(spacing: 8) {
                    Text(playlist.mood.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(playlist.mood.primaryColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(playlist.mood.primaryColor.opacity(0.15))
                        .cornerRadius(6)
                    Text(playlist.genre.rawValue)
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                }
                Text("\(playlist.trackCount) tracks · \(playlist.durationString)")
                    .font(.system(size: 12))
                    .foregroundColor(.textInactive)
            }

            Spacer()

            VStack(spacing: 12) {
                Button(action: onFavorite) {
                    Image(systemName: playlist.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 16))
                        .foregroundColor(playlist.isFavorite ? .neonPink : .textInactive)
                }

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16))
                        .foregroundColor(.textInactive)
                }
            }
        }
        .padding(14)
        .cardStyle()
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.spring04) { isPressed = true } }
                .onEnded { _ in withAnimation(.spring04) { isPressed = false } }
        )
    }
}

struct EditPlaylistView: View {
    @EnvironmentObject var playlistVM: PlaylistViewModel
    @Environment(\.presentationMode) var presentationMode
    @State var playlist: Playlist
    @State private var saved = false

    var body: some View {
        ZStack {
            LinearGradient.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Text("Edit Playlist")
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

                VStack(spacing: 16) {
                    // Name field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Name")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.textSecondary)
                        TextField("Playlist Name", text: $playlist.name)
                            .font(.system(size: 16))
                            .foregroundColor(.textPrimary)
                            .padding(14)
                            .background(Color.bgCard)
                            .cornerRadius(12)
                    }

                    // Mood
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mood")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.textSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(MoodType.allCases, id: \.self) { mood in
                                    MoodPill(mood: mood, isSelected: playlist.mood == mood) {
                                        playlist.mood = mood
                                    }
                                }
                            }
                        }
                    }

                    // Genre
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Genre")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.textSecondary)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(GenreType.allCases, id: \.self) { genre in
                                GenrePill(genre: genre, isSelected: playlist.genre == genre) {
                                    playlist.genre = genre
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                BMPrimaryButton(title: saved ? "✓ Saved!" : "Save Changes") {
                    playlistVM.updatePlaylist(playlist)
                    withAnimation(.spring04) { saved = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }
}

// MARK: - Track Notes
struct TrackNotesView: View {
    @EnvironmentObject var playlistVM: PlaylistViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showAddNote = false

    var body: some View {
        ZStack {
            LinearGradient.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Track Notes")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Button(action: { showAddNote = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.neonPurple)
                    }
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.textInactive)
                            .padding(.leading, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 16)

                if playlistVM.trackNotes.isEmpty {
                    Spacer()
                    EmptyStateView(icon: "note.text", title: "No Notes", subtitle: "Add notes to your tracks", buttonTitle: "Add Note", action: { showAddNote = true })
                    Spacer()
                } else {
                    List {
                        ForEach(playlistVM.trackNotes) { note in
                            TrackNoteRow(note: note)
                                .listRowBackground(Color.bgCard.opacity(0.6))
                                .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: playlistVM.deleteNote)
                    }
                    .listStyle(.plain)
                    .background(Color.clear)
                }
            }
        }
        .sheet(isPresented: $showAddNote) { AddTrackNoteView() }
    }
}

struct TrackNoteRow: View {
    let note: TrackNote

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.trackName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text(note.moodNote)
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= note.rating ? "star.fill" : "star")
                        .font(.system(size: 11))
                        .foregroundColor(star <= note.rating ? .neonOrange : .textInactive)
                }
            }
        }
        .padding(14)
    }
}

struct AddTrackNoteView: View {
    @EnvironmentObject var playlistVM: PlaylistViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var trackName = ""
    @State private var moodNote = ""
    @State private var rating = 3
    @State private var selectedMood: MoodType = .focus
    @State private var saved = false

    var body: some View {
        ZStack {
            LinearGradient.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Text("Add Track Note")
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

                VStack(spacing: 16) {
                    BMTextField(placeholder: "Track Name", text: $trackName)
                    BMTextField(placeholder: "Mood Note", text: $moodNote)

                    // Rating
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rating")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.textSecondary)
                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { star in
                                Button(action: { withAnimation(.spring04) { rating = star } }) {
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .font(.system(size: 28))
                                        .foregroundColor(star <= rating ? .neonOrange : .textInactive)
                                        .neonGlow(color: star <= rating ? .neonOrange : .clear, radius: 4)
                                }
                                .scaleEffect(star == rating ? 1.2 : 1.0)
                                .animation(.spring04, value: rating)
                            }
                        }
                    }
                    .padding(16)
                    .cardStyle()

                    // Mood
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mood")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.textSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(MoodType.allCases, id: \.self) { mood in
                                    MoodPill(mood: mood, isSelected: selectedMood == mood) {
                                        selectedMood = mood
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                BMPrimaryButton(title: saved ? "✓ Added!" : "Add Note") {
                    guard !trackName.isEmpty else { return }
                    let note = TrackNote(trackName: trackName, moodNote: moodNote, rating: rating, mood: selectedMood, date: Date())
                    playlistVM.addNote(note)
                    withAnimation(.spring04) { saved = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }
}

// MARK: - Shared Components
struct BMTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.system(size: 16))
            .foregroundColor(.textPrimary)
            .padding(14)
            .background(Color.bgCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            )
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.textInactive)
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.textPrimary)
            Text(subtitle)
                .font(.system(size: 15))
                .foregroundColor(.textSecondary)
            BMPrimaryButton(title: buttonTitle, action: action)
                .frame(width: 200)
        }
        .padding(40)
    }
}
