//
//  CGFloat+NSNumber.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 26/2/25.
//


import Foundation
import CoreGraphics

extension CGFloat {

    var nsNumber: NSNumber {
        return .init(value: native)
    }
}
