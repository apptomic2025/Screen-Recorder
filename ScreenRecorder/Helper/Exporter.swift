//
//  Exporter.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 5/3/25.
//


import Foundation
import AVKit
import PhotosUI

enum TaskState {
    
    case pending
    case inProgess
    case completed
    case error
    
    var description: String {
        switch self {
        case .pending:
            return "Pending"
            
        case .inProgess:
            return "Uploading"
            
        case .completed:
            return "Completed"
            
        case .error:
            return "error"
            
        }
    
    }
}

var exportPresets = [AVAssetExportPreset960x540, AVAssetExportPreset1280x720,AVAssetExportPreset1920x1080,AVAssetExportPreset3840x2160]

struct CommentaryVideo{
    var videoURL: URL
    var audioURL: URL
    var videoVolume: Float
    var audioVolume: Float
    var videoComposition: AVVideoComposition
}

enum ExportType{
    case normal,commentary,facecam,editor
}
class Exporter{
    
    //static let shared = Exporter()
    private var progressTimer:Timer?
    private var progressCallback: ((Double?) -> Void)?
    private var assetExportsSession: AVAssetExportSession?

    private func resolutionForLocalVideo(asset: AVAsset) -> CGSize? {
        guard let track = asset.tracks(withMediaType: AVMediaType.video).first else { return nil }
        let size = track.naturalSize.applying(track.preferredTransform)
        return CGSize(width: abs(size.width), height: abs(size.height))
    }
    
    func deleteFile(_ filePath:URL) {
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            return
        }
        do {
            try FileManager.default.removeItem(atPath: filePath.path)
        }catch{
            fatalError("Unable to delete file: \(error) : \(#function).")
        }
    }
    
    func exportComentary(_ commentaryVideo: CommentaryVideo, progress: ((Double?) -> Void)? = nil, success: @escaping ((URL) -> Void), failure: @escaping ((String?) -> Void)) {
        // Load the video and audio assets
        let videoAsset = AVAsset(url: commentaryVideo.videoURL)
        let audioAsset = AVAsset(url: commentaryVideo.audioURL)
        
        let composition = AVMutableComposition()
        let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioOfvideoTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        do {
            try videoTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: videoAsset.duration), of: videoAsset.tracks(withMediaType: .video)[0], at: .zero)
            try audioOfvideoTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: videoAsset.duration), of: videoAsset.tracks(withMediaType: .audio)[0], at: .zero)
        } catch  {
            debugPrint(error.localizedDescription)
        }
        
        let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        do {
            try audioTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: audioAsset.duration), of: audioAsset.tracks(withMediaType: .audio)[0], at: .zero)
        } catch  {
            debugPrint(error.localizedDescription)
        }

        // Add your video and audio assets to the tracks

        let audioMix = AVMutableAudioMix()
        let audioMixInputParameters = AVMutableAudioMixInputParameters(track: audioTrack)
        audioMixInputParameters.trackID = audioTrack!.trackID
        audioMixInputParameters.setVolume(commentaryVideo.audioVolume, at: CMTime.zero) // adjust audio volume to 0.5

        let videoMixInputParameters = AVMutableAudioMixInputParameters(track: audioOfvideoTrack)
        videoMixInputParameters.trackID = audioOfvideoTrack!.trackID
        videoMixInputParameters.setVolume(commentaryVideo.videoVolume, at: CMTime.zero) // adjust video volume to 0.8

        audioMix.inputParameters = [audioMixInputParameters, videoMixInputParameters]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, h:mm:ss a"
        let dateString = dateFormatter.string(from: Date())
