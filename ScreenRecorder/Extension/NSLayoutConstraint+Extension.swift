//
//  NSLayoutConstraint+Extension.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 27/2/25.
//

import UIKit

extension NSLayoutConstraint {
    func priority(_ value: CGFloat) -> NSLayoutConstraint {
        priority = UILayoutPriority(Float(value))
        return self
    }
}

