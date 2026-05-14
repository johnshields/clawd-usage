import SwiftUI

struct SettingsView: View {
    @AppStorage("refreshInterval")  private var refreshInterval  = AppSettings.defaultRefreshInterval
    @AppStorage("warningThreshold") private var warningThreshold = AppSettings.defaultWarningThreshold
    @AppStorage("showPercentLabel") private var showPercentLabel = AppSettings.defaultShowPercentLabel

    var body: some View {
        Form {
            Section {
                HStack {
                    Stepper("Refresh interval:", value: $refreshInterval, in: 2...120)
                    Text("\(refreshInterval)s")
                        .monospacedDigit()
                        .frame(width: 40, alignment: .trailing)
                }

                HStack {
                    Stepper("Warn (red) at:", value: $warningThreshold, in: 50...100, step: 5)
                    Text("\(warningThreshold)%")
                        .monospacedDigit()
                        .frame(width: 40, alignment: .trailing)
                }

                Toggle("Show % label beside icon", isOn: $showPercentLabel)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 320, height: 180)
    }
}
