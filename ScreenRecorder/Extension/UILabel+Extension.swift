//
//  UILabel+Extension.swift
//  ScreenRecorder
//
//  Created by Apptomic on 10/9/25.
//

import Foundation
import UIKit

extension UILabel {
    
    /**
     Sets the label's text, applying a specific color to a target substring.
     - Parameters:
       - fullText: The entire string to be displayed.
       - targetText: The portion of the string you want to color differently.
       - color: The color to apply to the targetText.
    */
    func setTextWithColoredPart(fullText: String, targetText: String, color: UIColor) {
        // Create a mutable attributed string with the entire text.
        let attributedString = NSMutableAttributedString(string: fullText)
        
        // Find the range of the target text.
        guard let range = fullText.range(of: targetText) else {
            // If the target text isn't found, just set the plain text and exit.
            self.text = fullText
            return
        }
        
        // Convert the Swift String range to an NSRange for UIKit.
        let nsRange = NSRange(range, in: fullText)
        
        // Apply the color attribute to the found range.
        attributedString.addAttribute(.foregroundColor, value: color, range: nsRange)
        
        // Set the label's attributedText.
        self.attributedText = attributedString
    }
}
