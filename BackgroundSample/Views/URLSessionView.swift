//
//  DiscretionaryBackgroundURLSessionView.swift
//  BackgroundSample
//
//  Created by Takuya Yokoyama on 2020/03/10.
//  Copyright © 2020 Takuya Yokoyama. All rights reserved.
//

import SwiftUI

struct URLSessionView: View {
    private let sample = URLSessionSample()
    private let url = URL(string: "http://localhost:3000/users")!
    
    var body: some View {
        VStack(spacing: 32) {
            Button(action: {
                self.sample.requestForeground(url: self.url)
            }) {
                Text("フォアグラウンドで実行")
            }
            
            Button(action: {
                self.sample.requestBackground(url: self.url)
            }) {
                Text("バックグラウンドで実行")
            }
            
            Button(action: {
                self.sample.requestBackgroundDiscretionary(url: self.url)
            }) {
                Text("バックグラウンドでシステム裁量実行")
            }
        }
    }
}

struct URLSessionView_Previews: PreviewProvider {
    static var previews: some View {
        URLSessionView()
    }
}

import Combine

class URLSessionSample: NSObject {
    private var cancellables: Set<AnyCancellable> = []
    
    override init() {
        super.init()
        
        NotificationCenter.default
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .delay(for: 1.0, scheduler: DispatchQueue.main)
            .map { _ in UIApplication.shared.backgroundTimeRemaining }
            .sink { backgroundTimeRemaining in Logger.debug(message: "backgroundTimeRemaining = \(backgroundTimeRemaining)") }
            .store(in: &cancellables)
    }
    
    func requestForeground(url: URL) {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        session.downloadTask(with: URLRequest(url: url)).resume()
    }
    
    func requestBackground(url: URL) {
        // バックグラウンド処理のセッションを作成する
        let config = URLSessionConfiguration.background(withIdentifier: UUID().uuidString)
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        
        session.downloadTask(with: URLRequest(url: url)).resume()
    }
    
    func requestBackgroundDiscretionary(url: URL) {
        // バックグラウンド処理のセッションを作成する
        let config = URLSessionConfiguration.background(withIdentifier: UUID().uuidString)
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

extension URLSessionSample: URLSessionDownloadDelegate {
    // すべてのイベントが配信されるとこのメソッドが呼び出される
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            // AppDelegateのhandleEventsForBackgroundURLSessionが呼び出された時に受け渡された完了ハンドラを保持しておき、ここで取り出す
            // 完了ハンドラを実行すると、didFinishDownloadingToが実行される
            appDelegate.backgroundCompletionHandler?()
            appDelegate.backgroundCompletionHandler = nil
        }
    }
    
    // 取得したデータをここで参照する
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // ダウンロードされたデータはこの関数の終了とともに利用できなくなる
        // そのため、このメソッド外でもデータ利用したい場合は、別の場所に退避させる必要がある
        NotificationHelper.postLocalNotification(with: Message(body: try! String(contentsOf: location)))
    }
}

