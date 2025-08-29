//
//  VideoToAudioViewController.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 21/3/25.
//

import UIKit
import AVKit
import AVFoundation

class VideoToAudioViewController: UIViewController {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let share = DirectoryManager.shared
        
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
    
    var isComeFromeMyRecordVC = false
    
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

    @IBAction func extractButtonAction(_ sender: UIButton){
        self.videoView.invalidate()

        DispatchQueue.main.async{
            showLoader(view: self.view)
        }
        if let url = video?.videoURL {
            if let startTime = trimmerView.startTime, let endTime = trimmerView.endTime {
                
                let trimTimeRange = CMTimeRange(start: startTime, end: endTime)
                EditorManager.shared.extractAudioFromVideo(inputURL: url, range: trimTimeRange) { extractURL in
                    
                    if let extractURL = extractURL {
                        print(extractURL)

                        if let vc = loadVCfromStoryBoard(name: "VideoToAudio", identifier: "ExtractMusicViewController") as? ExtractMusicViewController{
                            
                            let extract = ExtractAudio(context: self.context)
                            let duration = AVAsset(url: extractURL).duration.seconds
                            extract.name = extractURL.deletingPathExtension().lastPathComponent
                            extract.duration = duration
                            extract.creationDate = Date()
                            extract.thumbName = extractURL.deletingPathExtension().lastPathComponent
                            
                            try? self.context.save()
                            
                            DispatchQueue.main.async {
                                self.navigationController?.popViewController(animated: true)
                                dismissLoader()
                            }
                        }
                        
                    }else{
                        print("error")
                    }
                }
            }
        }
        
    }
    
}

extension VideoToAudioViewController: TrimmerViewDelegate {
    
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
        if let player = videoView.player{
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
}

// MARK: ViewController + VideoDelegate
extension VideoToAudioViewController: VideoDelegate {
    
    func videoFinishedFromVideoView() {
        self.playerStatus = .pause
        self.videoView.pause()
        playPauseButton.isHidden = false
    }
    
    
    func videoPlaying() {
        
    }
}

