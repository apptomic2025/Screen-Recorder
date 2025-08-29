//
//  MusicView.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 19/3/25.
//

import Foundation
import UIKit
import AVKit

enum PlayerStatus {
    case play,pause,stop
}

public protocol MusicViewDelegate: AnyObject {
    func didChangePositionBarr(_ playerTime: CMTime)
    func positionBarStoppedMovingg(_ playerTime: CMTime)
    func didChangeScrollPosition(_ offsetX: CGFloat)
}

class MusicView: UIView,UIGestureRecognizerDelegate{
    
    // MARK: Constraints

    weak var delegate: MusicViewDelegate?
    
    public var maxDuration: Double = 15
    var middleXposition: CGFloat = 0
    var contentWidth: CGFloat = 0.0
    private var generator: AVAssetImageGenerator?
    
    @IBOutlet weak var middelView: UIView!
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentViewWidthConstraint: NSLayoutConstraint!
    
    
    @IBOutlet weak var scrollview: UIScrollView!{
        didSet{
            self.scrollview.delegate = self
        }
    }
    
    @IBOutlet weak var scrollContentview: UIView!
    
    
    
    var playerStatus: PlayerStatus = .stop{
        didSet{
            
        }
    }
    
    public var video: Video? {
        didSet {
            assetDidChange(newAsset: video?.asset)
        }
    }
    