//        let videoName = "Commentary_\(dateString).mp4"
        let videoName = "Commentary_.mp4"
    
        guard let documentsPath = DirectoryManager.shared.commentaryDirURL() else { return }
        let outputURL = URL(fileURLWithPath: documentsPath.path).appendingPathComponent(videoName)
        
        debugPrint(outputURL)
        deleteFile(outputURL)
        
        self.progressCallback = progress
        
        // progress timer
        DispatchQueue.main.async {
            if #available(iOS 10.0, *) {
                self.progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] (time) in
                    if let progress = self?.assetExportsSession?.progress {
                        self?.progressCallback?(Double(progress))
                        if progress >= 1 {
                            self?.progressTimer?.invalidate()
                            self?.progressTimer = nil
                        }
                    } else if self?.assetExportsSession == nil {
                        self?.progressTimer?.invalidate()
                        self?.progressTimer = nil
                    }
                }
            } else {
                self.progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.timerAction(_:)), userInfo: nil, repeats: true)
            }
        }
        
        //export the video to as per your requirement conversion
        
        self.assetExportsSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHEVCHighestQuality)

        self.assetExportsSession?.outputURL = outputURL
        self.assetExportsSession?.outputFileType = AVFileType.mov
        self.assetExportsSession?.videoComposition = commentaryVideo.videoComposition
        self.assetExportsSession?.shouldOptimizeForNetworkUse = true
        self.assetExportsSession?.audioMix = audioMix
        
        self.assetExportsSession?.exportAsynchronously(completionHandler: {
            
            self.progressCallback?(1)
            self.progressCallback = nil
            self.progressTimer?.invalidate()
            self.progressTimer = nil
            
            
            
            if let exportSession = self.assetExportsSession,let url = self.assetExportsSession?.outputURL{
                
                self.restore()
                
                switch exportSession.status {
                case .completed :
                    
                    DispatchQueue.main.async {
                        PHPhotoLibrary.shared().performChanges({
                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                        }) { saved, error in
                            if saved {
                                
                            }
                        }
                    }
                    
                    success(url)
                case .failed:
                    if let _error = exportSession.error?.localizedDescription {
                        failure(_error)
                    }
                case .cancelled:
                    if let _error = exportSession.error?.localizedDescription {
                        failure(_error)
                    }
                default:
                    if let _error = exportSession.error?.localizedDescription {
                        failure(_error)
                    }
                }
            }
            
        })
    }
    
    func exportFacecamVideo(_ video: Video, presetVideoComposition: AVVideoComposition?,progress: ((Double?) -> Void)? = nil, success: @escaping ((URL) -> Void), failure: @escaping ((String?) -> Void)) {
        

        guard let asset = video.asset, let videoTime = video.videoTime else { return }
        let duration = (videoTime.endTime ?? asset.duration) - (videoTime.startTime ?? .zero)
        
        //Create Directory path for Save
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, h:mm:ss a"
        let dateString = dateFormatter.string(from: Date())
        let videoName = "Facecam_\(dateString).mov"
        
        guard let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else { return }
        let outputURL = URL(fileURLWithPath: documentsPath).appendingPathComponent(videoName)
        
        do { // delete old video
            try FileManager.default.removeItem(at: outputURL as URL)
        } catch {
            print(error.localizedDescription)
        }
        
        //Remove existing file
        self.deleteFile(outputURL)
        
        self.progressCallback = progress
        
        // progress timer
        DispatchQueue.main.async {
            if #available(iOS 10.0, *) {
                self.progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] (time) in
                    if let progress = self?.assetExportsSession?.progress {
                        self?.progressCallback?(Double(progress))
                        if progress >= 1 {
                            self?.progressTimer?.invalidate()
                            self?.progressTimer = nil
                        }
                    } else if self?.assetExportsSession == nil {
                        self?.progressTimer?.invalidate()
                        self?.progressTimer = nil
                    }
                }
            } else {
                self.progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.timerAction(_:)), userInfo: nil, repeats: true)
            }
        }
        
        //export the video to as per your requirement conversion
        
        self.assetExportsSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHEVCHighestQuality)

        self.assetExportsSession?.outputURL = outputURL
        self.assetExportsSession?.outputFileType = AVFileType.mov
        if let presetVideoComposition{
            self.assetExportsSession?.videoComposition = presetVideoComposition
        }
        self.assetExportsSession?.shouldOptimizeForNetworkUse = true
        
        self.assetExportsSession?.exportAsynchronously(completionHandler: {
            
            self.progressCallback?(1)
            self.progressCallback = nil
            self.progressTimer?.invalidate()
            self.progressTimer = nil
            
            
            
            if let exportSession = self.assetExportsSession,let url = self.assetExportsSession?.outputURL{
                
                self.restore()
                
                switch exportSession.status {
                case .completed :
                    /*
                    DispatchQueue.main.async {
                        PHPhotoLibrary.shared().performChanges({
                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                        }) { saved, error in
                            if saved {
                                
                            }
                        }
                    }
                    */
                    success(url)
                case .failed:
                    if let _error = exportSession.error?.localizedDescription {
                        failure(_error)
                    }
                case .cancelled:
                    if let _error = exportSession.error?.localizedDescription {
                        failure(_error)
                    }
                default:
                    if let _error = exportSession.error?.localizedDescription {
                        failure(_error)
                    }
                }
            }
            
        })
        
    }

    func exportVideoOld(_ video: Video, presetVideoComposition: AVVideoComposition?,progress: ((Double?) -> Void)? = nil, success: @escaping ((URL) -> Void), failure: @escaping ((String?) -> Void)) {
        
        
        guard let asset = video.asset, let videoTime = video.videoTime else { return }
        guard let startTime = videoTime.startTime, let endTime = videoTime.endTime else {
            
            return
        }
        
//        let videoAssetTrack = asset.tracks(withMediaType: .video)[0]
//        let audioAssetTrack = asset.tracks(withMediaType: .audio)[0]
        
       // let duratiaon = endTime - startTime
        //let timeRange = CMTimeRangeMake(start: startTime, duration: duration)
        let timeRange = CMTimeRange(start: startTime, end: endTime)
        
        let composition = AVMutableComposition()
        
        let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first!
        let videoCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        try? videoCompositionTrack?.insertTimeRange(timeRange, of: videoTrack, at: CMTime.zero)

        let audioTrack = asset.tracks(withMediaType: AVMediaType.audio).first!
        let audioCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        try? audioCompositionTrack?.insertTimeRange(timeRange, of: audioTrack, at: CMTime.zero)

       
        let audioMix = AVMutableAudioMix()
        let audioMixInputParameters = AVMutableAudioMixInputParameters(track: audioCompositionTrack)
        audioMixInputParameters.setVolume(video.volume, at: CMTime.zero)
        audioMix.inputParameters = [audioMixInputParameters]

        let speed = Float64(video.speed)
        let newTimeRange = CMTimeMultiplyByFloat64(timeRange.duration, multiplier: 1/speed)
        
        videoCompositionTrack?.scaleTimeRange(timeRange, toDuration: newTimeRange)
        audioCompositionTrack?.scaleTimeRange(timeRange, toDuration: newTimeRange)


//        let composition = AVMutableComposition()
//
//        if let videoTrack = asset.tracks(withMediaType: .video).first{
//
//            let speedVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
//
//            speedVideoTrack?.preferredTransform = videoTrack.preferredTransform
//            try? speedVideoTrack?.insertTimeRange(timeRange, of: videoTrack, at: .zero)
//
//        }
//
//        if let audioTrack = asset.tracks(withMediaType: .audio).first {
//            if audioTrack.segments.isEmpty{
//
//                if let track = audioTrack as? AVCompositionTrack{
//                    composition.removeTrack(track)
//                }
//
//            }else{
//
//                let speedAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
//
//                try? speedAudioTrack?.insertTimeRange(timeRange, of: audioTrack, at: .zero)
//
//                if video.speed != 1{
//                    let newDuration = CMTimeMultiplyByFloat64(timeRange.duration, multiplier: 1/Float64(video.speed))
//
//                    speedAudioTrack?.scaleTimeRange(timeRange, toDuration: newDuration)
//                }
//            }
//        }
        
//        let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
//        let audioOfvideoTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
//        do {
//            try videoTrack?.insertTimeRange(timeRange, of: videoAssetTrack, at: timeRange.start)
//            try audioOfvideoTrack?.insertTimeRange(timeRange, of: audioAssetTrack, at: timeRange.start)
//        } catch  {
//            debugPrint(error.localizedDescription)
//        }
        

        // Add your video and audio assets to the tracks

//        let audioMix = AVMutableAudioMix()
//
//        let videoMixInputParameters = AVMutableAudioMixInputParameters(track: audioOfvideoTrack)
//        videoMixInputParameters.trackID = audioOfvideoTrack!.trackID
//        videoMixInputParameters.setVolume(video.volume, at: startTime) // adjust video volume to 0.8
//
//        audioMix.inputParameters = [videoMixInputParameters]

        
        //Create Directory path for Save
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var outputURL = documentDirectory.appendingPathComponent("Output")
        do {
            try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
            outputURL = outputURL.appendingPathComponent("\(outputURL.lastPathComponent).mov")
        }catch let error {
            failure(error.localizedDescription)
        }
        
        //Remove existing file
        self.deleteFile(outputURL)
        
        //set resoultaion
        var pixel = AVAssetExportPreset1280x720
        if let pixel_ = video.pixel{
            pixel = pixel_
        }
        
        self.progressCallback = progress
        
        // progress timer
        DispatchQueue.main.async {
            if #available(iOS 10.0, *) {
                self.progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] (time) in
                    if let progress = self?.assetExportsSession?.progress {
                        self?.progressCallback?(Double(progress))
                        if progress >= 1 {
                            self?.progressTimer?.invalidate()
                            self?.progressTimer = nil
                        }
                    } else if self?.assetExportsSession == nil {
                        self?.progressTimer?.invalidate()
                        self?.progressTimer = nil
                    }
                }
            } else {
                self.progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.timerAction(_:)), userInfo: nil, repeats: true)
            }
        }
        
        //export the video to as per your requirement conversion
        
        self.assetExportsSession = AVAssetExportSession(asset: composition, presetName: pixel)

        self.assetExportsSession?.outputURL = outputURL
        self.assetExportsSession?.outputFileType = .mov
        if let presetVideoComposition{
            self.assetExportsSession?.videoComposition = presetVideoComposition
        }
        self.assetExportsSession?.shouldOptimizeForNetworkUse = true
        self.assetExportsSession?.audioMix = audioMix
        self.assetExportsSession?.timeRange = timeRange
        self.assetExportsSession?.exportAsynchronously(completionHandler: {
            
            self.progressCallback?(1)
            self.progressCallback = nil
            self.progressTimer?.invalidate()
            self.progressTimer = nil
            
            
            
            if let exportSession = self.assetExportsSession,let url = self.assetExportsSession?.outputURL{
                
                self.restore()
                
                switch exportSession.status {
                case .completed :
                    
//                    DispatchQueue.main.async {
//                        PHPhotoLibrary.shared().performChanges({
//                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
//                        }) { saved, error in
//                            if saved {
//
//                            }
//                        }
//                    }
                    
                    success(url)
                case .failed:
                    if let _error = exportSession.error?.localizedDescription {
                        failure(_error)
                    }
                case .cancelled:
                    if let _error = exportSession.error?.localizedDescription {
                        failure(_error)
                    }
                default:
                    if let _error = exportSession.error?.localizedDescription {
                        failure(_error)
                    }
                }
            }
            
        })


       
        
       /* */
        
    }
    
    func translation(image: CIImage, x: CGFloat, y: CGFloat) -> CIImage?{
        guard let filter = CIFilter(name: "CIAffineTransform") else {print("Unable to generate filter"); return nil}
        let translate = CGAffineTransform.init(translationX: x, y: y)
        filter.setValue(image, forKey: "inputImage")
        filter.setValue(translate, forKey: "inputTransform")
        return filter.outputImage
    }
    
    func rotate(image: CIImage, rotation: CGFloat) -> CIImage?{
        guard let filter = CIFilter(name: "CIAffineTransform") else {print("Unable to generate filter");return nil}
        let rotationTransform = CGAffineTransform.init(rotationAngle: rotation)
        filter.setValue(image, forKey: "inputImage")
        filter.setValue(rotationTransform, forKey: "inputTransform")
        return filter.outputImage
    }
    
    func finalExportVideo(_ video: Video, option: ConverterOption? = nil,progress: ((Double?) -> Void)? = nil, success: @escaping ((URL) -> Void), failure: @escaping ((String?) -> Void)) {
        
        self.restore()
        guard let videoTrack = self.videoTrack, let asset = self.asset else {
            DispatchQueue.main.async {
                failure("Can't find video")
            }
            return
        }
        self.option = option
        if self.renderSize?.width == 0 || self.renderSize?.height == 0 {
            self.restore()
            DispatchQueue.main.async {
                failure("The crop size is too small")
            }
            return
        }
        
        let composition = AVMutableComposition()

        var trackTimeRange: CMTimeRange
        
        if let trimRange = option?.trimRange {
            trackTimeRange = trimRange
        } else {
            trackTimeRange = CMTimeRange(start: .zero, duration: asset.duration)
        }
        
        guard let videoCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: videoTrack.trackID) else {
            self.restore()
            DispatchQueue.main.async {
                failure("Can't find video")
            }
            return
        }
        
        // trim
        try? videoCompositionTrack.insertTimeRange(trackTimeRange, of: videoTrack, at: .zero)
        
        //video speed
        let factor: Float = video.speed
        let scaledDuration = CMTimeMultiplyByFloat64(asset.duration, multiplier: 1/Float64(factor))

        videoCompositionTrack.scaleTimeRange(CMTimeRange(start: .zero, duration: asset.duration), toDuration: scaledDuration)
        
        //filter
