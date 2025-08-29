//
//  VideoEditorModels.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 26/2/25.
//


import Foundation
import AVKit

struct VideoFilter{
    var filterName:String
    var filterDisplayName:String
    var isSelected:Bool
}

struct CropModel{
    var icon:String
    var title:String
    var cellWidth:Double
    var ratio: CGFloat
}

struct EditorModel{
    var icon:String
    var title:String
    var cellWidth:Double
}

// EditorModel(icon: "rotateEdit", title: "ROTATE", cellWidth: 46)
var editorArray:[EditorModel] = [EditorModel(icon: "trimEdit", title: "Trim",cellWidth: 30),EditorModel(icon: "cropEdit", title: "Crop",cellWidth: 34),EditorModel(icon: "filterEdit", title: "Filter",cellWidth: 38),EditorModel(icon: "speedEdit", title: "Speed",cellWidth: 38), EditorModel(icon: "rotateEdit", title: "Rotate", cellWidth: 46),EditorModel(icon: "volumeEdit", title: "Volume",cellWidth: 51)]

class Video{
    
    var creationDate: Date?
    var videoURL: URL?
    var duration: Float64?
    var speed: Float = 1.0
    var videoTime: VideoTime?
    var asset: AVAsset?
    var videoThumb: UIImage?
    var videoFilter: VideoFilter?
    var volume:Float = 1.0
    var frameRate: CMTimeScale?
    var pixel: String?
    var degrees: Float = 0
    var cropRect: CropperRect?
    
    init(_ videoURL:URL?) {
        self.creationDate = Date()
        self.videoURL = videoURL
        if let videoURL{
            VideoHelper.shared.generateImages(for: AVAsset(url: videoURL), at: [NSValue(time: CMTime(value: 0, timescale: 1000))], with: CGSize(width: 100, height: 100)) { imagee in
                self.videoThumb = imagee
            }

        }
    }
}

