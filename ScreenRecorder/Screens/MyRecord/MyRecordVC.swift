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

    enum SelectToolType: Int {
        case faceCam, commentary, gif, edit, voiceReocrd, photoToVideo,videoToPhoto, videoToAudio, trim, compress, speed, crop, extractAudio, none
    }

    let share = DirectoryManager.shared
    
    @IBOutlet weak var collectionView: UICollectionView!{
        didSet{
            collectionView.isHidden = true
        }
    }
    @IBOutlet weak var emptyView: UIView!

    var savedVideos: [SavedVideo] = [SavedVideo]()
    var isComeFromFaceCam: Bool = false
    var isComeCommentary: Bool = false
    var isComeVideoToGif: Bool = false
    
    var selectToolType = SelectToolType.edit
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
        loadVideo()
    }

    override func viewWillAppear(_ animated: Bool) {
        collectionView.reloadData()
    }
    
    // MARK: - Private Methods
    
    func setupCollectionView() {
        let nib = UINib(nibName: "SRCVCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "SRCVCell")
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    func loadVideo() {
        
        self.savedVideos = CoreDataManager.shared.fetchSavedVideos()
        DispatchQueue.main.async { [self] in
            collectionView.reloadData()
        }
        checkEmpty()
    }
    
    private func checkEmpty(){
        
        if savedVideos.count > 0{
            DispatchQueue.main.async { [self] in
                collectionView.isHidden = false
                emptyView.isHidden = true
            }
        }else{
            DispatchQueue.main.async { [self] in
                collectionView.isHidden = true
                emptyView.isHidden = false
            }
        }
    }
    
//    func copyFilesFromBundleToDocumentsFolderWith(fileExtension: String) {
//        if let resPath = Bundle.main.resourcePath {
//            do {
//                let dirContents = try FileManager.default.contentsOfDirectory(atPath: resPath)
//                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
//                let filteredFiles = dirContents.filter{ $0.contains(fileExtension)}
//                for fileName in filteredFiles {
//                    if let documentsURL = documentsURL {
//                        let sourceURL = Bundle.main.bundleURL.appendingPathComponent(fileName)
//                        let destURL = documentsURL.appendingPathComponent(fileName)
//                        do { try FileManager.default.copyItem(at: sourceURL, to: destURL) } catch { }
//                    }
//                }
//            } catch { }
//        }
//    }
//
    func duplicateVideo(sender: UIButton) {
        if let selectedCell = sender.superview?.superview as? SRCVCell {
            if let indexPath = collectionView.indexPath(for: selectedCell) {
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
                                    self.collectionView.reloadItems(at: [IndexPath(item: 0, section: 0)])
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
        if let selectedCell = sender.superview?.superview as? SRCVCell {
            if let indexPath = collectionView.indexPath(for: selectedCell) {
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
                        
                        DispatchQueue.main.async { [self] in
                            self?.collectionView.reloadItems(at: [indexPath])
                        }
                    }
                    
                    let cancel = UIAlertAction(title: "Cancel", style: .default) { (alertAction) in }
                    alert.addAction(cancel)
                    alert.addAction(submitAction)
                    present(alert, animated: true)
                
            }
        }
    }
    
    func removeVideo(sender: UIButton) {
        if let selectedCell = sender.superview?.superview as? SRCVCell {
            
            let actionsheet1 = UIAlertController(title: "This video will be deleted from your my recordings.", message: nil, preferredStyle: .actionSheet)
            
            actionsheet1.addAction(UIAlertAction(title: "Delete Video", style: .destructive, handler: {
             [weak self]  (UIAlertAction) in
                
                if let indexPath = self?.collectionView.indexPath(for: selectedCell) {
                    print("selected index : ", indexPath.row)
                    
                    let name = self?.savedVideos[indexPath.row].name
                    let thumbName = self?.savedVideos[indexPath.row].thumbName
                    
                    self?.collectionView.deleteItems(at: [indexPath])
                    
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
        if let selectedCell = sender.superview?.superview as? SRCVCell {
            if let indexPath = collectionView.indexPath(for: selectedCell) {
                if let name = savedVideos[indexPath.row].name {
                    guard let videoURL = share.appGroupBaseURL()?.appendingPathComponent(name) else { return }
                    let vc = UIActivityViewController(activityItems: [videoURL], applicationActivities: [])
                    self.present(vc, animated: true)
                }
            }
        }
    }
    
    func goToFaceCamVC(videoUrl: URL) {
//        let vc = loadVCfromStoryBoard(name: "FaceCam", identifier: "FaceCamViewController") as! FaceCamViewController
//        let video = Video(videoUrl)
//        vc.video = video
//        DispatchQueue.main.async{
//            self.navigationController?.pushViewController(vc, animated: true)
//        }
    }
    
    func goToCommentaryVC(videoUrl: URL) {
//        let vc = loadVCfromStoryBoard(name: "Commentary", identifier: "CommentaryViewController") as! CommentaryViewController
//        let video = Video(videoUrl)
//        vc.video = video
//        DispatchQueue.main.async{
//            self.navigationController?.pushViewController(vc, animated: true)
//        }
    }
    
    func goToVideoToGifVC(videoUrl: URL) {
//        let vc = loadVCfromStoryBoard(name: "VideoToGIF", identifier: "VideoToGIFViewController") as! VideoToGIFViewController
//        let video = Video(videoUrl)
//        vc.video = video
//        DispatchQueue.main.async {
//            self.navigationController?.pushViewController(vc, animated: true)
//        }
    }
    
    // MARK: - Button Action
    
    @IBAction func backButtonAction(_ sender: UIButton){
        self.dismiss(animated: true)
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func moreButtonAction(_ sender: UIButton) {
        print(sender.tag)
        
        if let selectedCell = sender.superview?.superview as? SRCVCell {
            if let indexPath = collectionView.indexPath(for: selectedCell) {
                let name = savedVideos[indexPath.row].displayName
                
                let actionsheet = UIAlertController(title: nil, message: name, preferredStyle: .actionSheet)
                
                actionsheet.addAction(UIAlertAction(title: "Rename", style: .default , handler:{ (UIAlertAction)in
                    print("Rename")
                    self.renameVideo(sender: sender)
                }))
                    
                actionsheet.addAction(UIAlertAction(title: "Duplicate", style: .default , handler: {
                    (UIAlertAction)in
                    print("Duplicate")
                    self.duplicateVideo(sender: sender)
                }))

                actionsheet.addAction(UIAlertAction(title: "Share", style: .default , handler:{ (UIAlertAction)in
                    print("Share")
                    self.shareVideo(sender: sender)
                }))
                
                actionsheet.addAction(UIAlertAction(title: "Delete", style: .destructive , handler:{ (UIAlertAction)in
                    print("delete")
                    self.removeVideo(sender: sender)
                    
                    

                }))
                
                actionsheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ (UIAlertAction)in
                        print("User click Dismiss button")
                    }))
                self.present(actionsheet, animated: true)
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
        cell.moreButton.addTarget(self, action: #selector(moreButtonAction), for: .touchUpInside)
        cell.moreBigButton.addTarget(self, action: #selector(moreButtonAction), for: .touchUpInside)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    
        if selectToolType == .gif {
            if let name = savedVideos[indexPath.row].name {
                guard let url = share.appGroupBaseURL()?.appendingPathComponent(name) else { return }
                goToVideoToGifVC(videoUrl: url)
            }
            
        }else if  selectToolType == .extractAudio { /// is come from my video to audion vc
            if let name = savedVideos[indexPath.row].name {
                guard let url = share.appGroupBaseURL()?.appendingPathComponent(name) else { return }
                goToVideoToAudioVC(videoUrl: url)
            }
        }else if selectToolType == .edit {
            if let name = savedVideos[indexPath.row].name {
                guard let url = share.appGroupBaseURL()?.appendingPathComponent(name) else { return }
                gotoVideoEditor(videoUrl: url)
            }
        }else if selectToolType == .voiceReocrd {
            if let name = savedVideos[indexPath.row].name {
                guard let url = share.appGroupBaseURL()?.appendingPathComponent(name) else { return }
                gotoVoiceRecorVC(videoUrl: url)
            }
        }else if selectToolType == .videoToPhoto {
            if let name = savedVideos[indexPath.row].name {
                guard let url = share.appGroupBaseURL()?.appendingPathComponent(name) else { return }
                goToVideoToPhotoVC(videoUrl: url)
            }
        }else if selectToolType == .videoToAudio {
            if let name = savedVideos[indexPath.row].name {
                guard let url = share.appGroupBaseURL()?.appendingPathComponent(name) else { return }
                goToExtractMusicVC()
            }
        }else if selectToolType == .trim {
            if let name = savedVideos[indexPath.row].name {
                guard let url = share.appGroupBaseURL()?.appendingPathComponent(name) else { return }
                gotToTrimVC(videoUrl: url)
            }
        }else if selectToolType == .compress {
            if let name = savedVideos[indexPath.row].name {
                guard let url = share.appGroupBaseURL()?.appendingPathComponent(name) else { return }
                gotoCompressVC(videoUrl: url)
            }
        }else if selectToolType == .photoToVideo {
            if let name = savedVideos[indexPath.row].name {
                guard let url = share.appGroupBaseURL()?.appendingPathComponent(name) else { return }
            }
        }else if selectToolType == .speed {
            if let name = savedVideos[indexPath.row].name {
                guard let url = share.appGroupBaseURL()?.appendingPathComponent(name) else { return }
                gotToSpeedVC(videoUrl: url)
            }
        }else if selectToolType == .crop {
            if let name = savedVideos[indexPath.row].name {
                guard let url = share.appGroupBaseURL()?.appendingPathComponent(name) else { return }
                gotoCropVC(videoUrl: url)
            }
            
        } else if isComeFromFaceCam { /// home vc button action
            ///
            if let name = savedVideos[indexPath.row].name {
                guard let url = share.appGroupBaseURL()?.appendingPathComponent(name) else { return }
                goToFaceCamVC(videoUrl: url)
            }
        }else if isComeCommentary {
            if let name = savedVideos[indexPath.row].name {
                guard let url = share.appGroupBaseURL()?.appendingPathComponent(name) else { return }
                goToCommentaryVC(videoUrl: url)
            }
        }else{
//            let vc = loadVCfromStoryBoard(name: "PreviewVideo", identifier: "PreviewVideoViewController") as! PreviewVideoViewController
//            if let name = savedVideos[indexPath.row].name {
//                guard let documentsDirectoryPath = share.appGroupBaseURL()?.appendingPathComponent(name) else { return }
//                let video = Video(documentsDirectoryPath)
//                vc.video = video
//            }
//            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    /// cell layout
    ///
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let w = (DEVICE_WIDTH - 40) / 2
        let h = (285 * w)/170
        return CGSize(width: w - 5, height: h - 50)
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
