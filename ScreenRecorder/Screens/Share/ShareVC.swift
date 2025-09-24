//
//  ShareVC.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 5/3/25.
//

import UIKit
import AVKit
import AVFoundation
import PhotosUI
import Photos
import SCSDKCreativeKit
import FacebookShare


protocol ShareDelegate: AnyObject {
    func shareInstagramStory(_ videoURL: URL?)
    func shareInstagram(_ localID: String?)
    func shareSnapchat(_ videoURL: URL?)
    func shareTikTok(_ video: Video?)
    func shareFacebook(_ videoURL: URL?)
    func shareYoutube(_ video: Video?)
    func shareMore(_ video: Video?)
    func shareMoreShare(_ video: Video?)
    func shareFacebookAll(_ localID: String?)
}

class GlobalShareDelegate{
    weak var delegate: ShareDelegate?
    static let shared = GlobalShareDelegate()
}

class ShareVC: UIViewController {
    let share = GifManager.shared
   
    struct ShareModel{
        var title: String
        var icon: String
    }
    
    fileprivate lazy var snapAPI = {
        return SCSDKSnapAPI()
    }()
    
    
    weak var delegate: ShareDelegate?
    var commentary: CommentaryVideo?
    var exportType: ExportType = .normal
    var exportedURL: URL?
    var localId: String?
    var shareArray: [ShareModel] = [ShareModel(title: "Saved", icon: "saved 1"), ShareModel(title: "IG Story", icon: "IgStory"),ShareModel(title: "IG Feed", icon: "IgFeed"),ShareModel(title: "Snapchat", icon: "SnapChat"),ShareModel(title: "FB Story", icon: "FbStory"),ShareModel(title: "Facebook", icon: "fb"),ShareModel(title: "Messenger", icon: "messanger"),ShareModel(title: "More", icon: "more")]
    
    @IBOutlet private weak var playerView: UIView!
    var player: AVPlayer? {
        didSet {
            
        }
    }
    
    @IBOutlet weak var savedTikView: UIView!
    @IBOutlet weak var downloadView: UIView!{
        didSet{
            downloadView.alpha = 0.0
        }
    }
    
    @IBOutlet weak var percentageLabel: UILabel!{
        didSet{
            percentageLabel.text = "0%"
            self.percentageLabel.textColor = .black
        }
    }
    
    @IBOutlet weak var downloadContentView: UIView!{
        didSet{
            downloadContentView.layer.cornerRadius = 3
            //downloadContentView.backgroundColor = UIColor.darkGray.withAlphaComponent(0.9)
            downloadContentView.clipsToBounds = true
            
        }
    }
    @IBOutlet weak var downloadProgressView: UIView!{
        didSet{
            downloadProgressView.frame.size.width = 0.0
            downloadProgressView.backgroundColor = .white
        }
    }
    
