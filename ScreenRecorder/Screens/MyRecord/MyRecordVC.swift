//
//  MyRecordVC.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 6/3/25.
//



import UIKit
import AVFoundation
import AVKit

class MyRecordVC: UIViewController {

    
    @IBOutlet weak var navView: UIView!
    @IBOutlet weak var cnstNavViewHeight: NSLayoutConstraint!
    @IBOutlet weak var lblTittle: UILabel!{
        didSet{
            self.lblTittle.font = .appFont_CircularStd(type: .bold, size: 20)
            self.lblTittle.textColor = UIColor(hex: "#151517")
        }
    }
    
    @IBOutlet weak var myRecordCollectionView: UICollectionView!{
        didSet{
            myRecordCollectionView.isHidden = true
        }
    }
    @IBOutlet weak var emptyView: UIView!

    var savedVideos: [SavedVideo] = [SavedVideo]()
    var isComeFromFaceCam: Bool = false
    var isComeCommentary: Bool = false
    var isComeVideoToGif: Bool = false
    let share = DirectoryManager.shared
    var selectToolType = SelectToolType.edit
    var isVCLoaded: Bool = false
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        loadVideo()
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if !isVCLoaded{
            isVCLoaded = true
            setupNavHeight()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        myRecordCollectionView.reloadData()
    }
    
    // MARK: - Private Methods
    
