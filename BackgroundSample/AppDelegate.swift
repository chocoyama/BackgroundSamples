//
//  AppDelegate.swift
//  BackgroundSample
//
//  Created by Takuya Yokoyama on 2020/03/10.
//  Copyright © 2020 Takuya Yokoyama. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    @UserDefault(key: .latestBackgroundPushUpdateDate, defaultValue: nil)
    private var latestBackgroundPushUpdateDate: Date?
    var backgroundCompletionHandler: (() -> Void)?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        NotificationHelper.requestAuthorization(withDelegate: self)
        return true
    }

    // MARK: UISceneSession Lifecycle

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
    
    // バックグラウンドでURLSessionが動いていた場合、処理が完了した直後にシステムがアプリを起動してこれを呼び出す
    // 第2引数にsessionのIDが受け渡されるので、アプリ起動後の何らかの処理でSessionの再作成を行っている場所がない場合は、これを用いて再生成をする必要がある
    // 第3引数の完了ハンドラは処理が全て終わった際に呼び出すべきものなので、URLSessionの完了イベントが呼び出されるまで一旦保持しておき、そちら側で呼び出す
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        self.backgroundCompletionHandler = completionHandler
        // let config = URLSessionConfiguration.background(withIdentifier: "some unique identifier")
        // let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    // プッシュ通知に利用するデバイストークンを取得した際に呼び出される
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("token = \(token)")
    }
    
    // バックグラウンドプッシュを受け取った際に呼び出される
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        self.latestBackgroundPushUpdateDate = Date()
        NotificationHelper.postLocalNotification(with: Message(body: "Received Background Push"))
        DispatchQueue.main.async {
            completionHandler(.noData)
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // 通知をタップして起動された際に呼び出される
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    // アプリ起動中に通知を受信した際に呼び出される
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
}