    @IBOutlet weak var playPauseButton: UIButton!{
        didSet{
            playPauseButton.addTarget(self, action: #selector(playButtonAction), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var downloadStatusLabel: UILabel!
    
    ///
    @IBOutlet weak var gifImageView: UIImageView!
    var isComeFromVideoToGifVC: Bool = false
    var imageArray: [UIImage] = []
    var exportGifURL: URL?
    
    let identifier = "ShareCollectionViewCell"
    @IBOutlet weak var shareCollectionView:UICollectionView!{
        didSet{
            self.shareCollectionView.delegate = self
            self.shareCollectionView.dataSource = self
            self.shareCollectionView.register(UINib(nibName: "ShareCVCell", bundle: nil), forCellWithReuseIdentifier: identifier)
            self.shareCollectionView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
            self.shareCollectionView.backgroundColor = .white
        }
    }
    
    @IBOutlet weak var exportBgView: UIVisualEffectView!
    @IBOutlet weak var tickImageView: UIImageView!
    @IBOutlet weak var lblTittle: UILabel!{
        didSet{
            self.lblTittle.font = .appFont_CircularStd(type: .bold, size: 20)
            self.lblTittle.textColor = UIColor(hex: "#151517")
        }
    }
    @IBOutlet weak var lblVideoSaved: UILabel!{
        didSet{
            self.lblVideoSaved.font = .appFont_CircularStd(type: .book, size: 15)
            self.lblVideoSaved.textColor = UIColor(hex: "#151517")
        }
    }
    @IBOutlet weak var navView: UIView!
    @IBOutlet weak var cnstNavViewHeight: NSLayoutConstraint!
    @IBOutlet weak var lblShareTo: UILabel!{
        didSet{
            self.lblShareTo.font = .appFont_CircularStd(type: .medium, size: 20)
            self.lblShareTo.textColor = UIColor(hex: "#151517")
        }
    }
    
    var video:Video?
    var videoComposition: AVVideoComposition?
    var option: ConverterOption?
    
    static func customInit(video: Video?,videoComposition: AVVideoComposition? = nil,option: ConverterOption? = nil,exportType: ExportType)->ShareVC?{
        if let shareVC = loadVCfromStoryBoard(name: "Share", identifier: "ShareViewController") as? ShareVC{
            shareVC.video = video
            shareVC.videoComposition = videoComposition
            shareVC.option = option
            shareVC.exportType = exportType
            return shareVC
        }
        return nil
    }
    
    var isPlay = false
    
    var isFirstTimeLoaded = false
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mickSetup(.playback)
        
        if self.exportType == .commentary{
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                self.exportCommentary()
            }
        }else if(self.exportType == .facecam){
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                self.exportFacecam()
            }
        }
        else{
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                self.export()
            }
            
            if isComeFromVideoToGifVC {
                gifImageView.isHidden = false
                exportGif()
            }
        }
        
