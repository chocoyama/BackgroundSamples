//
//  UserDefault.swift
//  BackgroundSample
//
//  Created by Takuya Yokoyama on 2020/03/11.
//  Copyright © 2020 Takuya Yokoyama. All rights reserved.
//

import Foundation

@propertyWrapper
struct UserDefault<T> {
    let key: UserDefaultKey
    let defaultValue: T
    
    var wrappedValue: T {
        get { UserDefaults.standard.object(forKey: key.rawValue) as? T ?? defaultValue }
        set { UserDefaults.standard.set(newValue, forKey: key.rawValue) }
    }
}

enum UserDefaultKey: String {
    case latestBackgroundPushUpdateDate
}
