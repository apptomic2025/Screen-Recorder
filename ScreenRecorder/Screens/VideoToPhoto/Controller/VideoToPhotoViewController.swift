//
//  VideoToPhotoViewController.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 21/3/25.
//

import UIKit
import AVKit
import AVFoundation

class VideoToPhotoViewController: UIViewController {

    @IBOutlet weak var playPauseButton: UIButton!{
        didSet{
            playPauseButton.addTarget(self, action: #selector(playButtonAction), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var lblTitle: UILabel!{
        didSet{
            self.lblTitle.font = .appFont_CircularStd(type: .bold, size: 20)
            self.lblTitle.textColor = UIColor(hex: "#151517")
        }
    }
    
    @IBOutlet weak var lblTimeDuration: UILabel!{
        didSet{
            self.lblTimeDuration.font = .appFont_CircularStd(type: .medium, size: 14)
        }
    }

    
    //var playerView: PlayerView?
    //NEW VIDEO VIEW
    private var videoView: VideoView = {
        let videoView = VideoView(frame: CGRect(x: 0, y: 0, width: 100, height: 100), viewType: .default)
        //videoView.translatesAutoresizingMaskIntoConstraints = false
        return videoView
    }()
    @IBOutlet weak var playerContainerView: UIView!
    @IBOutlet weak var videoCropView: VideoCropView!
    @IBOutlet weak var selectThumbView: ThumbSelectorView!
    @IBOutlet weak var frameTimeLabel: UILabel!

    var video: Video?
    var playerStatus: PlayerStatus = .stop
    var isPlay = false
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        selectThumbView.delegate = self
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let video = video, let url = video.videoURL {
            let asset = AVAsset(url: url)
            
            selectThumbView.cornerRadiusV = 2
            selectThumbView.thumbBorderColor = UIColor(named: "newBrandColor") ?? .orange
            
            videoCropView.asset = asset
            selectThumbView.asset = asset
            
            videoCropView.isHidden = true
            self.loadVideo()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoCropView.cropMaskView.isHidden = true
        videoCropView.cropMaskView.bringSubviewToFront(playPauseButton)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        controlVideo()
        self.videoView.invalidate()
    }
    
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
    
    var assetImgGenerate: AVAssetImageGenerator{
        let assetImgGenerate : AVAssetImageGenerator = AVAssetImageGenerator(asset: (self.video?.asset!)!)
        assetImgGenerate.appliesPreferredTrackTransform = true
        return assetImgGenerate
    }
    
    private func cropImage(_ time: CMTime){
        
        let img = try? assetImgGenerate.copyCGImage(at: time, actualTime: nil)
        dismissLoader()
        
        if let img = img {
            let croppedImage  = UIImage(cgImage: img)
            
            DispatchQueue.main.async {
                self.goToShareVC(image: croppedImage)
            }
        }
    }
    func goToShareVC(image: UIImage){
        if let vc = loadVCfromStoryBoard(name: "VideoToPhoto", identifier: "PhotoQualityViewController") as? PhotoQualityViewController{
            vc.selectedFrame = image
            DispatchQueue.main.async{
                self.navigationController?.pushViewController(vc, animated: true)
                
                dismissLoader()
            }
        }
    }
    
    func controlVideo() {
        videoCropView.player?.pause()
        playPauseButton.isHidden = false
        isPlay = false
        playerStatus = .play
        self.videoView.player?.pause()
    }
    
    // MARK: - Button Action -
    
    @IBAction func crossButtonAction(_ sender: UIButton){
        self.dismiss(animated: true)
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func shareButtonActionButtonAction(_ sender: UIButton){
        DispatchQueue.main.async{
            showLoader(view: self.view)
        }
        
        controlVideo()
        
        if let selectedTime = selectThumbView.selectedTime, let asset = videoCropView.asset {
            
            self.cropImage(selectedTime)
        }
    }
    
}

extension UIImage {
    func crop(in frame: CGRect) -> UIImage? {
        if let croppedImage = self.cgImage?.cropping(to: frame) {
            return UIImage(cgImage: croppedImage, scale: scale, orientation: imageOrientation)
        }
        return nil
    }
}

extension VideoToPhotoViewController: ThumbSelectorViewDelegate {
    func didChangeThumbPosition(_ imageTime: CMTime) {
        print("current time - \(imageTime.seconds)")
        
        videoCropView.player?.seek(to: imageTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        frameTimeLabel.text = imageTime.toHourMinuteSecond()
        self.videoView.player?.seek(to: imageTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        
    }
}

// MARK: ViewController + VideoDelegate
extension VideoToPhotoViewController: VideoDelegate {
    
    func videoFinishedFromVideoView() {
        self.playerStatus = .pause
        self.videoView.pause()
        playPauseButton.isHidden = false
    }
    
    
    func videoPlaying() {
        
    }
}

