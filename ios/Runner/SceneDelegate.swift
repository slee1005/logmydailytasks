import Flutter
import UIKit
import UserNotifications

class SceneDelegate: FlutterSceneDelegate {
  static var launchNotificationPayload: String?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    // UIKit can deliver a cold-start notification through the scene options.
    if let response = connectionOptions.notificationResponse,
       response.actionIdentifier == UNNotificationDefaultActionIdentifier {
      Self.launchNotificationPayload =
        response.notification.request.content.userInfo["payload"] as? String
    }
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }
}