        //        if let videoURL = self.video?.videoURL {
        //            //loadCleanVideo(videoURL)
        //            loadVideo(videoURL)
        //        }
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !isFirstTimeLoaded{
            isFirstTimeLoaded = true
            setupNavHeight()
            if let videoURL = self.video?.videoURL {
                loadVideo(videoURL)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.videoView.invalidate()
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
    
    @objc @IBAction func playButtonAction(_ sender: UIButton) {
        if isPlay{
            isPlay = false
            playPauseButton.isHidden = false
            //player?.pause()
            videoView.pause()
        }else{
            isPlay = true
            playPauseButton.isHidden = true
            //player?.play()
            //player?.rate = self.video?.speed ?? 1
            videoView.play()
        }
        
    }
    
    @IBAction func cancelExportButtonAction(_ sender: UIButton){
        self.dismiss(animated: true)
    }
    
    // MARK: - Private Methods -
    
    public func exportGif() {
        
        gifImageView.animationImages = imageArray
        gifImageView.layer.speed = 0.2
        // gifImageView.animationDuration = imageArray.count
        gifImageView.startAnimating()
        
        DispatchQueue.main.async {
            self.downloadView.alpha = 1.0
            let width = self.downloadView.frame.width
            
            self.share.imageToGif(framesArray: self.imageArray, progress: { (progress) in
                
                guard let  progress = progress else { return }
                debugPrint(progress)
                
            }, success: { (url) in
                print(url)
                
                DispatchQueue.main.async {
                    self.percentageLabel.text =  String("100") + "%"
                    PHPhotoLibrary.shared().performChanges({
                        //PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                        let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                        self.localId = request?.placeholderForCreatedAsset?.localIdentifier
                        
                    }) { saved, error in
                        if saved {
                            
                            DispatchQueue.main.async {
                                self.exportedURL = url
                                self.exportBgView.isHidden = true
                                self.downloadStatusLabel.text = "Successfully Saved"
                            }
                        }
                    }
                }
            }, failure: { (error) in
                DispatchQueue.main.async {
                    self.exportGifURL = nil
                }
            })
        }
    }
    
    public func exportFacecam(){
        
        guard let video = self.video, let videoComposition = self.videoComposition else { return }
        DispatchQueue.main.async {
            
            self.downloadView.alpha = 1.0
            let width = self.downloadView.frame.width
            
            let exporter = Exporter(asset: video.asset)
            exporter.exportFacecamVideo(video, presetVideoComposition: videoComposition,progress: { (progress) in
                
                guard let  progress = progress else { return }
                debugPrint(progress)
                
                DispatchQueue.main.async {
                    let currentProgress = progress * 100
                    UIView.transition(with:self.downloadProgressView , duration: 0.3, options: [.transitionCrossDissolve]) { [weak self] in
                        self?.downloadProgressView.frame.size.width = width * progress
                    }completion: { _ in
                        
                    }
                }
                
            }, success: { (url) in
                
                
                DispatchQueue.main.async {
                    self.percentageLabel.text =  String("100") + "%"
                    PHPhotoLibrary.shared().performChanges({
                        //PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                        let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                        self.localId = request?.placeholderForCreatedAsset?.localIdentifier
                        
                    }) { saved, error in
                        if saved {
                            DispatchQueue.main.async {
                                self.exportedURL = url
                                self.exportBgView.isHidden = true
                                self.downloadStatusLabel.text = "Successfully Saved"
                            }
                            
                        }
                    }
                    
                }
            }) { (error) in
                DispatchQueue.main.async {
                    self.exportedURL = nil
                }
            }
            
        }
    }
    
    public func exportCommentary(){
        
        guard let commentary = self.commentary else { return }
        DispatchQueue.main.async {
            
            self.downloadView.alpha = 1.0
            let width = self.downloadView.frame.width
            
            let exporter = Exporter()
            exporter.exportComentary(commentary, progress: { (progress) in
                
                guard let  progress = progress else { return }
                debugPrint(progress)
                
                DispatchQueue.main.async {
                    let currentProgress = progress * 100
                    UIView.transition(with:self.downloadProgressView , duration: 0.3, options: [.transitionCrossDissolve]) { [weak self] in
                        self?.downloadProgressView.frame.size.width = width * progress
                    }completion: { _ in
                        
                    }
                }
                
            }) { (url) in
                
                
                DispatchQueue.main.async {
                    self.percentageLabel.text =  String("100") + "%"
                    PHPhotoLibrary.shared().performChanges({
                        //PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                        let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                        self.localId = request?.placeholderForCreatedAsset?.localIdentifier
                        
                    }) { saved, error in
                        if saved {
                            
                            
                            DispatchQueue.main.async {
                                self.exportedURL = url
                                // self.loadCleanVideo(url)
                                self.exportBgView.isHidden = true
                                self.downloadStatusLabel.text = "Successfully Saved"
                
                            }
                            
                        }
                    }
                    
                }
            } failure: { (error) in
                DispatchQueue.main.async {
                    self.exportedURL = nil
                }
            }
            
            
        }
    }
    
    public func export() {
        guard let video = self.video else { return }
        
        DispatchQueue.main.async {
            self.downloadView.alpha = 1.0
            let width = self.downloadView.frame.width
            let exporter = Exporter(asset: video.asset)
            
            var optionn = self.option
            if self.option == nil {
                if let startTime = self.video?.videoTime?.startTime, let endTime = self.video?.videoTime?.endTime {
                    let timeRange = CMTimeRange(start: startTime, end: endTime)
                    optionn = ConverterOption(trimRange: timeRange, convertCrop: nil, rotate: nil, quality: nil)
                }
            }
            
            exporter.finalExportVideo(video, option: optionn, progress: { (progress) in
                guard let progress = progress else { return }
                debugPrint(progress)
                
                DispatchQueue.main.async {
                    let currentProgress = progress * 100
                    UIView.transition(with: self.downloadProgressView, duration: 0.3, options: [.transitionCrossDissolve]) { [weak self] in
                        self?.downloadProgressView.frame.size.width = width * progress
                    }
                }
                
            }, success: { (url) in
                DispatchQueue.main.async {
                    self.percentageLabel.text = "100%"
                    
                    // Move the video to the appGroupBaseURL directory
                                    if let newURL = self.saveVideoToDocumentsDirectory(originalURL: url) {
                                        
                                        // Generate & Save Thumbnail
                                        if let thumbFileName = self.saveThumbnail(from: newURL) {
                                            
                                            // Save video metadata in Core Data
                                            self.saveVideoToCoreData(fileURL: newURL, thumbFileName: thumbFileName)
                                            
                                            DispatchQueue.main.async {
                                                self.exportedURL = newURL
                                                self.exportBgView.isHidden = true
                                            }
                                        }
                                    }
                }
                
            }) { (error) in
                DispatchQueue.main.async {
                    self.exportedURL = nil
                }
            }
        }
    }
    
//    private func saveVideoToDocumentsDirectory(originalURL: URL) -> URL? {
//        guard let destinationFolder = DirectoryManager.shared.appGroupBaseURL() else { return nil }
//        
//        let fileName = originalURL.lastPathComponent
//        let destinationURL = destinationFolder.appendingPathComponent(fileName)
//        
//        do {
//            if FileManager.default.fileExists(atPath: destinationURL.path) {
//                try FileManager.default.removeItem(at: destinationURL)
//            }
//            try FileManager.default.moveItem(at: originalURL, to: destinationURL)
//            return destinationURL
//        } catch {
//            print("Failed to move video file: \(error)")
//            return nil
//        }
//    }
//    
//    private func saveThumbnail(from videoURL: URL) -> String? {
//        guard let thumbnail = videoURL.generateThumbnail(),
//              let thumbFolder = DirectoryManager.shared.appGroupThumbBaseURL() else { return nil }
//
//        let fileName = videoURL.deletingPathExtension().lastPathComponent + ".jpg"
//        let destinationURL = thumbFolder.appendingPathComponent(fileName)
//        
//        if let imageData = thumbnail.jpegData(compressionQuality: 0.8) {
//            do {
//                try imageData.write(to: destinationURL)
//                return fileName  // Return the saved thumbnail filename
//            } catch {
//                print("Failed to save thumbnail: \(error)")
//            }
//        }
//        return nil
//    }
    
    private func saveVideoToDocumentsDirectory(originalURL: URL) -> URL? {
        guard let destinationFolder = DirectoryManager.shared.appGroupBaseURL() else {
            print("Failed to get appGroupBaseURL")
            return nil
        }
        
        let fileName = "Recording_\(AppData.recordingCount+1).mp4"
        let destinationURL = destinationFolder.appendingPathComponent(fileName)
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: originalURL, to: destinationURL)
            print("Video saved at: \(destinationURL)")
            return destinationURL
        } catch {
            print("Failed to move video file: \(error)")
            return nil
        }
    }

