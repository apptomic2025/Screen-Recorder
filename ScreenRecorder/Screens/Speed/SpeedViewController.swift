//
//  SpeedViewController.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 22/3/25.
//

import UIKit
import AVKit
import AVFoundation
import Combine
import PureLayout

class SpeedViewController: UIViewController {

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
    
    @IBOutlet weak var lblTitle: UILabel!{
        didSet{
            self.lblTitle.font = .appFont_CircularStd(type: .bold, size: 20)
            self.lblTitle.textColor = UIColor(hex: "#151517")
        }
    }
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var speedRateLabel: UILabel!{
        didSet{
            self.speedRateLabel.font = .appFont_CircularStd(type: .medium, size: 12)
            self.speedRateLabel.textColor = UIColor(hex: "#151517")
        }
    }
    
    private lazy var slider: Slider = makeSlider()
    private var cancellables = Set<AnyCancellable>()
    var speed: Double = 1.0
    
    //var playerView: PlayerView?
    //NEW VIDEO VIEW
    private var videoView: VideoView = {
        let videoView = VideoView(frame: CGRect(x: 0, y: 0, width: 100, height: 100), viewType: .default)
        //videoView.translatesAutoresizingMaskIntoConstraints = false
        return videoView
    }()
    var playerStatus: PlayerStatus = .stop
    var video: Video?
    
    var isFirstTimeLoaded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        slider.speedDelegate = self
        
        slider.value = speed
        containerView.addSubview(slider)
        setupConstraints()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !isFirstTimeLoaded{
            isFirstTimeLoaded = true
            loadVideo()
        }
        
        self.videoView.pause()
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
    
    func setupConstraints() {
        let inset: CGFloat = 28.0
        slider.autoPinEdge(toSuperviewEdge: .left, withInset: inset)
        slider.autoPinEdge(toSuperviewEdge: .right, withInset: inset)
        slider.autoSetDimension(.height, toSize: 48.0)
        slider.autoAlignAxis(toSuperviewAxis: .horizontal)
    }

    func makeSlider() -> Slider {
        let slider = Slider()
        slider.range = .stepped(values: [0.2, 0.5, 1.0, 2.0, 5.0])
        slider.isContinuous = false
        return slider
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
            self.videoView.player?.pause()
        }
    }
    
    private var videoConverter: VideoConverter?

    fileprivate func gotoShareVC(){
        guard let video = self.video, let asset = video.asset else { return }
        
        var presetVideoComposition: AVMutableVideoComposition = AVMutableVideoComposition()
            presetVideoComposition = AVMutableVideoComposition(asset: asset,  applyingCIFiltersWithHandler: {
                (request) in
                let source = request.sourceImage.clampedToExtent()
                let output = source.cropped(to: request.sourceImage.extent)
                request.finish(with: output, context: nil)
            })
   
        
        let videoComposition: AVVideoComposition = self.videoView.cropScaleComposition ?? presetVideoComposition
        
        if let shareVC = ShareVC.customInit(video: self.video, videoComposition: videoComposition,exportType: .normal){
            shareVC.modalPresentationStyle = .fullScreen
            self.navigationController?.present(shareVC, animated: true)
        }
    }
    
    // MARK: - Button Action -
    
    @IBAction func crossButtonAction(_ sender: UIButton){
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func shareButtonAction(_ sender: UIButton){
        if let video {
            video.speed = videoView.speed ?? 1.0
        }
        self.videoView.invalidate()
        gotoShareVC()
    }
}

extension SpeedViewController: SliderValueDelegate {
    
    func getSpeedValue(_ speed: Double) {
        DispatchQueue.main.async { [self] in
            debugPrint("speed-----\(speed)")
            var currentValue = ((speed * 5)/5) //10
            currentValue = (round(currentValue * 10) / 10.0)
            if currentValue == 0.0{
                currentValue = 0.1
            }
            debugPrint("speed - = \(currentValue)")
            speedRateLabel.text = "\(currentValue)x"

            videoView.speed = Float(currentValue)
            videoView.player?.rate = Float(currentValue)
            
            self.playerStatus = .pause
            self.videoView.pause()
            playPauseButton.isHidden = false
        }
    }
    
    func beginTracking() {
    }
    
    func continueTracking() {
    }
    
    func endTracking() {
    }
}

// MARK: ViewController + VideoDelegate -

extension SpeedViewController: VideoDelegate {
    
    func videoFinishedFromVideoView() {
        self.playerStatus = .pause
        self.videoView.pause()
        playPauseButton.isHidden = false
    }
    
    
    func videoPlaying() {
        
    }
}

