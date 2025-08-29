//
//  VideoView.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 26/2/25.
//

import UIKit
import AVKit

protocol VideoDelegate: AnyObject {
    func videoPlaying()
    func videoFinishedFromVideoView()
}

class VideoView: UIView {
    private let viewType: VideoViewType

    weak var delegate: VideoDelegate?

    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let playerContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()


    private let playerLayer: AVPlayerLayer = {
        return AVPlayerLayer()
    }()

    var videoRect: CGRect {
        if self.degree == 0 || self.degree == 180 {
            return self.playerLayer.videoRect
        } else if self.degree == 90 || self.degree == 270 {
            return CGRect(x: self.playerLayer.videoRect.origin.y, y: self.playerLayer.videoRect.origin.x, width: self.playerLayer.videoRect.size.height, height: self.playerLayer.videoRect.size.width)
        } else {
            return .zero
        }
    }

    var player: AVPlayer? {
        return self.playerLayer.player
    }

    private var timer: Timer?

    var timeObserver: Any?
    
    var asset: AVAsset? {
        didSet {
            if let asset = self.asset {
                self.playerLayer.player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
                self.playerLayer.frame = self.playerContainerView.bounds

                if self.viewType == .convert {
                    self.startTime = .zero
                    self.endTime = self.player?.currentItem?.asset.duration ?? .zero
                }
                
                //self.addTimeObserver()
            }
        }
    }

    var url: URL? {
        didSet {
            if let url = self.url {
                self.playerLayer.player = AVPlayer(url: url)
                self.playerLayer.frame = self.playerContainerView.bounds
                if let n = self.asset?.tracks(withMediaType: .video).first?.naturalSize{
                    cRect = CGRect(x: 0, y: 0, width: n.width, height: n.height)
                }
                
                if self.viewType == .convert {
                    self.startTime = .zero
                    self.endTime = self.player?.currentItem?.asset.duration ?? .zero

                }
                
                //self.addTimeObserver()
            }
        }
    }

    var isMute: Bool = false {
        didSet {
            self.player?.isMuted = self.isMute
        }
    }

    var isPlaying: Bool {
        guard let player = self.player else { return false }
        return player.rate != 0 && player.error == nil
    }
    
    var videoFilter: VideoFilter?
    var cropScaleComposition: AVVideoComposition?
    
    var cropperRect:CropperRect?
    var cRect:CGRect?
    
    var degree: CGFloat = 0 {
        didSet {
            let dimFrame = self.dimFrame
            self.dimFrame = dimFrame
        }
    }

    var dimFrame: CGRect? = nil
    var rate: Float = 1.0
    var videoTime: VideoTime?{
        didSet{
            if let videoTime{
                self.startTime = videoTime.startTime ?? .zero
                self.endTime = videoTime.endTime ?? .zero
                self.durationTime = (self.endTime - self.startTime)
            }
        }
    }
    var videoComposition: AVVideoComposition?{
        didSet{
            if let videoComposition{
                self.player?.currentItem?.videoComposition = videoComposition
            }
        }
    }
    var speed:Float = 1.0
    var volume:Float = 1.0
    var startTime: CMTime = .zero
    var endTime: CMTime = .zero
    var durationTime: CMTime = .zero
    
