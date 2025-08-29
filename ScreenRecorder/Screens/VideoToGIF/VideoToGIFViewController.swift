//
//  VideoToGIFViewController.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 21/3/25.
//

import UIKit
import AVKit
import AVFoundation

class VideoToGIFViewController: UIViewController {

    let share = GifManager.shared
    
    @IBOutlet weak var playerContainerView: UIView!{
        didSet{
            self.playerContainerView.backgroundColor = .clear
        }
    }
    
    @IBOutlet weak var playPauseButton: UIButton!{
        didSet{
            playPauseButton.addTarget(self, action: #selector(playButtonAction), for: .touchUpInside)
        }
    }

    @IBOutlet weak var trimmerView: TrimmerView!
    @IBOutlet weak var trimmerDurationLbl: UILabel!
    
    private var generator: AVAssetImageGenerator!
    //var playerView: PlayerView?
    //NEW VIDEO VIEW
    private var videoView: VideoView = {
        let videoView = VideoView(frame: CGRect(x: 0, y: 0, width: 100, height: 100), viewType: .default)
        //videoView.translatesAutoresizingMaskIntoConstraints = false
        return videoView
    }()
    var playerStatus: PlayerStatus = .stop
    var video: Video?
    
    var imageArray: [UIImage] = []
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        trimmerView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadVideo()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadTrimeView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.videoView.invalidate()
    }
    
    @objc @IBAction func playButtonAction(_ sender: UIButton) {
        if self.playerStatus == .stop || self.playerStatus == .pause{
            self.playerStatus = .play
            self.videoView.play()
            playPauseButton.isHidden = true
        }else{
            self.playerStatus = .pause
            self.videoView.pause()
            playPauseButton.isHidden = false
        }
    }
    
    // MARK: - Private Methods -
    
    private func loadVideo() {
        
        if let video{
            guard let url = video.videoURL else { return }

            self.videoView = VideoView(frame: self.playerContainerView.bounds, viewType: .default)
            self.playerContainerView.addSubview(self.videoView)
            
            self.videoView.delegate = self
            
            self.videoView.url = url
            let asset = AVAsset(url: url)
            let videoTime = VideoTime(startTime: .zero, endTime: asset.duration)
            video.asset = asset
            video.videoTime = videoTime
            video.duration = video.videoTime?.duration
            
            self.videoView.videoTime = videoTime
        }
    }
    
    func loadTrimeView() {
        let currentVideo = self.video
        if let asset = currentVideo?.asset {
            DispatchQueue.main.async {
                
                self.trimmerView.asset = asset
                if let startTime = currentVideo?.videoTime?.startTime, let endTime = currentVideo?.videoTime?.endTime{
                    self.trimmerView.moveLeftHandle(to: startTime)
                    self.trimmerView.moveRightHandle(to: endTime)
                }
                UIView.animate(withDuration: 0.3) {
                    self.view.layoutIfNeeded()
                }
            }
        }
    }
    
    func extractFrames(from videoURL: URL, gifDuration: CMTimeRange) -> [UIImage] {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.requestedTimeToleranceBefore = CMTime.zero
        imageGenerator.requestedTimeToleranceAfter = CMTime.zero
        let durationInSeconds = CMTimeGetSeconds(asset.duration)
        let frameRate = 15.0 // fps
        let frameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
        var frames = [UIImage]()
        var currentTime = gifDuration.start
        
        while currentTime < gifDuration.duration {
            do {
                let imageRef = try imageGenerator.copyCGImage(at: currentTime, actualTime: nil)
                let frame = UIImage(cgImage: imageRef)
                
                if let lowQualityImageData = frame.jpegData(compressionQuality: 0.3) {
                    
                    if let uiImage = UIImage(data: lowQualityImageData) {
                        frames.append(uiImage)
                    }
                    
                }
//                let uiImage = UIImage(cgImage: imageRef)
//                frames.append(uiImage)
            } catch let error as NSError {
                print("Error extracting frame: \(error.localizedDescription)")
            }
            currentTime = CMTimeAdd(currentTime, frameDuration)
        }
        return frames
    }
    
    // MARK: - Button Action -
    
    @IBAction func backButtonAction(_ sender: UIButton){
        self.dismiss(animated: true)
        self.navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func shareButtonAction(_ sender: UIButton){
        
        if let video = video {
            
            
            if let startTime = trimmerView.startTime, let endTime = trimmerView.endTime {
                let duration = (endTime-startTime).seconds
                
                if Int(duration) <= 10000 {
                    
                    guard let startTime = trimmerView.startTime, let endTime = trimmerView.endTime else { return }
                    
                    guard let videoURL = video.videoURL else { return }
                    
                    DispatchQueue.main.async{
                        showLoader(view: self.view)
                    }
                   
                    let duration = CMTimeRange(start: startTime, duration: endTime)
                    let imageArr = self.extractFrames(from: videoURL, gifDuration: duration)
                    
                    DispatchQueue.main.async {
                        if let vc = loadVCfromStoryBoard(name: "Share", identifier: "ShareViewController") as? ShareVC{
                            vc.isComeFromVideoToGifVC = true
                            vc.imageArray = imageArr
                            vc.modalPresentationStyle = .fullScreen
                            self.present(vc, animated: true)
                        }
                        
                    }
                    dismissLoader()
                        
                    /*
                     self.share.createGif(imageArr) { gifURL in
                     print(gifURL)
                     
                     DispatchQueue.main.async {
                     if let vc = loadVCfromStoryBoard(name: "Share", identifier: "ShareViewController") as? ShareViewController{
                     vc.isComeFromVideoToGifVC = true
                     vc.imageArray = imageArr
                     vc.exportGifURL = gifURL
                     vc.modalPresentationStyle = .fullScreen
                     self.present(vc, animated: true)
                     }
                     }
                     }
                     */
                    
                }else{
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Attention", message: "Gif length should be within 10 seconds.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .default))
                        self.present(alert, animated: true)
                    }
                }
            }
        }
        
    }
    
}

extension VideoToGIFViewController: TrimmerViewDelegate {
    
    func positionBarStoppedMoving(_ playerTime: CMTime) {
        if let player = videoView.player{
            player.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            videoView.videoTime = VideoTime(startTime: trimmerView.startTime, endTime: trimmerView.endTime)
            //startPlaybackTimeChecker()
            let duration = (trimmerView.endTime! - trimmerView.startTime!).seconds
            let partsDuration = Int(duration)
            let durationString = partsDuration.secondsToHoursMinutesSecondsInString()
            trimmerDurationLbl.text = "\(durationString)s"
        }
    }
    
    func didChangePositionBar(_ playerTime: CMTime) {
        if let player = videoView.player {
            //stopPlaybackTimeChecker()
            self.playerStatus = .pause
            player.pause()
            player.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            let duration = (trimmerView.endTime! - trimmerView.startTime!).seconds
            let partsDuration = Int(duration)
            let durationString = partsDuration.secondsToHoursMinutesSecondsInString()
            trimmerDurationLbl.text = "\(durationString)s"
            //print(duration)
        }
    }
}

// MARK: ViewController + VideoDelegate
extension VideoToGIFViewController: VideoDelegate {
    
    func videoFinishedFromVideoView() {
        self.playerStatus = .pause
        self.videoView.pause()
        playPauseButton.isHidden = false
    }
    
    
    func videoPlaying() {
        
    }
}