    private func saveThumbnail(from videoURL: URL) -> String? {
        guard let thumbnail = videoURL.generateThumbnail(),
              let thumbFolder = DirectoryManager.shared.appGroupThumbBaseURL() else {
            print("Failed to get thumbnail folder")
            return nil
        }

        let fileName = videoURL.deletingPathExtension().lastPathComponent + ".jpg"
        let destinationURL = thumbFolder.appendingPathComponent(fileName)
        
        if let imageData = thumbnail.jpegData(compressionQuality: 0.8) {
            do {
                try imageData.write(to: destinationURL)
                print("Thumbnail saved at: \(destinationURL)")
                return fileName  // Return just the filename
            } catch {
                print("Failed to save thumbnail: \(error)")
            }
        }
        return nil
    }



    private func saveVideoToCoreData(fileURL: URL) {
        let duration = AVURLAsset(url: fileURL).duration.seconds
        let tduration = duration
        let tsize = getFileSize(from: fileURL)
    }
    
    private func saveVideoToCoreData(fileURL: URL, thumbFileName: String?) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, h:mm:ss a"
        let dateString = dateFormatter.string(from: Date())

        let videoName = "Recording_\(AppData.recordingCount+1).mp4"
        
        let displayName = "Recording_\(AppData.recordingCount+1)"
        
