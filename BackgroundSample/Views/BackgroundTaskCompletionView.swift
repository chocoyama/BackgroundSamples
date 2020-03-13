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
        VStack(spacing: 32) {
            Button(action: {
                // ①
                // 実行直後にバックグラウンドに移行した場合、バックグラウンド状態では処理が停止され、
                // フォアグラウンドに戻ったタイミングで処理が再開される。
                self.sample.executeForeground()
            }) {
                Text("フォアグラウンドで実行")
            }
            
            Button(action: {
                // ②
                // 実行直後にバックグラウンドに移行しても、バックグラウンド状態で処理が継続される
                self.sample.executeBackground()
            }) {
                Text("バックグラウンドで実行")
            }
            
            Button(action: {
                // ③
                // バックグラウンド処理の中で、再度バックグラウンド処理を開始しても、実行可能時間は延長されない
                self.sample.executeBackgroundForever()
            }) {
                Text("バックグラウンド処理の中で\nさらにバックグラウンド処理を開始")
            }
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
    private let sampleRepository = SampleRepository()

    func executeForeground() {
        // 処理の重たい処理を実行する（擬似的に10秒間かかる処理にしている）
        sampleRepository.post(processTime: 10)
            .sink(receiveCompletion: { (result) in
                switch result {
                case .finished:
                    break
                case .failure:
                    NotificationHelper.postLocalNotification(with: Message(body: "処理が失敗しました"))
                }
            }) { _ in
                NotificationHelper.postLocalNotification(with: Message(body: "処理が成功しました"))
            }.store(in: &cancellables)
    }
    
    func executeBackground() {
        // 1. バックグラウンドタスクを開始する
        // アプリケーションが閉じられてもタスクを継続するように伝える
        let taskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            // 4. expirationHandlerは、バックグラウンド状態でかつendBackgroundTaskが呼ばれなかった場合に呼ばれる
            self.cancellables.forEach { $0.cancel() }
            NotificationHelper.postLocalNotification(with: Message(body: "処理が完了しませんでした"))
            Logger.debug(message: "cancel background task")
        })
        Logger.debug(message: "start background task")
        
        
        // 2. 処理の重たい処理を実行する（擬似的に10秒間かかる処理にしている）
        sampleRepository.post(processTime: 10)
            .sink(receiveCompletion: { (result) in
                switch result {
                case .finished:
                    break
                case .failure:
                    NotificationHelper.postLocalNotification(with: Message(body: "処理が失敗しました"))
                    UIApplication.shared.endBackgroundTask(taskIdentifier)
                    Logger.debug(message: "end background task")
                }
            }) { _ in
                NotificationHelper.postLocalNotification(with: Message(body: "処理が成功しました"))
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
    
    func executeBackgroundForever() {
        let taskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            self.cancellables.forEach { $0.cancel() }
            NotificationHelper.postLocalNotification(with: Message(body: "処理が完了しませんでした"))
            Logger.debug(message: "cancel background task")
            self.executeBackgroundForever()
        })
        Logger.debug(message: "start background task")
        
        sampleRepository.post(processTime: 10)
            .sink(receiveCompletion: { (result) in
                switch result {
                case .finished:
                    break
                case .failure:
                    NotificationHelper.postLocalNotification(with: Message(body: "処理が失敗しました"))
                    UIApplication.shared.endBackgroundTask(taskIdentifier)
                    Logger.debug(message: "end background task")
                }
            }) { _ in
                NotificationHelper.postLocalNotification(with: Message(body: "処理が成功しました"))
                UIApplication.shared.endBackgroundTask(taskIdentifier)
                Logger.debug(message: "end background task")
                self.executeBackgroundForever()
            }.store(in: &cancellables)
    }
}

