//
//  VideoFilterExporter.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 5/3/25.
//

import Foundation
import AVKit


class VideoFilterExport{
   
   // For implementation in Swift 2.x, look at the history of this file at
   // https://github.com/jojodmo/VideoFilterExporter/blob/cf6fcdb4852eae5a1c8a2ce0887bebfeb0f36a9a/VideoFilterExporter.swift
    
    let asset: AVAsset
    let filters: [CIFilter]
    let context: CIContext
    init(asset: AVAsset, filters: [CIFilter], context: CIContext){
        self.asset = asset
        self.filters = filters
        self.context = context
    }
    
    convenience init(asset: AVAsset, filters: [CIFilter]){
        let eagl = EAGLContext(api: EAGLRenderingAPI.openGLES2)
        let context = CIContext(eaglContext: eagl!, options: [CIContextOption.workingColorSpace : NSNull()])
        
        self.init(asset: asset, filters: filters, context: context)
    }
    
    func export(toURL url: URL, callback: @escaping (_ url: URL?) -> Void){
        guard let track: AVAssetTrack = self.asset.tracks(withMediaType: .video).first else{callback(nil); return}
        
        let composition = AVMutableComposition()
        composition.naturalSize = track.naturalSize
        let videoTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        do{try videoTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: self.asset.duration), of: track, at: .zero)}
        catch _{callback(nil); return}
        
        if let audio = self.asset.tracks(withMediaType: .audio).first{
            do{try audioTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: self.asset.duration), of: audio, at: .zero)}
            catch _{callback(nil); return}
        }
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack!)
        layerInstruction.trackID = videoTrack!.trackID
        
        let instruction = VideoFilterCompositionInstruction(trackID: videoTrack!.trackID, filters: self.filters, context: self.context)
        instruction.timeRange = CMTimeRangeMake(start: .zero, duration: self.asset.duration)
        instruction.layerInstructions = [layerInstruction]
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.customVideoCompositorClass = VideoFilterCompositor.self
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        videoComposition.renderSize = videoTrack!.naturalSize
        videoComposition.instructions = [instruction]
        
        let session: AVAssetExportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)!
        session.videoComposition = videoComposition
        session.outputURL = url
        session.outputFileType = AVFileType.mp4
        
        session.exportAsynchronously(){
            DispatchQueue.main.async{
                callback(url)
            }
        }
    }
}

