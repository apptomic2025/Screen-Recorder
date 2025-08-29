//
//  EditorVC.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 27/2/25.
//

import UIKit
import AVKit
import AVFoundation
import PhotosUI



//
//extension EditorViewController: GADFullScreenContentDelegate{
//    
//    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
//      print("Ad will present full screen content.")
//    }
//
//    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error)
//    {
//      print("Ad failed to present full screen content with error \(error.localizedDescription).")
//        self.loadInterstitial()
//        self.gotoShareVC()
//    }
//
//    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
//      print("Ad did dismiss full screen content.")
//        self.loadInterstitial()
//        self.gotoShareVC()
//    }
//    
//}
let scrollHeight:CGFloat = 44
let midleFlagborderHeight = 60

class EditorVC: UIViewController {
    
#if DEBUG
    let fullScreenAdID = "ca-app-pub-3940256099942544/4411468910"
#else
    let fullScreenAdID = "ca-app-pub-3940256099942544/4411468910"
#endif
    
    /// The interstitial ad.
   // var interstitial: GAMInterstitialAd?
    
//    fileprivate func loadInterstitial() {
//      GAMInterstitialAd.load(
//        withAdManagerAdUnitID: fullScreenAdID,
//        request: GAMRequest()
//      ) { (ad, error) in
//        if let error = error {
//          print("Failed to load interstitial ad with error: \(error.localizedDescription)")
//          return
//        }
//        self.interstitial = ad
//        self.interstitial?.fullScreenContentDelegate = self
//      }
//    }
    
    private let cropPickerView: CropPickerView = {
        let cropPickerView = CropPickerView()
       // cropPickerView.translatesAutoresizingMaskIntoConstraints = false
        cropPickerView.backgroundColor = .clear
        cropPickerView.imageView.backgroundColor = .clear
        return cropPickerView
    }()
    
    var assetImgGenerate: AVAssetImageGenerator{
        let assetImgGenerate : AVAssetImageGenerator = AVAssetImageGenerator(asset: (self.video?.asset!)!)
        assetImgGenerate.appliesPreferredTrackTransform = true
        return assetImgGenerate
    }
    
    let bottomConstant:CGFloat = 194.0
    let bottomConstantFilter:CGFloat = 220.0
    
    @IBOutlet weak var topNavBarView: UIView!
    @IBOutlet weak var exportView: UIView!{
        didSet{
            exportView.alpha = 0.0
        }
    }
    @IBOutlet weak var trimmerView: TrimmerView!
    @IBOutlet weak var trimmerContainerView: UIView!
    @IBOutlet weak var trimViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var trimmerDurationLbl: UILabel!{
        didSet{
            trimmerDurationLbl.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        }
    }
    
    @IBOutlet weak var croperMainContainerView: UIView!{
        didSet{
            croperMainContainerView.backgroundColor = .clear
            croperMainContainerView.alpha = 0.0
        }
    }
    @IBOutlet weak var cropContainerView: UIView!
    @IBOutlet weak var cropBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var filterContainerView: UIView!
    @IBOutlet weak var filterView: UIView!
    @IBOutlet weak var filterBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var editorCollectionView: UICollectionView!
    
    @IBOutlet weak var editorView: UIView!
    
