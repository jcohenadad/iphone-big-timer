import AVFoundation
import UIKit
import UserNotifications

/// Looping in-app alarm sound + haptics. Uses the .playback category so it rings even with the silent switch on.
final class AlarmPlayer {
    private var player: AVAudioPlayer?
    private var hapticTimer: Timer?
    private(set) var isRinging = false

    func start() {
        guard !isRinging else { return }
        isRinging = true

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)

        if player == nil, let url = Bundle.main.url(forResource: "alarm", withExtension: "wav") {
            player = try? AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.prepareToPlay()
        }
        player?.currentTime = 0
        player?.play()

        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.warning)
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            haptic.notificationOccurred(.warning)
        }
    }

    func stop() {
        guard isRinging else { return }
        isRinging = false
        player?.stop()
        hapticTimer?.invalidate()
        hapticTimer = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

/// Local notifications so the alarm still rings when the app is in the background or the phone is locked.
enum AlarmNotifications {
    private static let idPrefix = "bigtimer.alarm."
    /// One notification at the end, then repeats every 30 s so a missed alarm keeps ringing for ~2 minutes.
    private static let count = 4

    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func schedule(after seconds: TimeInterval) {
        cancel()
        guard seconds > 0 else { return }
        let center = UNUserNotificationCenter.current()
        for i in 0..<count {
            let content = UNMutableNotificationContent()
            content.title = "Time's up!"
            content.body = i == 0 ? "Your timer has finished." : "Your timer is still ringing."
            content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm.wav"))
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds + Double(i) * 30, repeats: false)
            center.add(UNNotificationRequest(identifier: idPrefix + "\(i)", content: content, trigger: trigger))
        }
    }

    static func cancel() {
        let ids = (0..<count).map { idPrefix + "\($0)" }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }
}
