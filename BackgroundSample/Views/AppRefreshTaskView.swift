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

struct AppRefreshTaskView: View {
    var body: some View {
        Text("Hello, World!")
    }
}

struct AppRefreshTaskView_Previews: PreviewProvider {
    static var previews: some View {
        AppRefreshTaskView()
    }
}

class AppRefreshTaskSample {
    private let taskIdentifier = "jp.co.sample.app_refresh_task"
    private let sampleRepository = SampleRepository()
    private var cancellables: Set<AnyCancellable> = []
    
    func register() {
        // TaskIdentifier: Info.plistに設定したIDを指定
        // Queue: nilを渡すとシステムがキューを作成する
        // launchHandler: Appの起動時に呼ばれる
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { (task) in
            // BGTaskRequestは1度の起動にしか対応しないので、
            // 1日中Appをリフレッシュさせたい場合は、ハンドラ内で再度スケジューリングをさせる
            self.schedule()
            
            self.handle(task: task as! BGAppRefreshTask)
        }
    }
    
    func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        
        // 実行開始時期を遅らせる
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    private func handle(task: BGAppRefreshTask) {
        sampleRepository.post(processTime: 20)
            .sink(receiveCompletion: { (result) in
                switch result {
                case .finished:
                    break
                case .failure:
                    // タスクが完了したタイミングで、システムに完了を伝える。
                    task.setTaskCompleted(success: false)
                }
            }) { _ in
                // タスクが完了したタイミングで、システムに完了を伝える。
                task.setTaskCompleted(success: true)
            }.store(in: &cancellables)
        
        // タスクを完了しきれなかった場合に、処理をキャンセルする
        task.expirationHandler = {
            self.cancellables.forEach { $0.cancel() }
        }
    }
}
