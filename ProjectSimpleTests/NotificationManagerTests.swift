import Testing
import Foundation
@testable import ProjectSimple

// MARK: - NotificationManager Tests (no SwiftData dependency)

@MainActor
struct NotificationManagerTests {

    @Test func initialStateIsNotAuthorized() {
        let manager = NotificationManager()
        #expect(manager.isAuthorized == false)
    }

    @Test func rescheduleHandlesEmptyProjects() async {
        let manager = NotificationManager()
        await manager.rescheduleAll(for: [])
    }

    @Test func clearBadgeDoesNotCrash() {
        let manager = NotificationManager()
        manager.clearBadge()
    }

    @Test func updateBadgeDoesNotCrash() {
        let manager = NotificationManager()
        manager.updateBadge(count: 5)
    }

    @Test func updateBadgeWithZeroDoesNotCrash() {
        let manager = NotificationManager()
        manager.updateBadge(count: 0)
    }
}
