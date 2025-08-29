//
//  OnboardingModel.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 17/3/25.
//

import Foundation

struct VideoTool {
    let imageName: String
    let title: String
    let action: VideoToolAction
    let isPremium: Bool
}

enum VideoToolAction {
    case liveBroadcast
    case faceCam
    case commentary
    case gifMaker
    case editVideo
    case voiceRecorder
    case videoToPhoto
    case videoToAudio
    case videoTrimmer
    case videoCompress
    case photoToVideo
    case videoSpeed
    case cropVideo
}
