//
//  MessageRepository.swift
//  BackgroundTaskCompletionSample
//
//  Created by Takuya Yokoyama on 2020/03/10.
//  Copyright © 2020 Takuya Yokoyama. All rights reserved.
//

import Foundation
import Combine

struct Message {
    let title: String?
    let subtitle: String?
    let body: String
    
    init(title: String? = nil, subtitle: String? = nil, body: String) {
        self.title = title
        self.subtitle = subtitle
        self.body = body
    }
}

class MessageRepository {
    func post(message: Message, processTime: TimeInterval) -> AnyPublisher<Void, Never> {
        Future<Void, Never> { (promise) in
            DispatchQueue.main.asyncAfter(deadline: .now() + processTime) {
                NotificationHelper.postLocalNotification(with: message)
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
}