    required init(frame: CGRect, viewType: VideoViewType){
        self.viewType = viewType
        super.init(frame: frame)
        
        self.containerView.frame = self.bounds
        self.addSubview(self.containerView)
        
        self.playerContainerView.frame = self.containerView.bounds
        self.containerView.addSubview(self.playerContainerView)
        
        self.playerContainerView.layoutIfNeeded()
        self.playerContainerView.layer.addSublayer(self.playerLayer)
        self.playerLayer.frame = self.playerContainerView.bounds

        DispatchQueue.main.async {
            self.restoreCrop()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /*init(viewType: VideoViewType) {
        self.viewType = viewType
        super.init(frame: .zero)

        self.backgroundColor = .black

        self.addSubview(self.containerView)
        self.addSubview(self.dimView)
        self.addSubview(self.playButton)
        self.containerView.addSubview(self.playerContainerView)

        let heightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 240)
        heightConstraint.priority = UILayoutPriority(rawValue: 950)
        self.addConstraints([
            heightConstraint
        ])

        self.addConstraints([
            NSLayoutConstraint(item: self.containerView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.containerView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.containerView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.containerView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        ])

        self.addConstraints([
            NSLayoutConstraint(item: self.dimView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.dimView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.dimView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.dimView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        ])

        self.addConstraints([
            NSLayoutConstraint(item: self.playButton, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.playButton, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.playButton, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.playButton, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        ])

        self.containerView.addConstraints([
            NSLayoutConstraint(item: self.playerContainerView, attribute: .leading, relatedBy: .equal, toItem: self.containerView, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.playerContainerView, attribute: .trailing, relatedBy: .equal, toItem: self.containerView, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.playerContainerView, attribute: .top, relatedBy: .equal, toItem: self.containerView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.playerContainerView, attribute: .bottom, relatedBy: .equal, toItem: self.containerView, attribute: .bottom, multiplier: 1, constant: 0)
        ])

        self.playerContainerView.layoutIfNeeded()
        self.playerContainerView.layer.addSublayer(self.playerLayer)
        self.playerLayer.frame = self.playerContainerView.bounds

        self.playButton.addTarget(self, action: #selector(self.togglePlay(_:)), for: .touchUpInside)
        DispatchQueue.main.async {
            self.restoreCrop()
        }
    }*/

//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }

    private func addTimeObserver(){
        
        guard let player = self.playerLayer.player else { return }

        if let timeObserver = self.timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        
        timeObserver = self.player?.addProgressObserver { progress in
            self.delegate?.videoPlaying()
            
            if let player = self.player {
                let current = player.currentTime()
                let currentTime = CGFloat(current.value) / CGFloat(current.timescale)
                let endTime = CGFloat(self.endTime.value) / CGFloat(self.endTime.timescale)
                if currentTime >= endTime {
                    self.pause()
                    self.player?.seek(to: self.startTime, completionHandler: { (_) in
                        self.delegate?.videoFinishedFromVideoView()
                        self.delegate?.videoPlaying()
                    })
                }
            }
        }
    }
    private func removeTimeObserver(){
        
        guard let player = self.playerLayer.player else { return }

        if let timeObserver = self.timeObserver {
            player.removeTimeObserver(timeObserver)
        }
    }
    @objc private func togglePlay(_ sender: UIButton) {
        if self.isPlaying {
            self.pause()
        } else {
            self.play()
        }
    }

    @objc private func timerAction(_ sender: Timer) {
        self.delegate?.videoPlaying()
        if let player = self.player {
            let current = player.currentTime()
            let currentTime = CGFloat(current.value) / CGFloat(current.timescale)
            let endTime = CGFloat(self.endTime.value) / CGFloat(self.endTime.timescale)
            if currentTime >= endTime {
                sender.invalidate()
                self.pause()
                self.player?.seek(to: self.startTime, completionHandler: { (_) in
                    self.delegate?.videoPlaying()
                    self.delegate?.videoFinishedFromVideoView()
                })
            }
        }
    }

    func play() {
        //self.addTimeObserver()
        guard let player = self.playerLayer.player else { return }
        player.play()
        player.rate = self.speed
        
        self.timer = Timer.scheduledTimer(timeInterval: 0.03, target: self, selector: #selector(self.timerAction(_:)), userInfo: nil, repeats: true)
        self.delegate?.videoPlaying()
    }

    func pause() {
        guard let player = self.playerLayer.player else { return }
        player.pause()
        self.timer?.invalidate()
        self.timer = nil
        //self.removeTimeObserver()
    }

    func invalidate() {
        //self.removeTimeObserver()
        self.timer?.invalidate()
        self.timer = nil
        guard let player = self.playerLayer.player else { return }
        if self.isPlaying {
            player.pause()
        }
    }

    func restoreCrop() {
        self.dimFrame = nil
    }
}

// MARK: VideoView + VideoViewType
extension VideoView {
    enum VideoViewType {
        case `default`
        case convert
    }
}

extension VideoView{
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
        
       
        let cropScaleComposition = AVMutableVideoComposition(asset: item.asset, applyingCIFiltersWithHandler: {
            request in
         
            var outputImage = request.sourceImage


            outputImage = outputImage.cropped(to: cRect)


            outputImage = outputImage.correctedExtent

            if let filter = CIFilter(name: self.videoFilter?.filterName ?? ""){
                filter.setValue(outputImage, forKey: kCIInputImageKey)
                request.finish(with: filter.outputImage!, context: nil)
            }else{
                request.finish(with: outputImage, context: nil)
            }
            
        })
        cropScaleComposition.renderSize = cRect.size
        item.videoComposition = cropScaleComposition
        self.cropScaleComposition = cropScaleComposition
        self.cropperRect = cropperRect
        self.cRect = cRect
    }
}

// MARK: VideoView + DimView
extension VideoView {
    class DimView: UIView {
        private var path: CGPath?

        init() {
            super.init(frame: .zero)
            self.isUserInteractionEnabled = false
        }

        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }

        func mask(_ path: CGPath, duration: TimeInterval, animated: Bool) {
            self.path = path
            if let mask = self.layer.mask as? CAShapeLayer {
                mask.removeAllAnimations()
                if animated {
                    let animation = CABasicAnimation(keyPath: "path")
                    animation.delegate = self
                    animation.fromValue = mask.path
                    animation.toValue = path
                    animation.byValue = path
                    animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
                    animation.isRemovedOnCompletion = false
                    animation.fillMode = .forwards
                    animation.duration = duration
                    mask.add(animation, forKey: "path")
                } else {
                    mask.path = path
                }
            } else {
                let maskLayer = CAShapeLayer()
                maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
                maskLayer.backgroundColor = UIColor.clear.cgColor
                maskLayer.path = path
                self.layer.mask = maskLayer
            }
        }
    }
}

// MARK: VideoView.DimView + CAAnimationDelegate
extension VideoView.DimView: CAAnimationDelegate {
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard let path = self.path else { return }
        if let mask = self.layer.mask as? CAShapeLayer {
            mask.removeAllAnimations()
            mask.path = path
        }
    }
}

extension AVPlayer {
    func addProgressObserver(action:@escaping ((Double) -> Void)) -> Any {
        return self.addPeriodicTimeObserver(forInterval: CMTime.init(value: 1, timescale: 600), queue: .main, using: { time in
            if let duration = self.currentItem?.duration {
                let duration = CMTimeGetSeconds(duration), time = CMTimeGetSeconds(time)
                let progress = (time/duration)
                action(progress)
            }
        })
    }
}


