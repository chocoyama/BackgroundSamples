//
//  AppRefreshTaskView.swift
//  BackgroundSample
//
//  Created by Takuya Yokoyama on 2020/03/10.
//  Copyright © 2020 Takuya Yokoyama. All rights reserved.
//

import SwiftUI
import BackgroundTasks
import Combine

struct BackgroundTasksView: View {
    var body: some View {
        VStack(spacing: 32) {
            Button(action: {
                AppRefreshTaskSample.schedule()
            }) {
                Text("AppRefreshTaskをスケジューリング")
            }
            
            Button(action: {
                ProcessingTaskSample.schedule()
            }) {
                Text("ProcessingTaskをスケジューリング")
            }
        }
    }
}

struct AppRefreshTaskView_Previews: PreviewProvider {
    static var previews: some View {
        BackgroundTasksView()
    }
}

class AppRefreshTaskSample {
    private static let taskIdentifier = "jp.co.sample.app_refresh_task"
    private let sampleRepository = SampleRepository()
    private var cancellables: Set<AnyCancellable> = []
    
    func register() {
        // TaskIdentifier: Info.plistに設定したIDを指定
        // Queue: nilを渡すとシステムがキューを作成する
        // launchHandler: Appの起動時に呼ばれる
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.taskIdentifier, using: nil, launchHandler: { task in
            Logger.debug(message: "AppRefreshTasksのlaunchハンドラが呼ばれた")
            // BGTaskRequestは1度の起動にしか対応しないので、
            // 1日中Appをリフレッシュさせたい場合は、ハンドラ内で再度スケジューリングをさせる
            Self.schedule()
            self.handle(task: task as! BGAppRefreshTask)
        })
    }
    
    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        
        // 実行開始時期を遅らせる
        let oneHour: TimeInterval = 60 * 60
        request.earliestBeginDate = Date(timeIntervalSinceNow: oneHour)
        
        do {
            // バックグラウンドでのスケジュール時に導入しやすいため、同期処理になっている
            // 起動時などのパフォーマンスに影響しやすいタイミングに実行する場合は、バックグラウンドキューで呼ぶ方が良い
            try BGTaskScheduler.shared.submit(request)
        } catch {
            fatalError("Could not schedule app refresh: \(error)")
        }
    }
    
    private func handle(task: BGAppRefreshTask) {
        sampleRepository.post(processTime: 10)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { (result) in
                switch result {
                case .finished:
                    break
                case .failure:
                    NotificationHelper.postLocalNotification(with: Message(body: "AppRefreshTaskが失敗しました"))
                    // タスクが完了したタイミングで、システムに完了を伝える。
                    task.setTaskCompleted(success: false)
                }
            }) { _ in
                NotificationHelper.postLocalNotification(with: Message(body: "AppRefreshTaskが成功しました"))
                // タスクが完了したタイミングで、システムに完了を伝える。
                task.setTaskCompleted(success: true)
            }.store(in: &cancellables)
        
        // タスクを完了しきれなかった場合に、処理をキャンセルする
        task.expirationHandler = {
            self.cancellables.forEach { $0.cancel() }
            NotificationHelper.postLocalNotification(with: Message(body: "AppRefreshTaskが完了しませんでした"))
            task.setTaskCompleted(success: false)
        }
    }
}

class ProcessingTaskSample {
    private static let taskIdentifier = "jp.co.sample.processing_task"
    private let sampleRepository = SampleRepository()
    private var cancellables: Set<AnyCancellable> = []
    
    func register() {
        // TaskIdentifier: Info.plistに設定したIDを指定
        // Queue: nilを渡すとシステムがキューを作成する
        // launchHandler: Appの起動時に呼ばれる
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.taskIdentifier, using: nil, launchHandler: { (task) in
            Logger.debug(message: "ProcessingTasksのlaunchハンドラが呼ばれた")
            // BGTaskRequestは1度の起動にしか対応しないので、
            // 1日中Appをリフレッシュさせたい場合は、ハンドラ内で再度スケジューリングをさせる
            Self.schedule()
            self.handle(task: task as! BGProcessingTask)
        })
    }
    
    static func schedule() {
        let request = BGProcessingTaskRequest(identifier: taskIdentifier)
        
        // 通信が必要な場合はtrueにする（デフォルトはfalseで、この場合通信がない時間にも起動される）
        request.requiresNetworkConnectivity = true
        
        // 充電中に実行したい処理の場合はtrueにする
        // これがtrueの時にCPU Monitorが無効になる
        request.requiresExternalPower = true
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule database cleaning: \(error)")
        }
    }
    
    private func handle(task: BGProcessingTask) {
        sampleRepository.post(processTime: 60)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { (result) in
                switch result {
                case .finished:
                    break
                case .failure:
                    NotificationHelper.postLocalNotification(with: Message(body: "ProcessingTaskが失敗しました"))
                    // タスクが完了したタイミングで、システムに完了を伝える。
                    task.setTaskCompleted(success: false)
                }
            }) { _ in
                NotificationHelper.postLocalNotification(with: Message(body: "ProcessingTaskが成功しました"))
                // タスクが完了したタイミングで、システムに完了を伝える。
                task.setTaskCompleted(success: true)
            }.store(in: &cancellables)
        
        // タスクを完了しきれなかった場合に、処理をキャンセルする
        task.expirationHandler = {
            self.cancellables.forEach { $0.cancel() }
            NotificationHelper.postLocalNotification(with: Message(body: "ProcessingTaskが完了しませんでした"))
            task.setTaskCompleted(success: false)
        }
    }
}
