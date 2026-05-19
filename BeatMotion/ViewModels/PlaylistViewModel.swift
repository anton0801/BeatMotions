import SwiftUI
import Combine

class PlaylistViewModel: ObservableObject {
    @Published var playlists: [Playlist] = []
    @Published var trackNotes: [TrackNote] = []
    private let playlistKey = "savedPlaylists"
    private let notesKey = "savedTrackNotes"

    init() {
        loadPlaylists()
        loadTrackNotes()
    }

    // MARK: - Playlists
    func addPlaylist(_ playlist: Playlist) {
        playlists.insert(playlist, at: 0)
        persistPlaylists()
    }

    func updatePlaylist(_ playlist: Playlist) {
        if let idx = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[idx] = playlist
            persistPlaylists()
        }
    }

    func deletePlaylist(at offsets: IndexSet) {
        playlists.remove(atOffsets: offsets)
        persistPlaylists()
    }

    func toggleFavorite(_ playlist: Playlist) {
        if let idx = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[idx].isFavorite.toggle()
            persistPlaylists()
        }
    }

    func createSmartMix(mood: MoodType, duration: TimeInterval, intensity: IntensityLevel, genre: GenreType) -> Playlist {
        let trackCount = max(3, Int(duration / 60 / 4))
        let playlist = Playlist(
            name: "\(mood.rawValue) Mix",
            mood: mood,
            duration: duration,
            trackCount: trackCount,
            genre: genre,
            intensity: intensity,
            createdAt: Date(),
            colorIndex: Int.random(in: 0...3)
        )
        return playlist
    }

    // MARK: - Track Notes
    func addNote(_ note: TrackNote) {
        trackNotes.insert(note, at: 0)
        persistNotes()
    }

    func updateNote(_ note: TrackNote) {
        if let idx = trackNotes.firstIndex(where: { $0.id == note.id }) {
            trackNotes[idx] = note
            persistNotes()
        }
    }

    func deleteNote(at offsets: IndexSet) {
        trackNotes.remove(atOffsets: offsets)
        persistNotes()
    }

    // MARK: - Persistence
    private func persistPlaylists() {
        if let data = try? JSONEncoder().encode(playlists) {
            UserDefaults.standard.set(data, forKey: playlistKey)
        }
    }

    private func loadPlaylists() {
        if let data = UserDefaults.standard.data(forKey: playlistKey),
           let decoded = try? JSONDecoder().decode([Playlist].self, from: data) {
            playlists = decoded
        } else {
            playlists = PlaylistViewModel.samplePlaylists()
        }
    }

    private func persistNotes() {
        if let data = try? JSONEncoder().encode(trackNotes) {
            UserDefaults.standard.set(data, forKey: notesKey)
        }
    }

    private func loadTrackNotes() {
        if let data = UserDefaults.standard.data(forKey: notesKey),
           let decoded = try? JSONDecoder().decode([TrackNote].self, from: data) {
            trackNotes = decoded
        } else {
            trackNotes = PlaylistViewModel.sampleNotes()
        }
    }

    // MARK: - Sample Data
    static func samplePlaylists() -> [Playlist] {
        return [
            Playlist(name: "Deep Focus", mood: .focus, duration: 3600, trackCount: 12, genre: .lofi, intensity: .medium, createdAt: Date(), colorIndex: 0),
            Playlist(name: "Night Vibes", mood: .night, duration: 2700, trackCount: 9, genre: .ambient, intensity: .low, createdAt: Date().addingTimeInterval(-86400), colorIndex: 1),
            Playlist(name: "Energy Rush", mood: .energy, duration: 1800, trackCount: 8, genre: .electronic, intensity: .high, createdAt: Date().addingTimeInterval(-172800), colorIndex: 2),
            Playlist(name: "Chill Sunday", mood: .chill, duration: 4500, trackCount: 15, genre: .jazz, intensity: .low, createdAt: Date().addingTimeInterval(-259200), colorIndex: 3),
        ]
    }

    static func sampleNotes() -> [TrackNote] {
        return [
            TrackNote(trackName: "Rainy Lofi", moodNote: "Perfect for reading", rating: 5, mood: .chill, date: Date()),
            TrackNote(trackName: "Focus Alpha", moodNote: "Great concentration boost", rating: 4, mood: .focus, date: Date().addingTimeInterval(-86400)),
        ]
    }
}
