//
//  PlayerView.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 26/2/25.
//

import Foundation
import AVFoundation
import AVKit
import CoreImage
import CoreImage.CIFilterBuiltins

class VideoTime{
    
    var duration: Float64?
    var startTime: CMTime?
    var endTime: CMTime?
    
    init(startTime: CMTime?, endTime:CMTime?){
        self.startTime = startTime
        self.endTime = endTime
        if let startTime = startTime,let endTime = endTime {
            self.duration = (endTime - startTime).seconds
        }
        
    }
     
}

public protocol PlayerViewDelegate: AnyObject {
    func videoFinished()
    func videoprogress(progress: Double)
}

class CropperRect{
    var superRect: CGRect
    var cropRect: CGRect
    
    init(superRect: CGRect, cropRect:CGRect){
        self.superRect = superRect
        self.cropRect = cropRect
    }
}
class PlayerView: UIView{
    
    var cropScaleComposition: AVVideoComposition?

    var timer = Timer()
    var progress_value = 0.1
    weak var delegate: PlayerViewDelegate?
    
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
            NotificationCenter.default
                .addObserver(self,
                selector: #selector(playerDidFinishPlaying),
                name: .AVPlayerItemDidPlayToEndTime,
                             object: playerLayer.player?.currentItem
            )
        }
    }
    
    @objc func playerDidFinishPlaying(note: NSNotification) {
        print("Video Finished")
        self.player?.seek(to: self.videoTime?.startTime ?? .zero)
        self.delegate?.videoFinished()

    }
    
    var degree: CGFloat = 0 {
        didSet {
            
        }
    }
    
    var dimFrame: CGRect? = nil
    
    var videoRect: CGRect {
        if self.degree == 0 || self.degree == 180 {
            return self.playerLayer.videoRect
        } else if self.degree == 90 || self.degree == 270 {
            return CGRect(x: self.playerLayer.videoRect.origin.y, y: self.playerLayer.videoRect.origin.x, width: self.playerLayer.videoRect.size.height, height: self.playerLayer.videoRect.size.width)
        } else {
            return .zero
        }
    }
        
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    private var playerItemContext = 0

    // Keep the reference and use it to observe the loading status.
    private var playerItem: AVPlayerItem?
    var playerItems = [AVPlayerItem]() // your array of items
    var currentTrack = 0
    var videoTime: VideoTime?
    var cropperRect:CropperRect?
    var cRect:CGRect?
    var videoFilter: VideoFilter?
    
