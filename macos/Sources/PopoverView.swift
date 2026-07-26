import SwiftUI

struct PopoverView: View {
    @ObservedObject var state: UsageState

    var body: some View {
        VStack(spacing: 8) {
            Text("Clawd usage")
                .font(.headline)

            Image(nsImage: ClawdIcon.render(
                pct: state.pct,
                loadError: state.hasError,
                size: Layout.popoverIcon,
                warningThreshold: AppSettings.warningThreshold
            ))
            .renderingMode(.original)
            .frame(width: Layout.popoverIcon.width, height: Layout.popoverIcon.height)

            if state.hasError {
                Text("Please login.")
                    .foregroundColor(Theme.dangerSUI)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            } else {
                usageBar(label: "5 hour", pct: state.pct)
                usageBar(label: "7 day", pct: state.sevenPct)

                if !state.resetsAt.isEmpty {
                    Text(DateUtils.formatResets(state.resetsAt))
                        .font(.caption)
                        .opacity(0.7)
                }

                if !state.updatedAt.isEmpty {
                    Text(DateUtils.formatAge(state.updatedAt))
                        .font(.caption2)
                        .opacity(0.5)
                }
            }

            Button(action: {
                state.requestFreshPoll()
                state.loadData()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.primarySUI)
        }
        .padding()
        .frame(width: 200)
    }

    @ViewBuilder
    private func usageBar(label: String, pct: Double) -> some View {
        VStack(spacing: 2) {
            HStack {
                Text(label).font(.caption)
                Spacer()
                Text("\(Int(pct.rounded()))%").font(.caption.bold())
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.25))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.usageColorSUI(frac: pct / 100,
                                                  threshold: AppSettings.warningThreshold))
                        .frame(width: geo.size.width * min(1, pct / 100))
                        .animation(.easeInOut(duration: 0.4), value: pct)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 4)
    }
}