//        let eagl = EAGLContext(api: EAGLRenderingAPI.openGLES2)
//        let context = CIContext(eaglContext: eagl!, options: [CIContextOption.workingColorSpace : NSNull()])
        
        let context = CIContext()
        var filters: [CIFilter] = []
        
        if let filter = CIFilter(name: video.videoFilter?.filterName ?? ""){
            filters.append(filter)
        }
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        layerInstruction.trackID = videoTrack.trackID
        layerInstruction.setOpacity(1.0, at: .zero)
        
        let transformFilter = CIFilter(name: "CIAffineTransform")!
        transformFilter.setDefaults()
        
        if let transform = self.transform {
            transformFilter.setValue(NSValue(cgAffineTransform: transform), forKey: kCIInputTransformKey)
            filters.append(transformFilter)

        }
        
        let instruction = VideoFilterCompositionInstruction(trackID: videoTrack.trackID, filters: filters, context: context)
        instruction.timeRange = CMTimeRangeMake(start: .zero, duration: asset.duration)
        instruction.layerInstructions = [layerInstruction]
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [instruction]
        // size
        if let renderSize = self.renderSize {
            videoComposition.renderSize = renderSize
        }
        videoComposition.customVideoCompositorClass = VideoFilterCompositor.self
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        
        let presetName = video.pixel ?? AVAssetExportPresetHighestQuality
        self.assetExportsSession = AVAssetExportSession(asset: composition, presetName: presetName)
        
        //volume
        if let audioTrack = asset.tracks(withMediaType: AVMediaType.audio).first {
            let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: audioTrack.trackID)
            // mute trim
            try? audioCompositionTrack?.insertTimeRange(trackTimeRange, of: audioTrack, at: .zero)
            audioCompositionTrack?.scaleTimeRange(CMTimeRangeMake(start: .zero, duration: asset.duration), toDuration: scaledDuration)

            //volume
            let audioMix = AVMutableAudioMix()
            let mixParameters = AVMutableAudioMixInputParameters(track: audioTrack)
            mixParameters.setVolume(0.1, at: CMTime.zero)
            audioMix.inputParameters = [mixParameters]
            self.assetExportsSession?.audioMix = audioMix
        }
        
        self.progressCallback = progress
        self.setuptimer()
        
        guard let outputURL = self.getOutputURL() else {
            failure("output url not found")
            return
        }
        
        //export the video to as per your requirement conversion
        
        self.assetExportsSession?.outputURL = outputURL
        self.assetExportsSession?.outputFileType = .mov
        
        self.assetExportsSession?.videoComposition = videoComposition
        self.assetExportsSession?.shouldOptimizeForNetworkUse = true
        self.assetExportsSession?.exportAsynchronously(completionHandler: {
            
            self.progressCallback?(1)
            self.progressCallback = nil
            self.progressTimer?.invalidate()
            self.progressTimer = nil
            
            
            
            if let exportSession = self.assetExportsSession,let url = self.assetExportsSession?.outputURL{
                
                self.restore()
                
                switch exportSession.status {
                case .completed :
                    success(url)
                case .failed:
                    if let _error = exportSession.error?.localizedDescription {
                        failure(_error)
                    }
                case .cancelled:
                    if let _error = exportSession.error?.localizedDescription {
                        failure(_error)
                    }
                default:
                    if let _error = exportSession.error?.localizedDescription {
                        failure(_error)
                    }
                }
            }
            
        })
    }
    
    func finalExportVideoo(_ video: Video, option: ConverterOption? = nil,progress: ((Double?) -> Void)? = nil, success: @escaping ((URL) -> Void), failure: @escaping ((String?) -> Void)) {
        
        self.restore()
        guard let videoTrack = self.videoTrack, let asset = self.asset else {
            DispatchQueue.main.async {
                failure("Can't find video")
            }
            return
        }
        
        
        self.progressCallback = progress
        self.option = option
        
        if self.renderSize?.width == 0 || self.renderSize?.height == 0 {
            self.restore()
            DispatchQueue.main.async {
                failure("The crop size is too small")
            }
            return
        }
        
        let composition = AVMutableComposition()

        var trackTimeRange: CMTimeRange
        
        if let trimRange = option?.trimRange {
            trackTimeRange = trimRange
        } else {
            trackTimeRange = CMTimeRange(start: .zero, duration: asset.duration)
        }
        
        guard let videoCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: videoTrack.trackID) else {
            self.restore()
            DispatchQueue.main.async {
                failure("Can't find video")
            }
            return
        }
        
        // trim
        try? videoCompositionTrack.insertTimeRange(trackTimeRange, of: videoTrack, at: .zero)
        
