//
//  Int+Extension.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 26/2/25.
//

import Foundation

// MARK: Int + time
extension Int {
    var time: String {
        let second = self
        let min = second / 60
        let sec = second % 60
        let secValue = sec < 10 ? "0\(sec)" : "\(sec)"
        return "\(min):\(secValue)"
    }
}
