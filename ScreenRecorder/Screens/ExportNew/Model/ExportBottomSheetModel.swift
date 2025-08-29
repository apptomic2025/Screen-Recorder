//
//  ExportBottomSheetModel.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 5/4/25.
//

import Foundation

struct VideoOption {
    var title: String       // e.g., "720p"
    var isSelected: Bool    // true if selected
    var value: Int          // e.g., 720
}

enum OptionMode {
    case resolution
    case bitRate
    case frameRate
}