//    {
//        didSet{
//            if let videoFilter{
//                let filter = CIFilter(name: videoFilter.filterName)
//                if let player = self.player{
//                    player.currentItem?.videoComposition = AVMutableVideoComposition(asset: player.currentItem!.asset,  applyingCIFiltersWithHandler: {
//                        (request) in
//                        let source = request.sourceImage.clampedToExtent()
//                        guard let ciFilter = filter else{ return }
//
//                        ciFilter.setValue(source, forKey: kCIInputImageKey)
//                        let output = ciFilter.outputImage!.cropped(to: request.sourceImage.extent)
//                        request.finish(with: output, context: nil)
//                    })
//                }
//
//            }else{
//                if let player = self.player{
//                    player.currentItem?.videoComposition = AVMutableVideoComposition(asset: player.currentItem!.asset,  applyingCIFiltersWithHandler: {
//                        (request) in
//                        let source = request.sourceImage.clampedToExtent()
//                        let output = source.cropped(to: request.sourceImage.extent)
//                        request.finish(with: output, context: nil)
//                    })
//                }
//
//            }
//        }
//    }
    var speed:Float = 1.0
    var volume:Float = 1.0
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    required init(frame: CGRect, speed:Float? = 1.0, delegate: PlayerViewDelegate?){
        self.delegate = delegate
        self.speed = speed ?? 1.0
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        player?.pause();
        playerLayer.removeFromSuperlayer()
        player = nil
        print("deinit of PlayerView")
    }
    
    func playTrack() {

        if playerItems.count > 0 {
            player?.replaceCurrentItem(with: playerItems[currentTrack])
            player?.play()
        }
    }
    
    func filter(_ filter: VideoFilter?){
        guard let item = self.player?.currentItem else { return }
        
        var cRect: CGRect = .zero
        if let cropperRect{
            
            guard let videoTrack = item.asset.tracks(withMediaType: .video).first else {
                print("No video track to crop.")
                //completionHandler(.failure(NSError()))
                return
            }
            // Original video size
            let videoSize = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
            
            let transX = cropperRect.cropRect.origin.x / cropperRect.superRect.width
            let transY = (cropperRect.superRect.height - cropperRect.cropRect.origin.y - (cropperRect.cropRect.height)) / cropperRect.superRect.height
            
            let scalX = cropperRect.cropRect.width / cropperRect.superRect.width
            let scalY = cropperRect.cropRect.height / cropperRect.superRect.height
            
            let x = transX * videoSize.width
            let y = transY * videoSize.height
            
            let width = scalX * videoSize.width
            let height = scalY * videoSize.height
            
            cRect = CGRect(origin: CGPoint(x: abs(x), y: abs(y)), size: CGSize(width: abs(width), height: abs(height)))
        }
        
        let cropScaleComposition = AVMutableVideoComposition(asset: item.asset, applyingCIFiltersWithHandler: {
            request in
            
            var outputImage = request.sourceImage
            
            if cRect != .zero{
                outputImage = outputImage.cropped(to: cRect)
                outputImage = outputImage.correctedExtent
            }
            
            
            if let filter = CIFilter(name: filter?.filterName ?? ""){
                filter.setValue(outputImage, forKey: kCIInputImageKey)
                request.finish(with: filter.outputImage!, context: nil)
            }else{
                request.finish(with: outputImage, context: nil)
            }
            
            
        })
        if cRect != .zero{
            cropScaleComposition.renderSize = cRect.size
        }
        item.videoComposition = cropScaleComposition
        self.cropScaleComposition = cropScaleComposition
        self.videoFilter = filter
        
    }
    func cropVideo(_ cropperRect: CropperRect) {
        
        guard let item = self.player?.currentItem else { return }
        
        guard let videoTrack = item.asset.tracks(withMediaType: .video).first else {
            print("No video track to crop.")
            //completionHandler(.failure(NSError()))
            return
        }
        // Original video size
        let videoSize = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
        
        let transX = cropperRect.cropRect.origin.x / cropperRect.superRect.width
        let transY = (cropperRect.superRect.height - cropperRect.cropRect.origin.y - (cropperRect.cropRect.height)) / cropperRect.superRect.height
        
        let scalX = cropperRect.cropRect.width / cropperRect.superRect.width
        let scalY = cropperRect.cropRect.height / cropperRect.superRect.height
        
        let x = transX * videoSize.width
        let y = transY * videoSize.height
        
        let width = scalX * videoSize.width
        let height = scalY * videoSize.height
        
        let cRect = CGRect(origin: CGPoint(x: abs(x), y: abs(y)), size: CGSize(width: abs(width), height: abs(height)))
        
        // Create transform to rotate video 90 degrees
//            var transform = CGAffineTransform.identity
//            transform = transform.rotated(by: CGFloat(Double.pi / 2))
//            transform = transform.translatedBy(x: videoSize.height, y: 0)
            
        
        let cropScaleComposition = AVMutableVideoComposition(asset: item.asset, applyingCIFiltersWithHandler: {
            request in
            
//            var outputImage = request.sourceImage
//
//
//            outputImage = outputImage.cropped(to: cRect)
//
//
//            outputImage = outputImage.correctedExtent
//
//            let compositionFilter = CIFilter(name: "CIAffineTransform")
//                compositionFilter?.setValue(outputImage, forKey: kCIInputImageKey)
//                compositionFilter?.setValue(NSValue(cgAffineTransform: transform), forKey: kCIInputTransformKey)
//
//            outputImage = (compositionFilter?.outputImage!)!
//
//            if let filter = CIFilter(name: self.videoFilter?.filterName ?? ""){
//                filter.setValue(outputImage, forKey: kCIInputImageKey)
//                request.finish(with: filter.outputImage!, context: nil)
//            }else{
//                request.finish(with: outputImage, context: nil)
//            }
            
            let cropFilter = CIFilter(name: "CICrop")! //1
                cropFilter.setValue(request.sourceImage, forKey: kCIInputImageKey) //2
                cropFilter.setValue(CIVector(cgRect: cRect), forKey: "inputRectangle")
                  
                  
                let imageAtOrigin = cropFilter.outputImage!.transformed(by: CGAffineTransform(translationX: -cRect.origin.x, y: -cRect.origin.y)) //3

                request.finish(with: imageAtOrigin, context: nil)
            
            
        })
        cropScaleComposition.renderSize = cRect.size
        //CGSize(width: cRect.height, height: cRect.width)
        item.videoComposition = cropScaleComposition
        self.cropScaleComposition = cropScaleComposition
        self.cropperRect = cropperRect
        self.cRect = cRect
    }
    
    //MARK : Timer
    func setTimer()  {
        self.progress_value = 0.1
        timer.fire()
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector:#selector(updateProgressValue), userInfo: nil, repeats: true)
    }
    
    @objc func updateProgressValue() {
        DispatchQueue.main.async {
            self.progress_value += 0.05
            if self.progress_value < 0.9 {
                //self.progress_Vw.progress = Float(self.progress_value)
            }else{
                self.timer.invalidate()
            }
        }
    }
    
    private func setUpAsset(with url: URL, completion: ((_ asset: AVAsset) -> Void)?) {
        let asset = AVAsset(url: url)
        
        asset.loadValuesAsynchronously(forKeys: ["playable"]) {
            var error: NSError? = nil
            let status = asset.statusOfValue(forKey: "playable", error: &error)
            debugPrint("error: \(error?.localizedDescription)")
            switch status {
            case .loaded:
                completion?(asset)
            case .failed:
                print(".failed")
            case .cancelled:
                print(".cancelled")
            default:
                print("default")
            }
        }
    }
    