    @IBOutlet weak var speedContainerView: UIView!
    @IBOutlet weak var speedViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var speedValueLabel: UILabel!{
        didSet{
            speedValueLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        }
    }
    @IBOutlet weak var speedSlider: UISlider! {
        didSet{
            
            guard let video = video else { return }
            speedSlider.value = video.speed
            speedSlider.addTarget(self, action: #selector(speedValueChanged(slider:event:)), for: .valueChanged)
        }
    }
    
    @IBOutlet weak var fakeView: UIView!{
        didSet{
            fakeView.alpha = 0.0
            fakeView.isHidden = true
        }
    }

    
    @IBOutlet weak var volumeContainerView: UIView!
    @IBOutlet weak var volumeViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var volumeLabel: UILabel!{
        didSet{
            volumeLabel.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .medium)
            volumeLabel.text = "\((video?.volume ?? 1) * 100)%"
        }
    }
    @IBOutlet weak var volumeSlider: UISlider! {
        didSet {
            guard let video = video else { return }
            volumeSlider.value = video.volume * 100
            volumeSlider.addTarget(self, action: #selector(volumeValueChanged(slider:event:)), for: .valueChanged)
        }
    }
    
    var timescalcolor: UIColor {
        return UIColor(hex: "#B4B4B4")
    }
    
    let ellipseView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 2, height: 2))
        view.layer.cornerRadius = 10
        return view
    }()
    
    @IBOutlet weak var btnCross: UIButton!
    @IBOutlet weak var btnExport: UIButton!
    
    @IBOutlet weak var timeSacleScrollView: UIScrollView!
    @IBOutlet weak var timeSacleContentView: UIView!
    @IBOutlet weak var timeSacleContentViewWidthConstraint: NSLayoutConstraint!
    
    var playerStatus: PlayerStatus = .stop
    var video: Video?
    var isFirstTimeLoaded = false
    
    @IBOutlet weak var timeLbl: UILabel!{
        didSet{
            timeLbl.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        }
    }
    @IBOutlet weak var timeLblWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var playerContainerView: UIView!{
        didSet{
            //self.playerContainerView.backgroundColor = .clear
        }
    }
    @IBOutlet weak var videoSplitView: MusicView!
    
    @IBOutlet weak var playPauseButton: UIButton!{
        didSet{
            playPauseButton.addTarget(self, action: #selector(playButtonAction), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var lblAddStickers: UILabel!{
        didSet{
            self.lblAddStickers.font = .appFont_CircularStd(type: .bold, size: 14)
            self.lblAddStickers.textColor = UIColor(hex: "#434343")
        }
    }
    
    @IBOutlet weak var lblAddMusic: UILabel!{
        didSet{
            self.lblAddMusic.font = .appFont_CircularStd(type: .bold, size: 14)
            self.lblAddMusic.textColor = .white
        }
    }
    
    //var playerView: PlayerView?
    var exportVC: ExportSettingsVC?
    
    var rotate: Double = 0
    
    var isComeFromFaceCam: Bool = false
    var isComeFromCommentaruy: Bool = false
    var isComeFromPreviewVC: Bool = false
    
    //NEW VIDEO VIEW
    private var videoView: VideoView = {
        let videoView = VideoView(frame: CGRect(x: 0, y: 0, width: 100, height: 100), viewType: .default)
        //videoView.translatesAutoresizingMaskIntoConstraints = false
        return videoView
    }()
    private var isPlaying = false
    
    // MARK: - LIFE CYCLE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.loadInterstitial()
        
        trimmerView.delegate = self
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        mickSetup(.playback)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.backToHome(_:)), name: NSNotification.Name(rawValue: "backToHome"), object: nil)

