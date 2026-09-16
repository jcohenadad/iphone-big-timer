import SwiftUI
import Observation

@Observable
final class TimerModel {
    enum Phase: String { case idle, running, paused, finished }

    private(set) var phase: Phase = .idle
    private(set) var duration: TimeInterval = 300
    private(set) var now = Date()
    private(set) var endDate: Date?
    private var pausedRemaining: TimeInterval = 0

    @ObservationIgnored private var ticker: Timer?
    @ObservationIgnored private let alarm = AlarmPlayer()
    @ObservationIgnored private var isActive = true
    @ObservationIgnored private let defaults = UserDefaults.standard

    init() { restore() }

    // MARK: - Derived values

    /// Seconds left. Negative once finished (overtime).
    var remaining: TimeInterval {
        switch phase {
        case .idle: return duration
        case .paused: return pausedRemaining
        case .running, .finished: return (endDate ?? now).timeIntervalSince(now)
        }
    }

    /// Fraction of time left, 1 → 0.
    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(1, max(0, remaining / duration))
    }

    static func format(_ t: TimeInterval) -> String {
        let overtime = t < 0
        let total = overtime ? Int(floor(-t)) : Int(ceil(t - 0.001))
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        let body = h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
        return overtime ? "+" + body : body
    }

    // MARK: - Actions

    func setDuration(_ seconds: TimeInterval) {
        alarm.stop()
        AlarmNotifications.cancel()
        stopTicker()
        duration = max(1, seconds.rounded())
        phase = .idle
        endDate = nil
        save()
    }

    func start() {
        let seconds = phase == .paused ? pausedRemaining : duration
        guard seconds > 0 else { return }
        alarm.stop()
        AlarmNotifications.requestPermission()
        endDate = Date().addingTimeInterval(seconds)
        phase = .running
        AlarmNotifications.schedule(after: seconds)
        startTicker()
        save()
    }

    func pause() {
        guard phase == .running else { return }
        pausedRemaining = max(1, remaining)
        phase = .paused
        endDate = nil
        AlarmNotifications.cancel()
        stopTicker()
        save()
    }

    func reset() {
        alarm.stop()
        AlarmNotifications.cancel()
        stopTicker()
        phase = .idle
        endDate = nil
        save()
    }

    /// Add (or remove) time. While ringing, this acts as a snooze.
    func add(_ seconds: TimeInterval) {
        switch phase {
        case .idle:
            duration = max(1, duration + seconds)
        case .paused:
            pausedRemaining = max(1, pausedRemaining + seconds)
        case .running:
            let newEnd = max(Date().addingTimeInterval(1), (endDate ?? Date()).addingTimeInterval(seconds))
            endDate = newEnd
            AlarmNotifications.schedule(after: newEnd.timeIntervalSinceNow)
        case .finished:
            alarm.stop()
            endDate = Date().addingTimeInterval(max(1, seconds))
            phase = .running
            AlarmNotifications.schedule(after: max(1, seconds))
        }
        save()
    }

    /// Big button / tap on the digits.
    func primaryAction() {
        switch phase {
        case .idle, .paused: start()
        case .running: pause()
        case .finished: reset()
        }
    }

    func scenePhaseChanged(_ scenePhase: ScenePhase) {
        isActive = scenePhase == .active
        if isActive {
            tick()
            if phase == .running || phase == .finished { startTicker() }
            // Came back shortly after the end: ring in-app until stopped.
            if phase == .finished, let end = endDate, Date().timeIntervalSince(end) < 60 {
                alarm.start()
            }
        } else if scenePhase == .background {
            alarm.stop()   // pending notifications keep ringing in the background
            stopTicker()
        }
        updateIdleTimer()
    }

    // MARK: - Ticking

    private func startTicker() {
        guard ticker == nil else { return }
        let t = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        ticker = t
        tick()
        updateIdleTimer()
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
        now = Date()
        updateIdleTimer()
    }

    private func tick() {
        now = Date()
        if phase == .running, let end = endDate, end <= now {
            phase = .finished
            save()
            if isActive { alarm.start() }
        }
    }

    /// Keep the screen awake while the timer is counting or ringing.
    private func updateIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = isActive && (phase == .running || phase == .finished)
    }

    // MARK: - Persistence (survives the app being closed)

    private enum Key {
        static let phase = "phase", duration = "duration", end = "endDate", paused = "pausedRemaining"
    }

    private func save() {
        defaults.set(phase.rawValue, forKey: Key.phase)
        defaults.set(duration, forKey: Key.duration)
        defaults.set(endDate?.timeIntervalSince1970, forKey: Key.end)
        defaults.set(pausedRemaining, forKey: Key.paused)
    }

    private func restore() {
        let savedDuration = defaults.double(forKey: Key.duration)
        if savedDuration > 0 { duration = savedDuration }
        pausedRemaining = defaults.double(forKey: Key.paused)
        let end = defaults.object(forKey: Key.end) as? Double
        endDate = end.map { Date(timeIntervalSince1970: $0) }
        phase = Phase(rawValue: defaults.string(forKey: Key.phase) ?? "") ?? .idle

        if (phase == .running || phase == .finished) && endDate == nil { phase = .idle }
        // The ticker is (re)started when the scene becomes active.
    }
}