//    private func setUpAssets(with urls: [URL], completion: ((_ assets: [AVAsset]) -> Void)?) {
//
//        var assets = [AVAsset]()
//
//        for (i,url) in urls.enumerated(){
//
//            let asset = AVAsset(url: url)
//
//            asset.loadValuesAsynchronously(forKeys: ["playable"]) {
//                var error: NSError? = nil
//                let status = asset.statusOfValue(forKey: "playable", error: &error)
//                debugPrint("error: \(error?.localizedDescription)")
//                switch status {
//                case .loaded:
//                    assets.append(asset)
//                    completion?(asset)
//                case .failed:
//                    print(".failed")
//                case .cancelled:
//                    print(".cancelled")
//                default:
//                    print("default")
//                }
//            }
//        }
//
//    }
    
    private func setUpPlayerItem(with asset: AVAsset) {
        playerItem = AVPlayerItem(asset: asset)
        playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: &playerItemContext)
        playerItem?.audioTimePitchAlgorithm = .timeDomain
        
        DispatchQueue.main.async { [weak self] in
            self?.player = AVPlayer(playerItem: self?.playerItem!)
            let _ = self?.player?.addProgressObserver { progress in
               //Update slider value
                if let endTime = self?.videoTime?.endTime, let totalDuration = self?.playerItem?.duration.seconds{
                    if progress *  totalDuration >= endTime.seconds{
                        self?.pause()
                        self?.delegate?.videoFinished()
                        return
                    }
                }
                //debugPrint("video progress = \(progress)")
                self?.delegate?.videoprogress(progress: progress)
            }
            
        }
    }
    
    private func setUpNewPlayerItem(with asset: AVAsset) {
        let playerItem = AVPlayerItem(asset: asset)
        self.playerItems.append(playerItem)
        
//        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: &playerItemContext)
//
//        DispatchQueue.main.async { [weak self] in
//            self?.player = AVPlayer(playerItem: self?.playerItem!)
//            self?.player?.addProgressObserver { progress in
//               //Update slider value
//                self?.delegate?.videoprogress(progress: progress)
//            }
//
//        }
    }
        
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        // Only handle observations for the playerItemContext
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
            
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItem.Status
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            // Switch over status value
            switch status {
            case .readyToPlay:
                print(".readyToPlay")
                //player?.play()
            case .failed:
                print(".failed")
            case .unknown:
                print(".unknown")
            @unknown default:
                print("@unknown default")
            }
        }
    }
    
    func play(){
        player?.play()
        player?.rate = self.speed
    }
    func pause(){
        player?.pause()
    }
    
    func load(with url: URL, completion:  ((_ videoTime: VideoTime, _ asset: AVAsset) -> Void)?) {
    //((_ duration: Float64, _ asset: AVAsset) -> Void)?) {
        setUpAsset(with: url) { [weak self] (asset: AVAsset) in
            self?.setUpPlayerItem(with: asset)
            let duration = asset.duration
            let videoTime = VideoTime(startTime: .zero, endTime: duration)
            self?.videoTime = videoTime
            completion?(videoTime, asset)
        }
    }
    
//    func load(with urls: [URL], completion: (([URL:Float64]) -> Void)?) {
//
//        var dict:[URL:Float64] = [:]
//
//        for url in urls {
//            setUpAsset(with: url) { [weak self] (asset: AVAsset) in
//                self?.setUpNewPlayerItem(with: asset)
//                let duration = asset.duration
//                let durationTime = CMTimeGetSeconds(duration)
//                dict[url] = durationTime
//                if dict.count == urls.count{
//                    completion?(dict)
//                }
//
//
//            }
//        }
//
//        self.playerItems.first?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: &playerItemContext)
//
//        DispatchQueue.main.async { [weak self] in
//            self?.player = AVPlayer(playerItem: self?.playerItems.first)
//            self?.player?.addProgressObserver { progress in
//               //Update slider value
//                self?.delegate?.videoprogress(progress: progress)
//            }
//
//        }
//
//    }
    
    var isSeekInProgress = false
    var chasingTime = CMTime.zero

    func seekActually(time: CMTime) {
        isSeekInProgress = true
        player?.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero) { success in
            if time == self.chasingTime {
                self.isSeekInProgress = false
            } else {
                self.trySeekToChaseTime()
            }
        }
    }

    func trySeekToChaseTime() {
        guard let status = player?.currentItem?.status, status != .readyToPlay else { return }
        seekActually(time: chasingTime)
    }

    func seekSmoothly(to time: CMTime) {
        if chasingTime != time {
            chasingTime = time
            if !isSeekInProgress {
                trySeekToChaseTime()
            }
        }
    }
}


