//
//  MessageRepository.swift
//  BackgroundTaskCompletionSample
//
//  Created by Takuya Yokoyama on 2020/03/10.
//  Copyright © 2020 Takuya Yokoyama. All rights reserved.
//

import Foundation
import Combine

class SampleRepository {
    func post(processTime: TimeInterval) -> AnyPublisher<Void, Never> {
        Future<Void, Never> { (promise) in
            DispatchQueue.main.asyncAfter(deadline: .now() + processTime) {
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
}
