//
//  VideoToosViewController.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 22/3/25.
//


import UIKit
import Photos
import PhotosUI

struct Tools {
    var icon: UIImage
    var smallTitle: String
    var bigTitle: String
    var isProItem: Bool = false
}

//enum SelectToolType: Int {
//    case faceCam, commentary, gif, edit, voiceReocrd, photoToVideo,videoToPhoto, videoToAudio, trim, compress, speed, crop, extractAudio, none
//}


class VideoToolsViewController: UIViewController {

    enum SelectToolType: Int {
        case gif, edit, voiceReocrd, videoToPhoto, videoToAudio, trim, compress, photoToVideo,speed, crop, extractAudio, none
    }

    let cellIdentifier = "VideoToolsCollectionViewCell"
    let share = GifManager.shared
    
    @IBOutlet weak var lblBannerTitle: UILabel!{
        didSet{
            self.lblBannerTitle.font = .appFont_CircularStd(type: .medium, size: 18)
            self.lblBannerTitle.textColor = .white
        }
    }
    
    @IBOutlet weak var lblBannerText: UILabel!{
        didSet{
            self.lblBannerText.font = .appFont_CircularStd(type: .book, size: 12)
            self.lblBannerText.textColor = .white
        }
    }
    
    @IBOutlet weak var lblVideoTools: UILabel!{
        didSet{
            self.lblVideoTools.font = .appFont_CircularStd(type: .bold, size: 16)
            self.lblVideoTools.textColor = UIColor(hex: "#151517")
        }
    }


    @IBOutlet weak var iapButtonBgView: UIView!
    @IBOutlet weak var iapButtonBgViewNSLayout: NSLayoutConstraint!

    @IBOutlet weak var toolsCollectionView: UICollectionView!{
        didSet{
            toolsCollectionView.contentInset = UIEdgeInsets(top: -8, left: 0, bottom: 30, right: 0)

        }
    }
    
    private var selection = [String: PHPickerResult]()
    private var selectedAssetIdentifiers = [String]()
    private var selectedAssetIdentifierIterator: IndexingIterator<[String]>?
    private var currentAssetIdentifier: String?
    var recevedCount = 0
    var mediaItems: PickedMediaItems = PickedMediaItems()
        
    var selectToolType: SelectToolType = .none
    
    let toolsData: [Tools] = [
        Tools(icon: UIImage(named: "GifMakerIcon")!, smallTitle: "GIF", bigTitle: "GIF Maker"),
        Tools(icon: UIImage(named: "videoEditIcon")!, smallTitle: "EDIT", bigTitle: "Edit Video"),
        Tools(icon: UIImage(named: "VoiceRecorderIcon")!, smallTitle: "VOICE", bigTitle: "Voice Recorder",isProItem: true),
        Tools(icon: UIImage(named: "VideoToPhotoIcon")!, smallTitle: "PHOTO", bigTitle: "Video to Photo",isProItem: true),
        Tools(icon: UIImage(named: "VideoToAudioIcon")!, smallTitle: "VIDEO", bigTitle: "Video to Audio",isProItem: true),
        Tools(icon: UIImage(named: "TrimIcon")!, smallTitle: "VIDEO", bigTitle: "Video Trimmer"),
        Tools(icon: UIImage(named: "ComptrssIcon")!, smallTitle: "VIDEO", bigTitle: "Video Compress"),
        Tools(icon: UIImage(named: "PhotoToVideoIcon")!, smallTitle: "VIDEO", bigTitle: "Photo to Video"),
        Tools(icon: UIImage(named: "SpeedIcon")!, smallTitle: "VIDEO", bigTitle: "Video Speed"),
        Tools(icon: UIImage(named: "CropIcon")!, smallTitle: "CROP", bigTitle: "Crop Video")
    ]
    
    var exportVC: ExportSettingsVC?
    
    var selectedFrame: [UIImage] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if AppData.premiumUser {
            iapButtonBgViewNSLayout.constant = 0
        }
        
