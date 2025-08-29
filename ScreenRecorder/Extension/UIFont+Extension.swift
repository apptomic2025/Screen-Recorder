//
//  UIFont+Extension.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 17/3/25.
//

import UIKit
import Foundation

extension UIFont {

    public enum FontType: String {
        case black = "-Black"     // 900
        case bold = "-Bold"       // 700
        case book = "-Book"       // 450
        case medium = "-Medium"   // 500
    }
    
    // CircularStd
    static func appFont_CircularStd(type: FontType, size: CGFloat) -> UIFont {
        let fontName = "CircularStd\(type.rawValue)"
        return UIFont(name: fontName, size: size) ?? UIFont.systemFont(ofSize: size)
    }
}