        let vduration = AVURLAsset(url: fileURL).duration.seconds
        let vsize = getFileSize(from: fileURL)
        
        if let videoSaved = CoreDataManager.shared.createSavedVideo(displayName: displayName,name: videoName,size: vsize,type: "mp4",duration: vduration,thumbName: thumbFileName // Save thumbnail filename
        ){
            AppData.recordingCount += 1
        }
    }

    
    func getFileSize(from url: URL) -> String? {
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = fileAttributes[.size] as? Int64 {
                return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
            }
        } catch {
            print("Error getting file size: \(error)")
        }
        return nil
    }
    //NEW VIDEO VIEW
    private var videoView: VideoView = {
        let videoView = VideoView(frame: CGRect(x: 0, y: 0, width: 100, height: 100), viewType: .default)
        //videoView.translatesAutoresizingMaskIntoConstraints = false
        return videoView
    }()
    private var isPlaying = false
    private var videoConverter: VideoConverter?
    
    private func loadVideo(_ url: URL) {
        
        self.videoView = VideoView(frame: self.playerView.bounds, viewType: .default)
        self.playerView.addSubview(self.videoView)
        
        self.videoView.delegate = self
        
        self.videoView.url = url
        let asset = AVAsset(url: url)
        self.videoConverter = VideoConverter(asset: asset)
        
        
        if var video = self.video{
            video.asset = asset
            if let videoTime = video.videoTime{
                self.videoView.videoTime = videoTime
                if let player = videoView.player{
                    player.seek(to: videoTime.startTime ?? .zero, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
                    
                }
            }else{
                self.videoView.videoTime = VideoTime(startTime: .zero, endTime: asset.duration)
            }
            
            if let degree = self.video?.degrees{
                playerView.rotateVideo(degrees: CGFloat(degree))
            }
            
            if let videoComposition{
                videoView.videoComposition = videoComposition
            }
            
            videoView.speed = video.speed
            videoView.volume = video.volume
        }else{
            self.videoView.videoTime = VideoTime(startTime: .zero, endTime: asset.duration)
            if let degree = self.video?.degrees{
                playerView.rotateVideo(degrees: CGFloat(degree))
            }
        }
        
    }
    
    fileprivate func loadCleanVideo(_ videoURL: URL) {
        //
        
        self.player = AVPlayer(url: videoURL)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = playerView.layer.bounds
        playerLayer.videoGravity = .resizeAspect
        
        playerView.layer.addSublayer(playerLayer)
        
        guard let startTime = self.video?.videoTime?.startTime else { return }
        self.player?.seek(to: startTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        
        guard let item = self.player?.currentItem else { return }
        item.videoComposition = self.videoComposition
        
        if let degree = self.video?.degrees{
            playerView.rotateVideo(degrees: CGFloat(degree))
        }
        
        self.player?.volume = self.video?.volume ?? 1
    }
    
    @IBAction func dismiss(){
        //self.delegate?.dismissCropView()
        self.dismiss(animated: true)
    }
    @IBAction func returnHome(){
        
        DispatchQueue.main.async {
            if let delegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                delegate.setOnboardingAsRoot()
            }
        }
    }
}

extension ShareVC :UICollectionViewDataSource{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.shareArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! ShareCVCell
        
        let share = self.shareArray[indexPath.item]
        cell.imgView.contentMode = .scaleAspectFit
        
        if let sourceImage = UIImage(named: share.icon){
            cell.imgView.image = sourceImage
        }else{
            
        }
        cell.lbl.text = share.title
        return cell
    }
}

extension ShareVC :UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        switch indexPath.row {
        case 1:
            self.shareInstagramStory(self.exportedURL)
        case 2:
            self.shareInstagram(self.localId)
        case 3:
            self.shareSnapchat(self.exportedURL)
        case 4:
            self.shareFacebook(self.exportedURL)
            