//        let compositionInstructions = AVMutableVideoCompositionInstruction()
//        compositionInstructions.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
//        compositionInstructions.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1).cgColor
//
//        let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)
//        // opacity
//        layerInstructions.setOpacity(1.0, at: .zero)
        // transform
//        if let transform = self.transform {
//            //layerInstructions.setTransform(transform, at: .zero)
//        }
        //compositionInstructions.layerInstructions = [layerInstructions]
       
//        let videoComposition = AVMutableVideoComposition()
//        videoComposition.instructions = [compositionInstructions]
        // size
        
        
        let compositionFilter = CIFilter(name: "CIAffineTransform")
        var needToTransform = false
        if let transform = self.transform {
            compositionFilter?.setValue(NSValue(cgAffineTransform: transform), forKey: kCIInputTransformKey)
            needToTransform = true
        }
        
        let cRect = option?.convertCrop?.cRect ?? CGRect(x: 0, y: 0, width: self.videoTrack?.naturalSize.width ?? 0, height: self.videoTrack?.naturalSize.height ?? 0)
        let ninghtyDegreeRect = normalRect(sSize: videoTrack.naturalSize, cRect: cRect, position: self.converterDegree ?? .degree0)
        
        let videoComposition = AVMutableVideoComposition(asset: asset, applyingCIFiltersWithHandler: {
            request in
            
            var outputImage = request.sourceImage
            
            if needToTransform{
                compositionFilter?.setValue(outputImage, forKey: kCIInputImageKey)
                outputImage = (compositionFilter?.outputImage!)!
                outputImage = outputImage.cropped(to: ninghtyDegreeRect)
                outputImage = outputImage.correctedExtent
                
            }
            
            if let filter = CIFilter(name: video.videoFilter?.filterName ?? ""){
                filter.setValue(outputImage, forKey: kCIInputImageKey)
                request.finish(with: filter.outputImage!, context: nil)
            }else{
                request.finish(with: outputImage, context: nil)
            }
            
            //request.finish(with: outputImage, context: nil)
           
            
        })
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
//        if let renderSize = self.renderSize {
//            videoComposition.renderSize = renderSize
//        }
        
        videoComposition.renderSize = ninghtyDegreeRect.size

            let factor: Float = video.speed
            let scaledDuration = CMTimeMultiplyByFloat64(asset.duration, multiplier: 1/Float64(factor))

            //try? videoCompositionTrack.insertTimeRange(trackTimeRange, of: videoTrack, at: .zero)
            videoCompositionTrack.scaleTimeRange(CMTimeRange(start: .zero, duration: asset.duration), toDuration: scaledDuration)
            
        
       
        
        //set resoultaion
        let presetName = video.pixel ?? AVAssetExportPresetHighestQuality
        self.assetExportsSession = AVAssetExportSession(asset: composition, presetName: presetName)

        if let audioTrack = asset.tracks(withMediaType: .audio).first{
            let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: audioTrack.trackID)
            try? audioCompositionTrack?.insertTimeRange(trackTimeRange, of: audioTrack, at: .zero)
            audioCompositionTrack?.scaleTimeRange(CMTimeRange(start: .zero, duration: asset.duration), toDuration: scaledDuration)
            
            //volume
            let audioParams = AVMutableAudioMixInputParameters(track: audioTrack)
            audioParams.setVolume(video.volume, at: .zero)
            let audioMix = AVMutableAudioMix()
            audioMix.inputParameters = [audioParams]
            
            self.assetExportsSession?.audioMix = audioMix

        }
        
        // progress timer
        DispatchQueue.main.async {
            if #available(iOS 10.0, *) {
                self.progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] (time) in
                    if let progress = self?.assetExportsSession?.progress {
                        self?.progressCallback?(Double(progress))
                        if progress >= 1 {
                            self?.progressTimer?.invalidate()
                            self?.progressTimer = nil
                        }
                    } else if self?.assetExportsSession == nil {
                        self?.progressTimer?.invalidate()
                        self?.progressTimer = nil
                    }
                }
            } else {
                self.progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.timerAction(_:)), userInfo: nil, repeats: true)
            }
        }
        
        //Create Directory path for Save
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var outputURL = documentDirectory.appendingPathComponent("Output")
        do {
            try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
            outputURL = outputURL.appendingPathComponent("\(outputURL.lastPathComponent).mov")
        }catch let error {
            failure(error.localizedDescription)
        }
        
        //Remove existing file
        self.deleteFile(outputURL)

        
        //export the video to as per your requirement conversion
        
        self.assetExportsSession?.outputURL = outputURL
        self.assetExportsSession?.outputFileType = .mov
        
        self.assetExportsSession?.videoComposition = videoComposition
        self.assetExportsSession?.shouldOptimizeForNetworkUse = true
        self.assetExportsSession?.exportAsynchronously(completionHandler: {
            
            self.progressCallback?(1)
            self.progressCallback = nil
            self.progressTimer?.invalidate()
            self.progressTimer = nil
            
            
            
            if let exportSession = self.assetExportsSession,let url = self.assetExportsSession?.outputURL{
                
                self.restore()
                
                switch exportSession.status {
                case .completed :
                    success(url)
                case .failed:
                    if let _error = exportSession.error?.localizedDescription {
                        failure(_error)
                    }
                case .cancelled:
                    if let _error = exportSession.error?.localizedDescription {
                        failure(_error)
                    }
                default:
                    if let _error = exportSession.error?.localizedDescription {
                        failure(_error)
                    }
                }
            }
            
        })
    }
    
    func setuptimer(){
        // progress timer
        DispatchQueue.main.async {
            if #available(iOS 10.0, *) {
                self.progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] (time) in
                    if let progress = self?.assetExportsSession?.progress {
                        self?.progressCallback?(Double(progress))
                        if progress >= 1 {
                            self?.progressTimer?.invalidate()
                            self?.progressTimer = nil
                        }
                    } else if self?.assetExportsSession == nil {
                        self?.progressTimer?.invalidate()
                        self?.progressTimer = nil
                    }
                }
            } else {
                self.progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.timerAction(_:)), userInfo: nil, repeats: true)
            }
        }
    }
    
    func getOutputURL()->URL?{
        //Create Directory path for Save
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var outputURL = documentDirectory.appendingPathComponent("OutputVideo")
        do {
            try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
            outputURL = outputURL.appendingPathComponent("\(outputURL.lastPathComponent).mov")
        }catch let error {
            debugPrint(error.localizedDescription)
            return nil
        }
        
        //Remove existing file
        self.deleteFile(outputURL)
        
        return outputURL
    }
    
    func exportVideo(_ video: Video, presetVideoComposition: AVVideoComposition?,progress: ((Double?) -> Void)? = nil, success: @escaping ((URL) -> Void), failure: @escaping ((String?) -> Void)) {
        
        
        guard let asset = video.asset, let videoTime = video.videoTime else { return }
        guard let startTime = videoTime.startTime, let endTime = videoTime.endTime else {
            
            return
        }
        
        
        //Create Directory path for Save
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var outputURL = documentDirectory.appendingPathComponent("Output")
        do {
            try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
            outputURL = outputURL.appendingPathComponent("\(outputURL.lastPathComponent).mov")
        }catch let error {
            failure(error.localizedDescription)
        }
        
        //Remove existing file
        self.deleteFile(outputURL)
        
        //set resoultaion
        var pixel = AVAssetExportPresetHighestQuality
        if let pixel_ = video.pixel{
            pixel = pixel_
        }
        
        self.progressCallback = progress
        
        // progress timer
        DispatchQueue.main.async {
            if #available(iOS 10.0, *) {
                self.progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] (time) in
                    if let progress = self?.assetExportsSession?.progress {
                        self?.progressCallback?(Double(progress))
                        if progress >= 1 {
                            self?.progressTimer?.invalidate()
                            self?.progressTimer = nil
                        }
                    } else if self?.assetExportsSession == nil {
                        self?.progressTimer?.invalidate()
                        self?.progressTimer = nil
                    }
                }
            } else {
                self.progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.timerAction(_:)), userInfo: nil, repeats: true)
            }
        }
        
        let timeRange = CMTimeRange(start: startTime, end: endTime)
        let factor: Float = video.speed
        let scaledDuration = CMTimeMultiplyByFloat64(asset.duration, multiplier: 1/Float64(factor))
        
        let composition = AVMutableComposition()
        self.assetExportsSession = AVAssetExportSession(asset: composition, presetName: pixel)
        
        guard  let videoTrack = asset.tracks(withMediaType: .video).first else{
            return
        }
        //if let videoTrack = asset.tracks(withMediaType: .video).first{
            let videoCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: videoTrack.trackID)
            try? videoCompositionTrack?.insertTimeRange(timeRange, of: videoTrack, at: .zero)
            videoCompositionTrack?.scaleTimeRange(CMTimeRange(start: .zero, duration: asset.duration), toDuration: scaledDuration)
        //}
        
        if let audioTrack = asset.tracks(withMediaType: .audio).first{
            let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: audioTrack.trackID)
            try? audioCompositionTrack?.insertTimeRange(timeRange, of: audioTrack, at: .zero)
            audioCompositionTrack?.scaleTimeRange(CMTimeRange(start: .zero, duration: asset.duration), toDuration: scaledDuration)
            
            //volume
            let audioParams = AVMutableAudioMixInputParameters(track: audioTrack)
            audioParams.setVolume(video.volume, at: .zero)
            let audioMix = AVMutableAudioMix()
            audioMix.inputParameters = [audioParams]
            
            self.assetExportsSession?.audioMix = audioMix

        }
        
        
        

        //export the video to as per your requirement conversion
        
        self.assetExportsSession?.outputURL = outputURL
        self.assetExportsSession?.outputFileType = .mov
        self.assetExportsSession?.videoComposition = presetVideoComposition
        
