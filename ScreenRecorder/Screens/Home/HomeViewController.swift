

import UIKit
import Photos
import ReplayKit
import PhotosUI

//MARK: -> Recording settings Demo Model for check ===================
struct RecordingSettingsModel {
    var resolution: String
    var fileSize: String
    var frameRate: String
    var rotation: String
}

class HomeViewController: UIViewController {
    
    var isFirstTimeLoaded = false
    var savedVideos: [SavedVideo] = [SavedVideo]()
    var broadcastPicker: RPSystemBroadcastPickerView?
    var observations: [NSObjectProtocol] = []
    private lazy var notificationCenter: NotificationCenter = .default
    var session: AVCaptureSession?
    enum SelectToolType: Int {
        case faceCam, commentary, gif, edit, voiceReocrd, photoToVideo,videoToPhoto, videoToAudio, trim, compress, speed, crop, extractAudio, none
    }

    var exportVC: ExportSettingsVC?
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

    //MARK: -> Demo Model Set===============
    var recordingSettings: RecordingSettingsModel = RecordingSettingsModel(resolution: "720p", fileSize: "12Mbps", frameRate: "60fps", rotation: "Auto")
    
    //var dummyDataCount: Int = 20
    
    @IBOutlet weak var exportView: UIView!{
        didSet{
            exportView.alpha = 0.0
        }
    }
    @IBOutlet weak var imgBottomShade: UIImageView!
    @IBOutlet weak var imgThumbBottom: UIImageView!
    @IBOutlet weak var collectionForScroll: UICollectionView!{
        didSet{
            collectionForScroll.delegate = self
            collectionForScroll.dataSource = self
            collectionForScroll.register(Section1CVCell.nib(), forCellWithReuseIdentifier: Section1CVCell.identifier)
            collectionForScroll.register(HeaderCVCell.nib(), forCellWithReuseIdentifier: HeaderCVCell.identifier)
            collectionForScroll.register(RecordsCVCell.nib(), forCellWithReuseIdentifier: RecordsCVCell.identifier)
            if UIScreen.main.bounds.height <= 736 {
                collectionForScroll.contentInset = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
            } else {
                collectionForScroll.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
            }
        }
    }
    @IBOutlet weak var cnstBottomImgSec: NSLayoutConstraint!
    
    //MARK: - LIFE CYCLE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialLoad()
        
        if UIScreen.main.bounds.height == 667 {
            cnstBottomImgSec.constant = -55
        } else if UIScreen.main.bounds.height == 812 {
            cnstBottomImgSec.constant = -45
        } else if UIScreen.main.bounds.height == 852 {
            cnstBottomImgSec.constant = -45
        }
        
        collectionForScroll.reloadData()
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
            
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadVideo()
        
        if savedVideos.count != 0 {
            self.imgBottomShade.isHidden = true
            self.imgThumbBottom.isHidden = true
        }
    }

}

extension HomeViewController{
    
