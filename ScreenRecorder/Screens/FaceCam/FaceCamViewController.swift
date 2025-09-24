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

class FaceCamViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var recordButtonBg: UIView!
    @IBOutlet weak var cameraPositionImage: UIImageView!
    @IBOutlet weak var toggleImageView: UIImageView!
    @IBOutlet weak var volumeContainerView: UIView!
    @IBOutlet weak var volumeViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var volumeLabel: UILabel! {
        didSet {
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
    @IBOutlet weak var timeLbl: UILabel! {
        didSet {
            timeLbl.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        }
    }
    @IBOutlet weak var timeLblWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var playerContainerView: UIView! {
        didSet {
            self.playerContainerView.backgroundColor = .clear
        }
    }
    @IBOutlet weak var videoSplitView: MusicView!
    @IBOutlet weak var playPauseButton: UIButton! {
        didSet {
            playPauseButton.addTarget(self, action: #selector(playButtonAction), for: .touchUpInside)
        }
    }
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var buttonBgView: UIVisualEffectView!
    @IBOutlet weak var lblRecordingTime: UILabel!{
            didSet{
                self.lblRecordingTime.font = .appFont_CircularStd(type: .book, size: 20)
                self.lblRecordingTime.textColor = UIColor(hex: "#151517")
            }
    }
    
    @IBOutlet weak var lblFaceCam: UILabel!{
        didSet{
            self.lblFaceCam.font = .appFont_CircularStd(type: .bold, size: 20)
            self.lblFaceCam.textColor = UIColor(hex: "#151517")
        }
    }
    
    @IBOutlet weak var navView: UIView!
    @IBOutlet weak var cnstNavViewHeight: NSLayoutConstraint!
    @IBOutlet weak var tutorialBtnView: UIView!
    @IBOutlet weak var shareBtnView: UIView!{
        didSet{
            self.shareBtnView.isHidden = true
        }
    }
    @IBOutlet weak var editorBtnView: UIView!{
        didSet{
            self.editorBtnView.isHidden = true
        }
    }
    
    @IBOutlet weak var btnGotoShare: UIButton! {
        didSet {
            btnGotoShare.addTarget(self, action: #selector(btnGotoShareAction), for: .touchUpInside)
        }
    }
    @IBOutlet weak var btnGotoEditor: UIButton! {
        didSet {
            btnGotoEditor.addTarget(self, action: #selector(btnGotoEditorAction), for: .touchUpInside)
        }
    }
    
    // MARK: - Constants
    private let bottomConstant: CGFloat = 194.0
    
    // MARK: - UI Properties
    private var timescalcolor: UIColor {
        return UIColor(hex: "#B4B4B4")
    }
    
    private let ellipseView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 2, height: 2))
        view.layer.cornerRadius = 10
        return view
    }()
    
    // MARK: - Camera Properties
    private var captureSession: AVCaptureSession!
    private var stillImageOutput: AVCapturePhotoOutput!
    private var cameraPreviewLayer: AVCaptureVideoPreviewLayer!
    
    // MARK: - State Properties
    private var positionCount = 1
    private var isToggle: Bool = false
    private var playerStatus: PlayerStatus = .stop
    private var isVideoPlay: Bool = false
    private var timer: Timer = Timer()
    private var countSecond: Int = 0
    private var timerCounting: Bool = false
    private var isFirstTimeLoaded = false
    private var actualRect: CGRect?
    private var isRecording = false
    private var faceCamVideoURL: URL?
    
    // MARK: - Data & Coordinator Properties
    var video: Video?
    private var playerView: PlayerView?
    private var recordButtonView: RecordButtonViewNew?
    private var screenRecordCoordinator = ScreenRecordCoordinator(showOverlay: false)

    // MARK: - App Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        micSetup(.playback)
        GlobalDelegate.shared.rpScreenRecordDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isFirstTimeLoaded {
            loadVideo()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !isFirstTimeLoaded {
            isFirstTimeLoaded = true
            setupInitialUI()
            loadVideo()
            setupFrontCamera()
            cameraView.bringSubviewToFront(buttonBgView)
            volumeViewBottomConstraint.constant = -bottomConstant
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        playerView?.removeFromSuperview()
        playerView = nil
    }
    
    deinit {
        debugPrint("deinit of FaceCamViewController")
    }
    
    // MARK: - UI Setup
    private func setupInitialUI() {
        setupRecordButtonUI()
        setupNavHeight()
        ReplayFileUtil.createReplaysFolder()
        cameraView.cornerRadiusV = 5
        buttonBgView.layer.cornerRadius = 10
        buttonBgView.clipsToBounds = true
    }
    private func setupNavHeight(){
        let uiType = getDeviceUIType()
        switch uiType {
        case .dynamicIsland:
            print("Device has Dynamic Island")
            self.cnstNavViewHeight.constant = NavbarHeight.withDynamicIsland.rawValue
        case .notch:
            print("Device has a Notch")
            self.cnstNavViewHeight.constant = NavbarHeight.withNotch.rawValue
        case .noNotch:
            print("Device has no Notch")
            self.cnstNavViewHeight.constant = NavbarHeight.withOutNotch.rawValue
        }
        
    }
    
    private func setupRecordButtonUI() {
        recordButtonView = RecordButtonViewNew(frame: CGRect(x: 0, y: 0, width: 70, height: 70))
        recordButtonView?.delegate = self
        if let recordButton = recordButtonView {
            self.recordButtonBg.addSubview(recordButton)
        }
    }

    private func setProgressText(_ currentTime: Double) {
        guard let video = video, let duration = video.duration else { return }
        
        let parts = currentTime.splitIntoParts(decimalPlaces: 1, round: true)
        let firstPartString = parts.leftPart.secondsToHoursMinutesSecondsInString()
        let partsDuration = Int(duration)
        let firstPartDurationString = partsDuration.secondsToHoursMinutesSecondsInString()

        DispatchQueue.main.async {
            self.timeLbl.text = "\(firstPartString):\(parts.rightPart)/\(firstPartDurationString)"
            let width = self.timeLbl.textWidth()
            self.timeLblWidthConstraint.constant = width + 20
            self.view.layoutIfNeeded()
        }
    }
    
    private func activeEditingStateUI() {
        DispatchQueue.main.async {
            self.videoSplitView.isHidden = true
        }
    }
    
    private func inactiveEditingStateUI() {
        DispatchQueue.main.async {
            self.videoSplitView.isHidden = false
        }
    }
    
    // MARK: - Camera Logic
    private func setupFrontCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
        guard let frontCamera = getFrontCamera() else {
            print("Unable to access front camera.")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: frontCamera)
            stillImageOutput = AVCapturePhotoOutput()
            if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(stillImageOutput)
                setupPreview()
            }
        } catch {
            print("Error setting up camera input: \(error)")
        }
    }
    
    private func getFrontCamera() -> AVCaptureDevice? {
        return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front).devices.first
    }
    
    private func setupPreview() {
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
    
    private func setupFaceCamPosition() {
        guard let playerView = playerView else { return }
        let videoOrigin = playerView.playerLayer.videoRect.origin

        positionCount = (positionCount % 4) + 1 // Cycle through 1, 2, 3, 4

        UIView.animate(withDuration: 0.3) {
            switch self.positionCount {
            case 2: // Top Right
                self.cameraView.frame.origin.x = playerView.frame.size.width - self.cameraView.frame.size.width - videoOrigin.x - 10
                self.cameraView.frame.origin.y = videoOrigin.y + 10
                self.cameraPositionImage.image = UIImage(named: "position2")
            case 3: // Bottom Right
                self.cameraView.frame.origin.y = self.playerContainerView.frame.size.height - self.cameraView.frame.height - videoOrigin.y - 10
                self.cameraPositionImage.image = UIImage(named: "position3")
            case 4: // Bottom Left
                self.cameraView.frame.origin.x = videoOrigin.x + 10
                self.cameraPositionImage.image = UIImage(named: "position4")
            default: // Top Left (case 1)
                self.cameraView.frame.origin.y = videoOrigin.y + 10
                self.cameraPositionImage.image = UIImage(named: "position1")
            }
        }
    }
    
    // MARK: - Video Player Logic
    private func loadVideo() {
        guard let video = video, let url = video.videoURL else { return }
        
        playerView = PlayerView(frame: self.playerContainerView.bounds, delegate: self)
        guard let playerView = playerView else { return }
        playerContainerView.addSubview(playerView)
        playerContainerView.bringSubviewToFront(buttonBgView)
        playerView.load(with: url) { [weak self] (videoTime, asset) in
            guard let self = self else { return }
            video.duration = videoTime.duration
            video.videoTime = videoTime
            video.asset = asset
            
            DispatchQueue.main.async {
                self.videoSplitView.video = video
                self.videoSplitView.delegate = self
                self.setProgressText(0)
                self.setupTimeline(with: video, asset: asset)
                self.updateCameraViewPosition(with: asset)
            }
        }
    }
    
    private func setupTimeline(with video: Video, asset: AVAsset) {
        let contentWidth = self.videoSplitView.scrollview.contentSize.width - UIScreen.main.bounds.width
        self.timeSacleContentViewWidthConstraint.constant = contentWidth
        
        let perSecPixel = contentWidth / (video.duration ?? 1)
        
        for i in 0...Int(video.duration ?? 1) {
            if (i % 3 == 0) {
                let lbl = UILabel(frame: CGRect(x: i * Int(perSecPixel), y: 0, width: 70, height: 12))
                lbl.font = UIFont(name: "CircularStd-Medium", size: 9)
                lbl.textColor = self.timescalcolor
                lbl.text = "\(i)s"
                self.timeSacleContentView.addSubview(lbl)
                lbl.center.y = self.timeSacleContentView.center.y
            } else {
                let dotView = UIView(frame: CGRect(x: i * Int(perSecPixel), y: 0, width: 2, height: 2))
                dotView.layer.cornerRadius = 1
                dotView.backgroundColor = self.timescalcolor
                self.timeSacleContentView.addSubview(dotView)
                dotView.center.y = self.timeSacleContentView.center.y
            }
        }
    }

    private func updateCameraViewPosition(with asset: AVAsset) {
        guard let imageGenerator = createAssetImageGenerator(for: asset) else { return }

        do {
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            let frameImg = UIImage(cgImage: cgImage)
            
            DispatchQueue.main.async {
                let calculatedRect = AVMakeRect(aspectRatio: frameImg.size, insideRect: self.playerContainerView.bounds)
                self.actualRect = self.playerContainerView.convert(calculatedRect, to: self.view)
                
                if let rect = self.actualRect {
                    self.cameraView.frame.origin.x = rect.origin.x + 10
                    self.cameraView.frame.origin.y = rect.origin.y + 10
                }
            }
        } catch {
            debugPrint("Failed to generate CGImage: \(error)")
        }
    }
    
    private func controlVideo() {
        if playerStatus == .stop || playerStatus == .pause {
            playerStatus = .play
            videoSplitView.playerStatus = .play
            playerView?.play()
            playPauseButton.isHidden = true
        } else {
            playerStatus = .pause
            videoSplitView.playerStatus = .pause
            playerView?.pause()
            playPauseButton.isHidden = false
        }
    }
    
    // MARK: - Recording Logic
    private func startFaceCamRecord() {
        let fileName = "Recording_\(Date())"
        isRecording = true
        micSetup(.playAndRecord)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.screenRecordCoordinator.startRecording(withFileName: fileName) { _ in
                // Started handling
            } onCompletion: { [weak self] outputURL in
                guard let self = self, let outputURL = outputURL else { return }
                DispatchQueue.main.async {
                    micSetup(.playback)
                    self.isRecording = false
                    self.faceCamVideoURL = outputURL
                    self.showInitialNav(isShow: false)
                }
            }
        }
    }
    
    private func showInitialNav(isShow: Bool){
        self.tutorialBtnView.isHidden = !isShow
        self.editorBtnView.isHidden = isShow
        self.shareBtnView.isHidden = isShow
    }

    private func stopFaceCamRecord() {
        UIView.animate(withDuration: 0.5) {
            self.buttonBgView.transform = .identity
        }
        
        if playerStatus == .play {
            playerStatus = .pause
            videoSplitView.playerStatus = .pause
            playerView?.pause()
        }

        screenRecordCoordinator.stopRecording()
        
        lblRecordingTime.text = "00:00:00"
        countSecond = 0
        timerCounting = false
        timer.invalidate()
    }
    
    private func handleRecordingCompletion(outputURL: URL,isForEdit: Bool) {
        let asset = AVAsset(url: outputURL)
        let duration = asset.duration
        let videoTime = VideoTime(startTime: .zero, endTime: duration)
        
        let recordedVideo = Video(outputURL)
        recordedVideo.asset = asset
        recordedVideo.duration = videoTime.duration
        recordedVideo.videoTime = videoTime
        
        let cropperRect = CropperRect(
            superRect: self.view.frame,
            cropRect: self.actualRect ?? self.playerContainerView.frame
        )
        
        if let videoComposition = self.cropVideo(cropperRect, asset: asset) {
            if isForEdit{
                self.exportFacecam(recordedVideo, videoComposition: videoComposition)
            }else{
                if let shareVC = ShareVC.customInit(video: recordedVideo, videoComposition: videoComposition,exportType: .facecam){
                    shareVC.modalPresentationStyle = .fullScreen
                    self.navigationController?.present(shareVC, animated: true)
                }
            }
        }
    }

    // MARK: - Video Export & Processing
    private func exportFacecam(_ video: Video, videoComposition: AVVideoComposition) {
        DispatchQueue.main.async {
            showLoader(view: self.view)
        }
        
        let exporter = Exporter(asset: video.asset)
        
        exporter.exportFacecamVideo(video, presetVideoComposition: videoComposition, progress: { progress in
            debugPrint("Export Progress: \(progress ?? 0)")
        }, success: { [weak self] url in
            DispatchQueue.main.async {
                dismissLoader()
                self?.navigateAfterExport(url: url)
            }
        }, failure: { error in
            DispatchQueue.main.async {
                dismissLoader()
                debugPrint("Export failed: \(error)")
            }
        })
    }
    
    private func navigateAfterExport(url: URL) {
        if !AppData.premiumUser && AppData.faceCamFreeCount >= 500 {
            // Show IAP screen
            if let iapVC = loadVCfromStoryBoard(name: "IAP", identifier: "IAPController") as? IAPController {
                iapVC.modalPresentationStyle = .fullScreen
                self.navigationController?.pushViewController(iapVC, animated: true)
            }
            return
        }

        if !AppData.premiumUser {
            AppData.faceCamFreeCount += 1
        }
        
        if let editorVC = loadVCfromStoryBoard(name: "Editor", identifier: "EditorViewController") as? EditorVC {
            let video = Video(url)
            if let thumb = url.generateThumbnail() {
                video.videoThumb = thumb
            }
            editorVC.video = video
            editorVC.isComeFromFaceCam = true
            self.navigationController?.pushViewController(editorVC, animated: true)
        }
    }
    
    private func cropVideo(_ cropperRect: CropperRect, asset: AVAsset) -> AVVideoComposition? {
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            print("No video track to crop.")
            return nil
        }
        
        let videoSize = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
        
        let transX = cropperRect.cropRect.origin.x / cropperRect.superRect.width
        let transY = (cropperRect.superRect.height - cropperRect.cropRect.origin.y - cropperRect.cropRect.height) / cropperRect.superRect.height
        
        let scaleX = cropperRect.cropRect.width / cropperRect.superRect.width
        let scaleY = cropperRect.cropRect.height / cropperRect.superRect.height
        
        let cropRect = CGRect(
            x: abs(transX * videoSize.width),
            y: abs(transY * videoSize.height),
            width: abs(scaleX * videoSize.width),
            height: abs(scaleY * videoSize.height)
        )
        
        let cropScaleComposition = AVMutableVideoComposition(asset: asset) { request in
            var outputImage = request.sourceImage
            outputImage = outputImage.cropped(to: cropRect)
            outputImage = outputImage.correctedExtent
            request.finish(with: outputImage, context: nil)
        }
        
        cropScaleComposition.renderSize = cropRect.size
        return cropScaleComposition
    }

    // MARK: - Helper Methods
    @objc private func countTimer() {
        countSecond += 1
        let time = secondsToHoursMinutesSeconds(seconds: countSecond)
        lblRecordingTime.text = makeTimeString(hours: time.0, minutes: time.1, seconds: time.2)
    }
    
    private func createAssetImageGenerator(for asset: AVAsset) -> AVAssetImageGenerator? {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        return generator
    }
    
    // MARK: - Actions
    @objc private func playButtonAction(_ sender: UIButton) {
        controlVideo()
    }
    
    @objc private func btnGotoShareAction(_ sender: UIButton) {
        guard let faceCamVideoURL = self.faceCamVideoURL else {
            return
        }
        self.handleRecordingCompletion(outputURL: faceCamVideoURL, isForEdit: false)
    }
    
    @objc private func btnGotoEditorAction(_ sender: UIButton) {
        guard let faceCamVideoURL = self.faceCamVideoURL else {
            return
        }
        self.handleRecordingCompletion(outputURL: faceCamVideoURL, isForEdit: true)
    }
    
    @objc private func volumeValueChanged(slider: UISlider, event: UIEvent) {
        DispatchQueue.main.async {
            let normalizedValue = slider.value / 100.0
            let roundedValue = (round(normalizedValue * 10) / 10.0)
            
            self.playerView?.volume = roundedValue
            self.playerView?.player?.volume = roundedValue
            self.volumeLabel.text = "\(Int(slider.value))%"
        }
    }
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true)
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func cameraPostionControlBtnAction(_ sender: UIButton) {
        setupFaceCamPosition()
    }
    
    @IBAction func dismissVolumeView() {
        recordButtonView?.isHidden = false
        self.inactiveEditingStateUI()
        self.volumeViewBottomConstraint.constant = -bottomConstant
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func doneVolume() {
        recordButtonView?.isHidden = false
        inactiveEditingStateUI()
        if let video = video {
            video.volume = playerView?.volume ?? 1
        }
        volumeViewBottomConstraint.constant = -bottomConstant
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func volumeButtonAction(_ sender: UIButton) {
        recordButtonView?.isHidden = true
        if let volume = video?.volume {
            volumeSlider.value = volume * 100
            activeEditingStateUI()
            volumeViewBottomConstraint.constant = 0
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @IBAction func toggleButtonAction(_ sender: UIButton) {
        // This function is currently not implemented.
        toggleButtonAction()
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
        }
    }
}


extension FaceCamViewController: RecordButtonNewDelegate {

    func didStartRecording() {
        print("Start recording")
        UIView.animate(withDuration: 0.5) {
            self.playPauseButton.isHidden = true
            self.buttonBgView.transform = CGAffineTransform(translationX: 120, y: 0)
        }
        self.startFaceCamRecord() // রেকর্ডিং ফাংশন কল করুন
    }

    func didStopRecording() {
        print("Stop recording")
        self.stopFaceCamRecord() 
    }
}

// MARK: - RPScreenRecordDelegate
extension FaceCamViewController: RPScreenRecordDelegate {
    func startRecord() {
        
        mickSetup(.playAndRecord)
        DispatchQueue.main.async { [self] in
            if self.playerStatus == .stop || self.playerStatus == .pause{
                mickSetup(.playAndRecord)
                self.playerStatus = .play
                self.videoSplitView.playerStatus = .play
                if let player = self.playerView?.player, let startTime = self.playerView?.videoTime?.startTime {
                    player.seek(to: startTime, toleranceBefore: .zero, toleranceAfter: .zero)
                }
                self.playerView?.play()
                self.playerView?.player?.volume = AppData.volume
                
                self.timerCounting = true
                self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.countTimer), userInfo: nil, repeats: true)
            }
        }
    }
    
    func userDeniedTheRecordPermission() {
        // Handle permission denial if needed
    }
}

