//
//  ConverterOption.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 26/2/25.
//

import Foundation
import AVKit

public struct ConverterOption {
    public var trimRange: CMTimeRange?
    public var convertCrop: ConverterCrop?
    public var rotate: CGFloat?
    public var quality: String?
    public var isMute: Bool

    public init(trimRange: CMTimeRange?, convertCrop: ConverterCrop?, rotate: CGFloat?, quality: String?, isMute: Bool = false) {
        self.trimRange = trimRange
        self.convertCrop = convertCrop
        self.rotate = rotate
        self.quality = quality
        self.isMute = isMute
    }
}

