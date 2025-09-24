
import UIKit


struct ToolModel {
    let title: String
    let IconImg: UIImage?
    let isPremium: Bool
}


var tools: [ToolModel] = [
    ToolModel(title: "Live Broadcast", IconImg: UIImage(named: "liveBroadcast"), isPremium: true),
    ToolModel(title: "Facecam", IconImg: UIImage(named: "faceCam"), isPremium: false),
    ToolModel(title: "Commentary", IconImg: UIImage(named: "commentry"), isPremium: false),
    ToolModel(title: "Video to GIF", IconImg: UIImage(named: "videoToGif"), isPremium: false),
    ToolModel(title: "Video Edit", IconImg: UIImage(named: "videoEdit"), isPremium: false)
]

enum SelectToolType: Int {
    case faceCam, commentary, gif, edit, voiceReocrd, photoToVideo,videoToPhoto, videoToAudio, trim, compress, speed, crop, extractAudio, none
}
