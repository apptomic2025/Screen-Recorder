//
//  FaceCamViewController.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 21/3/25.
//


import UIKit
import AVKit
import AVFoundation
import ReplayKit
import Photos

class FaceCamViewController: UIViewController, UIGestureRecognizerDelegate {
    let bottomConstant:CGFloat = 194.0

    var timescalcolor: UIColor {
        return UIColor(white: 1.0, alpha: 0.6)
    }

    let ellipseView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 2, height: 2))
        view.layer.cornerRadius = 10
        return view
    }()
    
    var assetImgGenerate: AVAssetImageGenerator{
        let assetImgGenerate : AVAssetImageGenerator = AVAssetImageGenerator(asset: (self.video?.asset!)!)
        assetImgGenerate.appliesPreferredTrackTransform = true
        return assetImgGenerate
    }
    
    // MARK: - Outlet sction-
    @IBOutlet weak var recordButtonBg: UIView!

    @IBOutlet weak var cameraPositionImage: UIImageView!
    @IBOutlet weak var toggleImageView: UIImageView!

    @IBOutlet weak var topNavBarView: UIView!
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
    
    @IBOutlet weak var cameraView: UIView!
    
    @IBOutlet weak var buttonBgView: UIVisualEffectView!
    @IBOutlet weak var recordingTimeLabel: UILabel!
    
    // MARK: - Properties-

    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCapturePhotoOutput!
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer!
    var input: AVCaptureDeviceInput?
    var captureDevice: AVCaptureDevice?
    
    var positionCount = 1
    var isToggle: Bool = false
    
    var playerView: PlayerView?
    var playerStatus: PlayerStatus = .stop
    var video: Video?

    var recordButton: RecordButton?
    var isVideoPlay: Bool = false
    var screenRecordCoordinator: ScreenRecordCoordinator = ScreenRecordCoordinator(showOverlay: false)
    
    var timer: Timer = Timer()
    var countSecond: Int = 0
    var timerCounting: Bool = false
    
    var isFirstTimeLoaded = false

    // MARK: - APP LIFE CYCLE-

    override func viewDidLoad() {
        super.viewDidLoad()
        
       
        mickSetup(.playback)
        
        GlobalDelegate.shared.rpScreenRecordDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isFirstTimeLoaded {
            loadVideo()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !isFirstTimeLoaded{
            isFirstTimeLoaded = true
            setupRecordButtonUI()
            ReplayFileUtil.createReplaysFolder()
            setupUI()
            loadVideo()
            frontCameraSetUp()
            cameraView.bringSubviewToFront(buttonBgView)
//            if let playerView = playerView {
//                let videoDisplayFrame = playerView.playerLayer.videoRect.origin
//                print("videoDisplayFrame : \(playerView.playerLayer.videoRect)")
//
//
//            }
            volumeViewBottomConstraint.constant = -bottomConstant
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let playerView {
            playerView.removeFromSuperview()
        }
    }
    
    deinit{
        debugPrint("deinit of preview vc")
    }

    @objc func volumeValueChanged(slider: UISlider, event: UIEvent) {
        DispatchQueue.main.async { [self] in
            debugPrint(slider.value)
            var currentValue = slider.value/100
            currentValue = (round(currentValue * 10) / 10.0)
            
            playerView?.volume = currentValue
            playerView?.player?.volume = currentValue
            
            volumeLabel.text = "\(Int(slider.value))%"
            debugPrint("volume: \(currentValue)")
        }
    }
    
    @objc @IBAction func playButtonAction(_ sender: UIButton) {
        controlVideo()
    }
    
    @objc func countTimer() -> Void {
        countSecond = countSecond + 1
        let time = secondsToHoursMinutesSeconds(seconds: countSecond)
        let timeString = makeTimeString(hours: time.0, minutes: time.1, seconds: time.2)
        recordingTimeLabel.text = timeString
    }
    
    // MARK: - Private Methods -
    
    func setupUI() {
        cameraView.cornerRadiusV = 5
        buttonBgView.layer.cornerRadius = 10
        buttonBgView.clipsToBounds = true
    }
    
    private func setupFaceCamPosition() {
        /// get video display frame = playerView.playerLayer.videoRect
        print("videoDisplayFrame : \(playerView?.playerLayer.videoRect)")

        if positionCount == 1 {
            positionCount += 1
            
            if let playerView = playerView {
                let videoDisplayFrame = playerView.playerLayer.videoRect.origin
                DispatchQueue.main.async {
                    
                    UIView.animate(withDuration: 0.3) { [self] in
                        cameraView.frame.origin.x = playerView.frame.size.width-cameraView.frame.origin.x-cameraView.frame.size.width
                        cameraView.frame.origin.y = (videoDisplayFrame.y)+cameraView.frame.size.height
                        self.cameraPositionImage.image = UIImage(named: "position2")
                    }
                }
            }
        } else if positionCount == 2 {
            positionCount += 1
            if let playerView = playerView {
                let videoDisplayFrame = playerView.playerLayer.videoRect.origin
                
                DispatchQueue.main.async {
                    
                    UIView.animate(withDuration: 0.3) { [self] in
                        cameraView.frame.origin.y = playerContainerView.frame.size.height-videoDisplayFrame.y-35 //20
                        self.cameraPositionImage.image = UIImage(named: "position3")
                    }
                }
            }
        } else if positionCount == 3 {
            positionCount += 1
            
            if let playerView = playerView {
                let videoDisplayFrame = playerView.playerLayer.videoRect.origin
                
                DispatchQueue.main.async {
                    
                    UIView.animate(withDuration: 0.3) { [self] in
                        cameraView.frame.origin.x = videoDisplayFrame.x+10
                        self.cameraPositionImage.image = UIImage(named: "position4")
                    }
                }
            }
        }else{
            positionCount = 1
            if let playerView = playerView {
                let videoDisplayFrame = playerView.playerLayer.videoRect.origin
                DispatchQueue.main.async {
                    
                    UIView.animate(withDuration: 0.3) { [self] in
                        cameraView.frame.origin.y = videoDisplayFrame.y+cameraView.frame.size.height
                        self.cameraPositionImage.image = UIImage(named: "position1")
                    }
                }
            }
        }
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
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer.videoGravity = .resizeAspectFill
        cameraPreviewLayer.connection?.videoOrientation = .portrait
        cameraView.layer.addSublayer(cameraPreviewLayer)
        cameraView.isHidden = false
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.cameraPreviewLayer.frame = self.cameraView.bounds
            }
        }
    }
    
    func controlVideo() {
        if self.playerStatus == .stop || self.playerStatus == .pause{
            self.playerStatus = .play
            self.videoSplitView.playerStatus = .play
            self.playerView?.play()
            playPauseButton.isHidden = true
        }else{
            self.playerStatus = .pause
            self.videoSplitView.playerStatus = .pause
            self.playerView?.pause()
            playPauseButton.isHidden = false
        }
    }
    
    var actualRect: CGRect?
    private func loadVideo() {
        
        if let video {
            guard let url = video.videoURL else { return }
            self.playerView = PlayerView(frame: self.playerContainerView.bounds, delegate: self)
            
            if let playerView {
                
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
                        
                        
//                        let videoFrameInSuperview = self.playerContainerView.layer.convert(playerView.playerLayer.frame, from: playerView.playerLayer)
//
//                        let actualRect = AVMakeRect(aspectRatio: playerView.playerLayer.frame.size, insideRect: self.playerContainerView.bounds)
//                        debugPrint(videoFrameInSuperview)
//                        debugPrint(actualRect)
//
//                        let videoPosition = playerView.playerLayer.frame
//                        let x = videoPosition.origin.x
//                        let y = videoPosition.origin.y
                        //
                        
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
                                    self.cameraView.frame.origin.x = (rect.origin.x)+10
                                    self.cameraView.frame.origin.y = (rect.origin.y)+10
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
    
    func toggleButtonAction(){
        if isToggle {
            isToggle = false
            
            cameraView?.layer.addSublayer(cameraPreviewLayer)

            DispatchQueue.main.async {
                self.cameraPreviewLayer.frame = self.cameraView.bounds
            }
            
        }else{
            isToggle = true
            
            DispatchQueue.main.async {
                self.view.layer.replaceSublayer(self.cameraView.layer, with:self.playerContainerView.layer)
            }
            
//            DispatchQueue.main.async {
//                if self.playerView != nil {
//                    self.cameraPreviewLayer.frame = (self.playerView?.playerLayer.videoRect)!
//                }
//            }
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
            
            //self.saveTocoredata(videoName)
            
        } catch {
            debugPrint("ERROR", error)
        }
        
        DispatchQueue.main.async {
            self.dismiss(animated: true)
            
            //self.delegate?.needToExport(destination, cuttingRect: self.videoView.frame, actualRect: self.view.frame)
            
        }
    }
    
//    private func saveTocoredata(_ videoName:String){
//        
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
//    }
    
    // MARK: - RPRecording start or stop section
    
    func startFaceCamRecord() {
        let date = Date()
        let fileName = "Recording_\(date)"
        mickSetup(.playAndRecord)
        
        DispatchQueue.main.asyncAfter(deadline: .now()+2.0){
            self.screenRecordCoordinator.startRecording(withFileName: fileName) { url in
                if let _ = url{

                }
            } onCompletion: { outputURL in
                if let outputURL = outputURL{

                    DispatchQueue.main.async {
                        mickSetup(.playback)
                        let asset = AVAsset(url: outputURL)
                        
                        // self.saveToDocDir(outputURL)
                        /*
                         guard let video = self.video, let asset = video.asset else { return }
                         
                         var presetVideoComposition: AVMutableVideoComposition = AVMutableVideoComposition()
                             presetVideoComposition = AVMutableVideoComposition(asset: asset,  applyingCIFiltersWithHandler: {
                                 (request) in
                                 let source = request.sourceImage.clampedToExtent()
                                 let output = source.cropped(to: request.sourceImage.extent)
                                 request.finish(with: output, context: nil)
                             })
                    
                         
                         let videoComposition: AVVideoComposition = self.playerView?.cropScaleComposition ?? presetVideoComposition
                         
                         if let shareVC = ShareViewController.customInit(video: self.video, videoComposition: videoComposition){
                             shareVC.modalPresentationStyle = .fullScreen
                             shareVC.delegate = self
                             self.navigationController?.present(shareVC, animated: true)
                         }
                         */

                        let duration = asset.duration
                        let videoTime = VideoTime(startTime: .zero, endTime: duration)
                        
                        let video = Video(outputURL)
                        video.asset  = asset
                        video.duration = videoTime.duration
                        video.videoTime = videoTime
                        
                        let cropperRect = CropperRect(superRect: self.view.frame, cropRect: self.actualRect ?? self.playerContainerView.frame)
                        if let presetVideoComposition = self.cropVideo(cropperRect, asset: asset){
                            
                            self.exportFacecam(video, videoComposition: presetVideoComposition)
                            
    //                        if let shareVC = ShareViewController.customInit(video: video, videoComposition: presetVideoComposition){
    //                            shareVC.modalPresentationStyle = .fullScreen
    //                            shareVC.exportType = .facecam
    //                            //shareVC.delegate = self
    //                            self.navigationController?.present(shareVC, animated: true)
    //                        }
                        }
                        
                    }
                }
            }
        }

    }
    
    private func showLimitExceedAlert(){
        DispatchQueue.main.async {
            
            let alertVC = UIAlertController(title: "Free Limit Exceed", message: "We're sorry, but you've reached your free limit. Please upgrade to our premium plan for unlimited facecam reactions.", preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let OKAction = UIAlertAction(title: "Proceed", style: .default) { action in
                presentIAP(self)
            }
            alertVC.addAction(cancelAction)
            alertVC.addAction(OKAction)
            alertVC.preferredAction = OKAction
            
            self.present(alertVC, animated: true)
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
                
                if !AppData.premiumUser {
                    
                    if AppData.faceCamFreeCount <= 5 {
                        
                        AppData.faceCamFreeCount += 1

//                        if let vc = loadVCfromStoryBoard(name: "Editor", identifier: "EditorViewController") as? EditorViewController{
//                            let video = Video(url)
//                            vc.video = video
//                            vc.isComeFromFaceCam = true
//                            self.navigationController?.pushViewController(vc, animated: true)
//                        }
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
//                        if let iapViewController = loadVCfromStoryBoard(name: "IAP", identifier: "IAPViewController") as? IAPViewController{
//                            iapViewController.modalPresentationStyle = .fullScreen
//                            self.present(iapViewController, animated: true, completion: nil)
//                        }
                        
                        if let iapViewController = loadVCfromStoryBoard(name: "IAP", identifier: "IAPController") as? IAPController {
                            iapViewController.modalPresentationStyle = .fullScreen
                            //self.present(iapViewController, animated: true, completion: nil)
                            self.navigationController?.pushViewController(iapViewController, animated: true)
                        }
                    }
                }else{
                    /// is premium user
//                    if let vc = loadVCfromStoryBoard(name: "Editor", identifier: "EditorViewController") as? EditorViewController{
//                        let video = Video(url)
//                        vc.video = video
//                        vc.isComeFromFaceCam = true
//                        self.navigationController?.pushViewController(vc, animated: true)
//                    }
                    
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

        UIView.animate(withDuration: 1.0) { [self] in
            buttonBgView.transform = CGAffineTransform(translationX: -15, y: 0)
        }
        
        if self.playerStatus != .stop || self.playerStatus != .pause{
            self.playerStatus = .pause
            self.videoSplitView.playerStatus = .pause
            self.playerView?.pause()
        }

        self.screenRecordCoordinator.stopRecording()
        
        recordingTimeLabel.text = "00:00:00"
        countSecond = 0
        timerCounting = false
        timer.invalidate()
    }
    
    // MARK: - Button Action-
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true)
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func cameraPostionControlBtnAction(_ sender: UIButton){
        setupFaceCamPosition()
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
    
    @IBAction func volumeButtonAction(_ sender: UIButton) {
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
    
    @IBAction func toggleButtonAction(_ sender: UIButton) {
        // toggleButtonAction()
    }
    
}

// MARK: - Record button action delegate extension-

extension FaceCamViewController: RecordButtonDelegate {
    
    func tapButton(isRecording: Bool) {
        if isRecording {
            print("Start recording")
            UIView.animate(withDuration: 1.0) { [self] in
                playPauseButton.isHidden = true
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

extension FaceCamViewController: RPScreenRecordDelegate {
    
    func startRecord() {
        
        mickSetup(.playAndRecord)
        DispatchQueue.main.async { [self] in
            if self.playerStatus == .stop || self.playerStatus == .pause{
                mickSetup(.playAndRecord)
                self.playerStatus = .play
                self.videoSplitView.playerStatus = .play
                if let player = self.playerView?.player, let startTime = self.playerView?.videoTime?.startTime{
                    player.seek(to: startTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
                }
                self.playerView?.play()
                self.playerView?.player?.volume = AppData.volume
                
                timerCounting = true
                timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(countTimer), userInfo: nil, repeats: true)
            }
        }
    }
    
    func userDeniedTheRecordPermission() {
        
    }
}


// MARK: - Video player view delegate extension-

extension FaceCamViewController: PlayerViewDelegate {
    
    func videoFinished() {
        self.playerStatus = .pause
        self.playerStatus = .stop
        
        if let player = self.playerView?.player, let startTime = self.playerView?.videoTime?.startTime{
            player.seek(to: startTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        }
        
        self.screenRecordCoordinator.stopRecording()
        timerCounting = false
        timer.invalidate()
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

// MARK: - Music view delegate extension -

extension FaceCamViewController: MusicViewDelegate {
    
    func didChangePositionBarr(_ playerTime: CMTime) {
        if let player = self.playerView?.player {
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

/*
 func toggleButtonAction(){
     if isToggle {
         isToggle = false
         
         DispatchQueue.main.async { [self] in
             videoView.frame = cameraView.frame
             cameraView.frame = videoView.frame
             
             videoView.addSubview(avpController.view)
             videoView.bringSubviewToFront(cameraView)
             
             DispatchQueue.global(qos: .userInitiated).async {
                 self.captureSession.startRunning()
                 DispatchQueue.main.async {
                     self.videoPreviewLayer.frame = self.cameraView.bounds
                 }
             }
         }
         
     }else{
         isToggle = true
         
         DispatchQueue.main.async { [self] in
             videoView.frame = cameraView.frame
             cameraView.frame = videoView.frame

             cameraView.addSubview(avpController.view)
             videoView.bringSubviewToFront(cameraView)

             DispatchQueue.global(qos: .userInitiated).async {
                 self.captureSession.startRunning()
                 DispatchQueue.main.async {
                     self.videoPreviewLayer.frame = self.videoView.bounds
                 }
             }
         }
     }
 }
 */




