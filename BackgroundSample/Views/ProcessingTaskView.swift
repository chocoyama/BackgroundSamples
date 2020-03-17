//
//  ProcessingTaskView.swift
//  BackgroundSample
//
//  Created by Takuya Yokoyama on 2020/03/10.
//  Copyright © 2020 Takuya Yokoyama. All rights reserved.
//

import SwiftUI
import BackgroundTasks

struct ProcessingTaskView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct ProcessingTaskView_Previews: PreviewProvider {
    static var previews: some View {
        ProcessingTaskView()
    }
}

struct ProcessingTaskSample {
    private let taskIdentifier = "jp.co.sample.processing_task"
    
    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { (task) in
            self.handle(task: task as! BGProcessingTask)
        }
    }
    
    private func handle(task: BGProcessingTask) {
        task.expirationHandler = {
            
        }
    }
    
    // 頻繁に実行しなくて良い場合はブロックする
    func scheduleIfNeeded() {
        let lastExecuted = Date()
        
        let now = Date()
        let oneWeek = TimeInterval(7 * 24 * 60 * 60)
        
        guard now > lastExecuted + oneWeek else { return }
        
        schedule()
    }
    
    private func schedule() {
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
}
