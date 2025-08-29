//
//  ConverterCrop.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 26/2/25.
//

import UIKit

public struct ConverterCrop {
    public var frame: CGRect
    public var contrastSize: CGSize
    public var cRect: CGRect

    public init(frame: CGRect, contrastSize: CGSize, cRect: CGRect) {
        self.frame = frame
        self.contrastSize = contrastSize
        self.cRect = cRect
    }
}

