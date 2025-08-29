//
//  EditorManager.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 5/3/25.
//


import Foundation
import AVKit
import AVFoundation

class EditorManager: NSObject {
    
    static let shared = EditorManager()
    
    func deleteFile(_ filePath:URL) {
        guard FileManager.default.fileExists(atPath: filePath.path) else { return }
        do {
            try FileManager.default.removeItem(atPath: filePath.path)
        }catch{
            fatalError("Unable to delete file: \(error) : \(#function).")
        }
    }
    
    func extractAudioFromVideo(inputURL: URL, range: CMTimeRange, completion: @escaping (URL?) -> Void) {
        let asset = AVURLAsset(url: inputURL)
        let composition = AVMutableComposition()

        // Extract the audio track from the asset
        guard let audioAssetTrack = asset.tracks(withMediaType: .audio).first else {
            completion(nil)
            return
        }

        let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: audioAssetTrack.trackID)

        do {
            //try audioCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: asset.duration), of: audioAssetTrack, at: .zero)
            try audioCompositionTrack?.insertTimeRange(range, of: asset.tracks(withMediaType: .audio)[0], at: .zero)
        } catch let error {
            completion(nil)
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, h:mm:ss a"
        let dateString = dateFormatter.string(from: Date())
        let videoName = "ExtractAudio_\(dateString).m4a"

        guard let documentsPath = DirectoryManager.shared.extractAudioDirPath() else {
            print("error")
            return }
        let outputURL = documentsPath.appendingPathComponent(videoName)
        debugPrint(outputURL)
        
        // create thumImage and save document directory
        if let img = inputURL.generateThumbnail() {
            let imgFileName = "ExtractAudio_\(dateString).jpg" //inputURL.deletingPathExtension().lastPathComponent+".jpg"
            if let thumbURL = DirectoryManager.shared.extractAudioThumDirPath()?.appendingPathComponent(imgFileName){
                do {
                    try img.jpegData(compressionQuality: 0.6)?.write(to: thumbURL)
                } catch {
                    debugPrint("img saving failed")
                }
            }
        }
        
        // Export the audio track to a file
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            completion(nil)
            return
        }

        exportSession.outputFileType = AVFileType.m4a
        exportSession.outputURL = outputURL

