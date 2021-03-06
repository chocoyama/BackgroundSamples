//
//  ContentView.swift
//  BackgroundSample
//
//  Created by Takuya Yokoyama on 2020/03/10.
//  Copyright © 2020 Takuya Yokoyama. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 16.0) {
                NavigationLink(destination: BackgroundTaskCompletionView()) {
                    Text("Background Task Completion")
                }
                NavigationLink(destination: BackgroundNotificationView()) {
                    Text("Background Notification (Silent Push)")
                }
                NavigationLink(destination: URLSessionView()) {
                    Text("Background URLSession")
                }
                NavigationLink(destination: BackgroundTasksView()) {
                    Text("Background Tasks")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