    func setupCollectionView() {
        let nib = UINib(nibName: "SRCVCell", bundle: nil)
        myRecordCollectionView.register(nib, forCellWithReuseIdentifier: "SRCVCell")
        myRecordCollectionView.delegate = self
        myRecordCollectionView.dataSource = self
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
    
    func loadVideo() {
        
        self.savedVideos = CoreDataManager.shared.fetchSavedVideos()
        DispatchQueue.main.async { [self] in
            myRecordCollectionView.reloadData()
        }
        checkEmpty()
    }
    
    private func checkEmpty(){
        
        if savedVideos.count > 0{
            DispatchQueue.main.async { [self] in
                myRecordCollectionView.isHidden = false
                emptyView.isHidden = true
            }
        }else{
            DispatchQueue.main.async { [self] in
                myRecordCollectionView.isHidden = true
                emptyView.isHidden = false
            }
        }
    }
    

    func duplicateVideo(sender: UIButton) {
        if let selectedCell = sender.superview?.superview?.superview as? SRCVCell {
            if let indexPath = myRecordCollectionView.indexPath(for: selectedCell) {
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
                                    self.myRecordCollectionView.reloadData()
                                }
                            }
                            
                        } catch {
                            debugPrint(error.localizedDescription)
                        }
                    }
                }
               
            }
        }
    }
    
    func renameVideo(sender: UIButton) {
        if let selectedCell = sender.superview?.superview?.superview as? SRCVCell {
            if let indexPath = myRecordCollectionView.indexPath(for: selectedCell) {
                print("selected index : ", indexPath.row)
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
                        
                        DispatchQueue.main.async { [self] in
                            self?.myRecordCollectionView.reloadItems(at: [indexPath])
                        }
                    }
                    
                    let cancel = UIAlertAction(title: "Cancel", style: .default) { (alertAction) in }
                    alert.addAction(cancel)
                    alert.addAction(submitAction)
                   alert.overrideUserInterfaceStyle = .light
                    present(alert, animated: true)
                
            }
        }
    }
    
    func removeVideo(sender: UIButton) {
        if let selectedCell = sender.superview?.superview?.superview as? SRCVCell {
            
            let actionsheet1 = UIAlertController(title: "This video will be deleted from your my recordings.", message: nil, preferredStyle: .actionSheet)
            
            actionsheet1.addAction(UIAlertAction(title: "Delete Video", style: .destructive, handler: {
             [weak self]  (UIAlertAction) in
                
                if let indexPath = self?.myRecordCollectionView.indexPath(for: selectedCell) {
                    print("selected index : ", indexPath.row)
                    
                    let name = self?.savedVideos[indexPath.row].name
                    let thumbName = self?.savedVideos[indexPath.row].thumbName
                    
                    self?.myRecordCollectionView.reloadData()
                    
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
                    
                }
            }))
            
            actionsheet1.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ (UIAlertAction)in
                    print("User click Dismiss button")
                }))
            self.present(actionsheet1, animated: true)
            
            
        }
        checkEmpty()
    
    }
    
    func shareVideo(sender: UIButton) {
        if let selectedCell = sender.superview?.superview?.superview as? SRCVCell {
            if let indexPath = myRecordCollectionView.indexPath(for: selectedCell) {
                if let name = savedVideos[indexPath.row].name {
                    guard let videoURL = share.appGroupBaseURL()?.appendingPathComponent(name) else { return }
                    let vc = UIActivityViewController(activityItems: [videoURL], applicationActivities: [])
                    vc.overrideUserInterfaceStyle = .light
                    self.present(vc, animated: true)
                }
            }
        }
    }
    
    func goToFaceCamVC(videoUrl: URL) {
        let vc = loadVCfromStoryBoard(name: "FaceCam", identifier: "FaceCamViewController") as! FaceCamViewController
        let video = Video(videoUrl)
        vc.video = video
        DispatchQueue.main.async{
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func goToCommentaryVC(videoUrl: URL) {
        let vc = loadVCfromStoryBoard(name: "Commentary", identifier: "CommentaryViewController") as! CommentaryViewController
        let video = Video(videoUrl)
        vc.video = video
        DispatchQueue.main.async{
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func goToVideoToGifVC(videoUrl: URL) {
        let vc = loadVCfromStoryBoard(name: "VideoToGIF", identifier: "VideoToGIFViewController") as! VideoToGIFViewController
        let video = Video(videoUrl)
        vc.video = video
        DispatchQueue.main.async {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    // MARK: - Button Action
    
    @IBAction func backButtonAction(_ sender: UIButton){
        self.dismiss(animated: true)
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func moreButtonAction(_ sender: UIButton) {
        print(sender.tag)
        
        if let selectedCell = sender.superview?.superview?.superview as? SRCVCell {
            if let indexPath = myRecordCollectionView.indexPath(for: selectedCell) {
                let name = savedVideos[indexPath.row].displayName
                
                // Example of how to call the updated RecordCellOptionVC

                // 1. Define which options you want to show. You can include any or all of them.
                let options: [RecordCellOptionVC.Option] = [.rename, .duplicate, .share, .delete]

                // 2. Instantiate the view controller with the options and their corresponding actions.
                let selectionVC = RecordCellOptionVC.instantiate(
                    options: options,
                    onSelectRename: { [weak self] in
                        print("Rename action triggered.")
                        self?.renameVideo(sender: sender)
                    },
                    onSelectDuplicate: { [weak self] in
                        print("Duplicate action triggered.")
                        self?.duplicateVideo(sender: sender)
                    },
                    onSelectShare: { [weak self] in
                        self?.shareVideo(sender: sender)
                    },
                    onSelectDelete: { [weak self] in
                        print("Delete action triggered.")
                        self?.removeVideo(sender: sender)
                    }
                )

                // 3. Present the sheet. This part remains the same.
                // Note: The grabber visibility is now set inside the VC, so this check is optional.
                if let sheet = selectionVC.sheetPresentationController {
                    // You can still customize the sheet here if needed.
                    // For example: sheet.largestUndimmedDetentIdentifier = .medium
                }

                self.present(selectionVC, animated: true)
                
            }
        }
       
    }
}

extension MyRecordVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.savedVideos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
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
        cell.moreBigButton.addTarget(self, action: #selector(moreButtonAction), for: .touchUpInside)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // 1. Get the video URL once, right at the start.
        guard let name = savedVideos[indexPath.row].name,
              let url = share.appGroupBaseURL()?.appendingPathComponent(name) else {
            print("Error: Could not construct video URL.")
            return
        }
        
        // 2. Use a switch statement on the tool type for cleaner logic.
        switch selectToolType {
        case .gif:
            goToVideoToGifVC(videoUrl: url)
            
        case .extractAudio:
            goToVideoToAudioVC(videoUrl: url)
            
        case .edit:
            gotoVideoPreview(videoUrl: url)
            
        case .voiceReocrd:
            gotoVoiceRecorVC(videoUrl: url)
            
        case .videoToPhoto:
            goToVideoToPhotoVC(videoUrl: url)
            
        case .videoToAudio:
            goToExtractMusicVC()
            
        case .trim:
            gotToTrimVC(videoUrl: url)
            
        case .compress:
            gotoCompressVC(videoUrl: url)
            
        case .photoToVideo:
            print("Photo to Video selected with URL: \(url)")
            
        case .speed:
            gotToSpeedVC(videoUrl: url)
            
        case .crop:
            gotoCropVC(videoUrl: url)
            
        case .faceCam:
            goToFaceCamVC(videoUrl: url)
            
        case .commentary:
            goToCommentaryVC(videoUrl: url)
            
        default:
            gotoVideoEditor(videoUrl: url)
        }
    }
    
  
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let w = (DEVICE_WIDTH - 40) / 2
        return CGSize(width: w - 5, height: w - 5)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
}

extension MyRecordVC {
    
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
    
    func gotoVideoPreview(videoUrl: URL){
        if let vc = loadVCfromStoryBoard(name: "MyRecord", identifier: "MyRecordVideoPreviewVC") as? MyRecordVideoPreviewVC {
          
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
    
    func gotToVideoToGifVC(videoURL: URL) {
        dismissLoader()
//        let vc = loadVCfromStoryBoard(name: "VideoToGIF", identifier: "VideoToGIFViewController") as! VideoToGIFViewController
//        let video = Video(videoURL)
//        vc.video = video
//        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func gotToTrimVC(videoUrl: URL){
//        if let vc = loadVCfromStoryBoard(name: "Trim", identifier: "TrimViewController") as? TrimViewController{
//            let video = Video(videoUrl)
//            vc.video = video
//            DispatchQueue.main.async{
//                self.navigationController?.pushViewController(vc, animated: true)
//            }
//        }
    }
    
    func gotToSpeedVC(videoUrl: URL){
//        if let vc = loadVCfromStoryBoard(name: "Speed", identifier: "SpeedViewController") as? SpeedViewController{
//            let video = Video(videoUrl)
//            vc.video = video
//            DispatchQueue.main.async{
//                self.navigationController?.pushViewController(vc, animated: true)
//            }
//        }
    }
    
    func goToVideoToPhotoVC(videoUrl: URL){
//        if let vc = loadVCfromStoryBoard(name: "VideoToPhoto", identifier: "VideoToPhotoViewController") as? VideoToPhotoViewController{
//            let video = Video(videoUrl)
//            vc.video = video
//            
//            DispatchQueue.main.async{
//                self.navigationController?.pushViewController(vc, animated: true)
//            }
//        }
    }
    
    func gotoVoiceRecorVC(videoUrl: URL){
//        if let vc = loadVCfromStoryBoard(name: "Trim", identifier: "TrimViewController") as? TrimViewController{
//            let video = Video(videoUrl)
//            vc.video = video
//            DispatchQueue.main.async{
//                self.navigationController?.pushViewController(vc, animated: true)
//            }
//        }
    }
    
    func gotoCompressVC(videoUrl: URL){
//        if let vc = loadVCfromStoryBoard(name: "VideoCompress", identifier: "VideoCompressViewController") as? VideoCompressViewController{
//
//            let video = Video(videoUrl)
//            vc.video = video
//            //exportVC?.video = video
//            DispatchQueue.main.async{
//                self.navigationController?.pushViewController(vc, animated: true)
//            }
//        }
    }
    
    func gotoCropVC(videoUrl: URL){
//        if let vc = loadVCfromStoryBoard(name: "Crop", identifier: "CropViewController") as? CropViewController{
//            let video = Video(videoUrl)
//            vc.video = video
//            DispatchQueue.main.async{
//                self.navigationController?.pushViewController(vc, animated: true)
//            }
//        }
    }
    
    func goToExtractMusicVC(){
//        if let vc = loadVCfromStoryBoard(name: "VideoToAudio", identifier: "ExtractMusicViewController") as? ExtractMusicViewController{
//            DispatchQueue.main.async{
//                self.navigationController?.pushViewController(vc, animated: true)
//            }
//        }
    }
    
    func goToVideoToAudioVC(videoUrl: URL){
//        if let vc = loadVCfromStoryBoard(name: "VideoToAudio", identifier: "VideoToAudioViewController") as? VideoToAudioViewController {
//            let video = Video(videoUrl)
//            vc.video = video
//            vc.isComeFromeMyRecordVC = true
//            DispatchQueue.main.async{
//                self.navigationController?.pushViewController(vc, animated: true)
//            }
//        }
    }
}
