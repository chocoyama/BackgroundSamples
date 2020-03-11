//
//  BackgroundNotificationView.swift
//  BackgroundSample
//
//  Created by Takuya Yokoyama on 2020/03/11.
//  Copyright © 2020 Takuya Yokoyama. All rights reserved.
//

import SwiftUI

struct BackgroundNotificationView: View {
    @UserDefault(key: .latestBackgroundPushUpdateDate, defaultValue: nil)
    private var latestBackgroundPushUpdateDate: Date?
    private var latestBackgroundPushUpdateDateString: String {
        latestBackgroundPushUpdateDate.flatMap {
            dateFormatter.string(from: $0)
        } ?? "なし"
    }
    public let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(abbreviation: "JST")
        dateFormatter.dateFormat = "MM月dd日 HH時mm分ss秒"
        return dateFormatter
    }()
    
    var body: some View {
        Text("最終更新日時 = \(latestBackgroundPushUpdateDateString)")
    }
}

struct BackgroundNotificationView_Previews: PreviewProvider {
    static var previews: some View {
        BackgroundNotificationView()
    }
}
