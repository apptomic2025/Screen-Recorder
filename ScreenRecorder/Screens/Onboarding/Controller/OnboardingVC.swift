//
//  OnboardingVC.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 17/3/25.
//

import UIKit
import AVFoundation
import AVKit
import Photos
import ReplayKit
import PhotosUI

class OnboardingVC: UIViewController {
    
    @IBOutlet weak var navbarView: UIView!
    @IBOutlet weak var consNavbarViewHeight: NSLayoutConstraint!
    @IBOutlet weak var toolsCollectionView: UICollectionView!{
        didSet{
            toolsCollectionView.showsHorizontalScrollIndicator = false
            toolsCollectionView.register(UINib.init(nibName: "ToolsCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ToolsCollectionViewCell")
            toolsCollectionView.delegate = self
            toolsCollectionView.dataSource = self
        }
    }
    @IBOutlet weak var consToolsViewHeight: NSLayoutConstraint!
    @IBOutlet weak var constoolsCollectionViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var myRecordCollectionView: UICollectionView!{
        didSet{
            let nib = UINib(nibName: "SRCVCell", bundle: nil)
            myRecordCollectionView.register(nib, forCellWithReuseIdentifier: "SRCVCell")
            myRecordCollectionView.delegate = self
            myRecordCollectionView.dataSource = self
        }
    }
    
    @IBOutlet weak var lblTools: UILabel!{
        didSet{
            self.lblTools.font = .appFont_CircularStd(type: .book, size: 15)
            self.lblTools.textColor = UIColor(hex: "#151517") 
        }
    }
    @IBOutlet weak var lblToolsSeeAll: UILabel!{
        didSet{
            self.lblToolsSeeAll.font = .appFont_CircularStd(type: .medium, size: 12)
            self.lblToolsSeeAll.textColor = UIColor(hex: "#151517")
        }
    }
    @IBOutlet weak var lblRecording: UILabel!{
        didSet{
            self.lblRecording.font = .appFont_CircularStd(type: .book, size: 15)
            self.lblRecording.textColor = UIColor(hex: "#151517")
        }
    }
    
    @IBOutlet weak var consResulationViewHeight: NSLayoutConstraint!
    @IBOutlet weak var consResulationStackViewHeight: NSLayoutConstraint!

    
    @IBOutlet weak var lblQualityValue: UILabel!{
        didSet{
            self.lblQualityValue.font = .appFont_CircularStd(type: .medium, size: 14)
        }
    }
    
    @IBOutlet weak var lblQuality: UILabel!{
        didSet{
            self.lblQuality.font = .appFont_CircularStd(type: .book, size: 12)
        }
    }
    
    @IBOutlet weak var lblFrameRateValue: UILabel!{
        didSet{
            self.lblFrameRateValue.font = .appFont_CircularStd(type: .medium, size: 14)
        }
    }
    
    @IBOutlet weak var lblFrameRate: UILabel!{
        didSet{
            self.lblFrameRate.font = .appFont_CircularStd(type: .book, size: 12)
        }
    }
    
    @IBOutlet weak var lblBitRateValue: UILabel!{
        didSet{
            self.lblBitRateValue.font = .appFont_CircularStd(type: .medium, size: 14)
        }
    }
    
    @IBOutlet weak var lblBitRate: UILabel!{
        didSet{
            self.lblBitRate.font = .appFont_CircularStd(type: .book, size: 12)
        }
    }

    @IBOutlet weak var btnToolsSeeAll: UIButton!{
        didSet{
            self.btnToolsSeeAll.addTarget(self, action: #selector(btnToolsSeeAllAction), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var lblTapToStart: UILabel!{
        didSet{
            self.lblTapToStart.font = .appFont_CircularStd(type: .bold, size: 36)
            self.lblTapToStart.textColor = UIColor(hex: "#151517")
        }
    }
    
    @IBOutlet weak var lblRecordingScreen: UILabel! {
        didSet {
            let fontSize: CGFloat = 14 // Your font size
            let letterSpacing = fontSize * 0.22 // 22% of font size
            
            let attributedString = NSAttributedString(
                string: lblRecordingScreen.text ?? "",
                attributes: [
                    .font: UIFont.appFont_CircularStd(type: .book, size: fontSize),
                    .foregroundColor: UIColor(hex: "#151517"),
                    .kern: letterSpacing
                ]
            )
            self.lblRecordingScreen.attributedText = attributedString
        }
    }
    
    @IBOutlet weak var lblMyRecordings: UILabel!{
        didSet{
            self.lblMyRecordings.font = .appFont_CircularStd(type: .book, size: 15)
            self.lblMyRecordings.textColor = UIColor(hex: "#151517")
        }
    }
    @IBOutlet weak var lblMyRecordingsSeeAll: UILabel!{
        didSet{
            self.lblMyRecordingsSeeAll.font = .appFont_CircularStd(type: .medium, size: 12)
            self.lblMyRecordingsSeeAll.textColor = UIColor(hex: "#151517")
        }
    }
    
    @IBOutlet weak var btnMyRecordingsSeeAll: UIButton!{
        didSet{
            self.btnMyRecordingsSeeAll.addTarget(self, action: #selector(btnMyRecordingsSeeAllAction), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var btnStartScreenRecord: UIButton!{
        didSet{
            self.btnStartScreenRecord.addTarget(self, action: #selector(btnStartScreenRecordAction), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var consScreenRecordHeight: NSLayoutConstraint!
    @IBOutlet weak var consScreenRecordWidth: NSLayoutConstraint!
    @IBOutlet weak var consScreenRecordTop: NSLayoutConstraint!
    @IBOutlet weak var consScreenRecordBottom: NSLayoutConstraint!
    @IBOutlet weak var consScreenRecordParentHeight: NSLayoutConstraint!
    @IBOutlet weak var exportView: UIView!{
        didSet{
            exportView.alpha = 0.0
        }
    }
    
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var consEmptyViewTop: NSLayoutConstraint!
    
    @IBOutlet weak var myRecordingView: UIView!{
        didSet{
            myRecordingView.alpha = 0.0
        }
    }
    
    @IBOutlet weak var btnSetting: UIButton!{
        didSet{
            self.btnSetting.addTarget(self, action: #selector(btnSettingAction), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var btnIAP: UIButton!{
        didSet{
            self.btnIAP.addTarget(self, action: #selector(btnIAPAction), for: .touchUpInside)
        }
    }
    
    let tools: [VideoTool] = [
        VideoTool(imageName: "live_broadcast", title: "Live Broadcast", action: .liveBroadcast, isPremium: true),
        VideoTool(imageName: "face_cam", title: "Face Cam", action: .faceCam, isPremium: false),
        VideoTool(imageName: "commentary", title: "Commentary", action: .commentary, isPremium: false),
        VideoTool(imageName: "gif_icon", title: "GIF Maker", action: .gifMaker, isPremium: false),
        VideoTool(imageName: "edit_icon", title: "Edit Video", action: .editVideo, isPremium: false),
        VideoTool(imageName: "voice_icon", title: "Voice Recorder", action: .voiceRecorder, isPremium: false),
        VideoTool(imageName: "video_to_photo", title: "Video to Photo", action: .videoToPhoto, isPremium: false),
        VideoTool(imageName: "video_to_audio", title: "Video to Audio", action: .videoToAudio, isPremium: false),
        VideoTool(imageName: "video_trimmer", title: "Video Trimmer", action: .videoTrimmer, isPremium: false),
        VideoTool(imageName: "video_compress", title: "Video Compress", action: .videoCompress, isPremium: false),
        VideoTool(imageName: "photo_to_video", title: "Photo to Video", action: .photoToVideo, isPremium: false),
        VideoTool(imageName: "video_speed", title: "Video Speed", action: .videoSpeed, isPremium: false),
        VideoTool(imageName: "crop_video", title: "Crop Video", action: .cropVideo, isPremium: false),
    ]
    
    var savedVideos: [SavedVideo] = [SavedVideo]()
    var broadcastPicker: RPSystemBroadcastPickerView?
    var observations: [NSObjectProtocol] = []
    private lazy var notificationCenter: NotificationCenter = .default
    var session: AVCaptureSession?
    enum SelectToolType: Int {
        case faceCam, commentary, gif, edit, voiceReocrd, photoToVideo,videoToPhoto, videoToAudio, trim, compress, speed, crop, extractAudio, none
    }

    var exportVC: ExportSettingsVC?
    var isFirstTimeLoaded = false
    private var selection = [String: PHPickerResult]()
    private var selectedAssetIdentifiers = [String]()
    private var selectedAssetIdentifierIterator: IndexingIterator<[String]>?
    private var currentAssetIdentifier: String?
    
    var selectedFrame: [UIImage] = []
    var recevedCount = 0
    var mediaItems: PickedMediaItems = PickedMediaItems()
    let share = DirectoryManager.shared
    let gifManager = GifManager.shared
    var selectToolType: SelectToolType = .none
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        AppData.isIntroFinished = true
        checkNotificationOfExtension()
        updateRecordingSettings()
        getNotificationPermissionState { state in
            if state == .notAsked{
                askNotificationPermission()
            }
        }
                
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            askNotificationPermission()
        }
        
        observations.append(
            notificationCenter.addObserver(
                forName: VIDEO_SAVED_NOTIFICATION,
                object: nil,
                queue: nil
            ) { [weak self] _ in
                self?.handleRecordedVideo()
            }
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadVideo()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //observations.forEach(notificationCenter.removeObserver(_:))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !isFirstTimeLoaded{
            isFirstTimeLoaded = true
            if let exportVC = loadVCfromStoryBoard(name: "Export", identifier: "ExportSettingsVC") as? ExportSettingsVC{
                exportVC.type = .screenRecord
                self.exportVC = exportVC
                self.exportVC?.delegate = self
                self.add(exportVC, contentView: exportView)
            }
            self.uiSetupForDeviceCompatibility()
        }
    }
    
    func uiSetupForDeviceCompatibility(){
        let uiType = getDeviceUIType()
        switch uiType {
        case .dynamicIsland:
            print("Device has Dynamic Island")
            self.consNavbarViewHeight.constant = NavbarHeight.withDynamicIsland.rawValue
        case .notch:
            print("Device has a Notch")
            self.consNavbarViewHeight.constant = NavbarHeight.withNotch.rawValue
        case .noNotch:
            print("Device has no Notch")
            self.consNavbarViewHeight.constant = NavbarHeight.withOutNotch.rawValue
        }
        
        let originalViewHeight: CGFloat = 120
        let responsiveHeight = scaledHeight(for: originalViewHeight)
        self.constoolsCollectionViewHeight.constant = responsiveHeight
        self.consToolsViewHeight.constant = responsiveHeight + 44
        
        let resulationStackViewHeight: CGFloat = 65
        let responsiveStackViewHeight = scaledHeight(for: resulationStackViewHeight)
        self.consResulationStackViewHeight.constant = responsiveStackViewHeight
        self.consResulationViewHeight.constant = responsiveStackViewHeight + 28
        
        let screenRecordTopBottom: CGFloat = 70
        let responsiveScreenRecordTopBottom = scaledHeight(for: screenRecordTopBottom)
        self.consScreenRecordTop.constant = responsiveScreenRecordTopBottom
        self.consScreenRecordBottom.constant = responsiveScreenRecordTopBottom
        
        let screenRecordHeight: CGFloat = 183
        let responsivescreenRecordHeight = scaledHeight(for: screenRecordHeight)
        self.consScreenRecordHeight.constant = responsivescreenRecordHeight
        
        let ScreenRecordWidth: CGFloat = 182
        let responsiveScreenRecordWidth = scaledHeight(for: ScreenRecordWidth)
        self.consScreenRecordWidth.constant = responsiveScreenRecordWidth
        
        let ScreenRecordParentHeight: CGFloat = 256
        let responsiveScreenRecordParentHeight = scaledHeight(for: ScreenRecordParentHeight)
        self.consScreenRecordParentHeight.constant = responsiveScreenRecordParentHeight
        
        let EmptyViewTop: CGFloat = 50
        let responsiveEmptyViewTop = scaledHeight(for: EmptyViewTop)
        self.consEmptyViewTop.constant = responsiveEmptyViewTop
    }
    
    func loadVideo() {
        self.savedVideos = CoreDataManager.shared.fetchSavedVideos()
        
        if self.savedVideos.count > 0 {
            self.myRecordingView.alpha = 1.0
            self.emptyView.alpha = 0.0
        }else{
            self.myRecordingView.alpha = 0.0
            self.emptyView.alpha = 1.0
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.myRecordCollectionView.reloadData()
        }
    }
    
    private func updateRecordingSettings(){
        updateActiveResoulationView()
        updateActiveBitrateView()
        updateActiveFramerateView()
    }
    private func updateActiveResoulationView(){
        let resoulation = AppData.resolution
        if resoulation == 3840{
            lblQualityValue.text = "4k (UHD)"
        }else if (resoulation == 1080 || resoulation == 7200){
            lblQualityValue.text = "\(resoulation)p (FHD)"
        }else{
            lblQualityValue.text = "\(resoulation)p (SD)"
            
        }
       
    }
    
    private func updateActiveBitrateView(){
                
        let bitrate = AppData.bitrate
        lblBitRateValue.text = "\(bitrate) Mbps"
    }
    
    private func updateActiveFramerateView(){
                
        let bitrate = AppData.framerate
        lblFrameRateValue.text = "\(bitrate)Fps"
    }

    
    func checkNotificationOfExtension() {
        let darwinNotificationName = "com.samar.videoSaved" as CFString
        let darwinNotificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
        
        CFNotificationCenterAddObserver(darwinNotificationCenter,
                                        nil,
                                        { (
                                            center: CFNotificationCenter?,
                                            observer: UnsafeMutableRawPointer?,
                                            name: CFNotificationName?,
                                            object: UnsafeRawPointer?,
                                            userInfo: CFDictionary?
                                            
                                        ) in
            
            
            NotificationCenter.default.post(name: VIDEO_SAVED_NOTIFICATION, object: nil)
        },darwinNotificationName, nil,CFNotificationSuspensionBehavior.deliverImmediately)
    }
    
    private func handleRecordedVideo() {

            
            if let lastVideoName = AppData.lastRecordedVideo{
                let displayName = "Recording_\(AppData.recordingCount+1)"

                if let video = CoreDataManager.shared.createSavedVideo(displayName: displayName, name: lastVideoName){
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
                                            
                    
                                            let vc = loadVCfromStoryBoard(name: "Editor", identifier: "EditorViewController") as! EditorVC
                                            if let name = video.name {
                                                guard let documentsDirectoryPath = DirectoryManager.shared.appGroupBaseURL()?.appendingPathComponent(name) else { return }
                                                let video = Video(documentsDirectoryPath)
                                                vc.video = video
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now()+1.0){
                                                self.navigationController?.pushViewController(vc, animated: true)
                                            }
                                
                                        }
                                    } catch {
                                        debugPrint("img saving failed")
                                    }
                                    
                                }
                            }
                        }
                    }
                }
                
            }else{
                let alertVC = UIAlertController(title: "Alert", message: "no video found", preferredStyle: .alert)
                self.present(alertVC, animated: true) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        alertVC.dismiss(animated: true, completion: nil)
                    }
                }
            }
            
        
        
    }
    
    private func presentPicker(type: Bool?=nil) {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        
        // Set the filter type according to the user’s selection.
        if type != nil {
            configuration.filter = .any(of: [.images])
        }else{
            configuration.filter = .any(of: [.videos])
        }
        // configuration.filter = .any(of: [.videos])
        // Set the mode to avoid transcoding, if possible, if your app supports arbitrary image/video encodings.
        configuration.preferredAssetRepresentationMode = .current
        // Set the selection behavior to respect the user’s selection order.
        //configuration.selection = .ordered
        // Set the selection limit to enable multiselection.
        if type != nil {
            configuration.selectionLimit = 90
        }else{
            configuration.selectionLimit = 1
        }
        // configuration.selectionLimit = 1
        // Set the preselected asset identifiers with the identifiers that the app tracks.
        //configuration.preselectedAssetIdentifiers = selectedAssetIdentifiers
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.overrideUserInterfaceStyle = .light
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true)
    }
    func presentPHpicker(selectToolType: SelectToolType){
        var titleText = ""
        var messageText = ""
        if selectToolType == .gif {
            titleText = "Video to GIF"
        }else if selectToolType == .edit {
            titleText = "Video Edit"
        }else if selectToolType == .voiceReocrd {
            titleText = "Voice Recorder"
        }else if selectToolType == .videoToPhoto {
            titleText = "Video to Photo"
        }else if selectToolType == .videoToAudio {
            titleText = "Video to Audio"
        }else if selectToolType == .trim {
            titleText = "Video Trimmer"
        }else if selectToolType == .compress {
            titleText = "Video Compress"
        }else if selectToolType == .photoToVideo {
            titleText = "Photo to Video"
        }else if selectToolType == .speed {
            titleText = "Video Speed"
        }else if selectToolType == .crop {
            titleText = "Crop Video"
        }
        
        let actionsheet = UIAlertController(title: titleText, message: "Select a video source from previous Recordings, Gallery", preferredStyle: .actionSheet)
        actionsheet.overrideUserInterfaceStyle = .light
        actionsheet.addAction(UIAlertAction(title: "Gallery", style: .default , handler:{ (UIAlertAction)in
            self.presentPicker()
        }))
            
        actionsheet.addAction(UIAlertAction(title: "Recordings", style: .default , handler:{ (UIAlertAction)in
            if let vc = loadVCfromStoryBoard(name: "MyRecord", identifier: "MyRecordVC") as? MyRecordVC{
                
                if selectToolType  == .faceCam {
                    vc.selectToolType = .faceCam
                    
                }else if selectToolType == .commentary{
                    vc.selectToolType = .commentary
                    
                }else if selectToolType == .gif {
                    vc.selectToolType = .gif

                }else if selectToolType == .edit {
                    vc.selectToolType = .edit

                }else if selectToolType == .voiceReocrd {
                    vc.selectToolType = .voiceReocrd

                }else if selectToolType == .videoToPhoto {
                    vc.selectToolType = .videoToPhoto

                }else if selectToolType == .videoToAudio {
                    vc.selectToolType = .videoToPhoto

                }else if selectToolType == .trim {
                    vc.selectToolType = .trim
                    
                }else if selectToolType == .compress {
                    vc.selectToolType = .compress

                }else if selectToolType == .photoToVideo {
                    vc.selectToolType = .photoToVideo

                }else if selectToolType == .speed {
                    vc.selectToolType = .speed

                }else if selectToolType == .crop {
                    vc.selectToolType = .crop
                }
                DispatchQueue.main.async {
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }))
        
        actionsheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ (UIAlertAction)in
                print("User click Dismiss button")
        }))
        self.present(actionsheet, animated: true)
    }

    
    func CollectionViewDidSelectAction(videoToolAction: VideoToolAction) {
        switch videoToolAction {
            
        case .liveBroadcast:
            print("Live Broadcast selected")
            let vc = loadVCfromStoryBoard(name: "Broadcast", identifier: "BroadCastVC") as! BroadCastVC
            self.navigationController?.pushViewController(vc, animated: true)
            
        case .faceCam:
            print("Face Cam selected")
            selectToolType = .faceCam
            let actionsheet = UIAlertController(title: "Select video source", message: "React to videos from Screen Recorder Camera Roll or YouTube", preferredStyle: .actionSheet)
            
            actionsheet.addAction(UIAlertAction(title: "My Recordings", style: .default , handler:{ (UIAlertAction)in
                self.gotToMyVideos(isComeFaceCam: true)
            }))
                
            actionsheet.addAction(UIAlertAction(title: "Camera Roll", style: .default , handler:{ (UIAlertAction)in
                self.selectToolType = .faceCam
                self.presentPicker()
            }))

            actionsheet.addAction(UIAlertAction(title: "React to Youtube", style: .default , handler:{ (UIAlertAction)in
                self.goToSearchVideoVC()
            }))
            
            actionsheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ (UIAlertAction)in
                    print("User click Dismiss button")
            }))
            self.present(actionsheet, animated: true)
            
        case .commentary:
            print("Commentary selected")
            let actionsheet = UIAlertController(title: "Select video source", message: "Add commentary to videos from Screen Recorder or Camera Roll", preferredStyle: .actionSheet)
            
            actionsheet.addAction(UIAlertAction(title: "My Recordings", style: .default , handler:{ (UIAlertAction)in
                self.gotToMyVideos(isComeCommentary: true)
            }))
                
            actionsheet.addAction(UIAlertAction(title: "Camera Roll", style: .default , handler:{ (UIAlertAction)in
                self.selectToolType = .commentary
                self.presentPicker()
            }))
            
            actionsheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ (UIAlertAction)in
                    print("User click Dismiss button")
            }))
            self.present(actionsheet, animated: true)
            
        case .gifMaker:
            print("GIF Maker selected")
            let actionsheet = UIAlertController(title: "Video to GIF", message: "Select a video source and react to videos from previous Recordings, Gallery or Youtube", preferredStyle: .actionSheet)
            
            actionsheet.addAction(UIAlertAction(title: "Gallery", style: .default , handler:{ (UIAlertAction)in
                self.selectToolType = .gif
                self.presentPicker()
            }))
                
            actionsheet.addAction(UIAlertAction(title: "Recordings", style: .default , handler:{ (UIAlertAction)in
        
                if let vc = loadVCfromStoryBoard(name: "MyRecord", identifier: "MyRecordVC") as? MyRecordVC{
                    vc.selectToolType = .gif
                    vc.modalPresentationStyle = .fullScreen
                    self.navigationController?.pushViewController(vc, animated: true)
                }

            }))
            
            actionsheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ (UIAlertAction)in
                    print("User click Dismiss button")
            }))
            self.present(actionsheet, animated: true)
            
        case .editVideo:
            print("Edit Video selected")
            selectToolType = .edit
            self.presentPicker()
        case .voiceRecorder:
            print("Voice Recorder selected")
            self.gotoVoiceRecordVC()
        case .videoToPhoto:
            print("Video to Photo selected")
            selectToolType = .videoToPhoto
            presentPHpicker(selectToolType: .videoToPhoto)
        case .videoToAudio:
            print("Video to Audio selected")
            selectToolType = .extractAudio
            self.goToExtractMusicVC()
        case .videoTrimmer:
            print("Video Trimmer selected")
            self.selectToolType = .trim
            presentPHpicker(selectToolType: .trim)
        case .videoCompress:
            print("Video Compress selected")
            selectToolType = .compress
            presentPHpicker(selectToolType: .compress)
        case .photoToVideo:
            print("Photo to Video selected")
            selectToolType = .photoToVideo
            presentPicker(type: true)
        case .videoSpeed:
            print("Video Speed selected")
            selectToolType = .speed
            presentPHpicker(selectToolType: .speed)
        case .cropVideo:
            print("Crop Video selected")
            selectToolType = .crop
            presentPHpicker(selectToolType: .crop)
        }
    }
    
    @objc func btnToolsSeeAllAction(){
        
                let vc = loadVCfromStoryBoard(name: "VideoTools", identifier: "VideoToolsViewController") as! VideoToolsViewController
                self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    
    @objc func btnMyRecordingsSeeAllAction(){
        
        if let vc = loadVCfromStoryBoard(name: "MyRecord", identifier: "MyRecordVC") as? MyRecordVC{
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
    }
    
    @objc func btnStartScreenRecordAction(){
        let pickerView = RPSystemBroadcastPickerView()
        //pickerView.preferredExtension = "com.appnotrix.SR.broadcastUpload"
        pickerView.preferredExtension = "com.samar.screenrecorder.BroadcastUpload"
        
        let buttonPressed = NSSelectorFromString("buttonPressed:")
        if pickerView.responds(to: buttonPressed) {
            pickerView.perform(buttonPressed, with: nil)
        }
        pickerView.showsMicrophoneButton = true
    }
    
    @objc func btnSettingAction(){
        if let vc = loadVCfromStoryBoard(name: "Settings", identifier: "SettingsViewController") as? SettingsViewController{
            let navVC = LightNavVC(rootViewController: vc)
            navVC.modalPresentationStyle = .fullScreen
            self.present(navVC, animated: true)
        }
    }
    
    @objc func btnIAPAction(){
        hepticFeedBack()
        if let iapViewController = loadVCfromStoryBoard(name: "IAP", identifier: "IAPVC") as? IAPVC{
            iapViewController.modalPresentationStyle = .fullScreen
            self.present(iapViewController, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func btnExportSettingTapped(_ sender: UIButton) {
        self.goToExportVC(tag: sender.tag)
    }
    
    
}

extension OnboardingVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case toolsCollectionView:
            return self.tools.count
        case myRecordCollectionView:
            return self.savedVideos.count
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch collectionView {
        case toolsCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ToolsCollectionViewCell", for: indexPath) as! ToolsCollectionViewCell
            let tool = tools[indexPath.item] // Get VideoTool from your data array
            cell.videoTool = tool // Assign it to the cell
            return cell
        case myRecordCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SRCVCell", for: indexPath) as! SRCVCell
            
            //load thumb image
            if let fileName = savedVideos[indexPath.row].thumbName, let url = DirectoryManager.shared.appGroupThumbBaseURL()?.appendingPathComponent(fileName){
                cell.fileThumbnailImgView.image = UIImage(contentsOfFile: url.path)
            }else{
                
                // do not taste with this code
                //keep it diable
                //generating image in cell for row is very bad practice
                
     /*           if let fileName = savedVideos[indexPath.row].name, let url = DirectoryManager.shared.appGroupBaseURL()?.appendingPathComponent(fileName), let img = generateThumbnail(url: url){
                    cell.fileThumbnailImgView.image = img
                }else{
                    cell.fileThumbnailImgView.image = UIImage(named: "")
                }*/
                
            }
            
            cell.video = self.savedVideos[indexPath.item]
//            cell.moreButton.addTarget(self, action: #selector(moreButtonAction), for: .touchUpInside)
//            cell.moreBigButton.addTarget(self, action: #selector(moreButtonAction), for: .touchUpInside)
            return cell
        default:
            return UICollectionViewCell()
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.CollectionViewDidSelectAction(videoToolAction: tools[indexPath.item].action)
    }
    
    //Cell size
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        switch collectionView {
        case toolsCollectionView:
            return CGSize(width: self.toolsCollectionView.bounds.height , height: self.toolsCollectionView.bounds.height)
        case myRecordCollectionView:
            let w = (DEVICE_WIDTH - 40) / 2
            let h = (285 * w)/170
            return CGSize(width: w - 5, height: h - 50)
        default:
            return CGSize(width: 0 , height: 0)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }
    
    // section space
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
      
        switch collectionView {
        case toolsCollectionView:
            return 8
        case myRecordCollectionView:
            return 20
        default:
            return 0
        }
        
    }
    
}

extension OnboardingVC: PHPickerViewControllerDelegate {
    /// - Tag: ParsePickerResults
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        
        //let existingSelection = self.selection
        
        var newSelection = [String: PHPickerResult]()
        for result in results {
            let identifier = result.assetIdentifier!
            newSelection[identifier] = result
        }
        
        // Track the selection in case the user deselects it later.
        selection = newSelection
        selectedAssetIdentifiers = results.map(\.assetIdentifier!)
        selectedAssetIdentifierIterator = selectedAssetIdentifiers.makeIterator()
        
        if selection.isEmpty {
            //displayEmptyImage()
        } else {
            displayNext()
        }
    }
}

private extension OnboardingVC {
    
    /// - Tag: LoadItemProvider
    func displayNext() {
        
        self.mediaItems.deleteAll()
        recevedCount = 0
        
        DispatchQueue.main.async {
            showLoader(view: self.view)
        }
        
        while let assetIdentifier = selectedAssetIdentifierIterator?.next() {
            print(assetIdentifier)
            
            //guard let assetIdentifier = selectedAssetIdentifierIterator?.next() else { return }
            currentAssetIdentifier = assetIdentifier
            
            let progress: Progress?
            let itemProvider = selection[assetIdentifier]!.itemProvider
            if itemProvider.canLoadObject(ofClass: PHLivePhoto.self) {
                progress = itemProvider.loadObject(ofClass: PHLivePhoto.self) { [weak self] livePhoto, error in
                    DispatchQueue.main.async {
                        self?.handleCompletion(assetIdentifier: assetIdentifier, object: livePhoto, error: error)
                    }
                }
            }
            else if itemProvider.canLoadObject(ofClass: UIImage.self) {
                progress = itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    DispatchQueue.main.async {
                        self?.handleCompletion(assetIdentifier: assetIdentifier, object: image, error: error)
                    }
                }
            } else if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                progress = itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    
                    guard let url = url else { return }
                    
                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                    guard let targetURL = documentsDirectory?.appendingPathComponent(url.lastPathComponent) else { return }
                    
                    do {
                        if FileManager.default.fileExists(atPath: targetURL.path) {
                            try FileManager.default.removeItem(at: targetURL)
                        }
                        
                        try FileManager.default.copyItem(at: url, to: targetURL)
                        
                        DispatchQueue.main.async {
                            self.handleCompletion(assetIdentifier: assetIdentifier, object: targetURL)
                        }
                        
                    } catch {
                        print(error.localizedDescription)
                        DispatchQueue.main.async {
                            self.handleCompletion(assetIdentifier: assetIdentifier, object: nil, error: error)
                        }
                    }
                }
            } else {
                progress = nil
                DispatchQueue.main.async {
                    dismissLoader()
                }
            }
            
            displayProgress(progress)
        }
    }
    
    func displayProgress(_ progress: Progress?) {
        //debugPrint(progress)
//        progressView.observedProgress = progress
//        progressView.isHidden = progress == nil
    }
    
    
    func handleCompletion(assetIdentifier: String, object: Any?, error: Error? = nil) {
        
        if let livePhoto = object as? PHLivePhoto {
            //displayLivePhoto(livePhoto)
            recevedCount += 1
            self.mediaItems.append(item: PhotoPickerModel(with: livePhoto))
        } else if let image = object as? UIImage {
            //displayImage(image)
            recevedCount += 1
            //self.mediaItems.append(item: PhotoPickerModel(with: image))
            
            if let pickedImage = object as? UIImage {
                selectedFrame.append(pickedImage)
            }
            
        } else if let url = object as? URL {
            //displayVideoPlayButton(forURL: url)
            recevedCount += 1
            self.mediaItems.append(item: PhotoPickerModel(with: url))
            
        } else if let error = error {
            recevedCount += 1
        }
        
        if recevedCount == selection.count{
            
            if selectToolType == .photoToVideo {
                self.gotoPhotoToVideo(imageArr: selectedFrame)
                self.mediaItems.deleteAll()
            }else{
                
                DispatchQueue.main.async {
                    //self.progressView.isHidden = true
                    dismissLoader()
                }
            }
            
            if let url = self.mediaItems.items.first?.url {
                
                switch selectToolType{
                case .commentary:
                    self.goToCommentaryVC(videoUrl: url)
                    break
                case .gif:
                    gotToVideoToGifVC(videoURL: url)
                    break
                case .edit:
                    gotoVideoEditor(videoUrl: url)
                    break
                case .voiceReocrd:
                    break
                case .photoToVideo:
                    
                    break
                case .videoToPhoto:
                    self.goToVideoToPhotoVC(videoUrl: url)
                    break
                case .videoToAudio:
                    break
                case .trim:
                     gotToTrimVC(videoUrl: url)
                case .compress:
                    self.gotoCompressVC(videoUrl: url)
                    break
                case .speed:
                    gotToSpeedVC(videoUrl: url)
                    break
                case .crop:
                    gotoCropVC(videoUrl: url)
                    break
                case .extractAudio:
                    break
                case .none:
                    break
                case .faceCam:
                    goToFaceCamVC(videoUrl: url)
                    break
                }
                
            }
        }
    }
    
    func gotToTrimVC(videoUrl: URL){
        
        if let vc = loadVCfromStoryBoard(name: "Trim", identifier: "TrimVC") as? TrimVC{
            let video = Video(videoUrl)
            vc.video = video
            DispatchQueue.main.async{
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func gotToMyVideos(isComeFaceCam: Bool? = false, isComeCommentary: Bool? = false) {
        
        if let vc = loadVCfromStoryBoard(name: "MyRecord", identifier: "MyRecordVC") as? MyRecordVC{
            vc.modalPresentationStyle = .fullScreen
            vc.isComeFromFaceCam = isComeFaceCam ?? false
            vc.isComeCommentary = isComeCommentary ?? false
            DispatchQueue.main.async{
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func goToSearchVideoVC() {
        let vc = loadVCfromStoryBoard(name: "ReactToYoutube", identifier: "SearchVideoViewController") as! SearchVideoViewController
        vc.modalPresentationStyle = .fullScreen
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func goToFaceCamVC(videoUrl: URL) {
        DispatchQueue.main.async {
            //self.progressView.isHidden = true
            dismissLoader()
            let vc = loadVCfromStoryBoard(name: "FaceCam", identifier: "FaceCamViewController") as! FaceCamViewController
            let video = Video(videoUrl)
            vc.video = video
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
    }
    
    func goToCommentaryVC(videoUrl: URL) {
        DispatchQueue.main.async {
            //self.progressView.isHidden = true
            dismissLoader()
            let vc = loadVCfromStoryBoard(name: "Commentary", identifier: "CommentaryViewController") as! CommentaryViewController
            let video = Video(videoUrl)
            vc.video = video
            vc.isComeFromCommentaruy = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func gotToVideoToGifVC(videoURL: URL) {
        dismissLoader()
        let vc = loadVCfromStoryBoard(name: "VideoToGIF", identifier: "VideoToGIFViewController") as! VideoToGIFViewController
        let video = Video(videoURL)
        vc.video = video
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func gotoVideoEditor(videoUrl: URL){
        
        if let vc = loadVCfromStoryBoard(name: "Editor", identifier: "EditorViewController") as? EditorVC {
          
            let video = Video(videoUrl)
            if let img = videoUrl.generateThumbnail(){
                video.videoThumb = img
            }
            vc.video = video
            DispatchQueue.main.async{
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func gotoVoiceRecordVC(){
        
//        if !AppData.premiumUser{
//            if let iapViewController = loadVCfromStoryBoard(name: "IAP", identifier: "IAPViewController") as? IAPViewController{
//                //iapViewController.delegate = self
//                iapViewController.modalPresentationStyle = .fullScreen
//                self.present(iapViewController, animated: true, completion: nil)
//            }
//            return
//        }
        
        if let vc = loadVCfromStoryBoard(name: "VoiceRecord", identifier: "VoiceRecordViewController") as? VoiceRecordViewController{
            DispatchQueue.main.async{
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func goToVideoToPhotoVC(videoUrl: URL){
        if let vc = loadVCfromStoryBoard(name: "VideoToPhoto", identifier: "VideoToPhotoViewController") as? VideoToPhotoViewController{
            let video = Video(videoUrl)
            vc.video = video
            DispatchQueue.main.async{
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func goToExtractMusicVC(){
//        if !AppData.premiumUser{
//            if let iapViewController = loadVCfromStoryBoard(name: "IAP", identifier: "IAPViewController") as? IAPViewController{
//                //iapViewController.delegate = self
//                iapViewController.modalPresentationStyle = .fullScreen
//                self.present(iapViewController, animated: true, completion: nil)
//            }
//            return
//        }
        
        if let vc = loadVCfromStoryBoard(name: "VideoToAudio", identifier: "ExtractMusicViewController") as? ExtractMusicViewController{
            DispatchQueue.main.async{
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func gotoCompressVC(videoUrl: URL){
        if let vc = loadVCfromStoryBoard(name: "VideoCompress", identifier: "VideoCompressViewController") as? VideoCompressViewController{
            let video = Video(videoUrl)
            vc.video = video
            exportVC?.video = video

            DispatchQueue.main.async{
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func gotoPhotoToVideo(imageArr: [UIImage]) {
        
        guard let songURL = Bundle.main.url(forResource: "Happy Day", withExtension: "mp3") else { return }
        
        GifManager.shared.makeSlideShowVideo(audioURL: songURL, images: imageArr, frameTransition: .none) { videoURL in
            
            if let vc = loadVCfromStoryBoard(name: "PhotoToVideo", identifier: "PhotoToVideoViewController") as? PhotoToVideoViewController{
                let video = Video(videoURL)
                vc.video = video
                vc.selectedPhoto = imageArr
                DispatchQueue.main.async{
                    self.navigationController?.pushViewController(vc, animated: true)
                    dismissLoader()
                }
            }
        }
    }
    
    func gotToSpeedVC(videoUrl: URL){
        if let vc = loadVCfromStoryBoard(name: "Speed", identifier: "SpeedViewController") as? SpeedViewController{
            let video = Video(videoUrl)
            vc.video = video
            DispatchQueue.main.async{
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func gotoCropVC(videoUrl: URL){
        if let vc = loadVCfromStoryBoard(name: "Crop", identifier: "CropViewController") as? CropViewController{
            let video = Video(videoUrl)
            vc.video = video
            DispatchQueue.main.async{
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func goToExportVC(tag: Int) {
        
//        exportVC?.mainContentViewBottomContraint.constant = 0
//        UIView.animate(withDuration: 0.3) {
//            self.exportView.alpha = 1.0
//            self.view.layoutIfNeeded()
//        }
       
        guard let vc = UIStoryboard(name: "ExportBottomSheet", bundle: nil).instantiateViewController(identifier: "ExportBottomSheet") as? ExportBottomSheetVC else{ return }
        
        vc.dismissCompletion = { [weak self] in
            guard let self = self else { return }
            print("Popup dismissed!")
            self.updateRecordingSettings()
        }
        
        switch tag {
        case 1:
            vc.optionMode = .resolution
        case 2:
            vc.optionMode = .bitRate
        case 3:
            vc.optionMode = .frameRate
        default:
            break
        }
        
        if #available(iOS 16.0, *) {
            
            if let sheet = vc.sheetPresentationController {
                sheet.prefersGrabberVisible = false
                sheet.preferredCornerRadius = CGFloat(16)
                sheet.detents = [.custom{ _ in
                    var pageDetent = 299
                    switch tag {
                    case 1:
                        pageDetent = 299
                    case 2:
                        pageDetent = 449
                    case 3:
                        pageDetent = 299
                    default:
                        break
                    }

                    return CGFloat(pageDetent)
                    }]
            }
        }
        
        else {
            self.viewDisappearAnimation()
            vc.dismissCompletion = {
                self.viewAppearAnimation()
            }
            vc.modalPresentationStyle = .overCurrentContext
            self.viewDisappearAnimation()
            vc.dismissCompletion = {
                self.viewAppearAnimation()
            }
        }
        
        self.present(vc, animated: true)
        
    }

}

extension OnboardingVC: ExportDelegate {
    
    func exportClicked(_ video: Video?) {
        UIView.animate(withDuration: 0.5) {
            self.exportView.alpha = 0
        }
    }
    
    func dismissExportVC() {
        UIView.animate(withDuration: 0.5) {
            self.exportView.alpha = 0
        }
    }
    
    func exportOptionChoosed(_ pixel: Int?, bitRate: Int?, frameRate: Int?) {
        if let pixel{
            debugPrint(pixel)
            self.updateActiveResoulationView()
        }
        if let bitRate{
            debugPrint(bitRate)
            self.updateActiveBitrateView()
        }
        if let frameRate{
            debugPrint(frameRate)
            self.updateActiveFramerateView()
        }
    }
}
