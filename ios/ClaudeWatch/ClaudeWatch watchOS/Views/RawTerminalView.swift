import SwiftUI

/// slyterm on the wrist: the bridge mirrors a real tmux session (the same
/// shell slyterm serves through ttyd) and streams its rendered screen here.
/// Mic button sends dictated/typed text back as literal keystrokes.
struct RawTerminalView: View {
    @EnvironmentObject private var session: WatchViewState
    @State private var showInput = false

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 3) {
                // Header — ✳ slyterm + live dot
                HStack(spacing: 4) {
                    Text("✳")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.Text.primary)
                    Text("slyterm")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.Text.primary)
                    Spacer(minLength: 0)
                    Circle()
                        .fill(session.termScreen.isEmpty ? Theme.Text.secondary : Theme.Accent.success)
                        .frame(width: 5, height: 5)
                }

                if session.termScreen.isEmpty {
                    Spacer()
                    Text("waiting for terminal…")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Theme.Text.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        Text(session.termScreen)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.white.opacity(0.9))
                            .lineSpacing(0)
                            .minimumScaleFactor(0.6)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(.bottom, 36)
                    }
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.Text.primary.opacity(0.8), lineWidth: 1.5)
            )
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Theme.Background.primary)

            // Mic button (bottom-right, same placement as SessionView)
            HStack {
                Spacer()
                Button { showInput = true } label: {
                    ZStack {
                        Circle()
                            .fill(Theme.Text.primary.opacity(0.75))
                            .frame(width: 28, height: 28)
                        Image(systemName: "mic.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.black)
                    }
                    .shadow(color: .black.opacity(0.6), radius: 6, y: 3)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 16)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 16)
        }
        .ignoresSafeArea(edges: .bottom)
        .fullScreenCover(isPresented: $showInput) {
            VoiceInputView(onSend: { session.sendTermInput($0) })
        }
    }
}

#Preview {
    RawTerminalView()
        .environmentObject(WatchViewState.shared)
}
