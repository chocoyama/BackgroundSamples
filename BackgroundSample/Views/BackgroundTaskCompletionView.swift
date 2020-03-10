//
//  BackgroundTaskCompletionView.swift
//  BackgroundSample
//
//  Created by Takuya Yokoyama on 2020/03/10.
//  Copyright © 2020 Takuya Yokoyama. All rights reserved.
//

import SwiftUI
import Combine

struct BackgroundTaskCompletionView: View {
    private let sample = BackgroundTaskCompletionSample()
    
    var body: some View {
        Button(action: {
            self.sample.send(Message(title: nil, subtitle: nil, body: "test"))
        }) {
            Text("Button")
        }
    }
}

struct BackgroundTaskCompletionView_Previews: PreviewProvider {
    static var previews: some View {
        BackgroundTaskCompletionView()
    }
}

class BackgroundTaskCompletionSample {
    private var cancellables: Set<AnyCancellable> = []
    private let messageRepository = MessageRepository()

    func send(_ message: Message) {
        // 1. バックグラウンドタスクを開始する
        // アプリケーションが閉じられてもタスクを継続するように伝える
        let taskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            // 4. expirationHandlerは、バックグラウンド状態でかつendBackgroundTaskが呼ばれなかった場合に呼ばれる
            self.cancellables.forEach { $0.cancel() }
            NotificationHelper.postLocalNotification(with: Message(body: "メッセージ送信に失敗しました。"))
            Logger.debug(message: "cancel background task")
        })
        Logger.debug(message: "start background task")
        
        
        // 2. 処理の重たい処理を実行する（擬似的に20秒間かかる処理にしている）
        messageRepository.post(message: message, processTime: 20)
            .sink(receiveCompletion: { (result) in
                switch result {
                case .finished:
                    break
                case .failure:
                    NotificationHelper.postLocalNotification(with: Message(body: "メッセージ送信に失敗しました。"))
                    UIApplication.shared.endBackgroundTask(taskIdentifier)
                    Logger.debug(message: "end background task")
                }
            }) { _ in
                // 3. バックグラウンド処理の終了をシステムに伝える
                // これを行わないと処理が継続し続けてしまうので、節電やパフォーマンスなどの面で良くない
                UIApplication.shared.endBackgroundTask(taskIdentifier)
                Logger.debug(message: "end background task")
            }.store(in: &cancellables)
        
        
        // バックグラウンド状態かつbeginBackgroundTaskで開始したタスクがある場合、
        // UIApplicationのbackgroundTimeRemainingプロパティから実行可能な残り時間を取得できる
        NotificationCenter.default
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .delay(for: 1.0, scheduler: DispatchQueue.main)
            .map { _ in UIApplication.shared.backgroundTimeRemaining }
            .sink { backgroundTimeRemaining in Logger.debug(message: "backgroundTimeRemaining = \(backgroundTimeRemaining)") }
            .store(in: &cancellables)
    }
}


struct Logger {
    static func debug(message: String) {
        print("### \(Date()) \(message)")
    }
}
