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
        let taskIdentifier = startBackgroundTask()
        
        NotificationCenter.default
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .delay(for: 1.0, scheduler: DispatchQueue.main)
            .sink { _ in
                // バックグラウンド状態かつbeginBackgroundTaskで開始したタスクがある場合、実行可能な残り時間を取得できる
                Logger.debug(message: "backgroundTimeRemaining = \(UIApplication.shared.backgroundTimeRemaining)")
            }.store(in: &cancellables)
        
        messageRepository.post(message: message, processTime: 60)
            .sink(receiveCompletion: { [weak self] (result) in
                switch result {
                case .finished: break
                case .failure: self?.endBackgroundTask(taskIdentifier)
                }
            }) { [weak self] _ in
                self?.endBackgroundTask(taskIdentifier)
            }.store(in: &cancellables)
    }
    
    private func startBackgroundTask() -> UIBackgroundTaskIdentifier {
        // アプリケーションが閉じられてもタスクを継続するように伝える
        // expirationHandlerは、バックグラウンド状態でかつendBackgroundTaskが呼ばれなかった場合に呼ばれる
        let taskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            self.cancellables.forEach { $0.cancel() }
            NotificationHelper.postLocalNotification(with: Message(body: "メッセージ送信に失敗しました。"))
            Logger.debug(message: "cancel background task")
        })
        Logger.debug(message: "start background task")
        return taskIdentifier
    }
    
    private func endBackgroundTask(_ taskIdentifier: UIBackgroundTaskIdentifier) {
        // 処理が完了したらタスクを終了させることで、節電やパフォーマンス向上につながる
        UIApplication.shared.endBackgroundTask(taskIdentifier)
        Logger.debug(message: "end background task")
    }
}


struct Logger {
    static func debug(message: String) {
        print("### \(Date()) \(message)")
    }
}
