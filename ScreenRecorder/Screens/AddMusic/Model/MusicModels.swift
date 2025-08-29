//
//  MusicModels.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 22/3/25.
//

import Foundation
import UIKit
import AVFoundation

class MusicCollectionModel{
    var name: String?
    var duration: Double?
    var songURL: URL?
    var artistName: String?
    var thumbImage: UIImage?
    
    init(name: String? = nil, duration: Double? = nil, songURL: URL? = nil, artistName: String? = nil, thumbImage: UIImage? = nil) {
        self.name = name
        self.duration = duration
        self.songURL = songURL
        self.artistName = artistName
        self.thumbImage = thumbImage
    }
}


class AddMusicModel{
    var startTime: Double?
    var endTime: Double?
    var asset: AVAsset?
    var url: URL?
    
    init(startTime: Double? = nil, endTime: Double? = nil, asset: AVAsset? = nil, url: URL? = nil) {
        self.startTime = startTime
        self.endTime = endTime
        self.asset = asset
        self.url = url
    }
}

