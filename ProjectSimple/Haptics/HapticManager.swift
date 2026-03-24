import UIKit

enum HapticManager {

    private static let hapticsEnabledKey = "hapticsEnabled"

    private static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: hapticsEnabledKey)
    }

    /// Medium impact — used when a task is marked completed.
    static func taskCompleted() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Light impact — used when a step checkbox is toggled.
    static func stepToggled() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Success notification — used when all tasks in a project are completed.
    static func milestoneReached() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