        exportSession.exportAsynchronously {
            if exportSession.status == .completed {
                completion(outputURL)
            } else {
                let error = exportSession.error ?? NSError(domain: "Unknown", code: -1, userInfo: nil)
                completion(nil)
            }
        }
    }
    
    func mergeVideoWithAudio(videoUrl: URL, audioUrl: URL, volumeLabel: Float, microphoneLabel: Float, success: @escaping((URL) -> Void)) {
        let videoAsset = AVAsset(url: videoUrl)
        let musicAsset = AVAsset(url: audioUrl)

        let audioVideoComposition = AVMutableComposition()

        let audioMix = AVMutableAudioMix()
        var mixParameters = [AVMutableAudioMixInputParameters]()

        let videoCompositionTrack = audioVideoComposition
            .addMutableTrack(withMediaType: .video, preferredTrackID: .init())!

        let audioCompositionTrack = audioVideoComposition
            .addMutableTrack(withMediaType: .audio, preferredTrackID: .init())!

        let musicCompositionTrack = audioVideoComposition
            .addMutableTrack(withMediaType: .audio, preferredTrackID: .init())!

        let videoAssetTrack = videoAsset.tracks(withMediaType: .video)[0]
        let audioAssetTrack = videoAsset.tracks(withMediaType: .audio).first
        let musicAssetTrack = musicAsset.tracks(withMediaType: .audio)[0]

        let audioParameters = AVMutableAudioMixInputParameters(track: audioAssetTrack)
        audioParameters.trackID = audioCompositionTrack.trackID

        let musicParameters = AVMutableAudioMixInputParameters(track: musicAssetTrack)
        musicParameters.trackID = musicCompositionTrack.trackID

        audioParameters.setVolume(volumeLabel, at: .zero)
        musicParameters.setVolume(microphoneLabel, at: .zero)

        mixParameters.append(audioParameters)
        mixParameters.append(musicParameters)

        audioMix.inputParameters = mixParameters

        /// prevents video from unnecessary rotations
        videoCompositionTrack.preferredTransform = videoAssetTrack.preferredTransform

        do {
            let timeRange = CMTimeRange(start: .zero, duration: videoAsset.duration)
            try videoCompositionTrack.insertTimeRange(timeRange, of: videoAssetTrack, at: .zero)
            if let audioAssetTrack = audioAssetTrack {
                try audioCompositionTrack.insertTimeRange(timeRange, of: audioAssetTrack, at: .zero)
            }
            try musicCompositionTrack.insertTimeRange(timeRange, of: musicAssetTrack, at: .zero)

        } catch {
            print("error")
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, h:mm:ss a"
        let dateString = dateFormatter.string(from: Date())
        let videoName = "Commentary_\(dateString).mp4"

        guard let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else { return }
        let outputURL = URL(fileURLWithPath: documentsPath).appendingPathComponent(videoName)

        do { // delete old video
            try FileManager.default.removeItem(at: outputURL as URL)
        } catch {
            print(error.localizedDescription)
        }

        let mutableVideoComposition: AVMutableVideoComposition = AVMutableVideoComposition()
        mutableVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        //mutableVideoComposition.renderSize = CGSize(width: 480, height: 640)

        if let exportSession = AVAssetExportSession(asset: audioVideoComposition, presetName: AVAssetExportPresetHighestQuality) {
            exportSession.outputURL = outputURL
            exportSession.outputFileType = AVFileType.mp4
            exportSession.shouldOptimizeForNetworkUse = true
            exportSession.audioMix = audioMix

            /// try to export the file and handle the status cases
            exportSession.exportAsynchronously(completionHandler: { [self] in
                switch exportSession.status {
                case .failed:
                    if exportSession.error != nil {
                        print("error : \(exportSession.error?.localizedDescription ?? "error")")
                    }

                case .cancelled:
                    if exportSession.error != nil {
                        print("error : \(exportSession.error?.localizedDescription ?? "error")")
                    }

                default:
                    print("finished")
                    print("avMarge URL--", outputURL)
                    success(outputURL)
                }
            })
        } else {
            // failure(nil)
        }
    }
    
    // ============================================
    
    /// Merges video and sound while keeping sound of the video too
    ///
    /// - Parameters:
    ///   - videoUrl: URL to video file
    ///   - audioUrl: URL to audio file
    ///   - shouldFlipHorizontally: pass True if video was recorded using frontal camera otherwise pass False
    ///   - completion: completion of saving: error or url with final video
    func mergeVideoAndAudio(videoUrl: URL,
                            audioUrl: URL,
                            shouldFlipHorizontally: Bool = false,
                            volumeLabel: Float,
                            microphoneLabel: Float,
                            completion: @escaping (_ error: Error?, _ url: URL?) -> Void) {

        let mixComposition = AVMutableComposition()
        var mutableCompositionVideoTrack = [AVMutableCompositionTrack]()
        var mutableCompositionAudioTrack = [AVMutableCompositionTrack]()
        var mutableCompositionAudioOfVideoTrack = [AVMutableCompositionTrack]()

        /*
        let audioMix = AVMutableAudioMix()
        var mixParameters = [AVMutableAudioMixInputParameters]()
        */
         
        //start merge

        let aVideoAsset = AVAsset(url: videoUrl)
        let aAudioAsset = AVAsset(url: audioUrl)

        let compositionAddVideo = mixComposition.addMutableTrack(withMediaType: .video,
                                                                       preferredTrackID: kCMPersistentTrackID_Invalid)

        let compositionAddAudio = mixComposition.addMutableTrack(withMediaType: .audio,
                                                                     preferredTrackID: kCMPersistentTrackID_Invalid)

        let compositionAddAudioOfVideo = mixComposition.addMutableTrack(withMediaType: .audio,
                                                                            preferredTrackID: kCMPersistentTrackID_Invalid)

        let aVideoAssetTrack: AVAssetTrack = aVideoAsset.tracks(withMediaType: .video)[0]
        let aAudioOfVideoAssetTrack: AVAssetTrack? = aVideoAsset.tracks(withMediaType: .audio).first
        let aAudioAssetTrack: AVAssetTrack = aAudioAsset.tracks(withMediaType: .audio)[0]
        
        /*
        // add volume label and micro volume label section /
        let audioParameters = AVMutableAudioMixInputParameters(track: aAudioOfVideoAssetTrack)
        audioParameters.trackID = compositionAddAudio!.trackID

        let musicParameters = AVMutableAudioMixInputParameters(track: aAudioAssetTrack)
        musicParameters.trackID = compositionAddAudioOfVideo!.trackID

        audioParameters.setVolume(volumeLabel, at: .zero)
        musicParameters.setVolume(microphoneLabel, at: .zero)

        mixParameters.append(audioParameters)
        mixParameters.append(musicParameters)
        audioMix.inputParameters = mixParameters
        */
        
        
        // Default must have tranformation
        compositionAddVideo?.preferredTransform = aVideoAssetTrack.preferredTransform

        if let compositionAddVideo = compositionAddVideo, let compositionAddAudio = compositionAddAudio, let compositionAddAudioOfVideo = compositionAddAudioOfVideo{
            mutableCompositionVideoTrack.append(compositionAddVideo)
            mutableCompositionAudioTrack.append(compositionAddAudio)
            mutableCompositionAudioOfVideoTrack.append(compositionAddAudioOfVideo)
        }


        do {
            try mutableCompositionVideoTrack[0].insertTimeRange(CMTimeRangeMake(start: .zero,
                                                                                duration: aVideoAssetTrack.timeRange.duration),
                                                                of: aVideoAssetTrack,
                                                                at: .zero)
            mutableCompositionVideoTrack[0].preferredVolume = volumeLabel

            //In my case my audio file is longer then video file so i took videoAsset duration
            //instead of audioAsset duration
            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(start: .zero,
                                                                                duration: aVideoAssetTrack.timeRange.duration),
                                                                of: aAudioAssetTrack,
                                                                at: .zero)
            mutableCompositionAudioTrack[0].preferredVolume = microphoneLabel

            // adding audio (of the video if exists) asset to the final composition
            if let aAudioOfVideoAssetTrack = aAudioOfVideoAssetTrack {
                try mutableCompositionAudioOfVideoTrack[0].insertTimeRange(CMTimeRangeMake(start: .zero,
                                                                                           duration: aVideoAssetTrack.timeRange.duration),
                                                                           of: aAudioOfVideoAssetTrack,
                                                                           at: .zero)
            }
        } catch {
            print(error.localizedDescription)
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, h:mm:ss a"
        let dateString = dateFormatter.string(from: Date())
        let videoName = "Commentary_\(dateString).mp4"
        
        guard let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else { return }
        let savePathUrl = URL(fileURLWithPath: documentsPath).appendingPathComponent(videoName)
        
        do { // delete old video
            try FileManager.default.removeItem(at: savePathUrl as URL)
        } catch {
            print(error.localizedDescription)
        }
        
        // Exporting
//        let savePathUrl: URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/newVideo.mp4")
//        do { // delete old video
//            try FileManager.default.removeItem(at: savePathUrl)
//        } catch { print(error.localizedDescription) }

        let assetExport: AVAssetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)!
        assetExport.outputFileType = .mp4
        assetExport.outputURL = savePathUrl
        assetExport.shouldOptimizeForNetworkUse = true

        assetExport.exportAsynchronously { () -> Void in
            switch assetExport.status {
            case AVAssetExportSession.Status.completed:
                print("success")
                completion(nil, savePathUrl)
            case AVAssetExportSession.Status.failed:
                print("failed \(assetExport.error?.localizedDescription ?? "error nil")")
                completion(assetExport.error, nil)
            case AVAssetExportSession.Status.cancelled:
                print("cancelled \(assetExport.error?.localizedDescription ?? "error nil")")
                completion(assetExport.error, nil)
            default:
                print("complete")
                completion(assetExport.error, nil)
            }
        }

    }
    
    // ========================================================================

    func exportVideo(sourceURL: URL, startTime: CMTime?=nil, endTime: CMTime?=nil, filterName: String?=nil, speedLabel: Float?=nil, success: @escaping (URL) -> Void) {
        /// Asset
        let asset = AVPlayerItem(url: sourceURL).asset
        // Composition Audio Video
        let mixComposition = AVMutableComposition()
        
        //TotalTimeRange
        let timeRange1 = CMTimeRangeMake(start: CMTime.zero, duration: asset.duration)
        
        /// Video Tracks
        let videoTracks = asset.tracks(withMediaType: AVMediaType.video)
        if videoTracks.count == 0 {
            /// Can not find any video track
            return
        }
        
        /// Video track
        guard let videoTrack = videoTracks.first else { return }
        
        let compositionVideoTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        /// Audio Tracks
        let audioTracks = asset.tracks(withMediaType: AVMediaType.audio)
        if audioTracks.count > 0 {
            /// Use audio if video contains the audio track
            let compositionAudioTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            
            /// Audio track
            let audioTrack = audioTracks.first!
            do {
                try compositionAudioTrack?.insertTimeRange(timeRange1, of: audioTrack, at: CMTime.zero)
                let destinationTimeRange = CMTimeMultiplyByFloat64(asset.duration, multiplier:(1/Double((speedLabel ?? 1.0))))
                compositionAudioTrack?.scaleTimeRange(timeRange1, toDuration: destinationTimeRange)
                
                compositionAudioTrack?.preferredTransform = audioTrack.preferredTransform
                
            } catch _ {
                /// Ignore audio error
            }
        }
        
        do {
            try compositionVideoTrack?.insertTimeRange(timeRange1, of: videoTrack, at: CMTime.zero)
            let destinationTimeRange = CMTimeMultiplyByFloat64(asset.duration, multiplier:(1/Double((speedLabel ?? 1.0))))
            compositionVideoTrack?.scaleTimeRange(timeRange1, toDuration: destinationTimeRange)
            
            /// Keep original transformation
            compositionVideoTrack?.preferredTransform = videoTrack.preferredTransform
            
            /// Create Directory path for Save
            let fileManager = FileManager.default
            let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            var outputURL = documentDirectory.appendingPathComponent("export")
            do {
                try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
                outputURL = outputURL.appendingPathComponent("\(sourceURL.lastPathComponent)")
            }catch let error {
                print(error)
            }
            
            /// Remove existing file
            self.deleteFile(outputURL)
            
            // trim section ---------------------------------------------------------------------------
            let timeRange = CMTimeRange(start: startTime ?? CMTime.zero, end: endTime ?? asset.duration)
            
            // filter section -------------------------------------------------------------------------
            guard let filter = CIFilter(name: filterName ?? "") else { return }
            /// AVVideoComposition
            let filterComposition = AVVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
                // Clamp to avoid blurring transparent pixels at the image edges
                let source = request.sourceImage.clampedToExtent()
                filter.setValue(source, forKey: kCIInputImageKey)
                // Crop the blurred output to the bounds of the original image
                guard let output = filter.outputImage?.cropped(to: request.sourceImage.extent) else { return }
                // Provide the filter output to the composition
                request.finish(with: output, context: nil)
            })
            
            if let exportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) {
                exportSession.outputURL = outputURL
                exportSession.outputFileType = AVFileType.mp4
                exportSession.shouldOptimizeForNetworkUse = true
                
                exportSession.timeRange = timeRange /// trim video
                exportSession.videoComposition = filterComposition /// filter video

                exportSession.exportAsynchronously {
                    switch exportSession.status {
                    case .completed:
                        print("exported at \(outputURL)")
                        success(outputURL)
                    case .failed:
                        print("failed \(exportSession.error.debugDescription)")
                    case .cancelled:
                        print("cancelled \(exportSession.error.debugDescription)")
                    default: break
                    }
                }
            }
        }catch {
            print("Inserting time range failed.")
        }
    }
    
    // ========================================================================

    // MARK: - Trim
    
    func trim(sourceURL: URL, startTime: CMTime, endTime: CMTime, completion: @escaping (URL) -> Void) {
        
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let asset = AVAsset(url: sourceURL)
        let length = Float(asset.duration.value) / Float(asset.duration.timescale)
        print("video length: \(length) seconds")
        var outputURL = documentDirectory.appendingPathComponent("trim")
        do {
            try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
            outputURL = outputURL.appendingPathComponent("\(sourceURL.lastPathComponent)")
        }catch let error {
            print(error)
        }
        
        //Remove existing file
        deleteFile(outputURL)
        
        /// trim export section
        let timeRange = CMTimeRange(start: startTime, end: endTime)
        
        if let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) {
            exportSession.outputURL = outputURL
            exportSession.outputFileType = AVFileType.mp4
            exportSession.shouldOptimizeForNetworkUse = true
            
            exportSession.timeRange = timeRange /// trim video
            
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    print("exported at \(outputURL)")
                    completion(outputURL)
                case .failed:
                    print("failed \(exportSession.error.debugDescription)")
                case .cancelled:
                    print("cancelled \(exportSession.error.debugDescription)")
                default: break
                }
            }
        }
    }
    
    // MARK: - filter
    func filter(sourceURL: URL, filterName: String, completion: @escaping (URL) -> Void) {
        
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let asset = AVAsset(url: sourceURL)
        let length = Float(asset.duration.value) / Float(asset.duration.timescale)
        print("video length: \(length) seconds")
        var outputURL = documentDirectory.appendingPathComponent("filter")
        do {
            try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
            outputURL = outputURL.appendingPathComponent("\(sourceURL.lastPathComponent)")
        }catch let error {
            print(error)
        }
        
        //Remove existing file
        deleteFile(outputURL)
        
        /// filter section
        ///
        guard let filter = CIFilter(name: filterName) else { return }
        //AVVideoComposition
        let filterComposition = AVVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
            // Clamp to avoid blurring transparent pixels at the image edges
            let source = request.sourceImage.clampedToExtent()
            filter.setValue(source, forKey: kCIInputImageKey)
            // Crop the blurred output to the bounds of the original image
            guard let output = filter.outputImage?.cropped(to: request.sourceImage.extent) else { return }
            // Provide the filter output to the composition
            request.finish(with: output, context: nil)
        })
        
        
        if let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) {
            exportSession.outputURL = outputURL
            exportSession.outputFileType = AVFileType.mp4
            exportSession.shouldOptimizeForNetworkUse = true
            
            exportSession.videoComposition = filterComposition /// filter video
            
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    print("exported at \(outputURL)")
                    completion(outputURL)
                case .failed:
                    print("failed \(exportSession.error.debugDescription)")
                case .cancelled:
                    print("cancelled \(exportSession.error.debugDescription)")
                default: break
                }
            }
        }
    }
    
    // MARK: - speed
    
    func speed(sourceURL: URL, by scale: Float64, success: @escaping (URL) -> Void) {
        /// Asset
        let asset = AVPlayerItem(url: sourceURL).asset
        // Composition Audio Video
        let mixComposition = AVMutableComposition()
        
        //TotalTimeRange
        let timeRange = CMTimeRangeMake(start: CMTime.zero, duration: asset.duration)
        
        /// Video Tracks
        let videoTracks = asset.tracks(withMediaType: AVMediaType.video)
        if videoTracks.count == 0 {
            /// Can not find any video track
            return
        }
        
        /// Video track
        let videoTrack = videoTracks.first!
        
        let compositionVideoTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        /// Audio Tracks
        let audioTracks = asset.tracks(withMediaType: AVMediaType.audio)
        if audioTracks.count > 0 {
            /// Use audio if video contains the audio track
            let compositionAudioTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            
            /// Audio track
            let audioTrack = audioTracks.first!
            do {
                try compositionAudioTrack?.insertTimeRange(timeRange, of: audioTrack, at: CMTime.zero)
                let destinationTimeRange = CMTimeMultiplyByFloat64(asset.duration, multiplier:(1/scale))
                compositionAudioTrack?.scaleTimeRange(timeRange, toDuration: destinationTimeRange)
                
                compositionAudioTrack?.preferredTransform = audioTrack.preferredTransform
                
            } catch _ {
                /// Ignore audio error
            }
        }
        
        do {
            try compositionVideoTrack?.insertTimeRange(timeRange, of: videoTrack, at: CMTime.zero)
            let destinationTimeRange = CMTimeMultiplyByFloat64(asset.duration, multiplier:(1/scale))
            compositionVideoTrack?.scaleTimeRange(timeRange, toDuration: destinationTimeRange)
            
            /// Keep original transformation
            compositionVideoTrack?.preferredTransform = videoTrack.preferredTransform
            
            //Create Directory path for Save
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            var outputURL = documentDirectory.appendingPathComponent("speed")
            do {
                try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
                outputURL = outputURL.appendingPathComponent("\(sourceURL.lastPathComponent)")
            }catch let error {
                
                print(error.localizedDescription)
            }
            
            //Remove existing file
            self.deleteFile(outputURL)
            
            if let exportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) {
                exportSession.outputURL = outputURL
                exportSession.outputFileType = AVFileType.mp4
                exportSession.shouldOptimizeForNetworkUse = true
                
                exportSession.exportAsynchronously {
                    switch exportSession.status {
                    case .completed:
                        print("exported at \(outputURL)")
                        success(outputURL)
                    case .failed:
                        print("failed \(exportSession.error.debugDescription)")
                    case .cancelled:
                        print("cancelled \(exportSession.error.debugDescription)")
                    default: break
                    }
                }
            }
        }catch {
            print("Inserting time range failed.")
        }
    }
    
    
    // =============
    func volume(sourceURL: URL, volumeLabel: Float, success: @escaping (URL) -> Void) {
        
        let mixComposition: AVMutableComposition = AVMutableComposition()
        
        var mutableCompositionVideoTrack: [AVMutableCompositionTrack] = []
        var mutableCompositionAudioTrack: [AVMutableCompositionTrack] = []
        var mutableCompositionAudioOfVideoTrack: [AVMutableCompositionTrack] = []
        let totalVideoCompositionInstruction: AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        
        let aVideoAsset: AVAsset = AVAsset(url: sourceURL)
        
        mutableCompositionVideoTrack.append(mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)!)
        mutableCompositionAudioTrack.append(mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)!)
        mutableCompositionAudioOfVideoTrack.append(mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)!)
        
        let aAudioOfVideoTrack: AVAssetTrack = aVideoAsset.tracks(withMediaType: AVMediaType.audio)[0]
        let aVideoAssetTrack: AVAssetTrack = aVideoAsset.tracks(withMediaType: AVMediaType.video)[0]
        
        do {
            try mutableCompositionAudioOfVideoTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration), of: aAudioOfVideoTrack, at: CMTime.zero)
            try mutableCompositionVideoTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration), of: aVideoAssetTrack, at: CMTime.zero)
        } catch {
            
        }
        
        //TODO: how to set audio track volume
        let audioMix: AVMutableAudioMix = AVMutableAudioMix()
        var audioMixParam: [AVMutableAudioMixInputParameters] = []
        
        let assetAudioFromVideo: AVAssetTrack = aVideoAsset.tracks(withMediaType: AVMediaType.audio)[0]
        
        let videoParam: AVMutableAudioMixInputParameters = AVMutableAudioMixInputParameters(track: assetAudioFromVideo)
        videoParam.trackID = aAudioOfVideoTrack.trackID
        
        videoParam.setVolume(volumeLabel, at: CMTime.zero)
        audioMixParam.append(videoParam)
        audioMix.inputParameters = audioMixParam
        
        
        totalVideoCompositionInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration)
        //        let mutableVideoComposition: AVMutableVideoComposition = AVMutableVideoComposition()
        //        mutableVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        //        mutableVideoComposition.renderSize = CGSize(width: 720, height: 1280)//CGSize(1280,720)
        
        //Create Directory path for Save
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var outputURL = documentDirectory.appendingPathComponent("volume")
        do {
            try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
            outputURL = outputURL.appendingPathComponent("\(sourceURL.lastPathComponent)")
        }catch let error {
            print(error.localizedDescription)
        }
        
        //Remove existing file
        self.deleteFile(outputURL)
        
        if let assetExport: AVAssetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality){
            assetExport.outputFileType = AVFileType.mp4
            assetExport.outputURL = outputURL
            assetExport.shouldOptimizeForNetworkUse = true
            
            assetExport.exportAsynchronously {
                switch assetExport.status {
                case .completed:
                    print("success")
                    success(outputURL)
                case .failed:
                    print("failed \(String(describing: assetExport.error))")
                case .cancelled:
                    print("cancelled \(String(describing: assetExport.error))")
                default:
                    print("complete")
                }
            }
        }
    }
    
}


