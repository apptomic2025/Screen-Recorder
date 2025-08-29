//
//  MenuStackComponentView.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 21/2/25.
//
import UIKit

struct StackModel {
    var title:String
    var icon: String
}

var stackArray1: [StackModel] = [StackModel(title: "Live Broadcast", icon: "broadcast"), StackModel(title: "Face Cam", icon: "facecam"), StackModel(title: "Commentary", icon: "mick"), StackModel(title: "Voice Recorder", icon: "voiceRecorder"), StackModel(title: "Video to Photo", icon: "videoToPhoto"), StackModel(title: "Trim", icon: "broadcast"), StackModel(title: "Speed", icon: "speedMenu")]

var stackArray2: [StackModel] = [StackModel(title: "My Recordings", icon: "myVideo"), StackModel(title: "Video to GIF", icon: "gif-file"), StackModel(title: "Video Editor", icon: "videoeditor"), StackModel(title: "Photo to Video", icon: "photoToVideo"), StackModel(title: "Video to Audio", icon: "videoToAudio"), StackModel(title: "Compress Video", icon: "compressMenu"), StackModel(title: "Crop", icon: "cropMenu")]

class MenuStackComponentView: UIView {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imgViewIcon: UIImageView!
    @IBOutlet weak var btnTap: UIButton!
    
    @IBOutlet weak var titleLabel2: UILabel!
    @IBOutlet weak var imgViewIcon2: UIImageView!
    @IBOutlet weak var btnTap2: UIButton!
    
    
    @IBOutlet weak var probadgeIcon: UIImageView!
    @IBOutlet weak var probadgeIcon2: UIImageView!

}
