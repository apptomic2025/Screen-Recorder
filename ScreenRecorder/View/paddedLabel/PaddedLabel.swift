//
//  PaddedLabel.swift
//  ScreenRecorder
//
//  Created by Apptomic on 4/10/25.
//

import Foundation
import UIKit

@IBDesignable
class PaddedLabel: UILabel {

    @IBInspectable var topInset: CGFloat = 0.0
    @IBInspectable var bottomInset: CGFloat = 0.0
    @IBInspectable var leftInset: CGFloat = 8.0
    @IBInspectable var rightInset: CGFloat = 8.0

    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + leftInset + rightInset,
                      height: size.height + topInset + bottomInset)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let newSize = super.sizeThatFits(size)
        return CGSize(width: newSize.width + leftInset + rightInset,
                      height: newSize.height + topInset + bottomInset)
    }
}