    /// The asset to be displayed in the underlying scroll view. Setting a new asset will automatically refresh the thumbnails.
//    public var asset: AVAsset? {
//        didSet {
//            assetDidChange(newAsset: asset)
//        }
//    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    /// It is used when you create the view programmatically.
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }

    private func commonInit() {
        /// Loading the nib
        guard let contenttView = self.fromNib() else {
            debugPrint("View could not load from nib")
            return
        }
        
        contenttView.frame = self.bounds
        addSubview(contenttView)
        

        
    }
 

    func assetDidChange(newAsset: AVAsset?) {
        if let asset = newAsset {
            self.regenerateThumbnails(for: asset)
        }
    }
    
    
    internal func regenerateThumbnails(for asset: AVAsset) {
        guard let thumbnailSize = getThumbnailFrameSize(from: asset), thumbnailSize.width != 0 else {
            print("Could not calculate the thumbnail size.")
            return
        }

        generator?.cancelAllCGImageGeneration()
        removeFormerThumbnails()
        let newContentSize = setContentSize(for: asset, size: thumbnailSize)
        let visibleThumbnailsCount = Int(ceil(frame.width / thumbnailSize.width))
        let thumbnailCount = Int(ceil(newContentSize.width / thumbnailSize.width))
        addThumbnailViews(thumbnailCount, size: thumbnailSize)
        let timesForThumbnail = getThumbnailTimes(for: asset, numberOfThumbnails: thumbnailCount)
        generateImages(for: asset, at: timesForThumbnail, with: thumbnailSize, visibleThumnails: visibleThumbnailsCount)
    }
    
    func getThumb(for asset: AVAsset){
        guard let thumbnailSize = getThumbnailFrameSize(from: asset), thumbnailSize.width != 0 else {
            print("Could not calculate the thumbnail size.")
            return
        }
        
        generator?.cancelAllCGImageGeneration()
        let newContentSize = setContentSize(for: asset, size: thumbnailSize)
        let visibleThumbnailsCount = Int(ceil(frame.width / thumbnailSize.width))
        let thumbnailCount = Int(ceil(newContentSize.width / thumbnailSize.width))
        let timesForThumbnail = getThumbnailTimes(for: asset, numberOfThumbnails: thumbnailCount)
        generateImages(for: asset, at: timesForThumbnail, with: thumbnailSize, visibleThumnails: visibleThumbnailsCount)
    }
    
    private func removeFormerThumbnails() {
        contentView.subviews.forEach({ $0.removeFromSuperview() })
    }
    
    private func getThumbnailFrameSize(from asset: AVAsset) -> CGSize? {
        guard let track = asset.tracks(withMediaType: AVMediaType.video).first else { return nil}

        let assetSize = track.naturalSize.applying(track.preferredTransform)

        let height = self.contentView.frame.height
        let ratio = assetSize.width / assetSize.height
        let width = height * ratio
        return CGSize(width: abs(width), height: abs(height))
    }
    
    private func setContentSize(for asset: AVAsset, size: CGSize) -> CGSize {

        let contentWidthFactor = CGFloat(max(1, (self.video?.videoTime?.duration ?? asset.duration.seconds) / maxDuration))
        //+ 1
        contentViewWidthConstraint?.isActive = false
        contentViewWidthConstraint = contentView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: contentWidthFactor)
        contentViewWidthConstraint?.isActive = true
        layoutIfNeeded()
        return contentView.bounds.size
    }
    
    private func addThumbnailViews(_ count: Int, size: CGSize) {

        for index in 0..<count {

            let thumbnailView = UIImageView(frame: CGRect.zero)
            thumbnailView.clipsToBounds = true

            let viewEndX = CGFloat(index) * size.width + size.width

            if viewEndX > contentView.frame.width {
                thumbnailView.frame.size = CGSize(width: size.width + (contentView.frame.width - viewEndX), height: size.height)
                thumbnailView.contentMode = .scaleAspectFill
            } else {
                thumbnailView.frame.size = size
                thumbnailView.contentMode = .scaleAspectFit
            }

            //debugPrint("point = \((CGFloat(index) * size.width) - (size.width/2))")
            //thumbnailView.frame.origin = CGPoint(x: (CGFloat(index) * size.width) - (size.width/2), y: 0)
            thumbnailView.frame.origin.x = (CGFloat(index) * size.width)
            thumbnailView.frame.origin.y = 0
            //debugPrint("index = \(index)")
            thumbnailView.tag = (index == 0) ? 919822 : index
            //thumbnailView.backgroundColor = .red
            contentView.addSubview(thumbnailView)
        }
        
        debugPrint("")
    }
    
    private func getThumbnailTimes(for asset: AVAsset, numberOfThumbnails: Int) -> [NSValue] {
        let timeIncrement = ((video?.videoTime?.duration ?? asset.duration.seconds) * 1000) / Double(numberOfThumbnails)
        var timesForThumbnails = [NSValue]()
        for index in 0..<numberOfThumbnails {
            let cmTime = CMTime(value: Int64((timeIncrement * Float64(index)) + (video?.videoTime?.startTime?.seconds ?? 0)), timescale: 1000)
            let nsValue = NSValue(time: cmTime)
            timesForThumbnails.append(nsValue)
        }
        return timesForThumbnails
    }

    private func generateImages(for asset: AVAsset, at times: [NSValue], with maximumSize: CGSize, visibleThumnails: Int) {
        generator = AVAssetImageGenerator(asset: asset)
        generator?.appliesPreferredTrackTransform = true

        let scaledSize = CGSize(width: maximumSize.width * UIScreen.main.scale, height: maximumSize.height * UIScreen.main.scale)
        generator?.maximumSize = scaledSize
        var count = 0

        let handler: AVAssetImageGeneratorCompletionHandler = { [weak self] (_, cgimage, _, result, error) in
            if let cgimage = cgimage, error == nil && result == AVAssetImageGenerator.Result.succeeded {
                DispatchQueue.main.async(execute: { [weak self] () -> Void in

                    if count == 0 {
                        //self?.displayFirstImage(cgimage, visibleThumbnails: visibleThumnails)
                    }
                    self?.displayImage(cgimage, at: (count == 0) ? 919822 : count)
                    count += 1
                })
            }
        }
        
        generator?.generateCGImagesAsynchronously(forTimes: times, completionHandler: handler)
    }
    
    
    /// The minimum duration allowed for the trimming. The handles won't pan further if the minimum duration is attained.
    public var minDuration: Double = 3

    private var minimumDistanceBetweenHandle: CGFloat {
        guard let asset = video?.asset else { return 0 }
        return CGFloat(minDuration) * scrollContentview.frame.width / CGFloat(video?.videoTime?.duration ?? asset.duration.seconds)
    }

   
    
