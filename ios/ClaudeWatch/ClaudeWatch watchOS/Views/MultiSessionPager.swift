import SwiftUI

struct MultiSessionPager: View {
    @EnvironmentObject private var state: WatchViewState

    var body: some View {
        TabView(selection: $state.activeSessionIndex) {
            if state.sessions.isEmpty {
                waitingView
                    .tag(0)
            } else {
                ForEach(Array(state.sessions.enumerated()), id: \.element.id) { index, _ in
                    SessionView(sessionIndex: index)
                        .tag(index)
                }
            }

            // Raw terminal mirror — swipe past the sessions to reach slyterm
            RawTerminalView()
                .tag(-1)
        }
        .tabViewStyle(.page)
    }

    private var waitingView: some View {
        VStack(spacing: 8) {
            AppLogo(size: 56)
                .opacity(0.6)
            Text("Waiting for session...")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            Text("Start Claude or Codex on your Mac")
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

#Preview("Waiting") {
    MultiSessionPager()
        .environmentObject(WatchViewState.shared)
}
