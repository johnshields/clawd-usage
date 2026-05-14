import Foundation
import Combine

final class UsageState: ObservableObject {
    @Published var pct: Double = 0
    @Published var sevenPct: Double = 0
    @Published var resetsAt: String = ""
    @Published var sevenDayResetsAt: String = ""
    @Published var updatedAt: String = ""
    @Published var loadError: Bool = false

    private var timer: Timer?
    private var defaultsObserver: Any?

    init() {
        loadData()
        scheduleTimer()
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.scheduleTimer()
        }
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(AppSettings.refreshInterval),
            repeats: true
        ) { [weak self] _ in
            self?.loadData()
        }
    }

    func loadData() {
        guard let data = FileManager.default.contents(atPath: Paths.stateFile),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            DispatchQueue.main.async { self.loadError = true }
            return
        }

        DispatchQueue.main.async {
            self.pct              = json["used_percentage"]      as? Double ?? 0
            self.sevenPct         = json["seven_day_percentage"] as? Double ?? 0
            self.resetsAt         = json["resets_at"]            as? String ?? ""
            self.sevenDayResetsAt = json["seven_day_resets_at"]  as? String ?? ""
            self.updatedAt        = json["updated_at"]           as? String ?? ""
            self.loadError        = false
        }
    }
}