//    private func generateImagesNew(for asset: AVAsset, at times: [NSValue], with maximumSize: CGSize, visibleThumnails: Int) -> UIImage?{
//        generator = AVAssetImageGenerator(asset: asset)
//        generator?.appliesPreferredTrackTransform = true
//
//        let scaledSize = CGSize(width: maximumSize.width * UIScreen.main.scale, height: maximumSize.height * UIScreen.main.scale)
//        generator?.maximumSize = scaledSize
//        var count = 0
//
//        let handler: AVAssetImageGeneratorCompletionHandler = { [weak self] (_, cgimage, _, result, error) in
//            if let cgimage = cgimage, error == nil && result == AVAssetImageGenerator.Result.succeeded {
//                DispatchQueue.main.async(execute: { [weak self] () -> Void in
//
//                    if count == 0 {
//                        //self?.displayFirstImage(cgimage, visibleThumbnails: visibleThumnails)
//                        let uiimage = UIImage(cgImage: cgimage, scale: 1.0, orientation: UIImage.Orientation.up)
//                        //return uiimage
//                    }
//                    //self?.displayImage(cgimage, at: count)
//                    //count += 1
//                })
//            }
//        }
//
//        generator?.generateCGImagesAsynchronously(forTimes: times, completionHandler: handler)
//    }
//
    private func displayFirstImage(_ cgImage: CGImage, visibleThumbnails: Int) {
        for i in 0...visibleThumbnails {
            displayImage(cgImage, at: i)
        }
    }

    private func displayImage(_ cgImage: CGImage, at index: Int) {
        if let imageView = contentView.viewWithTag(index) as? UIImageView {
            let uiimage = UIImage(cgImage: cgImage, scale: 1.0, orientation: UIImage.Orientation.up)
            imageView.image = uiimage
        }
    }
    
    private func updateSelectedTime(stoppedMoving: Bool) {
        guard let playerTime = positionBarTime else {
            return
        }
        if stoppedMoving {
            delegate?.positionBarStoppedMovingg(playerTime)
        } else {
            delegate?.didChangePositionBarr(playerTime)
        }
    }
    
    var durationSize: CGFloat {
        return contentView.bounds.size.width
    }
    
    
    private var positionBarTime: CMTime? {
        let barPosition = scrollview.contentOffset.x
        //debugPrint("x=\(barPosition)")
        return getTime(from: barPosition)
    }
    
    func getTime(from position: CGFloat) -> CMTime? {
       
        guard let asset = video?.asset else {
            return nil
        }
        
        let playerCurrentTime = (position / durationSize) * (video?.videoTime?.duration ?? asset.duration.seconds)
        //let normalizedRatio = max(min(1, position / durationSize), 0)
        //let positionTimeValue = Double(normalizedRatio) * Double(asset.duration.value)
        let time = CMTimeMakeWithSeconds(playerCurrentTime, preferredTimescale: 1000)
        return time
        //return CMTime(value: Int64(playerCurrentTime), timescale: asset.duration.timescale)
    }

    func getPosition(from time: CMTime) -> CGFloat? {
        guard let asset = video?.asset else {
            return nil
        }
        var duration = asset.duration
        if let endTime = video?.videoTime?.endTime, let startTime = video?.videoTime?.startTime{
            duration = endTime - startTime
        }
        
        let timeRatio = CGFloat(time.value) * CGFloat(duration.timescale) /
            (CGFloat(time.timescale) * CGFloat(duration.value))
        return timeRatio * durationSize
    }
}

extension MusicView: UIScrollViewDelegate{
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if self.playerStatus == .pause || self.playerStatus == .stop{
            updateSelectedTime(stoppedMoving: true)
        }
        
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate && self.playerStatus == .pause || self.playerStatus == .stop{
            updateSelectedTime(stoppedMoving: true)
        }
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        debugPrint(scrollView.contentSize.width)
//        debugPrint(scrollView.contentOffset)
        
        delegate?.didChangeScrollPosition(scrollview.contentOffset.x)
        if (self.playerStatus == .pause || self.playerStatus == .stop){
            updateSelectedTime(stoppedMoving: false)
        }else{
            
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.playerStatus = .pause
    }
}

