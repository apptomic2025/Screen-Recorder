//
//  CropResult.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 27/2/25.
//

import Foundation
import UIKit

public struct CropResult {
    public var error: Error?
    public var image: UIImage?
    public var cropFrame: CGRect?
    public var imageSize: CGSize?
    public var realCropFrame: CGRect?

    public init() { }
}
