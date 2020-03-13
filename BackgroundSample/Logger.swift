//
//  Logger.swift
//  BackgroundSample
//
//  Created by Takuya Yokoyama on 2020/03/13.
//  Copyright © 2020 Takuya Yokoyama. All rights reserved.
//

import Foundation

struct Logger {
    static func debug(message: String) {
        print("### \(Date()) \(message)")
    }
}