        case 5:
            self.shareFacebookAll(self.localId)
        case 6:
            self.shareFacebookAll(self.localId)
        case 7:
            if let url = self.exportedURL{
                let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                self.present(activityViewController, animated: true, completion: nil)
            }
            
        default:
            self.delegate?.shareInstagramStory(self.exportedURL)
        }
    }
}

extension ShareVC :UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: 64, height: 77)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
}

extension ShareVC{
    
    func shareFacebookAll(videoAsset: PHAsset) {
        
        let video = ShareVideo(videoAsset: videoAsset)
        let content = ShareVideoContent()
        content.video = video
        // Optional
        /*content.hashtag = Hashtag("#MatrixSolution")
         content.quote = "MatrixSolution"
         content.contentURL = URL.init(string: "https://matrixsolution.xyz/")!*/
        let dialog = ShareDialog.init(fromViewController: self, content: content, delegate: self)
        // Recommended to validate before trying to display the dialog
        do {
            try dialog.validate()
        } catch {
            print(error)
        }
        
        DispatchQueue.main.async {
            dialog.show()
        }
    }
    
    func shareInstagram(_ localID: String?) {
        
        guard let localID = localID else { return }
        let url = URL(string: "instagram://library?LocalIdentifier=\(localID)")!
        guard UIApplication.shared.canOpenURL(url) else {
            // handle this error
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        
    }
    
    
    func shareInstagramStory(_ videoURL: URL?) {
        
        
        if let url = videoURL {
            
            do {
                
                let video = try Data(contentsOf: url)
                if let storiesUrl = URL(string: "instagram-stories://share") {
                    if UIApplication.shared.canOpenURL(storiesUrl) {
                        let pasteboardItems: [String: Any] = [
                            "com.instagram.sharedSticker.backgroundVideo": video,
                            "com.instagram.sharedSticker.backgroundTopColor": "#636e72",
                            "com.instagram.sharedSticker.backgroundBottomColor": "#b2bec3"
                        ]
                        let pasteboardOptions = [
                            UIPasteboard.OptionsKey.expirationDate: Date().addingTimeInterval(300)
                        ]
                        UIPasteboard.general.setItems([pasteboardItems], options: pasteboardOptions)
                        UIApplication.shared.open(storiesUrl, options: [:], completionHandler: nil)
                        // self.dismiss(animated: true, completion: nil)
                    } else {
                        print("Sorry the application is not installed")
                    }
                }
            } catch {
                print(error)
                return
            }
        }
        
    }
    
    func shareSnapchat(_ videoURL: URL?) {
        print("shareSnapchat")
        
        if isComeFromVideoToGifVC{
            if let url = self.exportGifURL{
                let photo = SCSDKSnapPhoto(imageUrl: url)
                let photoContent = SCSDKPhotoSnapContent(snapPhoto: photo)
                snapAPI.startSending(photoContent)
                return;
            }
            
        }
        
        guard let videoURL = videoURL else { return }
        let snapVideo = SCSDKSnapVideo(videoUrl: videoURL)
        let snapContent = SCSDKVideoSnapContent(snapVideo: snapVideo)
        
        // Send it over to Snapchat
        snapAPI.startSending(snapContent)
    }
    
    func shareTikTok(_ video: Video?) {
        print("shareTikTok")
    }
    
    func shareFB(_ assetURL: URL){

        if let url = self.exportGifURL{
            let photo = SharePhoto(imageURL: url, userGenerated: true)
            let content = SharePhotoContent()
            content.photos = [photo]
            let dialog = ShareDialog.init(fromViewController: self, content: content, delegate: self)
            // Recommended to validate before trying to display the dialog
            do {
                try dialog.validate()
            } catch {
                print(error)
            }
            
            DispatchQueue.main.async {
                dialog.show()
            }
            return
        }
        
        let video = ShareVideo(videoURL: assetURL)
        let content = ShareVideoContent()
        content.video = video
        // Optional
        /*content.hashtag = Hashtag("#MatrixSolution")
         content.quote = "MatrixSolution"
         content.contentURL = URL.init(string: "https://matrixsolution.xyz/")!*/
        let dialog = ShareDialog.init(fromViewController: self, content: content, delegate: self)
        // Recommended to validate before trying to display the dialog
        do {
            try dialog.validate()
        } catch {
            print(error)
        }
        
        DispatchQueue.main.async {
            dialog.show()
        }
        
    }
    func shareFacebookAll(_ localID: String?)
    {
        guard let localID = localID else { return }
        if let videoAsset = PHAsset.fetchAssets(withLocalIdentifiers: [localID], options: nil).firstObject{
            let video = ShareVideo(videoAsset: videoAsset)
            let content = ShareVideoContent()
            content.video = video
            // Optional
            /*content.hashtag = Hashtag("#MatrixSolution")
             content.quote = "MatrixSolution"
             content.contentURL = URL.init(string: "https://matrixsolution.xyz/")!*/
            let dialog = ShareDialog.init(fromViewController: self, content: content, delegate: self)
            // Recommended to validate before trying to display the dialog
            do {
                try dialog.validate()
            } catch {
                print(error)
            }
            
            DispatchQueue.main.async {
                dialog.show()
            }
        }
        
    }
    func shareFacebook(_ videoURL: URL?) {
        let appID = "YOUR_APP_ID"
        
        if let url = videoURL {
            if let videoData = try? Data.init(contentsOf: url) as Data {
                if let urlSchema = URL(string: "facebook-reels://share"){
                    if UIApplication.shared.canOpenURL(urlSchema) {
                        let pasteboardItems = [
                            ["com.facebook.sharedSticker.backgroundVideo": videoData],
                            ["com.facebook.sharedSticker.appID" : appID]
                        ];
                        let pasteboardOptions = [UIPasteboard.OptionsKey.expirationDate: Date().addingTimeInterval(60 * 5)];
                        
                        UIPasteboard.general.setItems(pasteboardItems, options: pasteboardOptions)
                        UIApplication.shared.open(urlSchema)
                    }
                }
            }
        }
        
    }
    
    func shareYoutube(_ video: Video?) {
        print("shareYoutube")
    }
    
    func shareMore(_ video: Video?) {
        print("shareMore")
    }
    
    func shareMoreShare(_ video: Video?) {
        print("shareMoreShare")
        if let video = video{
            if let url = video.videoURL {
                self.saveVideoToAlbum(url) { (error) in
                }
            }
        }
    }
    
    /// more share
    func requestAuthorization(completion: @escaping ()->Void) {
        if PHPhotoLibrary.authorizationStatus() == .notDetermined {
            PHPhotoLibrary.requestAuthorization { (status) in
                DispatchQueue.main.async {
                    completion()
                }
            }
        } else if PHPhotoLibrary.authorizationStatus() == .authorized{
            completion()
        }
    }
    
    func saveVideoToAlbum(_ outputURL: URL, _ completion: ((Error?) -> Void)?) {
        requestAuthorization {
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .video, fileURL: outputURL, options: nil)
            }) { (result, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        print(error.localizedDescription)
                    } else {
                        print("Saved successfully")
                    }
                    completion?(error)
                }
            }
        }
    }
}

extension ShareVC: SharingDelegate{
    func sharer(_ sharer: Sharing, didCompleteWithResults results: [String : Any]) {
        
    }
    
    func sharer(_ sharer: Sharing, didFailWithError error: Error) {
        
    }
    
    func sharerDidCancel(_ sharer: Sharing) {
        
    }
    
}

// MARK: ViewController + VideoDelegate
extension ShareVC: VideoDelegate {
    
    func videoFinishedFromVideoView() {
        self.videoView.pause()
        playPauseButton.isHidden = false
    }
    
    
    func videoPlaying() {
        
    }
}
