//
//  CropViewController.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 22/3/25.
//

import UIKit
import AVKit
import AVFoundation
import PhotosUI

class CropViewController: UIViewController {

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
    
    @IBOutlet weak var croperMainContainerView: UIView!
    @IBOutlet weak var cropContainerView: UIView!
    @IBOutlet weak var cropBottomConstraint: NSLayoutConstraint!
    
    var playerStatus: PlayerStatus = .stop
    var video: Video?
    var isFirstTimeLoaded = false
    
    //var playerView: PlayerView?
    //NEW VIDEO VIEW
    private var videoView: VideoView = {
        let videoView = VideoView(frame: CGRect(x: 0, y: 0, width: 100, height: 100), viewType: .default)
        //videoView.translatesAutoresizingMaskIntoConstraints = false
        return videoView
    }()
    var exportVC: ExportSettingsVC?
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if isFirstTimeLoaded {
            loadVideo()
        }
    }
    
    var isLoaded = false
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if !isLoaded{
            isLoaded = true
            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isFirstTimeLoaded {
            setupContainerViewUI()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.videoView.invalidate()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !isFirstTimeLoaded{
            isFirstTimeLoaded = true
            
            loadVideo()
            setupContainerViewUI()
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
    
    func setupContainerViewUI() {
        cropBottomConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.croperMainContainerView.alpha = 1.0
            self.playerContainerView.alpha = 0.0
            self.view.layoutIfNeeded()
        }
        
        let cropview = CustomCropView(frame: self.cropContainerView.bounds)
        cropview.delegate = self
        //cropview.navVView.isHidden = true
        self.cropContainerView.addSubview(cropview)
        
        self.croperMainContainerView.addSubview(self.cropPickerView)
        self.cropPickerView.frame = self.croperMainContainerView.bounds
        self.cropPickerView.delegate = self
        
        DispatchQueue.main.async {
            self.loadCroppperView()
        }
    }
    
    var actualRect: CGRect?
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
        self.dismiss(animated: true)
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func shareButtonAction(_ sender: UIButton){
        self.videoView.invalidate()
        gotoShareVC()
    }
    
}


extension CropViewController: CropViewDelegate{
    func dismissCropView() {
//        UIView.animate(withDuration: 0.3) {
//            self.croperMainContainerView.alpha = 0.0
//            self.playerContainerView.alpha = 1.0
//            self.view.layoutIfNeeded()
//        }
    }
    
    func doneCrop() {

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
            }
            
        }
    }
    
    func cropSelected(_ crop: CropModel){
        self.cropPickerView.aspectRatio = crop.ratio
        
        UIView.animate(withDuration: 0.3) {
            self.croperMainContainerView.alpha = 1.0
            self.playerContainerView.alpha = 0.0
            self.view.layoutIfNeeded()
        }
    }
}

extension CropViewController: CropPickerViewDelegate {
    func cropPickerView(_ cropPickerView: CropPickerView, result: CropResult) {
    }
    
    func cropPickerView(_ cropPickerView: CropPickerView, didChange frame: CGRect) {

        debugPrint(frame)
    }
}

// MARK: ViewController + VideoDelegate
extension CropViewController: VideoDelegate {
    
    func videoFinishedFromVideoView() {
        self.playerStatus = .pause
        self.videoView.pause()
        playPauseButton.isHidden = false
    }
    
    
    func videoPlaying() {
        
    }
}
