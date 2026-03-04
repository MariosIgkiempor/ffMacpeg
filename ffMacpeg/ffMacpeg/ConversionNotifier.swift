import Foundation
import UserNotifications

/// Sends macOS notifications for conversion results.
enum ConversionNotifier {

    /// Requests notification permission. Call once at app startup.
    static func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        try? await center.requestAuthorization(options: [.alert, .sound])
    }

    /// Sends a success notification.
    static func notifySuccess(inputFileName: String, outputURL: URL) {
        let content = UNMutableNotificationContent()
        content.title = "Conversion Complete"
        content.body = "\(inputFileName) converted to \(outputURL.pathExtension.uppercased())"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// Sends a failure notification.
    static func notifyFailure(inputFileName: String, error: Error) {
        let content = UNMutableNotificationContent()
        content.title = "Conversion Failed"
        content.body = "\(inputFileName): \(error.localizedDescription)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