//        if isFirstTimeLoaded {
//            loadVideo()
//        }
    }
    
    var isLoaded = false
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if !isLoaded{
            isLoaded = true
            
        }
    }
    @objc func backToHome(_ notification: NSNotification) {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isComeFromPreviewVC || isComeFromFaceCam {
            setupContainerViewUI()
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.videoView.invalidate()
        
    }
        
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !isFirstTimeLoaded{
            
            isFirstTimeLoaded = true
            
            loadVideo()
            setupCollectionView()
            setupContainerViewUI()
            if let exportVC = loadVCfromStoryBoard(name: "Export", identifier: "ExportSettingsVC") as? ExportSettingsVC{
                self.exportVC = exportVC
                self.exportVC?.delegate = self
                self.add(exportVC, contentView: exportView)
                
                setupContainerViewUI()
            }
        }
    }
    deinit{
        debugPrint("deinit of preview vc")
    }
    
    func setupContainerViewUI() {
        
        filterBottomConstraint.constant = -bottomConstantFilter
        trimViewBottomConstraint.constant = -bottomConstant
        speedViewBottomConstraint.constant = -bottomConstant
        volumeViewBottomConstraint.constant = -bottomConstant
        cropBottomConstraint.constant = -bottomConstant
        
        guard let thumb = self.video?.videoThumb else { return }
        let filterView = FilterView(frame: self.filterView.frame, sourceImage: thumb)
        filterView.delegate = self
        self.filterContainerView.addSubview(filterView)
        
        let cropview = CustomCropView(frame: self.cropContainerView.bounds)
        cropview.delegate = self
        self.cropContainerView.addSubview(cropview)
        
        self.croperMainContainerView.addSubview(self.cropPickerView)
        self.cropPickerView.frame = self.croperMainContainerView.bounds
        cropPickerView.backgroundColor = .green
        self.cropPickerView.delegate = self
        self.croperMainContainerView.alpha = 0.0
        
        DispatchQueue.main.async {
            self.loadCroppperView()
        }
    }
    
    @objc func speedValueChanged(slider: UISlider, event: UIEvent) {
        DispatchQueue.main.async { [self] in
            //debugPrint(slider.value)
            //speed 0.1x to 12x
            if slider.value > 5.0{
                let extra = slider.value - 5.0
                var currentValue = (extra * 12)/5
                currentValue = (round(currentValue * 10) / 10.0)
                if currentValue > 0 && currentValue < 1{
                    currentValue = 1
                }
                debugPrint("speed + = \(currentValue)")
                speedValueLabel.text = "\(currentValue)x"
                
                videoView.speed = currentValue
                
            }else{
                var currentValue = ((slider.value * 9)/5)/10
                currentValue = (round(currentValue * 10) / 10.0)
                if currentValue == 0.0{
                    currentValue = 0.1
                }
                debugPrint("speed - = \(currentValue)")
                speedValueLabel.text = "\(currentValue)x"
                
                videoView.speed = currentValue
                
            }
        }
    }
    
    @objc func volumeValueChanged(slider: UISlider, event: UIEvent) {
        DispatchQueue.main.async { [self] in
            debugPrint(slider.value)
            var currentValue = slider.value/100
            currentValue = (round(currentValue * 10) / 10.0)
            
            videoView.volume = currentValue
            videoView.player?.volume = currentValue
            
            volumeLabel.text = "\(Int(slider.value))%"
            debugPrint("volume: \(currentValue)")
        }
    }
    
    // MARK: - Private Methods
    
    private var videoConverter: VideoConverter?
    
    fileprivate func gotoShareVC(){
        
        guard let startTime = self.video?.videoTime?.startTime, let endTime = self.video?.videoTime?.endTime else { return }
        
        let duration = endTime - startTime

        var videoConverterCrop: ConverterCrop?
        
        let size = self.videoRect.size
        let n = (self.video?.asset?.tracks(withMediaType: .video).first?.naturalSize)!
        let cRect = self.videoView.cRect ?? CGRect(x: 0, y: 0, width: n.width, height: n.height)
        //let cRect = self.videoView.cRect ??
        
        if let dimFrame = self.videoView.dimFrame {
            videoConverterCrop = ConverterCrop(frame: dimFrame, contrastSize: size, cRect: cRect)
        }
        
        
        if let shareVC = ShareVC.customInit(video: video,videoComposition: self.videoView.cropScaleComposition, option:ConverterOption(
            trimRange: CMTimeRange(start: startTime, duration: duration),
            convertCrop: videoConverterCrop,
            rotate: CGFloat(.pi/2 * self.rotate),
            quality: nil,
            isMute: false),exportType: .normal){
            shareVC.modalPresentationStyle = .fullScreen
            //shareVC.delegate = self
            self.navigationController?.present(shareVC, animated: true)
        }
        
        return
        
//        videoConverter.convert(ConverterOption(
//            trimRange: CMTimeRange(start: startTime, duration: duration),
//            convertCrop: videoConverterCrop,
//            rotate: CGFloat(.pi/2 * self.rotate),
//            quality: nil,
//            isMute: false), progress: { [weak self] (progress) in
//               debugPrint(progress)
//            }, completion: { [weak self] (url, error) in
//            if let error = error {
//                let alertController = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
//                alertController.addAction(UIAlertAction(title: "Confirm", style: .default, handler: nil))
//                self?.present(alertController, animated: true)
//            } else {
//
//                DispatchQueue.main.async {
//                    let videoURL = url
//                    let player = AVPlayer(url: videoURL!)
//                    let playerViewController = AVPlayerViewController()
//                    playerViewController.player = player
//                    self?.present(playerViewController, animated: true) {
//                        playerViewController.player!.play()
//                    }
//                }
//            }
//        })
        
//        return
//        guard var video = self.video, let asset = video.asset else { return }
//
//        var presetVideoComposition: AVMutableVideoComposition = AVMutableVideoComposition()
//            presetVideoComposition = AVMutableVideoComposition(asset: asset,  applyingCIFiltersWithHandler: {
//                (request) in
//                let source = request.sourceImage.clampedToExtent()
//                let output = source.cropped(to: request.sourceImage.extent)
//                request.finish(with: output, context: nil)
//            })
//
//
//        let videoComposition: AVVideoComposition = self.videoView.cropScaleComposition ?? presetVideoComposition
//
//        video.cropRect = self.videoView.cRect
//
//        if let shareVC = ShareViewController.customInit(video: video, videoComposition: videoComposition){
//            shareVC.exportType = .normal
//            shareVC.modalPresentationStyle = .fullScreen
//            //shareVC.delegate = self
//            self.navigationController?.present(shareVC, animated: true)
//        }
    }
    
    var actualRect: CGRect?
    var videoRect: CGRect {
        if self.rotate == 0 || self.rotate == 2 {
            return actualRect ?? .zero
            //self.playerLayer.videoRect
        } else if self.rotate == 1 || self.rotate == 3 {
            guard let actualRect = actualRect else { return .zero}
            return CGRect(x: actualRect.origin.y, y: actualRect.origin.x, width: actualRect.size.height, height: actualRect.size.width)
        } else {
            return .zero
        }
    }

    private func loadCroppperView(){
        guard let time = self.video?.videoTime?.startTime else{
            return
        }
        let img = try? assetImgGenerate.copyCGImage(at: time, actualTime: nil)
        if let img = img {
            let frameImg  = UIImage(cgImage: img)
            DispatchQueue.main.async(execute: {
                self.actualRect = AVMakeRect(aspectRatio: frameImg.size, insideRect: self.croperMainContainerView.bounds)
                self.cropPickerView.image(frameImg)
                debugPrint("actualRect: \(self.actualRect ?? self.croperMainContainerView.bounds)")
                debugPrint("actualRectContainer: \(self.croperMainContainerView.bounds)")
                self.cropPickerView.frame = self.actualRect ?? (self.croperMainContainerView.bounds)
            })
            
        }
    }
    
    func activeEditingStateUI(){
        DispatchQueue.main.async {
            self.topNavBarView.isHidden = true
            self.editorView.isHidden = true
        }
        
    }
    func inactiveEditingStateUI(){
        DispatchQueue.main.async {
            self.topNavBarView.isHidden = false
            self.editorView.isHidden = false
        }
        
    }
    
    func setupCollectionView() {
        let nib = UINib(nibName: "EditorCVCell", bundle: nil)
        editorCollectionView.register(nib, forCellWithReuseIdentifier: "EditorCVCell")
        editorCollectionView.delegate = self
        editorCollectionView.dataSource = self
        editorCollectionView.isScrollEnabled = false
        DispatchQueue.main.async {
            self.editorCollectionView.reloadData()
        }
    }
    
    private func loadVideo() {
        
        if let video{
            guard let url = video.videoURL else { return }

            self.videoView = VideoView(frame: self.playerContainerView.bounds, viewType: .default)
            self.playerContainerView.addSubview(self.videoView)
            
            self.videoView.delegate = self
            
            self.videoView.url = url
            let asset = AVAsset(url: url)
            self.videoConverter = VideoConverter(asset: asset)
            
            let videoTime = VideoTime(startTime: .zero, endTime: asset.duration)
            video.asset = asset
            video.videoTime = videoTime
            video.duration = video.videoTime?.duration
            
            self.videoView.videoTime = videoTime
            
            self.videoSplitView.delegate = self
            self.loadSplitViews(video)
            
        }
    }
    
    private func removeFormerDots() {
        timeSacleContentView.subviews.forEach({ $0.removeFromSuperview() })
    }
    
    private func loadSplitViews(_ video: Video){
        
        DispatchQueue.main.async {
            self.videoSplitView.video = video
            self.removeFormerDots()
            
            self.setProgressText(0)
            debugPrint("contentsize = \(self.videoSplitView.scrollview.contentSize)")
            self.timeSacleContentViewWidthConstraint.constant = self.videoSplitView.scrollview.contentSize.width - DEVICE_WIDTH
            
            let contentwidth = self.videoSplitView.scrollview.contentSize.width - DEVICE_WIDTH
            let perSecPixel = contentwidth
            
            
            var currentX: CGFloat = 0 // Start position

            for i in 0...Int(video.videoTime?.duration ?? 1) {
                if i % 5 == 0 {
                    // Create a label
                    let lbl = UILabel()
                    lbl.font = UIFont(name: "CircularStd-Medium", size: 9)
                    lbl.textColor = self.timescalcolor
                    lbl.text = "\(i)s"
                    lbl.sizeToFit() // Adjust width based on text content
                    
                    lbl.frame.origin = CGPoint(x: currentX, y: 0) // Set position
                    self.timeSacleContentView.addSubview(lbl)
                    lbl.center.y = self.timeSacleContentView.center.y
                    
                    currentX += lbl.frame.width + 22 // Move forward by label width + 10px gap
                } else {
                    // Create a dot view
                    let dotview = UIView(frame: CGRect(x: currentX, y: 0, width: 2, height: 2))
                    dotview.layer.cornerRadius = 1
                    dotview.backgroundColor = self.timescalcolor
                    self.timeSacleContentView.addSubview(dotview)
                    dotview.center.y = self.timeSacleContentView.center.y
                    
                    currentX += 22 // Move forward by 10px after a dot
                }
            }


        }
    }
    
    private func setProgressText(_ currentTime: Double){
        
        if let video, let duration = video.videoTime?.duration{
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
    
    func goToExportVC() {
        self.videoView.pause()
        exportVC?.mainContentViewBottomContraint.constant = 0
        exportVC?.video = video
        UIView.animate(withDuration: 0.3) {
            self.exportView.alpha = 1.0
            self.view.layoutIfNeeded()
        }
    }
    
    func rotateVideo() {
        if rotate == 0{
            rotate += 1
            playerContainerView.rotateVideo(degrees: 90)
            croperMainContainerView.rotateVideo(degrees: 90)
            video?.degrees = 90
            self.videoView.degree = 90
        }else if rotate == 1 {
            rotate += 1
            playerContainerView.rotateVideo(degrees: 180)
            croperMainContainerView.rotateVideo(degrees: 180)
            video?.degrees = 180
            self.videoView.degree = 180
        }else if rotate == 2 {
            rotate += 1
            playerContainerView.rotateVideo(degrees: 270)
            croperMainContainerView.rotateVideo(degrees: 270)
            video?.degrees = 270
            self.videoView.degree = 270
        }else{
            rotate = 0
            playerContainerView.rotateVideo(degrees: 0)
            croperMainContainerView.rotateVideo(degrees: 0)
            video?.degrees = 0
            self.videoView.degree = 0
        }
    }
    
    // MARK: - Button Action
    @IBAction func doneFilterAction() {
        inactiveEditingStateUI()
        if let filter = self.videoView.videoFilter{
            self.video?.videoFilter = filter
        }
        
        filterBottomConstraint.constant = -bottomConstantFilter
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    @IBAction func dismissTrimmerView(){
        self.inactiveEditingStateUI()
        self.trimViewBottomConstraint.constant = -bottomConstant
        self.filterBottomConstraint.constant = -bottomConstantFilter
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    @IBAction func doneTrim(){
        self.inactiveEditingStateUI()
        self.video?.videoTime = videoView.videoTime
        self.loadSplitViews(video!)
        
        self.trimViewBottomConstraint.constant = -bottomConstant
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    /// speed view action functionality
    @IBAction func dismissSpeedView() {
        
        videoView.speed = video?.speed ?? 1
        //self.videoView.player?.rate = video?.speed ?? 1.0
        playPauseButton.isHidden = true
        self.inactiveEditingStateUI()
        self.speedViewBottomConstraint.constant = -bottomConstant
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func doneSpeed(){
        
        self.inactiveEditingStateUI()
        if let video {
            video.speed = videoView.speed
            //self.videoView.player?.rate = video.speed
            playPauseButton.isHidden = false
        }
        self.speedViewBottomConstraint.constant = -bottomConstant
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    /// volume view action functionality
    @IBAction func dismissVolumeView() {
        
        self.inactiveEditingStateUI()
        self.volumeViewBottomConstraint.constant = -bottomConstant
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func doneVolume(){
        
        self.inactiveEditingStateUI()
        if let video {
            video.volume = videoView.volume
        }
        self.volumeViewBottomConstraint.constant = -bottomConstant
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func backButtonAction(_ sender: UIBarButtonItem){
        
        let actionsheet = UIAlertController(title: "Are you sure you want to discard all changes?", message: nil, preferredStyle: .actionSheet)
        
        actionsheet.addAction(UIAlertAction(title: "Discard Changes", style: .destructive , handler:{ (UIAlertAction)in
            self.dismiss(animated: true)
            self.navigationController?.popViewController(animated: true)
        }))
            
        
        actionsheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ (UIAlertAction)in
                print("User click Dismiss button")
        }))
        self.present(actionsheet, animated: true)
        
        
    }
    
    @objc @IBAction func playButtonAction(_ sender: UIButton) {
        if self.playerStatus == .stop || self.playerStatus == .pause{
            self.playerStatus = .play
            self.videoSplitView.playerStatus = .play
            self.videoView.play()
            playPauseButton.isHidden = true
        }else{
            self.playerStatus = .pause
            self.videoSplitView.playerStatus = .pause
            self.videoView.pause()
            playPauseButton.isHidden = false
        }
        
    }
    
    /// export video
    @IBAction func exportButtonAction(_ sender: UIButton) {
        goToExportVC()
    }
    
}

extension EditorVC: PlayerViewDelegate{
    
    func videoFinished() {
        self.playerStatus = .pause
        self.playerStatus = .stop
        playPauseButton.isHidden = false
//        if let player = self.videoView.player, let startTime = self.playerView?.videoTime?.startTime{
//            player.seek(to: startTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
//        }
        
    }
    
    func videoprogress(progress: Double) {
        
        if self.playerStatus == .play{
            let doublevalue = Double( CGFloat(0) * scrollHeight)
            
            if let video, let duration = video.duration, let startTime = video.videoTime?.startTime, let trimmedDuration = video.videoTime?.duration{
                let mainCurrentTime = progress * duration
                let currentTime = mainCurrentTime - startTime.seconds
                let currentProgress = currentTime / trimmedDuration
                
                self.videoSplitView.scrollview.contentOffset = CGPoint(x: currentProgress*self.videoSplitView.durationSize+doublevalue, y: self.videoSplitView.scrollview.contentOffset.y)
                
                self.setProgressText(currentProgress * trimmedDuration)
            }
            
        }
        
    }
}

extension EditorVC: MusicViewDelegate{
    
    func didChangePositionBarr(_ playerTime: CMTime){
        
        if let player = self.videoView.player{
            self.isPlaying = self.videoView.isPlaying
            self.playerStatus = .pause
            self.videoView.pause()
            playPauseButton.isHidden = false
            var seekTime = playerTime
            if let startTime = video?.videoTime?.startTime{
                seekTime = seekTime + startTime
            }
            player.seek(to: seekTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            
            self.setProgressText(playerTime.seconds)
        }
        
    }
    func positionBarStoppedMovingg(_ playerTime: CMTime){
        
        
        if let player = self.videoView.player{
            var seekTime = playerTime
            if let startTime = video?.videoTime?.startTime{
                seekTime = seekTime + startTime
            }
            player.seek(to: seekTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)


            self.setProgressText(playerTime.seconds)
            
            if self.isPlaying {
                playPauseButton.isHidden = true
                self.videoView.play()
            }
        }
    }
    func didChangeScrollPosition(_ offsetX: CGFloat) {
        self.timeSacleScrollView.isScrollEnabled = true
        self.timeSacleScrollView.contentOffset.x = offsetX
        self.timeSacleScrollView.isScrollEnabled = false
    }
}

extension EditorVC: UICollectionViewDataSource{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return editorArray.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EditorCVCell", for: indexPath) as! EditorCVCell
        cell.editModel = editorArray[indexPath.item]
        return cell
    }
}
extension EditorVC: UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        self.playerStatus = .pause
        playPauseButton.isHidden = false
        
        let name = editorArray[indexPath.item].title
        if name.lowercased() == "filter" {
            self.stopState()
            self.activeEditingStateUI()
            filterBottomConstraint.constant = 0
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }else if name.lowercased() == "trim" {
            self.stopState()
            let currentVideo = self.video
            if let asset = currentVideo?.asset{
                DispatchQueue.main.async {
                    
                    self.activeEditingStateUI()
                    self.trimmerView.asset = asset
                    
                    self.trimViewBottomConstraint.constant = 0
                    //self.navBar.isHidden = true
                    if let startTime = currentVideo?.videoTime?.startTime, let endTime = currentVideo?.videoTime?.endTime{
                        self.trimmerView.moveLeftHandle(to: startTime)
                        self.trimmerView.moveRightHandle(to: endTime)
                    }
                    UIView.animate(withDuration: 0.3) {
                        
                        self.view.layoutIfNeeded()
                    }
                }
            }
            
        }else if name.lowercased() == "speed" {
            self.stopState()
            if let speed = video?.speed{
                print(speed)
                self.videoView.pause()
                //if speed >= 1.0{
                    let sliderValue = ((5 * speed)/12) + 5.0
                    speedSlider.value = sliderValue
                    self.activeEditingStateUI()
                    speedViewBottomConstraint.constant = 0
                    UIView.animate(withDuration: 0.3) {
                        self.view.layoutIfNeeded()
                    }
                //}
            }
            
        } else if name.lowercased() == "volume" {
            self.stopState()
            if let volume = video?.volume{
                let sliderValue = volume * 100
                volumeSlider.value = sliderValue
                self.activeEditingStateUI()
                volumeViewBottomConstraint.constant = 0
                UIView.animate(withDuration: 0.3) {
                    self.view.layoutIfNeeded()
                }
            }
            
        }else if name.lowercased() == "rotate" {
            self.stopState()
            rotateVideo()
        }else if name.lowercased() == "crop" {
            self.stopState()
            self.cropTap()
            self.activeEditingStateUI()
            cropBottomConstraint.constant = 0
            UIView.animate(withDuration: 0.3) {
                self.croperMainContainerView.alpha = 1.0
                self.playerContainerView.alpha = 0.0
                self.view.layoutIfNeeded()
            }
        }
        
    }
    
}

extension EditorVC{
    
    private func stopState(){
            self.playerStatus = .pause
            self.videoView.pause()
            playPauseButton.isHidden = false
    }
    private func cropTap() {
        
        guard let startTime = self.video?.videoTime?.startTime else { return }
        guard let imageRef = try? assetImgGenerate.copyCGImage(at: startTime, actualTime: nil) else { return }
        let image = UIImage(cgImage: imageRef)
        self.cropPickerView.image(image)
        
    }
}

extension EditorVC: UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        //return CGSize(width: editorArray[indexPath.item].cellWidth, height: 47)
        return CGSize(width: collectionView.bounds.width / 6, height: 47)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
}

extension EditorVC: FilterViewDelegate{
    func dismissFilterView() {
        
        inactiveEditingStateUI()
        if let previousFilter = self.video?.videoFilter{
            self.videoView.filter(previousFilter)
        }else{
            self.videoView.filter(nil)
        }
        
        filterBottomConstraint.constant = -bottomConstant
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func doneFilter() {
        inactiveEditingStateUI()
        if let filter = self.videoView.videoFilter{
            self.video?.videoFilter = filter
        }
        
        filterBottomConstraint.constant = -bottomConstant
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func filterSelected(_ filter: VideoFilter){
        
        
        
        videoView.filter(filter)
        
    }
}

extension EditorVC: CropViewDelegate{
    func dismissCropView() {
        
        inactiveEditingStateUI()
        cropBottomConstraint.constant = -bottomConstant
        UIView.animate(withDuration: 0.3) {
            self.croperMainContainerView.alpha = 0.0
            self.playerContainerView.alpha = 1.0
            self.view.layoutIfNeeded()
        }
    }

    
    func getOriginalRectFrom0(sRect: CGRect, cRect: CGRect) -> CGRect {
        /// sRect is 90 degree supper view rect
        /// cRect is 90 degree child view rect
        
        /*let x = cRect.origin.y
        let y = sRect.size.width - (cRect.origin.x + cRect.size.width)
        let width = cRect.size.height
        let height = cRect.size.width*/
        
        let x = sRect.size.height - (cRect.origin.y + cRect.size.height)
        let y = cRect.origin.x
        let width = cRect.size.height
        let height = cRect.size.width
        
        // this child 0 degree rect
        return CGRect(x: x, y: y, width: width, height: height)
    }

    
    func doneCrop() {
        inactiveEditingStateUI()
        cropBottomConstraint.constant = -bottomConstant
        UIView.animate(withDuration: 0.3) {
            self.croperMainContainerView.alpha = 0.0
            self.playerContainerView.alpha = 1.0
            self.view.layoutIfNeeded()
        }
        
        self.cropPickerView.crop { (crop) in
            
            if let cropFrame = crop.cropFrame, let imageSize =  crop.imageSize{
                
                debugPrint("cropped: \(cropFrame)")
                guard let superRect = self.actualRect else { return }
                let cropperRect = CropperRect(superRect: superRect, cropRect: cropFrame)
                self.videoView.cropVideo(cropperRect)
                
                var tempCroppedFrame = cropFrame
                
                if self.rotate == 1{
                    tempCroppedFrame = normalRect(sSize: imageSize, cRect: cropFrame, position: .degree90)
                }else if self.rotate == 2{
                    tempCroppedFrame = normalRect(sSize: imageSize, cRect: cropFrame, position: .degree180)
                }else if self.rotate == 3{
                    tempCroppedFrame = normalRect(sSize: imageSize, cRect: cropFrame, position: .degree270)
                }
                
                if self.rotate == 1 || self.rotate == 3{
                                    
                    debugPrint("tempCroppedFrame: \(tempCroppedFrame)")
                    
                        let rect = self.videoRect
                    
                        let frameX = tempCroppedFrame.origin.x * rect.size.width / imageSize.height
                        let frameY = tempCroppedFrame.origin.y * rect.size.height / imageSize.width
                        let frameWidth = tempCroppedFrame.size.width * rect.size.width / imageSize.height
                        let frameHeight = tempCroppedFrame.size.height * rect.size.height / imageSize.width
                        let dimFrame = CGRect(x: frameX, y: frameY, width: frameWidth, height: frameHeight)
                        self.videoView.dimFrame = dimFrame

                }else if self.rotate == 0 || self.rotate == 2{
                    let rect = self.videoRect
                    
                        let frameX = tempCroppedFrame.origin.x * rect.size.width / imageSize.width
                        let frameY = tempCroppedFrame.origin.y * rect.size.height / imageSize.height
                        let frameWidth = tempCroppedFrame.size.width * rect.size.width / imageSize.width
                        let frameHeight = tempCroppedFrame.size.height * rect.size.height / imageSize.height
                        let dimFrame = CGRect(x: frameX, y: frameY, width: frameWidth, height: frameHeight)
                        self.videoView.dimFrame = dimFrame
                }
                     
               
            }
            
        }
    }
    
    func cropSelected(_ crop: CropModel){
        
        self.cropPickerView.aspectRatio = crop.ratio
        
    }
}

extension EditorVC: TrimmerViewDelegate {
    func positionBarStoppedMoving(_ playerTime: CMTime) {
        
        if let player = videoView.player{
            player.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            videoView.videoTime = VideoTime(startTime: trimmerView.startTime, endTime: trimmerView.endTime)
            let duration = (trimmerView.endTime! - trimmerView.startTime!).seconds
            let partsDuration = Int(duration)
            let durationString = partsDuration.secondsToHoursMinutesSecondsInString()
            trimmerDurationLbl.text = durationString
            
            if self.isPlaying{
                playPauseButton.isHidden = true
                self.videoView.player?.play()
            }
        }

    }
    
    func didChangePositionBar(_ playerTime: CMTime) {
        
        if let player = videoView.player{
            self.isPlaying = self.videoView.isPlaying
            self.playerStatus = .pause
            self.videoView.pause()
            playPauseButton.isHidden = false
            player.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            let duration = (trimmerView.endTime! - trimmerView.startTime!).seconds
            let partsDuration = Int(duration)
            let durationString = partsDuration.secondsToHoursMinutesSecondsInString()
            trimmerDurationLbl.text = durationString
        }
        
    }
}

extension EditorVC: ExportDelegate{
    func exportClicked(_ video: Video?){
        self.video = video
        UIView.animate(withDuration: 0.5) {
            self.exportView.alpha = 0
        }
        
        self.gotoShareVC()
        
    }
    func dismissExportVC() {
        UIView.animate(withDuration: 0.5) {
            self.exportView.alpha = 0
        }
    }
    
    func exportOptionChoosed(_ pixel: Int?, bitRate: Int?, frameRate: Int?) {
        
    }
}

// MARK: CropPickerViewDelegate
extension EditorVC: CropPickerViewDelegate {
    func cropPickerView(_ cropPickerView: CropPickerView, result: CropResult) {
        
    }
    
    func cropPickerView(_ cropPickerView: CropPickerView, didChange frame: CGRect) {
        debugPrint(frame)
    }
}

// MARK: ViewController + VideoDelegate
extension EditorVC: VideoDelegate {
    
    func videoFinishedFromVideoView() {
        self.playerStatus = .pause
        self.videoSplitView.playerStatus = .pause
        self.videoView.pause()
        playPauseButton.isHidden = false
    }
    
    
    func videoPlaying() {
        let doublevalue = Double( CGFloat(0) * scrollHeight)
        
        if let mainCurrentTime = self.videoView.player?.currentTime(){
            let currentTime = mainCurrentTime - self.videoView.startTime
            let currentProgress = currentTime.seconds / self.videoView.durationTime.seconds
            self.videoSplitView.scrollview.contentOffset = CGPoint(x: currentProgress*self.videoSplitView.durationSize+doublevalue, y: self.videoSplitView.scrollview.contentOffset.y)
            
            self.setProgressText(currentProgress * self.videoView.durationTime.seconds)
        }
        
    }
}