//        if let presetVideoComposition{
//            self.assetExportsSession?.videoComposition = presetVideoComposition
//        }
        self.assetExportsSession?.shouldOptimizeForNetworkUse = true
        self.assetExportsSession?.exportAsynchronously(completionHandler: {
            
            self.progressCallback?(1)
            self.progressCallback = nil
            self.progressTimer?.invalidate()
            self.progressTimer = nil
            
            
            
            if let exportSession = self.assetExportsSession,let url = self.assetExportsSession?.outputURL{
                
                self.restore()
                
                switch exportSession.status {
                case .completed :
                    success(url)
                case .failed:
                    if let _error = exportSession.error?.localizedDescription {
                        failure(_error)
                    }
                case .cancelled:
                    if let _error = exportSession.error?.localizedDescription {
                        failure(_error)
                    }
                default:
                    if let _error = exportSession.error?.localizedDescription {
                        failure(_error)
                    }
                }
            }
            
        })


       
        
       /* */
        
    }
    
    // Restore
    open func restore() {
        self.assetExportsSession?.cancelExport()
        self.assetExportsSession = nil
        self.progressTimer?.invalidate()
        self.progressTimer = nil
        self.progressCallback = nil
        self.option = nil
    }
    
    // Progress Time Timer
    @objc private func timerAction(_ sender: Timer) {
        if let progress = self.assetExportsSession?.progress {
            self.progressCallback?(Double(progress))
            if progress >= 1 {
                self.progressTimer?.invalidate()
                self.progressTimer = nil
            }
        } else if self.assetExportsSession == nil {
            self.progressTimer?.invalidate()
            self.progressTimer = nil
        }
    }
    
    func exportVideo(_ video: Video,cropRect: CGRect,superRect:CGRect,speed:Float?,fps:Int?, controller: UIViewController) {
        
        guard let asset = video.asset else { return }
        
        let timeRange = CMTimeRangeMake(start: CMTime.zero, duration: asset.duration)
        
        let speedComposition = AVMutableComposition()
        
        if let videoTrack = asset.tracks(withMediaType: .video).first{
            
            let speedVideoTrack = speedComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            
            speedVideoTrack?.preferredTransform = videoTrack.preferredTransform
            try? speedVideoTrack?.insertTimeRange(timeRange, of: videoTrack, at: .zero)
            
        }
        
        if let audioTrack = asset.tracks(withMediaType: .audio).first {
            if audioTrack.segments.isEmpty{
                
                if let track = audioTrack as? AVCompositionTrack{
                    speedComposition.removeTrack(track)
                }
                
            }else{
                
                let speedAudioTrack = speedComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                
                try? speedAudioTrack?.insertTimeRange(timeRange, of: audioTrack, at: .zero)
                
                if let speed,speed != 1{
                    let newDuration = CMTimeMultiplyByFloat64(timeRange.duration, multiplier: 1/Float64(speed))
                    
                    speedAudioTrack?.scaleTimeRange(timeRange, toDuration: newDuration)
                }
            }
        }
        
        // Try getting first video track to get size and transform
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            print("No video track to crop.")
            //completionHandler(.failure(NSError()))
            return
        }
        // Original video size
        let videoSize = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
        
        let transX = cropRect.origin.x / superRect.width
        let transY = (superRect.height - cropRect.origin.y - (cropRect.height)) / superRect.height
        
        let scalX = cropRect.width / superRect.width
        let scalY = cropRect.height / superRect.height
        
        let x = transX * videoSize.width
        let y = transY * videoSize.height
        
        let width = scalX * videoSize.width
        let height = scalY * videoSize.height
        
        let cRect = CGRect(origin: CGPoint(x: abs(x), y: abs(y)), size: CGSize(width: abs(width), height: abs(height)))
        
        debugPrint("cRect ",cRect.size, "  ", cropRect)
        
        
        // Create a mutable video composition configured to apply Core Image filters to each video frame of the specified asset.
        let composition = AVMutableVideoComposition(asset: speedComposition, applyingCIFiltersWithHandler: { [weak self] request in
            
            guard self != nil else { return }
            
            var outputImage = request.sourceImage
            
            
            outputImage = outputImage.cropped(to: cRect)
            
            
            outputImage = outputImage.correctedExtent
            
            request.finish(with: outputImage, context: nil)
            
        })
        
        // Update composition render size
        composition.renderSize = cRect.size
        debugPrint("cRect  hhhh ",cRect.size)
        // Export cropped video with AVAssetExport session
        guard let export = AVAssetExportSession(
            asset: speedComposition,
            presetName: AVAssetExportPresetHighestQuality)
        else {
            print("Cannot create export session.")
            //completionHandler(.failure(NSError()))
            return
        }
        
        
        let videoName = "crop"
        let exportURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(videoName)
            .appendingPathExtension("mp4") // Change file extension
        
        // Try to remove old file if exist
        try? FileManager.default.removeItem(at: exportURL)
        
        // Assign created mutable video composition to exporter
        export.videoComposition = composition
        export.outputFileType = .mp4 // Change file type (it should be same with extension)
        export.outputURL = exportURL
        export.shouldOptimizeForNetworkUse = false
        
        
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { _ in
            let pr = export.progress
            
            debugPrint("progress = \(pr)")
        })
        
        
        export.exportAsynchronously {
            DispatchQueue.main.async {
                switch export.status {
                case .failed:
                    if let error = export.error {
                        print(error.localizedDescription)
                        self.progressTimer?.invalidate()
                        //completionHandler(.failure(error))
                    }
                case .completed:
                    self.progressTimer?.invalidate()
                    
                    DispatchQueue.main.async {
                        let player = AVPlayer(url: exportURL)
                        let playerViewController = AVPlayerViewController()
                        playerViewController.player = player
                        controller.present(playerViewController, animated: true) {
                            playerViewController.player!.play()
                        }
                    }
                    
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: exportURL)
                    }) { saved, error in
                        if saved {
                            DispatchQueue.main.async {
                                let alertController = UIAlertController(title: "Your video was successfully saved to camera roll", message: nil, preferredStyle: .alert)
                                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                alertController.addAction(defaultAction)
                                controller.present(alertController, animated: true, completion: nil)
                            }
                            
                        }
                    }
                    
                    break
                default:
                    print("Something went wrong during export.")
                    if let error = export.error {
                        print(error.localizedDescription)
                        self.progressTimer?.invalidate()
                        
                        DispatchQueue.main.async {
                            let alertController = UIAlertController(title: "Something went wrong during export.", message: nil, preferredStyle: .alert)
                            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                            alertController.addAction(defaultAction)
                            controller.present(alertController, animated: true, completion: nil)
                        }
                        
                        //completionHandler(.failure(error))
                    } else {
                        //completionHandler(.failure(NSError(domain: "unknown error", code: 0, userInfo: nil)))
                    }
                    break
                }
            }
        }
    }
    
    // Video Size
    private var renderSize: CGSize? {
        guard let naturalSize = self.naturalSize else { return nil }
        var renderSize = naturalSize
        if let cropFrame = self.cropFrame {
            let width = floor(cropFrame.size.width / 16) * 16
            let height = floor(cropFrame.size.height / 16) * 16
            renderSize = CGSize(width: width, height: height)
        }
        return renderSize
    }

    // Video Rotate & Rrigin
    private var transform: CGAffineTransform? {
        guard let naturalSize = self.naturalSize,
            let radian = self.radian,
            let converterDegree = self.converterDegree else { return nil }

        var transform = CGAffineTransform.identity
            transform = transform.rotated(by: radian)
        if converterDegree == .degree90 {
            transform = transform.translatedBy(x: 0, y: -naturalSize.width)
        } else if converterDegree == .degree180 {
            transform = transform.translatedBy(x: -naturalSize.width, y: -naturalSize.height)
        } else if converterDegree == .degree270 {
            transform = transform.translatedBy(x: -naturalSize.height, y: 0)
        }

        if let cropFrame = self.cropFrame {
            if converterDegree == .degree0 {
                transform = transform.translatedBy(x: -cropFrame.origin.x, y: -cropFrame.origin.y)
            } else if converterDegree == .degree90 {
                transform = transform.translatedBy(x: -cropFrame.origin.y, y: cropFrame.origin.x)
            } else if converterDegree == .degree180 {
                transform = transform.translatedBy(x: cropFrame.origin.x, y: cropFrame.origin.y)
            } else if converterDegree == .degree270 {
                transform = transform.translatedBy(x: cropFrame.origin.y, y: -cropFrame.origin.x)
            }
        }
        return transform
    }
    
    private var cropFrame: CGRect? {
        guard let crop = self.option?.convertCrop else { return nil }
        guard let naturalSize = self.naturalSize else { return nil }
        let contrastSize = crop.contrastSize
        let frame = crop.frame
        let cropX = frame.origin.x * naturalSize.width / contrastSize.width
        let cropY = frame.origin.y * naturalSize.height / contrastSize.height
        let cropWidth = frame.size.width * naturalSize.width / contrastSize.width
        let cropHeight = frame.size.height * naturalSize.height / contrastSize.height
        let cropFrame = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
        return cropFrame
    }
    
    public var option: ConverterOption?
    public let asset: AVAsset?
    //public let presets: [String]

    private var videoTrack: AVAssetTrack? {
        return self.asset?.tracks(withMediaType: .video).first
    }

    private var radian: CGFloat? {
        guard let videoTrank = self.videoTrack else { return nil }
        return atan2(videoTrank.preferredTransform.b, videoTrank.preferredTransform.a) + (self.option?.rotate ?? 0)
    }

    private var converterDegree: ConverterDegree? {
        guard let radian = self.radian else { return nil }
        let degree = radian * 180 / .pi
        return ConverterDegree.convert(degree: degree)
    }

    private var naturalSize: CGSize? {
        guard let videoTrack = self.videoTrack,
            let converterDegree = self.converterDegree else { return nil }
        if converterDegree == .degree90 || converterDegree == .degree270 {
            return CGSize(width: videoTrack.naturalSize.height, height: videoTrack.naturalSize.width)
        } else {
            return CGSize(width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
        }
    }

    public init(asset: AVAsset? = nil) {
        self.asset = asset
        //self.presets = AVAssetExportSession.exportPresets(compatibleWith: asset)
    }
    
}

public enum Degree {
    case rotate0, rotate90, rotate180, rotate270
}

func normalRect(sSize: CGSize, cRect: CGRect, position: ConverterDegree) -> CGRect {
    // sSize is 0 degree normal supper view size
    // cRect is current child view rect
    // position is current child state 0, 90, 180, 270 degree
    
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat
    
    switch position {
        
    case .degree0:
        x = cRect.origin.x
        y = cRect.origin.y
        width = cRect.size.width
        height = cRect.size.height
    
    case .degree90:
        x = cRect.origin.y
        y = abs(sSize.height - (cRect.origin.x + cRect.size.height))
        width = cRect.size.height
        height = cRect.size.width
    
    case .degree180:
        x = sSize.width - (cRect.origin.x + cRect.size.width)
        y =  sSize.height - (cRect.origin.y + cRect.size.height)
        width = cRect.size.width
        height = cRect.size.height
    
    case .degree270:
        x = sSize.width - (cRect.origin.y + cRect.size.width)
        y = cRect.origin.x
        width = cRect.size.height
        height = cRect.size.width
    }
    
    // 0 degree normal child view rect
    return CGRect(x: x, y: y, width: width, height: height)
}


