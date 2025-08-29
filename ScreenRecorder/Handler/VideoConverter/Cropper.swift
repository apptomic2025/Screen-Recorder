//
//  Cropper.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 26/2/25.
//


import Foundation
import AVKit
import PhotosUI

class Cropper{
    
    static let shared = Cropper()
    
    private var progressTimer:Timer?
    
    private func resolutionForLocalVideo(asset: AVAsset) -> CGSize? {
        guard let track = asset.tracks(withMediaType: AVMediaType.video).first else { return nil }
        let size = track.naturalSize.applying(track.preferredTransform)
        return CGSize(width: abs(size.width), height: abs(size.height))
    }
    
    func cropVideoWithGivenSizeWithSticker(asset: AVAsset,cropRect: CGRect,superRect:CGRect,overlayImage:CIImage? = nil,speed:Float?,fps:Int?, controller: UIViewController) {
        
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
    
}
// MARK: - CIImage extention

extension CIImage {
    
    var correctedExtent: CIImage {
        let toTransform = CGAffineTransform(translationX: -self.extent.origin.x, y: -self.extent.origin.y)
        return self.transformed(by: toTransform)
    }
    
    func rotate(_ angle: CGFloat) -> CIImage {
        let transform = CGAffineTransform(translationX: extent.midX, y: extent.midY) .rotated(by: angle) .translatedBy(x: -extent.midX, y: -extent.midY)
        return applyingFilter("CIAffineTransform", parameters: [kCIInputTransformKey: transform])
    }
    
    func convertCIToUI() -> UIImage {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(self, from: self.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
}
