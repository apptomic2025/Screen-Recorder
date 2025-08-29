//
//  ReactToYoutubeViewController.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 20/3/25.
//

import UIKit
import AVKit
import AVFoundation
import WebKit

class ReactToYoutubeViewController: UIViewController, WKUIDelegate {

    // MARK: - Outlet sction-
    @IBOutlet weak var initialBlackView: UIView!
    @IBOutlet weak var recordingButtonBgView: UIView!
    @IBOutlet weak var recordButtonBg: UIView!

    @IBOutlet weak var videoReactBgView: UIView!
    
    @IBOutlet weak var youtubePlayerView: YoutubePlayerView!
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var playPauseButton: UIButton!{
        didSet{
            playPauseButton.addTarget(self, action: #selector(playButtonAction), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var recordingTimeLabel: UILabel!
    @IBOutlet weak var buttonBgView: UIVisualEffectView!
    @IBOutlet weak var cameraPositionImage: UIImageView!
    @IBOutlet weak var toggleImageView: UIImageView!
    // MARK: - Properties-

    var isFirstTimeLoaded: Bool = false
    
    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var input: AVCaptureDeviceInput?
    var captureDevice: AVCaptureDevice?
    
    var videoLink: String?
    var videoId: String?
    
    var recordButton: RecordButton?
    var screenRecordCoordinator: ScreenRecordCoordinator = ScreenRecordCoordinator(showOverlay: false)
    
    var timer: Timer = Timer()
    var countSecond: Int = 0
    var timerCounting: Bool = false
        
    var isPlayVideo: Bool = false
    var positionCount = 1
    
    var actualRect: CGRect = CGRect(x: 0, y: 289, width: DEVICE_WIDTH, height: 233)

    // MARK: - APP LIFE CYCLE-

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mickSetup(.playback)
        GlobalDelegate.shared.rpScreenRecordDelegate = self
        
        DispatchQueue.main.async{
            showLoader(view: self.view)
        }
        
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if !isFirstTimeLoaded {
            isFirstTimeLoaded = true
            
            frontCameraSetUp()
            cameraView.cornerRadiusV = 5
            buttonBgView.layer.cornerRadius = 10
            buttonBgView.clipsToBounds = true
            youtubePlayerView.backgroundColor = .black
            
            setupRecordButtonUI()
            
            guard let link = videoLink != nil ? videoLink : videoId else { return }
            loadVideo(path: link)
        }
    }
    
    @objc @IBAction func playButtonAction(_ sender: UIButton) {
        if isPlayVideo {
            isPlayVideo = false
            playPauseButton.isHidden = false
            youtubePlayerView.pause()
        }else{
            isPlayVideo = true
            playPauseButton.isHidden = true
            youtubePlayerView.play()
        }
    }
    
    @objc func countTimer() -> Void {
        countSecond = countSecond + 1
        let time = secondsToHoursMinutesSeconds(seconds: countSecond)
        let timeString = makeTimeString(hours: time.0, minutes: time.1, seconds: time.2)
        recordingTimeLabel.text = timeString
    }
    
    // MARK: - Private Methods -

    public func setupRecordButtonUI() {
        recordButton = RecordButton(frame: CGRect(
                                                x: 0,
                                                y: 0,
                                                width: 70,
                                                height: 70))
        recordButton?.delegate = self
        self.recordButtonBg.addSubview(recordButton!)
    }
    
    func frontCameraSetUp() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        guard let backCamera = getFrontCamera() else { return }
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            stillImageOutput = AVCapturePhotoOutput()
            if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(stillImageOutput)
                setupPreview()
            }
        }
        catch { return }
    }
    
    func getFrontCamera() -> AVCaptureDevice? {
        captureSession.sessionPreset = .high
        return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .front).devices.first
        return nil
    }
    
    func setupPreview() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.connection?.videoOrientation = .portrait
        cameraView.layer.addSublayer(videoPreviewLayer)
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.videoPreviewLayer.frame = self.cameraView.bounds
            }
        }
    }
    
    func getYoutubeId(youtubeUrl: String) -> String? {
        return URLComponents(string: youtubeUrl)?.queryItems?.first(where: { $0.name == "v" })?.value
    }
    
    func loadVideo(path: String) {
        DispatchQueue.main.async { [self] in
            let playerVars: [String: Any] = [
                        "controls": 1,
                        "modestbranding": 1,
                        "playsinline": 1,
                        "rel": 0,
                        "showinfo": 0,
                        "autoplay": 1
                    ]
            
            if videoId != nil {
                youtubePlayerView.loadWithVideoId(path, with: playerVars)
            } else{
                guard let videoID = getYoutubeId(youtubeUrl: path) else { return }
                youtubePlayerView.loadWithVideoId(videoID, with: playerVars)
            }
            youtubePlayerView.delegate = self
    
//            youtubePlayerView.bringSubviewToFront(playPauseButton)
//            youtubePlayerView.bringSubviewToFront(youtubeTitleRemoveView)
//            youtubePlayerView.bringSubviewToFront(youtubeButtonRemoveView)
//            youtubePlayerView.bringSubviewToFront(cameraView)
//            youtubePlayerView.bringSubviewToFront(buttonBgView)
        }
        
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
        
        let videoName = "Recording_\(dateString).mp4"
        
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
            // self.dismiss(animated: true)
            
            //self.delegate?.needToExport(destination, cuttingRect: self.videoView.frame, actualRect: self.view.frame)
            
        }
    }
    
    private func saveTocoredata(_ videoName:String){
        
//        let displayName = "Facecam_\(AppData.faceCamCount+1)"
//
//        if var video = SavedVideo.create(name: videoName, displayName: displayName){
//            AppData.faceCamCount += 1
//            
//            if let fileName = video.name{
//                if let url = DirectoryManager.shared.appGroupBaseURL()?.appendingPathComponent(fileName){
//                    if let img = url.generateThumbnail(){
//                        let imgFileName = ((fileName as NSString).deletingPathExtension)+".jpg"
//                        if let thumbURL = DirectoryManager.shared.appGroupThumbBaseURL()?.appendingPathComponent(imgFileName){
//                            do {
//                                try img.jpegData(compressionQuality: 0.6)?.write(to: thumbURL)
//                                video.thumbName = imgFileName
//                                if CoreDataStack.shared.context.saveContext(){
//                                    
//                                }
//                            } catch {
//                                debugPrint("img saving failed")
//                            }
//                            
//                        }
//                    }
//                }
//            }
//        }
    }
    
    // MARK: - RPRecording start or stop section

    func startFaceCamRecord() {
        
        let date = Date()
        let fileName = "Recording_\(date)"
        self.screenRecordCoordinator.startRecording(withFileName: fileName) { url in
            if let _ = url{

            }
        } onCompletion: { outputURL in
            if let outputURL = outputURL{
                let asset = AVAsset(url: outputURL)
                // self.saveToDocDir(outputURL)

                // Cropper.shared.cropVideoWithGivenSizeWithSticker(asset: asset, cropRect: self.actualRect, superRect: self.view.frame, speed: nil, fps: nil, controller: self)
                
                let duration = asset.duration
                let videoTime = VideoTime(startTime: .zero, endTime: duration)
                
                let video = Video(outputURL)
                video.asset  = asset
                video.duration = videoTime.duration
                video.videoTime = videoTime
                
                DispatchQueue.main.async { [self] in
                    //let cropperRect = CropperRect(superRect: self.view.frame, cropRect: self.actualRect )
                    let cropperRect = CropperRect(superRect: self.view.frame, cropRect: self.videoReactBgView.frame )
                    if let presetVideoComposition = self.cropVideo(cropperRect, asset: asset){
                        
                        self.exportFacecam(video, videoComposition: presetVideoComposition)

                        /*
                        if let shareVC = ShareViewController.customInit(video: video, videoComposition: presetVideoComposition){
                            shareVC.modalPresentationStyle = .fullScreen
                            shareVC.exportType = .facecam
                            // self.navigationController?.present(shareVC, animated: true)
                            self.present(shareVC, animated: true)
                        }
                        */
                    }
                }
            }
        }
    }
    
    func exportFacecam(_ video: Video, videoComposition: AVVideoComposition){
        
        DispatchQueue.main.async{
            showLoader(view: self.view)
        }
        
        let exporter = Exporter(asset: video.asset)

        exporter.exportFacecamVideo(video, presetVideoComposition: videoComposition,progress: { (progress) in
            
            guard let  progress = progress else { return }
            debugPrint(progress)
            
        }, success: { (url) in
           
            DispatchQueue.main.async{
                dismissLoader()
                self.recordingTimeLabel.text = "00:00:00"

                if !AppData.premiumUser {
                    
                    if AppData.faceCamFreeCount <= 5 {

                        AppData.faceCamFreeCount += 1
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
                        
                    }else{

                        if let iapViewController = loadVCfromStoryBoard(name: "IAP", identifier: "IAPVC") as? IAPVC {
                            iapViewController.modalPresentationStyle = .fullScreen
                            //self.present(iapViewController, animated: true, completion: nil)
                            self.navigationController?.pushViewController(iapViewController, animated: true)
                        }
                    }
                }else{

                 
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

                /*
                if let vc = loadVCfromStoryBoard(name: "Editor", identifier: "EditorViewController") as? EditorViewController{
                    let video = Video(url)
                    vc.video = video
                    vc.isComeFromFaceCam = true
                    self.navigationController?.pushViewController(vc, animated: true)
                    self.recordingTimeLabel.text = "00:00:00"
                }
                */
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
    
    private func stopFaceCamRecord() {
        
        youtubePlayerView.stop()
        DispatchQueue.main.async {
            UIView.animate(withDuration: 1.0) { [self] in
                buttonBgView.transform = CGAffineTransform(translationX: -20, y: 0)
            }
        }
        
        self.screenRecordCoordinator.stopRecording()
        timerCounting = false
        timer.invalidate()
    }
        
    private func setupFaceCamPosition() {
        if positionCount == 1 {
            positionCount += 1
            
            let videoDisplayFrame = CGFloat(view.frame.size.width)
            DispatchQueue.main.async {
                
                UIView.animate(withDuration: 0.3) { [self] in
                    cameraView.frame.origin.x = videoReactBgView.frame.size.width-110
                    self.cameraPositionImage.image = UIImage(named: "position2")
                }
            }
        } else if positionCount == 2 {
            positionCount += 1
            DispatchQueue.main.async {
                
                UIView.animate(withDuration: 0.3) { [self] in
                    cameraView.frame.origin.y = videoReactBgView.frame.size.height-110
                    self.cameraPositionImage.image = UIImage(named: "position3")
                }
            }
        } else if positionCount == 3 {
            positionCount += 1
            DispatchQueue.main.async {
                
                UIView.animate(withDuration: 0.3) { [self] in
                    cameraView.frame.origin.x = 10
                    self.cameraPositionImage.image = UIImage(named: "position4")
                }
            }
        }else{
            positionCount = 1
            DispatchQueue.main.async {
                
                UIView.animate(withDuration: 0.3) { [self] in
                    cameraView.frame.origin.y = 10
                    self.cameraPositionImage.image = UIImage(named: "position1")
                }
            }
        }
    }
    
    // MARK: - Button Action-

    @IBAction func backButtonAction(_ sender: UIButton) {
        if isPlayVideo {
            youtubePlayerView.stop()
        }
        self.dismiss(animated: true)
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func cameraPostionControlBtnAction(_ sender: UIButton){
        setupFaceCamPosition()
    }
    
}

// MARK: - Record button action delegate extension-

extension ReactToYoutubeViewController: RecordButtonDelegate {
    func tapButton(isRecording: Bool) {
        
        if isRecording {
            print("Start recording")
            UIView.animate(withDuration: 1.0) { [self] in
                buttonBgView.transform = CGAffineTransform(translationX: 120, y: 0)
            }
            self.startFaceCamRecord()
            
        } else {
            print("Stop recording")
            self.stopFaceCamRecord()
        }
    }
}

// MARK: - RP start screen recording delegate extension-

extension ReactToYoutubeViewController: RPScreenRecordDelegate{
    
    func startRecord() {
        DispatchQueue.main.async { [self] in
            youtubePlayerView.play()
            
            isPlayVideo = true
            timerCounting = true
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(countTimer), userInfo: nil, repeats: true)
        }
    }
    
    func userDeniedTheRecordPermission() {
        
    }
}

// MARK: - Youtube player view delegate extension-

extension ReactToYoutubeViewController: YoutubePlayerViewDelegate {
    func playerViewDidBecomeReady(_ playerView: YoutubePlayerView) {
        print("Ready")
        initialBlackView.isHidden = true
        dismissLoader()
        playerView.pause()
    }

    func playerView(_ playerView: YoutubePlayerView, didChangedToState state: YoutubePlayerState) {
        print("Changed to state: \(state)")
        
        if state.rawValue == "0" {
            print("stop video")
            youtubePlayerView.stop()
        }
    }

    func playerView(_ playerView: YoutubePlayerView, didChangeToQuality quality: YoutubePlaybackQuality) {
        print("Changed to quality: \(quality)")
    }

    func playerView(_ playerView: YoutubePlayerView, receivedError error: Error) {
        print("Error: \(error)")
    }

    func playerView(_ playerView: YoutubePlayerView, didPlayTime time: Float) {
        print("Play time: \(time)")
    }
    
}