    private func updateRecordingSettings(){
        
        let resoulation = AppData.resolution
        if resoulation == 3840{
            //lblQualityValue.text = "4k (UHD)"
            self.recordingSettings.resolution = "4k (UHD)"
        }else if (resoulation == 1080 || resoulation == 7200){
            //lblQualityValue.text = "\(resoulation)p (FHD)"
            self.recordingSettings.resolution = "\(resoulation)p (FHD)"
        }else{
            //lblQualityValue.text = "\(resoulation)p (SD)"
            self.recordingSettings.resolution = "\(resoulation)p (SD)"
        }
        
        let bitrate = AppData.bitrate
        self.recordingSettings.fileSize = "\(bitrate) Mbps"
        
        let framerate = AppData.framerate
        self.recordingSettings.frameRate  = "\(framerate)Fps"
        
        DispatchQueue.main.async { [weak self] in
            self?.collectionForScroll.reloadData()
        }
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
    
    private func initialLoad(){
        AppData.isIntroFinished = true
        loadVideo()
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
    
    private func loadVideo() {
        self.savedVideos = CoreDataManager.shared.fetchSavedVideos()
        
        DispatchQueue.main.async { [weak self] in
            self?.collectionForScroll.reloadData()
        }
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
            actionsheet.overrideUserInterfaceStyle = .light
            
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
}



extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if savedVideos.count == 0 {
            return 1
        } else {
            return 2
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if savedVideos.count == 0 {
            return 1
        } else {
            if section == 0 {
                return 2
            } else {
                return savedVideos.count
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0 {
            if indexPath.row == 1 {
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HeaderCVCell.identifier, for: indexPath) as? HeaderCVCell {
                    cell.didTappedSeeAll = {
                        self.recordsHistorySeeAllBtnTapped()
                    }
                    return cell
                }
            }
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Section1CVCell.identifier, for: indexPath) as? Section1CVCell {
                cell.setView(self.recordingSettings)
                cell.didTappedSeeAll = {
                    self.toolsSeeAllBtnAction()
                }
                cell.didTappedToStart = {
                    self.startScreenRecordBtnTapped()
                }
                cell.didTappedResolutionSettings = { index in
                    self.presentRecordSettings(tag: index)
                }
                cell.didSelectTool = { selectedToolIndexPath in
                    switch selectedToolIndexPath.row {
                    case 0:
                        self.LiveBroadcastTapped()
                    case 1:
                        self.FaceCamTapped()
                    case 2:
                        self.commentryTapped()
                    case 3:
                        self.videoToGifTapped()
                    case 4:
                        self.videoEditTapped()
                    default:
                        print("no other tools yet.")
                    }
                }
                return cell
            }
        }
        
        if indexPath.section == 1 {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RecordsCVCell.identifier, for: indexPath) as? RecordsCVCell {
                cell.setView()
                //load thumb image
                if let fileName = savedVideos[indexPath.row].thumbName, let url = DirectoryManager.shared.appGroupThumbBaseURL()?.appendingPathComponent(fileName){
                    cell.imgThumb.image = UIImage(contentsOfFile: url.path)
                }
                
                cell.video = self.savedVideos[indexPath.item]
                cell.didSelectThreeDots = { [weak self] in
                    guard let self = self else {return}
                    self.threeDotRecordHistoryTapped(indexPath)
                }
                return cell
            }
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.recordingsHistoryTapped(indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            if indexPath.row == 1 {
                let width = collectionView.frame.size.width - 40
                return CGSize(width: width, height: 32)
            }
            let width = collectionView.frame.size.width
            let height = UIScreen.main.bounds.height
            let ratio: CGFloat = (231 / 930)
            let bottomSpace = ratio * height
            var cvHeight = height - bottomSpace - 20
            if UIScreen.main.bounds.height == 667 {
                cvHeight = height - bottomSpace
            }
            return CGSize(width: width, height: cvHeight)
        } else {
            
            let cvWidth = collectionView.frame.size.width
            let ratio: CGFloat = (292 / 191)
            
            let width = (cvWidth - 40 - 8) / 2
            let height = ratio * width
            
            return CGSize(width: width, height: height)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 0 {
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        return 24
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        return 8
    }
}





//MARK: -> All Buttons Actions are here
extension HomeViewController {
    func toolsSeeAllBtnAction() {
        print("Tools See All Btn Tapped")
        let vc = loadVCfromStoryBoard(name: "VideoTools", identifier: "VideoToolsViewController") as! VideoToolsViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func recordingSettingsBtnAction() {
        print("Recording Settings Btn Tapped")
    }
    
    func startScreenRecordBtnTapped() {
        print("Start Screen Record Btn Tapped")
        
        let pickerView = RPSystemBroadcastPickerView()
        //pickerView.preferredExtension = "com.appnotrix.SR.broadcastUpload"
        pickerView.preferredExtension = "com.samar.screenrecorder.BroadcastUpload"
        
        let buttonPressed = NSSelectorFromString("buttonPressed:")
        if pickerView.responds(to: buttonPressed) {
            pickerView.perform(buttonPressed, with: nil)
        }
        pickerView.showsMicrophoneButton = true
    }
    
    func myRecordingSeeAllBtnTapped() {
        print("My Recordings Btn Tapped.")
    }
    
    @IBAction func btnIAP(_ btn: UIButton) {
        print("IAP Btn Tapped")
        hepticFeedBack()
        if let iapViewController = loadVCfromStoryBoard(name: "IAP", identifier: "IAPController") as? IAPController{
            iapViewController.modalPresentationStyle = .fullScreen
            self.present(iapViewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func btnSettings(_ btn: UIButton) {
        print("Settings Btn Tapped")
        if let vc = loadVCfromStoryBoard(name: "Settings", identifier: "SettingsViewController") as? SettingsViewController{
            let navVC = LightNavVC(rootViewController: vc)
            navVC.modalPresentationStyle = .fullScreen
            self.present(navVC, animated: true)
        }
    }
    
    func LiveBroadcastTapped() {
        print("Live BroadCast Tapped")
        let vc = loadVCfromStoryBoard(name: "Broadcast", identifier: "BroadCastVC") as! BroadCastVC
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    func FaceCamTapped() {
        print("Face Cam Tapped")
        
        selectToolType = .faceCam
        let actionsheet = UIAlertController(title: "Select video source", message: "React to videos from Screen Recorder Camera Roll or YouTube", preferredStyle: .actionSheet)
        actionsheet.overrideUserInterfaceStyle = .light
        
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
    }
    
    func commentryTapped() {
        print("Commentry Tapped")
        
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
    }
    
    func videoToGifTapped() {
        print("Vieo To Gif Tapped")
        
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
        
    }
    
    func videoEditTapped() {
        print("Video Edit Tapped")
        selectToolType = .edit
        self.presentPicker()
    }
    
    func recordingsHistoryTapped(_ indexPath: IndexPath) {
        print("\(indexPath.row) no. Record History Tapped")
        
        if let name = savedVideos[indexPath.row].name {
            guard let url = share.appGroupBaseURL()?.appendingPathComponent(name) else { return }
            gotoVideoEditor(videoUrl: url)
        }
    }
    
    func recordsHistorySeeAllBtnTapped() {
        print("See All Record History tapped")
        if let vc = loadVCfromStoryBoard(name: "MyRecord", identifier: "MyRecordVC") as? MyRecordVC{
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func threeDotRecordHistoryTapped(_ indexPath: IndexPath) {
        print("\(indexPath.row) no. Record History three dot tapped")
            
            
                    let name = savedVideos[indexPath.row].displayName
                    
                    let actionsheet = UIAlertController(title: nil, message: name, preferredStyle: .actionSheet)
                    
                    actionsheet.addAction(UIAlertAction(title: "Rename", style: .default , handler:{ (UIAlertAction)in
                        print("Rename")
                        self.renameVideo(indexPath: indexPath)
                    }))
                        
                    actionsheet.addAction(UIAlertAction(title: "Duplicate", style: .default , handler: {
                        (UIAlertAction)in
                        print("Duplicate")
                        self.duplicateVideo(indexPath: indexPath)
                    }))

                    actionsheet.addAction(UIAlertAction(title: "Share", style: .default , handler:{ (UIAlertAction)in
                        print("Share")
                        self.shareVideo(indexPath: indexPath)
                    }))
                    
                    actionsheet.addAction(UIAlertAction(title: "Delete", style: .destructive , handler:{ (UIAlertAction)in
                        print("delete")
                        self.removeVideo(indexPath: indexPath)
                        
                        

                    }))
                    
                    actionsheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ (UIAlertAction)in
                            print("User click Dismiss button")
                        }))
                    self.present(actionsheet, animated: true)
                
            
           
        
    }
}


extension HomeViewController: PHPickerViewControllerDelegate {
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

private extension HomeViewController {
    
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
    
    func presentRecordSettings(tag: Int) {
        
       
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

extension HomeViewController: ExportDelegate {
    
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
           // self.updateActiveResoulationView()
        }
        if let bitRate{
            debugPrint(bitRate)
            //self.updateActiveBitrateView()
        }
        if let frameRate{
            debugPrint(frameRate)
           // self.updateActiveFramerateView()
        }
    }
}

extension HomeViewController{
    func duplicateVideo(indexPath: IndexPath) {
       
                print("selected index : ", indexPath.row)
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d, h:mm:ss a"
                let dateString = dateFormatter.string(from: Date())
                let duplicateName = "Recording_\(dateString).mp4"
                let duplicateThumbName = "Recording_\(dateString).jpg"
                
                guard let duplicateVideoUrl = share.appGroupBaseURL()?.appendingPathComponent(duplicateName), let duplicateThumbURL = DirectoryManager.shared.appGroupThumbBaseURL()?.appendingPathComponent(duplicateThumbName) else {return} /// create duplicate video url
                
                if let name = savedVideos[indexPath.row].name,let thumbName =  savedVideos[indexPath.row].thumbName{
                    if let orginalVideoUrl = share.appGroupBaseURL()?.appendingPathComponent(name),let orginalThumbUrl = share.appGroupThumbBaseURL()?.appendingPathComponent(thumbName) {
                        do {
                            try FileManager.default.copyItem(at: orginalVideoUrl, to: duplicateVideoUrl)
                            try FileManager.default.copyItem(at: orginalThumbUrl, to: duplicateThumbURL)
                            
                            if let video = CoreDataManager.shared.createSavedVideo(displayName: "Copy of \(savedVideos[indexPath.row].displayName ?? "")", name: duplicateName, thumbName: duplicateThumbName){
                                
                                
                                let duration = AVURLAsset(url: duplicateVideoUrl).duration.seconds
                                video.duration = duration
                                video.size = duplicateVideoUrl.fileSizeString
                                CoreDataManager.shared.saveContext()
                                
                                self.savedVideos.insert(video, at: 0)
                                DispatchQueue.main.async {
                                    self.loadVideo()
                                }
                            }
                            
                        } catch {
                            debugPrint(error.localizedDescription)
                        }
                    }
                }
               
            
        
    }
    
    func renameVideo(indexPath: IndexPath) {
       
                print("selected index : ", indexPath.row)
                
                //if let name = savedVideos[indexPath.row].name {
                    let alert = UIAlertController(title: "Rename", message: "\(savedVideos[indexPath.row].displayName ?? "")", preferredStyle: .alert)
                    alert.addTextField()
                    let textField = alert.textFields![0] as UITextField
                    textField.placeholder = savedVideos[indexPath.row].displayName
                    textField.text = savedVideos[indexPath.row].displayName
                    
                    let submitAction = UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] action in
                        guard let nameText = alert?.textFields?[0].text else { return }
                        print(nameText)
                        
                        if !nameText.isEmpty {
                            self?.savedVideos[indexPath.row].displayName = nameText
                            CoreDataManager.shared.saveContext()
                        }
                        
                        DispatchQueue.main.async {
                            self?.loadVideo()
                        }
                    }
                    
                    let cancel = UIAlertAction(title: "Cancel", style: .default) { (alertAction) in }
                    alert.addAction(cancel)
                    alert.addAction(submitAction)
                    present(alert, animated: true)
                
           
    }
    
    func removeVideo(indexPath: IndexPath) {
            
            let actionsheet1 = UIAlertController(title: "This video will be deleted from your my recordings.", message: nil, preferredStyle: .actionSheet)
            
            actionsheet1.addAction(UIAlertAction(title: "Delete Video", style: .destructive, handler: {
             [weak self]  (UIAlertAction) in
                
                    print("selected index : ", indexPath.row)
                    
                    let name = self?.savedVideos[indexPath.row].name
                    let thumbName = self?.savedVideos[indexPath.row].thumbName
                    
                    
                    
                    guard let video = self?.savedVideos[indexPath.row] else { return }
                    CoreDataManager.shared.deleteSavedVideo(video)
                    
                    if CoreDataManager.shared.saveContext(){
                        self?.savedVideos.remove(at: indexPath.row)
                    }
                    
                    if let name = name,let documentsDirectoryPath = self?.share.appGroupBaseURL()?.appendingPathComponent(name) {
                        self?.share.deleteFile(documentsDirectoryPath)
                    }
                    
                    if let thumbName = thumbName, let documentsDirectoryPath = self?.share.appGroupThumbBaseURL()?.appendingPathComponent(thumbName){
                        self?.share.deleteFile(documentsDirectoryPath)
                    }
                
                DispatchQueue.main.async {
                    self?.loadVideo()
                }
                    
                
            }))
            
            actionsheet1.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ (UIAlertAction)in
                    print("User click Dismiss button")
                }))
            self.present(actionsheet1, animated: true)
            
            
        
    
    }
    
    func shareVideo(indexPath: IndexPath) {
       
                if let name = savedVideos[indexPath.row].name {
                    guard let videoURL = share.appGroupBaseURL()?.appendingPathComponent(name) else { return }
                    let vc = UIActivityViewController(activityItems: [videoURL], applicationActivities: [])
                    self.present(vc, animated: true)
                }
            
    }
}
