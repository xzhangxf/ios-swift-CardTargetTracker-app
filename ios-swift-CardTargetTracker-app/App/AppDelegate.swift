//
//  AppDelegate.swift
//  ios-swift-CardTargetTracker-app
//
//  Created by Xufeng Zhang on 23/10/25.
//

import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("Permission: \(granted), error: \(String(describing: error))")
        }

        // Must be on main thread so delegate works (per Apple docs)
        DispatchQueue.main.async {
            UNUserNotificationCenter.current().delegate = self
        }
        Preload.seedIfNeeded() // set up the prebuild and it only run onece
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void)
    {
        if let cardId = response.notification.request.content.userInfo["cardId"] as? String
        {
            DispatchQueue.main.async {
                  guard
                      let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let window = windowScene.windows.first,
                      let rootNav = window.rootViewController as? UINavigationController
                  else {
                      completionHandler()
                      return
                  }
                  guard let card = TransactionManager.shared.allCards().first(where: { $0.id.uuidString == cardId }) else {
                      completionHandler()
                      return
                  }
                  let detailVC = CardDetailViewController(card: card)
                  detailVC.title = card.name
                  rootNav.popToRootViewController(animated: false)
                  rootNav.pushViewController(detailVC, animated: true)
              }
          }
          completionHandler()
      }
//class AppDelegate: UIResponder, UIApplicationDelegate {
//
//
//
//    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
//        UNUserNotificationCenter.current().delegate = self
//        // Override point for customization after application launch.
//        return true
//    }



    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    
}
