//
//  TrimVC.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 6/3/25.
//

import UIKit
import AVKit
import AVFoundation

class TrimVC: UIViewController {

    weak var delegate: ExportDelegate?

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
    
    @IBOutlet weak var trimmerView: TrimmerView!
    @IBOutlet weak var trimmerDurationLbl: UILabel!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!

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
        trimmerView.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !isFirstTimeLoaded{
            isFirstTimeLoaded = true
            
            loadVideo()
            endTimeLabel.text = video?.videoTime?.endTime?.toHourMinuteSecond()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isFirstTimeLoaded {
            loadVideo()
        }
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
            self.playPauseButton.setImage(nil, for: .normal)
        }else{
            self.playerStatus = .pause
            self.videoView.pause()
            let image = UIImage(named: "playPauseNewIcon")
            self.playPauseButton.setImage(image, for: .normal)
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
            //shareVC.delegate = self
            self.navigationController?.present(shareVC, animated: true)
        }
    }
    
    // MARK: - Button Action -
    
    @IBAction func crossButtonAction(_ sender: UIButton){
        self.dismiss(animated: true)
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func shareButtonAction(_ sender: UIButton){
        self.videoView.invalidate()

        self.video?.videoTime = videoView.videoTime
        gotoShareVC()
    }
    
}

extension TrimVC: TrimmerViewDelegate {
    
    func positionBarStoppedMoving(_ playerTime: CMTime) {
        if let player = videoView.player{
            player.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            videoView.videoTime = VideoTime(startTime: trimmerView.startTime, endTime: trimmerView.endTime)
            //startPlaybackTimeChecker()
            let duration = (trimmerView.endTime! - trimmerView.startTime!)//.seconds
            //let partsDuration = Int(duration)
            let durationString = duration.toHourMinuteSecond() //partsDuration.secondsToHoursMinutesSecondsInString()
            trimmerDurationLbl.text = durationString
        }
    }
    
    func didChangePositionBar(_ playerTime: CMTime) {
        if let player = videoView.player {
            //stopPlaybackTimeChecker()
            self.playerStatus = .pause
            player.pause()
            player.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            let duration = (trimmerView.endTime! - trimmerView.startTime!)
            //let partsDuration = Int(duration)
            let durationString = duration.toHourMinuteSecond() //partsDuration.secondsToHoursMinutesSecondsInString()
            trimmerDurationLbl.text = durationString
            
            startTimeLabel.text = trimmerView.startTime?.toHourMinuteSecond()
            endTimeLabel.text = trimmerView.endTime?.toHourMinuteSecond()
        }
    }
    
    func trimmerView(_ trimmer: TrimmerView,
                         didDrag handle: TrimmerView.Handle,
                         x: CGFloat,
                         time: CMTime) {
            // লাইভ আপডেট — UI লেবেল/স্লাইডার ইত্যাদি
            let mmss = String(format: "%02d:%02d", Int(time.seconds) / 60, Int(time.seconds) % 60)
            print("Dragging \(handle)  x=\(x)  time=\(mmss)")
            // e.g. currentTimeLabel.text = mmss
        }

        func trimmerView(_ trimmer: TrimmerView,
                         didEndDragging handle: TrimmerView.Handle,
                         x: CGFloat,
                         time: CMTime) {
            let mmss = String(format: "%02d:%02d", Int(time.seconds) / 60, Int(time.seconds) % 60)
            print("Ended \(handle)  x=\(x)  time=\(mmss)")
            // e.g. player.seek(to: time)
        }
}

extension CMTime {
    func toHourMinuteSecond() -> String {
        let totalSeconds = Int(self.seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = (totalSeconds % 3600) % 60
        //return (hours, minutes, seconds)

        let formattedTime = String(format: "%02d:%02d:%01d", hours, minutes, seconds)
        return formattedTime
    }
}

// MARK: ViewController + VideoDelegate
extension TrimVC: VideoDelegate {
    
    func videoFinishedFromVideoView() {
        self.playerStatus = .pause
        self.videoView.pause()
        playPauseButton.isHidden = false
    }
    
    
    func videoPlaying() {
        
    }
}

