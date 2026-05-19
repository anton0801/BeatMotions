import SwiftUI

struct MoodSelectorView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedMood: MoodType = .focus
    @State private var appear = false
    @State private var confirmation = false

    var body: some View {
        ZStack {
            LinearGradient.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 28) {
                // Header
                HStack {
                    Text("Sound Mood")
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

                Text("How do you feel right now?")
                    .font(.system(size: 16))
                    .foregroundColor(.textSecondary)

                // Mood Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(MoodType.allCases, id: \.self) { mood in
                        MoodCard(
                            mood: mood,
                            isSelected: selectedMood == mood,
                            onSelect: {
                                withAnimation(.spring04) { selectedMood = mood }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 30)

                // Selected mood info
                if appear {
                    SelectedMoodInfo(mood: selectedMood)
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()

                // Apply button
                BMPrimaryButton(title: confirmation ? "✓ Mood Applied!" : "Apply Mood") {
                    appState.setMood(selectedMood)
                    withAnimation(.spring04) { confirmation = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            selectedMood = appState.currentMood
            withAnimation(.spring04.delay(0.15)) { appear = true }
        }
    }
}

struct MoodCard: View {
    let mood: MoodType
    let isSelected: Bool
    let onSelect: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(mood.primaryColor.opacity(isSelected ? 0.3 : 0.1))
                        .frame(width: 64, height: 64)

                    if isSelected {
                        Circle()
                            .stroke(mood.primaryColor, lineWidth: 2)
                            .frame(width: 64, height: 64)
                    }

                    Image(systemName: mood.icon)
                        .font(.system(size: 28))
                        .foregroundColor(mood.primaryColor)
                        .neonGlow(color: mood.primaryColor, radius: isSelected ? 8 : 0)
                }

                VStack(spacing: 2) {
                    Text(mood.rawValue)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(isSelected ? .textPrimary : .textSecondary)
                    Text(mood.bpm)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(isSelected ? mood.primaryColor : .textInactive)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? mood.primaryColor.opacity(0.12) : Color.bgCard.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? mood.primaryColor.opacity(0.5) : Color.white.opacity(0.06), lineWidth: 1.5)
                    )
            )
        }
        .scaleEffect(isPressed ? 0.95 : (isSelected ? 1.03 : 1.0))
        .animation(.spring04, value: isSelected)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.spring04) { isPressed = true } }
                .onEnded { _ in withAnimation(.spring04) { isPressed = false } }
        )
    }
}

struct SelectedMoodInfo: View {
    let mood: MoodType

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: mood.icon)
                .font(.system(size: 22))
                .foregroundColor(mood.primaryColor)
                .neonGlow(color: mood.primaryColor, radius: 6)
                .frame(width: 40, height: 40)
                .background(mood.primaryColor.opacity(0.15))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 3) {
                Text(mood.rawValue + " Mode Active")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text(mood.description + " · " + mood.bpm)
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .cardStyle()
    }
}
