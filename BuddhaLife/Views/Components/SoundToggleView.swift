import SwiftUI

// MARK: - SoundToggleView
//
// A standalone sound mute/unmute button for use in the saffron-gold header bar.
//
// Toggles AudioEngine.shared.isMuted on tap.
// SF Symbols:
//   - speaker.wave.2.fill  (unmuted)
//   - speaker.slash.fill    (muted)
//
// White foreground, 44x44 tap target.

struct SoundToggleView: View {

    var body: some View {
        Button {
            AudioEngine.shared.isMuted.toggle()
        } label: {
            Image(systemName: AudioEngine.shared.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .font(.system(size: 18))
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(AudioEngine.shared.isMuted ? "Unmute sound" : "Mute sound")
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.accentColor
        SoundToggleView()
    }
    .frame(height: 56)
}
