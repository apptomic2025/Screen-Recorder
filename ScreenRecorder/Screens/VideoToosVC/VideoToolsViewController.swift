import UIKit
import Photos
import PhotosUI

struct Tools {
    var icon: UIImage
    var smallTitle: String
    var bigTitle: String
    var isProItem: Bool = false
    var type: SelectToolType
}

class VideoToolsViewController: UIViewController {

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
    
    @IBOutlet weak var navView: UIView!
    @IBOutlet weak var cnstNavViewHeight: NSLayoutConstraint!
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
        Tools(icon: UIImage(named: "GifMakerIcon")!, smallTitle: "GIF", bigTitle: "GIF Maker", type: .gif),
        Tools(icon: UIImage(named: "videoEditIcon")!, smallTitle: "EDIT", bigTitle: "Edit Video", type: .edit),
        Tools(icon: UIImage(named: "VoiceRecorderIcon")!, smallTitle: "VOICE", bigTitle: "Voice Recorder", isProItem: true, type: .voiceReocrd),
        Tools(icon: UIImage(named: "VideoToPhotoIcon")!, smallTitle: "PHOTO", bigTitle: "Video to Photo", isProItem: true, type: .videoToPhoto),
        Tools(icon: UIImage(named: "VideoToAudioIcon")!, smallTitle: "VIDEO", bigTitle: "Video to Audio", isProItem: true, type: .videoToAudio),
        Tools(icon: UIImage(named: "TrimIcon")!, smallTitle: "VIDEO", bigTitle: "Video Trimmer", type: .trim),
        Tools(icon: UIImage(named: "ComptrssIcon")!, smallTitle: "VIDEO", bigTitle: "Video Compress", type: .compress),
        Tools(icon: UIImage(named: "SpeedIcon")!, smallTitle: "VIDEO", bigTitle: "Video Speed", type: .speed),
        Tools(icon: UIImage(named: "CropIcon")!, smallTitle: "CROP", bigTitle: "Crop Video", type: .crop)
    ]
    
    var exportVC: ExportSettingsVC?
    var selectedFrame: [UIImage] = []
    var isVCLoaded: Bool = false

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
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if !isVCLoaded{
            isVCLoaded = true
            setupNavHeight()
        }
    }
    
    private func presentPicker(type: Bool? = nil) {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        if type != nil {
            configuration.filter = .any(of: [.images])
        } else {
            configuration.filter = .any(of: [.videos])
        }
        configuration.preferredAssetRepresentationMode = .current
        configuration.selectionLimit = (type != nil) ? 90 : 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true)
    }
    
    // MARK: - Private Methods -
    
    private func setupCollectionView() {
        let nib = UINib(nibName: "VideoToolsCollectionViewCell", bundle: nil)
        toolsCollectionView.register(nib, forCellWithReuseIdentifier: cellIdentifier)
        toolsCollectionView.delegate = self
        toolsCollectionView.dataSource = self
    }
    
    private func setupNavHeight(){
        let uiType = getDeviceUIType()
        switch uiType {
        case .dynamicIsland:
            self.cnstNavViewHeight.constant = NavbarHeight.withDynamicIsland.rawValue
        case .notch:
            self.cnstNavViewHeight.constant = NavbarHeight.withNotch.rawValue
        case .noNotch:
            self.cnstNavViewHeight.constant = NavbarHeight.withOutNotch.rawValue
        }
    }

    private func showSourceSelectionSheet(for tool: SelectToolType, title: String) {
        self.selectToolType = tool
        let selectionVC = VideoSourceSelectionViewController.instantiate(
            options: [.cameraRoll, .myRecordings],
            title: title,
            subtitle: "Select a video source to continue",
            onSelectCameraRoll: { [weak self] in
                self?.presentPicker()
            },
            onSelectMyRecordings: { [weak self] in
                self?.navigateToMyRecordings(for: tool)
            }
        )
        
        self.present(selectionVC, animated: true)
    }

    private func navigateToMyRecordings(for tool: SelectToolType) {
        if let vc = loadVCfromStoryBoard(name: "MyRecord", identifier: "MyRecordVC") as? MyRecordVC {
            vc.selectToolType = tool // This will no longer cause an error
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func goToExtractMusicVC(){
        if let vc = loadVCfromStoryBoard(name: "VideoToAudio", identifier: "ExtractMusicViewController") as? ExtractMusicViewController{
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func gotoVoiceRecordVC(){
        if let vc = loadVCfromStoryBoard(name: "VoiceRecord", identifier: "VoiceRecordViewController") as? VoiceRecordViewController{
            self.navigationController?.pushViewController(vc, animated: true)
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
    
    @IBAction func iapButtonAction(){
        hepticFeedBack()
        if let iapViewController = loadVCfromStoryBoard(name: "IAP", identifier: "IAPController") as? IAPController {
            iapViewController.modalPresentationStyle = .fullScreen
            self.present(iapViewController, animated: true, completion: nil)
        }
    }
}

// MARK: - CollectionView Delegate & DataSource
extension VideoToolsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return toolsData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = toolsCollectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! VideoToolsCollectionViewCell
        cell.configure(icon: toolsData[indexPath.row].icon, smallText: toolsData[indexPath.row].smallTitle, bigText: toolsData[indexPath.row].bigTitle)
        if toolsData[indexPath.row].isProItem && !AppData.premiumUser{
            cell.imgViewProBadge.isHidden = false
        } else {
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
        // Get the tool's data directly from the data source array
        let selectedTool = toolsData[indexPath.row]
        
        // Get the tool's type from the model itself, not from the row index
        let toolType = selectedTool.type
        
        // Check for premium status
//        if selectedTool.isProItem && !AppData.premiumUser {
//            iapButtonAction()
//            return
//        }

        // The switch statement now works reliably, regardless of item order
        switch toolType {
        case .gif, .edit, .videoToPhoto, .trim, .compress, .speed, .crop:
            showSourceSelectionSheet(for: toolType, title: selectedTool.bigTitle)
            
        case .voiceReocrd:
            gotoVoiceRecordVC()
            
        case .videoToAudio:
            goToExtractMusicVC()
            
        case .photoToVideo:
            selectToolType = .photoToVideo
            presentPicker(type: true)
            
        default:
            break
        }
    }
}

// MARK: - PHPickerViewControllerDelegate
extension VideoToolsViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        
        var newSelection = [String: PHPickerResult]()
        for result in results {
            guard let identifier = result.assetIdentifier else { continue }
            newSelection[identifier] = result
        }
        
        selection = newSelection
        selectedAssetIdentifiers = results.map { $0.assetIdentifier! }
        selectedAssetIdentifierIterator = selectedAssetIdentifiers.makeIterator()
        
        if selection.isEmpty {
            // displayEmptyImage()
        } else {
            displayNext()
        }
    }
}

// MARK: - Private Extension for Handling Picker Results
private extension VideoToolsViewController {
    
    func displayNext() {
        self.mediaItems.deleteAll()
        recevedCount = 0
        selectedFrame.removeAll()
        
        DispatchQueue.main.async {
            showLoader(view: self.view)
        }
        
        guard let iterator = selectedAssetIdentifierIterator else {
            dismissLoader(); return
        }
        
        for assetIdentifier in iterator {
            let itemProvider = selection[assetIdentifier]!.itemProvider
            
            if itemProvider.canLoadObject(ofClass: UIImage.self) {
                itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    DispatchQueue.main.async {
                        self?.handleCompletion(assetIdentifier: assetIdentifier, object: image, error: error)
                    }
                }
            } else if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                    if let error = error {
                        print("Error loading file representation: \(error)")
                        DispatchQueue.main.async {
                            self.handleCompletion(assetIdentifier: assetIdentifier, object: nil, error: error)
                        }
                        return
                    }
                    
                    guard let url = url else {
                        DispatchQueue.main.async {
                            self.handleCompletion(assetIdentifier: assetIdentifier, object: nil, error: nil)
                        }
                        return
                    }
                    
                    let newURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(url.pathExtension)
                    
                    do {
                        try? FileManager.default.removeItem(at: newURL)
                        try FileManager.default.copyItem(at: url, to: newURL)
                        DispatchQueue.main.async {
                            self.handleCompletion(assetIdentifier: assetIdentifier, object: newURL)
                        }
                    } catch {
                        print("Error copying video to new URL: \(error)")
                        DispatchQueue.main.async {
                            self.handleCompletion(assetIdentifier: assetIdentifier, object: nil, error: error)
                        }
                    }
                }
            } else {
                handleCompletion(assetIdentifier: assetIdentifier, object: nil, error: nil)
            }
        }
    }
    
    func handleCompletion(assetIdentifier: String, object: Any?, error: Error? = nil) {
        recevedCount += 1
        
        if let image = object as? UIImage {
            selectedFrame.append(image)
        } else if let url = object as? URL {
            self.mediaItems.append(item: PhotoPickerModel(with: url))
        } else if error != nil {
            print("Failed to load asset \(assetIdentifier): \(error!.localizedDescription)")
        }
        
        if recevedCount == selection.count {
            if selectToolType == .photoToVideo {
                createVideo(imageArr: selectedFrame)
            } else {
                dismissLoader()
                processSelectedMedia()
            }
        }
    }
    
    func processSelectedMedia() {
        guard let url = self.mediaItems.items.first?.url else { return }

        switch selectToolType {
        case .gif:
            gotToVideoToGifVC(videoURL: url)
        case .edit:
            gotoVideoEditor(videoUrl: url)
        case .videoToPhoto:
            goToVideoToPhotoVC(videoUrl: url)
        case .trim:
            gotToTrimVC(videoUrl: url)
        case .compress:
            gotoCompressVC(videoUrl: url)
        case .speed:
            gotToSpeedVC(videoUrl: url)
        case .crop:
            gotoCropVC(videoUrl: url)
        default:
            break
        }
    }
    
    // MARK: Navigation Helper Functions
    
    func gotoVideoEditor(videoUrl: URL){
        if let vc = loadVCfromStoryBoard(name: "Editor", identifier: "EditorViewController") as? EditorVC{
            vc.video = Video(videoUrl)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func gotToVideoToGifVC(videoURL: URL) {
        let vc = loadVCfromStoryBoard(name: "VideoToGIF", identifier: "VideoToGIFViewController") as! VideoToGIFViewController
        vc.video = Video(videoURL)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func gotToTrimVC(videoUrl: URL){
        if let vc = loadVCfromStoryBoard(name: "Trim", identifier: "TrimVC") as? TrimVC{
            vc.video = Video(videoUrl)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func gotToSpeedVC(videoUrl: URL){
        if let vc = loadVCfromStoryBoard(name: "Speed", identifier: "SpeedViewController") as? SpeedViewController{
            vc.video = Video(videoUrl)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func goToVideoToPhotoVC(videoUrl: URL){
        if let vc = loadVCfromStoryBoard(name: "VideoToPhoto", identifier: "VideoToPhotoViewController") as? VideoToPhotoViewController{
            vc.video = Video(videoUrl)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func gotoCompressVC(videoUrl: URL){
        if let vc = loadVCfromStoryBoard(name: "VideoCompress", identifier: "VideoCompressViewController") as? VideoCompressViewController{
            vc.video = Video(videoUrl)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func gotoCropVC(videoUrl: URL){
        if let vc = loadVCfromStoryBoard(name: "Crop", identifier: "CropViewController") as? CropViewController{
            vc.video = Video(videoUrl)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
