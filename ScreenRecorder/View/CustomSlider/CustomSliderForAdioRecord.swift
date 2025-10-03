//
//  CustomSlider.swift
//  ScreenRecorder
//
//  Created by Apptomic on 3/10/25.
//

import Foundation
import UIKit

class CustomSliderForAdioRecord: UISlider {

    @IBInspectable var trackHeight: CGFloat = 3

    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        // Keeps the origin and width, but overrides the track's height
        var newRect = super.trackRect(forBounds: bounds)
        newRect.size.height = trackHeight
        return newRect
    }
}