        iapButtonBgView.cornerRadiusV = 9
        setupCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.main.async {
            if AppData.premiumUser {
                self.iapButtonBgViewNSLayout.constant = 0
            }
            self.toolsCollectionView.reloadData()
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
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true)
    }
    
    // MARK: - Private Methods -
    
    func setupCollectionView() {
        let nib = UINib(nibName: "VideoToolsCollectionViewCell", bundle: nil)
        toolsCollectionView.register(nib, forCellWithReuseIdentifier: cellIdentifier)
        
        toolsCollectionView.delegate = self
        toolsCollectionView.dataSource = self
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
                
                if selectToolType == .gif {
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
    
    func goToExtractMusicVC(){
        if let vc = loadVCfromStoryBoard(name: "VideoToAudio", identifier: "ExtractMusicViewController") as? ExtractMusicViewController{
            DispatchQueue.main.async{
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func gotoVoiceRecordVC(){
        if let vc = loadVCfromStoryBoard(name: "VoiceRecord", identifier: "VoiceRecordViewController") as? VoiceRecordViewController{
            DispatchQueue.main.async{
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func createVideo(imageArr: [UIImage]) {
        
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
    
    // MARK: - Button Action -
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func settingsAction(){
        if let vc = loadVCfromStoryBoard(name: "Settings", identifier: "SettingsViewController") as? SettingsViewController {
            let navVC = LightNavVC(rootViewController: vc)
            navVC.modalPresentationStyle = .fullScreen
            self.present(navVC, animated: true)
        }
    }
    
    @IBAction func iapButtonAction(){
        hepticFeedBack()
        if let iapViewController = loadVCfromStoryBoard(name: "IAP", identifier: "IAPController") as? IAPController {
            iapViewController.modalPresentationStyle = .fullScreen
            self.present(iapViewController, animated: true, completion: nil)
        }
    }
}

extension VideoToolsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return toolsData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = toolsCollectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! VideoToolsCollectionViewCell
        cell.configure(icon: toolsData[indexPath.row].icon, smallText: toolsData[indexPath.row].smallTitle, bigText: toolsData[indexPath.row].bigTitle)
        if toolsData[indexPath.row].isProItem && !AppData.premiumUser{
            cell.imgViewProBadge.isHidden = false
        }else{
            cell.imgViewProBadge.isHidden = true
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let w = ((DEVICE_WIDTH - 56) / 3) - 1
        return CGSize(width: w, height: w)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        switch indexPath.row {
        case SelectToolType.gif.rawValue:
            selectToolType = .gif
            self.presentPHpicker(selectToolType: .gif)

        case SelectToolType.edit.rawValue:
            selectToolType = .edit
            self.presentPHpicker(selectToolType: .edit)

        case SelectToolType.voiceReocrd.rawValue:
            if !AppData.premiumUser{
                iapButtonAction()
            }else{
                selectToolType = .voiceReocrd
                gotoVoiceRecordVC()
            }
        case SelectToolType.videoToPhoto.rawValue:
            selectToolType = .videoToPhoto
            presentPHpicker(selectToolType: .videoToPhoto)
            
        case SelectToolType.videoToAudio.rawValue:
            
            if !AppData.premiumUser{
                iapButtonAction()
            }else{
                selectToolType = .videoToAudio
                goToExtractMusicVC()
            }
            
        case SelectToolType.trim.rawValue:
            selectToolType = .trim
            presentPHpicker(selectToolType: .trim)
            
        case SelectToolType.compress.rawValue:
            selectToolType = .compress
            presentPHpicker(selectToolType: .compress)
            
        case SelectToolType.photoToVideo.rawValue:
            
            if !AppData.premiumUser{
                iapButtonAction()
            }else{
                selectToolType = .photoToVideo
                presentPicker(type: true)
            }
            
        case SelectToolType.speed.rawValue:
            selectToolType = .speed
            presentPHpicker(selectToolType: .speed)
            
        case SelectToolType.crop.rawValue:
            selectToolType = .crop
            presentPHpicker(selectToolType: .crop)
            
        default:
            break
        }
    }
}


extension VideoToolsViewController: PHPickerViewControllerDelegate {
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

private extension VideoToolsViewController {
    
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
        //progressView.observedProgress = progress
        //progressView.isHidden = progress == nil
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
                createVideo(imageArr: selectedFrame)
                self.mediaItems.deleteAll()
            }else{
                
                DispatchQueue.main.async {
                    //self.progressView.isHidden = true
                    dismissLoader()
                }
            }
            
            if let url = self.mediaItems.items.first?.url {

                if selectToolType == .gif {
                    gotToVideoToGifVC(videoURL: url)
                }else if selectToolType == .edit {
                    gotoVideoEditor(videoUrl: url)
                }else if selectToolType == .voiceReocrd {
                    gotoVoiceRecorVC(videoUrl: url)
                }else if selectToolType == .videoToPhoto {
                    goToVideoToPhotoVC(videoUrl: url)
                }else if selectToolType == .videoToAudio {
                    
                }else if selectToolType == .trim {
                    gotToTrimVC(videoUrl: url)
                }else if selectToolType == .compress {
                    gotoCompressVC(videoUrl: url)
                }else if selectToolType == .photoToVideo {
                    
                }else if selectToolType == .speed {
                    gotToSpeedVC(videoUrl: url)
                }else if selectToolType == .crop {
                    gotoCropVC(videoUrl: url)
                }
            }
        }
    }
    
    func gotoVideoEditor(videoUrl: URL){
        if let vc = loadVCfromStoryBoard(name: "Editor", identifier: "EditorViewController") as? EditorVC{
            let video = Video(videoUrl)
            vc.video = video
            DispatchQueue.main.async{
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func gotToVideoToGifVC(videoURL: URL) {
        dismissLoader()
        let vc = loadVCfromStoryBoard(name: "VideoToGIF", identifier: "VideoToGIFViewController") as! VideoToGIFViewController
        let video = Video(videoURL)
        vc.video = video
        self.navigationController?.pushViewController(vc, animated: true)
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
    
    func gotToSpeedVC(videoUrl: URL){
        if let vc = loadVCfromStoryBoard(name: "Speed", identifier: "SpeedViewController") as? SpeedViewController{
            let video = Video(videoUrl)
            vc.video = video
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
    
    func gotoVoiceRecorVC(videoUrl: URL){
        if let vc = loadVCfromStoryBoard(name: "Trim", identifier: "TrimVC") as? TrimVC{
            let video = Video(videoUrl)
            vc.video = video
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
    
    func gotoCropVC(videoUrl: URL){
        if let vc = loadVCfromStoryBoard(name: "Crop", identifier: "CropViewController") as? CropViewController{
            let video = Video(videoUrl)
            vc.video = video
            DispatchQueue.main.async{
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}