// MARK: - PlayerViewDelegate
extension FaceCamViewController: PlayerViewDelegate {
    func videoFinished() {
        playerStatus = .stop
        if let player = self.playerView?.player, let startTime = self.playerView?.videoTime?.startTime {
            player.seek(to: startTime, toleranceBefore: .zero, toleranceAfter: .zero)
        }
        
        screenRecordCoordinator.stopRecording()
        timerCounting = false
        timer.invalidate()
    }
    
    func videoprogress(progress: Double) {
        if playerStatus == .play {
            self.videoSplitView.scrollview.contentOffset.x = progress * self.videoSplitView.durationSize
            
            if let video = video, let duration = video.duration {
                self.setProgressText(progress * duration)
            }
        }
    }
}

// MARK: - MusicViewDelegate
extension FaceCamViewController: MusicViewDelegate {
    func didChangePositionBarr(_ playerTime: CMTime) {
        guard let player = self.playerView?.player else { return }
        playerStatus = .pause
        player.pause()
        player.seek(to: playerTime, toleranceBefore: .zero, toleranceAfter: .zero)
        self.setProgressText(playerTime.seconds)
    }
    
    func positionBarStoppedMovingg(_ playerTime: CMTime) {
        guard let player = self.playerView?.player else { return }
        player.seek(to: playerTime, toleranceBefore: .zero, toleranceAfter: .zero)
        self.setProgressText(playerTime.seconds)
    }
    
    func didChangeScrollPosition(_ offsetX: CGFloat) {
        self.timeSacleScrollView.isScrollEnabled = true
        self.timeSacleScrollView.contentOffset.x = offsetX
        self.timeSacleScrollView.isScrollEnabled = false
    }
}
