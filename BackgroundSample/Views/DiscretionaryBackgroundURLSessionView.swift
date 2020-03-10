//
//  DiscretionaryBackgroundURLSessionView.swift
//  BackgroundSample
//
//  Created by Takuya Yokoyama on 2020/03/10.
//  Copyright © 2020 Takuya Yokoyama. All rights reserved.
//

import SwiftUI

struct DiscretionaryBackgroundURLSessionView: View {
    private let sample = DiscretionaryBackgroundURLSessionSample()
    var body: some View {
        Button(action: {
            self.sample.request(url: URL(string: "https://www.yahoo.co.jp")!)
        }) {
            Text("Button")
        }
    }
}

struct DiscretionaryBackgroundURLSessionView_Previews: PreviewProvider {
    static var previews: some View {
        DiscretionaryBackgroundURLSessionView()
    }
}

class DiscretionaryBackgroundURLSessionSample: NSObject {
    func request(url: URL) {
        let config = URLSessionConfiguration.background(withIdentifier: "some unique identifier")
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        
        // isDiscretionaryをtrueにすることで、システムの裁量でバックグラウンドタスクをスケジューリングさせるように指定する
        config.isDiscretionary = true
        
        // タスク完了時にシステムにアプリをバックグラウンドで再開または起動させる
        // 起動ハンドラとして、application(_:handleEventsForBackgroundURLSession:completionHandler:)が呼ばれる
        config.sessionSendsLaunchEvents = true
        
        // Wi-Fi接続に限る
        config.allowsCellularAccess = false
        
        // タイムアウト間隔の設定
        config.timeoutIntervalForResource = 24 * 60 * 60
        config.timeoutIntervalForRequest = 60
        
        let task = session.downloadTask(with: URLRequest(url: url))
        
        // 最短開始日時
        // 実行を遅らせたい場合に指定する
        task.earliestBeginDate = Date(timeIntervalSinceNow: 2 * 60 * 60)
        
        // 想定ダウンロードサイズ
        // ダウンロードの作業量をシステムに知らせておくことで、システムによるスケジューリングを最適化させる
        task.countOfBytesClientExpectsToSend = 160
        task.countOfBytesClientExpectsToReceive = 4096
        task.resume()
    }
}

extension DiscretionaryBackgroundURLSessionSample: URLSessionDownloadDelegate {
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                // handleEventsForBackgroundURLSessionで受け渡された完了ハンドラをAppDelegateで保持させておき、取り出す
                let backgroundCompletionHandler = appDelegate.backgroundCompletionHandler else { return }
            // これが呼ばれることで、didFinishDownloadingToが実行される
            backgroundCompletionHandler()
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // ダウンロードされたデータはこの関数の終了とともに利用できなくなる
        // そのため、このメソッド外でも利用したい場合は、別の場所にデータを退避させる必要がある
    }
}
