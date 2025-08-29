//
//  CommentaryViewController.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 21/3/25.
//


import UIKit
import AVKit
import AVFoundation
import ReplayKit
import Photos

class CommentaryViewController: UIViewController, AVAudioPlayerDelegate {
    let share = GifManager.shared

    let bottomConstant:CGFloat = 194.0
    
    var assetImgGenerate: AVAssetImageGenerator{
        let assetImgGenerate : AVAssetImageGenerator = AVAssetImageGenerator(asset: (self.video?.asset!)!)
        assetImgGenerate.appliesPreferredTrackTransform = true
        return assetImgGenerate
    }

    // MARK: - Outlet sction-

    @IBOutlet weak var topNavBarView: UIView!
    @IBOutlet weak var shareButton: UIButton!{
        didSet{
            shareButton.isEnabled = false
        }
    }
    @IBOutlet weak var recordButtonBg: UIView!
    
    @IBOutlet weak var volumeContainerView: UIView!
    @IBOutlet weak var volumeViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var volumeLabel: UILabel!{
        didSet{
            volumeLabel.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .medium)
            volumeLabel.text = "\(Int((video?.volume ?? 1) * 100))%"
        }
    }
    @IBOutlet weak var volumeSlider: UISlider! {
        didSet {
            guard let video = video else { return }
            volumeSlider.value = video.volume * 100
            volumeSlider.addTarget(self, action: #selector(volumeValueChanged(slider:event:)), for: .valueChanged)
        }
    }
    
    @IBOutlet weak var microphoneContainerView: UIView!
    @IBOutlet weak var microphoneViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var microphoneLabel: UILabel!{
        didSet{
            microphoneLabel.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .medium)
            microphoneLabel.text = "\(Int((AppData.microphone ?? 1) * 100))%"
        }
    }
    @IBOutlet weak var microphoneSlider: UISlider! {
        didSet {
            microphoneSlider.value = AppData.microphone * 100
            microphoneSlider.addTarget(self, action: #selector(microphoneValueChanged(slider:event:)), for: .valueChanged)
        }
    }
    
    var timescalcolor: UIColor {
        return UIColor(white: 1.0, alpha: 0.6)
    }

    let ellipseView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 2, height: 2))
        view.layer.cornerRadius = 10
        return view
    }()
    
    @IBOutlet weak var timeSacleScrollView: UIScrollView!
    @IBOutlet weak var timeSacleContentView: UIView!
    @IBOutlet weak var timeSacleContentViewWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var timeLbl: UILabel!{
        didSet{
            timeLbl.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        }
    }
    
    @IBOutlet weak var timeLblWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var playerContainerView: UIView!{
        didSet{
            self.playerContainerView.backgroundColor = .clear
        }
    }
    @IBOutlet weak var videoSplitView: MusicView!
    
    @IBOutlet weak var playPauseButton: UIButton!{
        didSet{
            playPauseButton.addTarget(self, action: #selector(playButtonAction), for: .touchUpInside)
        }
    }
        
    @IBOutlet weak var buttonBgView: UIVisualEffectView!
    @IBOutlet weak var playButton: UIButton!

    @IBOutlet weak var videoPlayButton: UIButton! {
        didSet {
            videoPlayButton.addTarget(self, action: #selector(playButtonAction), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var recorTimeLabel: UILabel!

    // MARK: - Properties-

    var playerView: PlayerView?
    var playerStatus: PlayerStatus = .stop
    var video: Video?

    var isComeFromCommentaruy: Bool = false

    var recordButton: RecordButton?
    var audioRecorder : AVAudioRecorder?
    var audioPlayer : AVAudioPlayer?
    
    fileprivate var timer: Timer!
    var isRecording : Bool = false
    var isPlaying : Bool = false
    var duration = CGFloat()
    
    var isFirstTimeLoaded = false

    var isStartVoiceRecord: Bool = false
    
    var commentaryOutputUrl: URL?
    
    // MARK: - APP LIFE CYCLE-

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mickSetup(.playback)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let playerView {
            playerView.removeFromSuperview()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        recorTimeLabel.text = "00:00:00"
        
        if isFirstTimeLoaded {
            loadVideo()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !isFirstTimeLoaded{
            loadVideo()
            
            setupUI()
            setupRecordButtonUI()
            micSetup()
            
            GlobalDelegate.shared.rpScreenRecordDelegate = self
            isFirstTimeLoaded = true
            volumeViewBottomConstraint.constant = -bottomConstant
            microphoneViewBottomConstraint.constant = -bottomConstant
        }
    }
    
    deinit{
        debugPrint("deinit of preview vc")
    }
    
    @objc func volumeValueChanged(slider: UISlider, event: UIEvent) {
        debugPrint(slider.value)
        var currentValue = slider.value/100
        currentValue = (round(currentValue * 10) / 10.0)
        
        playerView?.volume = currentValue
        playerView?.player?.volume = currentValue
        
        volumeLabel.text = "\(Int(slider.value))%"
        debugPrint("volume: \(currentValue)")
    }
    
    @objc func microphoneValueChanged(slider: UISlider, event: UIEvent) {
        debugPrint(slider.value)
        var currentValue = slider.value/100
        currentValue = (round(currentValue * 10) / 10.0)
        
        AppData.microphone = currentValue
        audioPlayer?.volume = currentValue
        microphoneLabel.text = "\(Int(slider.value))%"
        debugPrint("volume: \(currentValue)")
    }

    @objc func playButtonAction(_ sender: UIButton) {
        controlVideo()
    }
    
    @objc func updateDuration() {
        print("duration : \(duration)")
        
        if let video {
            guard let url = video.videoURL else { return }
            
            let videoDuration = Int(AVAsset(url: url).duration.seconds)
            if videoDuration == Int(duration) {
                
                if audioRecorder != nil{
                    timer.invalidate()
                    self.stopRecord()
                }
                
            }else{
                if isRecording && !isPlaying {
                    duration += 1
                }else{
                    timer.invalidate()
                }
            }
        }
    }
    
    @objc func updateAudioMeter(_ timer: Timer) {
        if isRecording && !isPlaying {
            duration += 1
        }else{
            timer.invalidate()
        }
        
        if let recorder = self.audioRecorder {
            if recorder.isRecording {
                let hr = Int((recorder.currentTime / 60) / 60)
                let min = Int(recorder.currentTime / 60)
                let sec = Int(recorder.currentTime.truncatingRemainder(dividingBy: 60))
                let totalTimeString = String(format: "%02d:%02d:%02d", hr, min, sec)
                recorTimeLabel.text = totalTimeString
                recorder.updateMeters()
            }
        }
    }
        
    // MARK: - Private Methods -

    func setupUI() {
        buttonBgView.layer.cornerRadius = 10
        buttonBgView.clipsToBounds = true
    }
    
    public func setupRecordButtonUI() {
        recordButton = RecordButton(frame: CGRect(
                                                x: 0,
                                                y: 0,
                                                width: 70,
                                                height: 70))
        recordButton?.delegate = self
        self.recordButtonBg.addSubview(recordButton!)
        view.bringSubviewToFront(volumeContainerView)
        view.bringSubviewToFront(microphoneContainerView)
    }
    
    /// record
    ///
    func micSetup() {
        /// Session
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord)
        try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        /// URL for saving
        if let basePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            let filepatharray = [basePath, "CommentaryVoice.m4a"]
            if let audioURL = NSURL.fileURL(withPathComponents: filepatharray) {
                var settings : [String:Any] = [:]
                settings[AVFormatIDKey] = Int(kAudioFormatMPEG4AAC)
                settings[AVSampleRateKey] = 44_100.0
                settings[AVNumberOfChannelsKey] = 2
                
                audioRecorder = try? AVAudioRecorder(url: audioURL, settings: settings)
                audioRecorder?.prepareToRecord()
            }
        }
    }
    
    func controlVideo() {
        if self.playerStatus == .stop || self.playerStatus == .pause{
            self.playerStatus = .play
            self.videoSplitView.playerStatus = .play
            self.playerView?.play()
            self.playButton.isHidden = true
        }else{
            self.playerStatus = .pause
            self.videoSplitView.playerStatus = .pause
            self.playerView?.pause()
            self.playButton.isHidden = false
        }
    }
    
    var actualRect: CGRect?
    private func loadVideo() {
        
        if let video {
            guard let url = video.videoURL else { return }
            self.playerView = PlayerView(frame: self.playerContainerView.bounds, delegate: self)
            
            if let playerView{
                playerContainerView.addSubview(playerView)
                playerContainerView.bringSubviewToFront(buttonBgView)
                playerView.load(with: url){ (videoTime: VideoTime, asset: AVAsset) in
                    
                    video.duration = videoTime.duration
                    video.videoTime = videoTime
                    video.asset = asset
                    DispatchQueue.main.async {
                        
                        self.videoSplitView.video = video
                        self.videoSplitView.delegate = self
                        self.setProgressText(0)
                        debugPrint("contentsize = \(self.videoSplitView.scrollview.contentSize)")
                        self.timeSacleContentViewWidthConstraint.constant = self.videoSplitView.scrollview.contentSize.width - DEVICE_WIDTH
                        
                        let contentwidth = self.videoSplitView.scrollview.contentSize.width - DEVICE_WIDTH
                        let perSecPixel = contentwidth/(video.duration ?? 1)
                        
                        for i in 0...Int(video.duration ?? 1) {
                            if (i%3 == 0){
                                let lbl = UILabel(frame: CGRect(x: i*Int(perSecPixel), y: 0, width: 70, height: 12))
                                lbl.font = UIFont(name: "CircularStd-Medium", size: 9)
                                lbl.textColor = self.timescalcolor
                                lbl.text =  "\(i)s"
                                self.timeSacleContentView.addSubview(lbl)
                                lbl.center.y = self.timeSacleContentView.center.y
                                
                            }else{
                                let dotview = UIView(frame: CGRect(x: i*Int(perSecPixel), y: 0, width: 2, height: 2))
                                dotview.layer.cornerRadius = 1
                                dotview.backgroundColor = self.timescalcolor
                                self.timeSacleContentView.addSubview(dotview)
                                dotview.center.y = self.timeSacleContentView.center.y
                            }
                        }
                        
                        let img = try? self.assetImgGenerate.copyCGImage(at: .zero, actualTime: nil)
                        if let img = img {
                            let frameImg  = UIImage(cgImage: img)
                            DispatchQueue.main.async(execute: {
                                let actualRect = AVMakeRect(aspectRatio: frameImg.size, insideRect: self.playerContainerView.bounds)
                                
                                debugPrint(actualRect)
                                
                                self.actualRect = self.playerContainerView.convert(actualRect, to: self.view)
                                let point = self.playerContainerView.convert(actualRect.origin, to: self.view)

                                debugPrint(self.actualRect ?? .zero)
                               
                                if let rect = self.actualRect{
                                    //self.cameraView.frame.origin.x = (rect.origin.x)+10
                                    // self.cameraView.frame.origin.y = (rect.origin.y)+10
                                }
                                
                            })
                            
                        }
                        
                    }
                }
            }
        }
    }
    
    private func setProgressText(_ currentTime: Double){
        
        if let video, let duration = video.duration{
            let parts = currentTime.splitIntoParts(decimalPlaces: 1, round: true)
            let firstPartString = parts.leftPart.secondsToHoursMinutesSecondsInString()
            
            let partsDuration = Int(duration)
            let firstPartDurationString = partsDuration.secondsToHoursMinutesSecondsInString()

            //print("\(firstPartString):\(parts.rightPart)/\(firstPartDurationString)")
            DispatchQueue.main.async {
                self.timeLbl.text = "\(firstPartString):\(parts.rightPart)/\(firstPartDurationString)"
                let width = self.timeLbl.textWidth()
                self.timeLblWidthConstraint.constant = width + 20
                self.view.layoutIfNeeded()
            }
        }
    }
    
    private func startVoiceRecord() {
        
        UIView.animate(withDuration: 1.0) { [self] in
            buttonBgView.transform = CGAffineTransform(translationX: buttonBgView.frame.width+30, y: 0)
        }
        
        isStartVoiceRecord = true
        self.playerStatus = .play
        self.videoSplitView.playerStatus = .play
        self.playerView?.play()
        self.playButton.isHidden = true
        
        if let recorder = audioRecorder {
            if recorder.isRecording {
                /// Stop Recording
                recorder.stop()
            } else {
                if self.playerStatus == .stop || self.playerStatus == .pause {
                    self.playerStatus = .play
                    self.videoSplitView.playerStatus = .play
                    self.playerView?.play()
                    self.playButton.isHidden = true
                }
                playerView?.player?.volume = video?.volume ?? 1.0 //AppData.volume
                
                /// Start recording
                self.timer = Timer.scheduledTimer(timeInterval: 0.1,
                                                  target: self,
                                                  selector: #selector(self.updateAudioMeter(_:)),
                                                  userInfo: nil,
                                                  repeats: true)
                duration = 0
                isRecording = true
                
                //self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateDuration), userInfo: nil, repeats: true) /// start  timer
                
                recorder.record()
            }
        }
    }
    
    private func stopRecord() {
        
        if self.playerStatus == .play {
            self.playerStatus = .stop
            self.videoSplitView.playerStatus = .stop
            self.playerView?.pause()
            self.playButton.isHidden = false
        }
        
        UIView.animate(withDuration: 1.0) { [self] in
            buttonBgView.transform = CGAffineTransform(translationX: (view.frame.width-buttonBgView.frame.origin.x), y: 0)
        }
        
        if let recorder = audioRecorder {
            if recorder.isRecording {
                /// Stop Recording
                recorder.stop()
                
                if let audioURL = audioRecorder?.url {
                    /// marge audio video
                    let volume = video?.volume ?? 1.0
                    let micphone = AppData.microphone
                    
                    if let video {
                        guard let url = video.videoURL, let asset = video.asset else { return }
                                                
                        var presetVideoComposition: AVMutableVideoComposition = AVMutableVideoComposition()
                            presetVideoComposition = AVMutableVideoComposition(asset: asset,  applyingCIFiltersWithHandler: {
                                (request) in
                                let source = request.sourceImage.clampedToExtent()
                                let output = source.cropped(to: request.sourceImage.extent)
                                request.finish(with: output, context: nil)
                            })
                        
                            let commentary = CommentaryVideo(videoURL: url, audioURL: audioURL, videoVolume: volume, audioVolume: micphone, videoComposition: presetVideoComposition)
                            
                        
                            self.exportComentar(commentary, videoComposition: presetVideoComposition)
                        
                        /*
                            if let shareVC = ShareViewController.customInit(video: video, videoComposition: presetVideoComposition){
                                shareVC.modalPresentationStyle = .fullScreen
                                shareVC.commentary = commentary
                                shareVC.exportType = .commentary
                                self.navigationController?.present(shareVC, animated: true)
                            }
                        */
                    }
                }
            }
        }
    }
    
    func exportComentar(_ commentaryVideo: CommentaryVideo, videoComposition: AVVideoComposition){
        
        DispatchQueue.main.async{
            showLoader(view: self.view)
        }
        
        let exporter = Exporter()

        exporter.exportComentary(commentaryVideo, progress: { (progress) in
            guard let  progress = progress else { return }
            debugPrint(progress)
            
        }, success: { (url) in
            
            DispatchQueue.main.async{
                dismissLoader()
//                if let vc = loadVCfromStoryBoard(name: "Editor", identifier: "EditorViewController") as? EditorViewController{
//                    let video = Video(url)
//                    vc.video = video
//                    vc.isComeFromFaceCam = true
//                    self.navigationController?.pushViewController(vc, animated: true)
//                }
                
                if let vc = loadVCfromStoryBoard(name: "Editor", identifier: "EditorViewController") as? EditorVC {
                  
                    let video = Video(url)
                    if let img = url.generateThumbnail(){
                        video.videoThumb = img
                    }
                    vc.video = video
                    vc.isComeFromFaceCam = true
                    DispatchQueue.main.async{
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }
            }
        }) { (error) in
            DispatchQueue.main.async {
                dismissLoader()
            }
        }
    }
    
    func cropVideo(_ cropperRect: CropperRect, asset: AVAsset) -> AVVideoComposition?{
        
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            print("No video track to crop.")
            //completionHandler(.failure(NSError()))
            return nil
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
        
        let cropScaleComposition = AVMutableVideoComposition(asset: asset, applyingCIFiltersWithHandler: {
            request in
            
            var outputImage = request.sourceImage
            
            
            outputImage = outputImage.cropped(to: cRect)
            
            
            outputImage = outputImage.correctedExtent
            
            request.finish(with: outputImage, context: nil)
            
            
        })
        cropScaleComposition.renderSize = cRect.size
        return cropScaleComposition
    }
    
    func startPlaying() {
        if let audioURL = audioRecorder?.url {
            audioPlayer = try? AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        }
    }
    
    func stopPlaying() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
    }
    
    private func saveToDocDir(_ outputURL: URL){
        
        guard let containerURL = DirectoryManager.shared.appGroupBaseURL() else{
            return
        }
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(
                at: containerURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            debugPrint("error creating", containerURL, error)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, h:mm:ss a"
        let dateString = dateFormatter.string(from: Date())
        
        let videoName = "Commentary_\(dateString).mp4"
        
        let destination = containerURL.appendingPathComponent(videoName)
        //fileManager.removeFileIfExists(url: destination)
        do {
            debugPrint("Moving", outputURL, "to:", destination)
            try fileManager.moveItem(
                at: outputURL,
                to: destination
            )
            
            self.saveTocoredata(videoName)
            
        } catch {
            debugPrint("ERROR", error)
        }
        
        DispatchQueue.main.async {
            //self.dismiss(animated: true)
        }
    }
    
    private func saveTocoredata(_ videoName:String){
        
        
            let displayName = "Recording_\(AppData.commentaryCount+1)"

            if let video = CoreDataManager.shared.createSavedVideo(displayName: videoName, name: displayName){
                AppData.recordingCount += 1
                
                if let fileName = video.name{
                    if let url = DirectoryManager.shared.appGroupBaseURL()?.appendingPathComponent(fileName){
                        
                        let duration = AVURLAsset(url: url).duration.seconds
                        video.duration = duration
                        video.size = url.fileSizeString
                        
                        if let img = url.generateThumbnail(){
                            let imgFileName = ((fileName as NSString).deletingPathExtension)+".jpg"
                            if let thumbURL = DirectoryManager.shared.appGroupThumbBaseURL()?.appendingPathComponent(imgFileName){
                                do {
                                    try img.jpegData(compressionQuality: 0.6)?.write(to: thumbURL)
                                    video.thumbName = imgFileName
                                    if CoreDataManager.shared.saveContext(){
                                        
                                    }
                                } catch {
                                    debugPrint("img saving failed")
                                }
                                
                            }
                        }
                    }
                }
            }
            
    }
    
    func doneCommentary(margeUrl: URL){
        let refreshAlert = UIAlertController(title: "Commentary", message: "", preferredStyle: UIAlertController.Style.alert)
                
        refreshAlert.addAction(UIAlertAction(title: "Save", style: .default, handler: { (action: UIAlertAction!) in
                    print("save commentary recond")
            
            self.saveToDocDir(margeUrl)
            
        }))
                
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            refreshAlert .dismiss(animated: true, completion: nil)
        }))

        self.present(refreshAlert, animated: true, completion: nil)
    }
    
    func activeEditingStateUI(){
        DispatchQueue.main.async {
            self.topNavBarView.isHidden = true
            self.videoSplitView.isHidden = true
        }
    }
    
    func inactiveEditingStateUI(){
        DispatchQueue.main.async {
            self.topNavBarView.isHidden = false
            self.videoSplitView.isHidden = false
        }
    }
    
    // MARK: - Button-

    @IBAction func backButtonAction(_ sender: UIButton) {
        
        self.dismiss(animated: true)
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func dismissVolumeView() {
        recordButton?.isHidden = false
        self.inactiveEditingStateUI()
        self.volumeViewBottomConstraint.constant = -bottomConstant
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func doneVolume() {
        recordButton?.isHidden = false
        self.inactiveEditingStateUI()
        if let video {
            video.volume = playerView?.volume ?? 1
        }
        self.volumeViewBottomConstraint.constant = -bottomConstant
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func volumeControlButtonAction(_ sender: UIButton) {
        recordButton?.isHidden = true
        if let volume = video?.volume{
            let sliderValue = volume * 100
            volumeSlider.value = sliderValue
            self.activeEditingStateUI()
            volumeViewBottomConstraint.constant = 0
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @IBAction func microControlButtonAction(_ sender: UIButton) {
        recordButton?.isHidden = true
        let mic = AppData.microphone
        let sliderValue = mic * 100
        volumeSlider.value = sliderValue
        self.activeEditingStateUI()
        microphoneViewBottomConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func dismissMicrophoneView() {
        recordButton?.isHidden = false
        self.inactiveEditingStateUI()
        self.microphoneViewBottomConstraint.constant = -bottomConstant
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func doneMicrophone() {
        recordButton?.isHidden = false
        self.inactiveEditingStateUI()
        if let video {
            video.volume = playerView?.volume ?? 1
        }
        self.microphoneViewBottomConstraint.constant = -bottomConstant
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func shareButtonAction(_ sender: UIButton) {
        /*
        if let commentaryOutputUrl = commentaryOutputUrl {
            if let vc = loadVCfromStoryBoard(name: "Editor", identifier: "EditorViewController") as? EditorViewController {
                let video = Video(commentaryOutputUrl)
                vc.video = video
                vc.isComeFromCommentaruy = true
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true)
            }
        }
        */
    }
}

// MARK: - Recording button delegate extension -

extension CommentaryViewController: RecordButtonDelegate {
    func tapButton(isRecording: Bool) {
        if isRecording {
            print("Start recording")
            self.startVoiceRecord()
        } else {
            print("Stop recording")
            self.stopRecord()
        }
    }
}

extension CommentaryViewController: RPScreenRecordDelegate{
    func startRecord() {
        startVoiceRecord()
    }
    
    func userDeniedTheRecordPermission() {
        
    }
}

extension CommentaryViewController: PlayerViewDelegate {
    
    func videoFinished() {
        self.playerStatus = .pause
        self.playerStatus = .stop
        
        if let player = self.playerView?.player, let startTime = self.playerView?.videoTime?.startTime{
            player.seek(to: startTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        }
        stopRecord()
    }
    
    func videoprogress(progress: Double) {
        
        if self.playerStatus == .play{
            let doublevalue = Double( CGFloat(0) * scrollHeight)
            self.videoSplitView.scrollview.contentOffset = CGPoint(x: progress*self.videoSplitView.durationSize+doublevalue, y: self.videoSplitView.scrollview.contentOffset.y)
            
            
            if let video, let duration = video.duration{
                self.setProgressText(progress * duration)
            }
        }
    }
}

extension CommentaryViewController: MusicViewDelegate{
    
    func didChangePositionBarr(_ playerTime: CMTime) {
        if let player = self.playerView?.player{
            self.playerStatus = .pause
            player.pause()
            player.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            
            self.setProgressText(playerTime.seconds)
        }
    }
    
    func positionBarStoppedMovingg(_ playerTime: CMTime){
        if let player = self.playerView?.player {
            player.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            self.setProgressText(playerTime.seconds)
        }
    }
    
    func didChangeScrollPosition(_ offsetX: CGFloat) {
        self.timeSacleScrollView.isScrollEnabled = true
        self.timeSacleScrollView.contentOffset.x = offsetX
        self.timeSacleScrollView.isScrollEnabled = false
    }
}

