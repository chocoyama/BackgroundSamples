//
//  NotificationCenter.swift
//  BackgroundTaskCompletionSample
//
//  Created by Takuya Yokoyama on 2020/03/10.
//  Copyright © 2020 Takuya Yokoyama. All rights reserved.
//

import UIKit

class NotificationHelper {
    static func requestAuthorization(withDelegate delegate: UNUserNotificationCenterDelegate? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .alert], completionHandler: { (granted, error) in
            if error != nil {
                return
            }

            if granted {
                UNUserNotificationCenter.current().delegate = delegate
            }
        })
    }
    
    static func postLocalNotification(with message: Message) {
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: {
                                                let content = UNMutableNotificationContent()
                                                if let title = message.title {
                                                    content.title = title
                                                }
                                                if let subtitle = message.subtitle {
                                                    content.subtitle = subtitle
                                                }
                                                content.body = message.body
                                                return content
                                            }(),
                                            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 3.0, repeats: false))
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
