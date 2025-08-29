//
//  ExtractMusicViewController.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 21/3/25.
//


import UIKit
import AVFoundation
import Photos
import PhotosUI

class ExtractMusicViewController: UIViewController {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    let identifier = "cell"
    @IBOutlet weak var musicTableView: UITableView!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var plusButton: UIButton!{
        didSet{
            plusButton.cornerRadiusV = plusButton.frame.width/2
        }
    }

    private var selection = [String: PHPickerResult]()
    private var selectedAssetIdentifiers = [String]()
    private var selectedAssetIdentifierIterator: IndexingIterator<[String]>?
    private var currentAssetIdentifier: String?
    var recevedCount = 0
    var mediaItems: PickedMediaItems = PickedMediaItems()
    
    var extractAudio : [ExtractAudio] = []
    
    var previousCell: Int?
    var nextCell: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        musicTableView.estimatedRowHeight = 190
        musicTableView.rowHeight = UITableView.automaticDimension
        
        setupTableView()
        checkEmpty()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if soundOnOff {
            audioPlayer.stop()
            timerT?.invalidate()
            timerT = nil
            soundOnOff = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadRecordFromCoreData()
    }
    
    func loadRecordFromCoreData(){
        if let recordsData = try? context.fetch(ExtractAudio.fetchRequest()){
            extractAudio = recordsData
            extractAudio.sort { $0.creationDate! > $1.creationDate! }
            
            DispatchQueue.main.async { [self] in
                musicTableView.reloadData()
            }
            checkEmpty()
        }
    }
    
    // MARK: - Private Methods -
    
    private func checkEmpty(){
        
        if extractAudio.count > 0{
            DispatchQueue.main.async { [self] in
                musicTableView.isHidden = false
                emptyView.isHidden = true
            }
        }else{
            DispatchQueue.main.async { [self] in
                musicTableView.isHidden = true
                emptyView.isHidden = false
            }
        }
    }
    
    private func setupTableView() {
        musicTableView.delegate = self
        musicTableView.dataSource = self
        musicTableView.register(UINib(nibName: "VoiceRecordTvCell", bundle: nil), forCellReuseIdentifier: "cell")
    }
    
    private func presentPicker() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        
        // Set the filter type according to the user’s selection.
        configuration.filter = .any(of: [.videos])
        // Set the mode to avoid transcoding, if possible, if your app supports arbitrary image/video encodings.
        configuration.preferredAssetRepresentationMode = .current
        // Set the selection behavior to respect the user’s selection order.
        //configuration.selection = .ordered
        // Set the selection limit to enable multiselection.
        configuration.selectionLimit = 1
        // Set the preselected asset identifiers with the identifiers that the app tracks.
        //configuration.preselectedAssetIdentifiers = selectedAssetIdentifiers
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true)
    }
    
    func presentPHpicker(){
        let actionsheet = UIAlertController(title: "Video to GIF", message: "Select a video source and react to videos from previous Recordings, Gallery or Youtube", preferredStyle: .actionSheet)
        
        actionsheet.addAction(UIAlertAction(title: "Gallery", style: .default , handler:{ (UIAlertAction)in
            self.presentPicker()
        }))
            
        actionsheet.addAction(UIAlertAction(title: "Recordings", style: .default , handler:{ (UIAlertAction)in
            if let vc = loadVCfromStoryBoard(name: "MyRecord", identifier: "MyRecordVC") as? MyRecordVC {
                vc.selectToolType = .extractAudio
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
    
    // MARK: - Button Action -
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        if soundOnOff {
            audioPlayer.stop()
            timerT?.invalidate()
            timerT = nil
            soundOnOff = false
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func addButtonAction(_ sender: UIButton) {
        presentPHpicker()
    }

}

extension ExtractMusicViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return extractAudio.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if nextCell == indexPath.row {
            return 180
        }else{
            return 75
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = musicTableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! VoiceRecordTvCell
        cell.selectionStyle = .none
        
        cell.extract = extractAudio[indexPath.row]
        
        cell.optionButton.tag = indexPath.row
        cell.trashButton.addTarget(self, action: #selector(deleteVoiceRecord), for: .touchUpInside)
        cell.optionButton.addTarget(self, action: #selector(optionButtonAction), for: .touchUpInside)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        previousCell = indexPath.row
        
        if previousCell != nextCell { /// when new cell action then this block working.  same cell action ignore this block
            /// new cell action
            
            print("p : \(previousCell) = n: \(nextCell)")
            timerT?.invalidate()
            timerT = nil
            audioPlayer.stop()
            soundOnOff = false
            
            let cell = musicTableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! VoiceRecordTvCell
            cell.playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            cell.currentDurationLbl.text = "00:00"
            cell.endingDurationLbl.text = "00:00"
            
            cell.slider.value = 0
            cell.counter = 0.0
            audioPlayer.currentTime = 0.0
            
            if let name = extractAudio[indexPath.row].name {
                if  let recordedDirURL = DirectoryManager.shared.extractAudioDirPath() {
                    let audioURL = recordedDirURL.appendingPathComponent(name + ".m4a")
                    
                    do {
                        audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
                    } catch let error as NSError {
                        print(error.localizedDescription)
                    } catch {
                        print("AVAudioPlayer init failed")
                    }
                }
            }
        }
        
        nextCell = previousCell
        
        musicTableView.reloadRows(at: [indexPath], with: .automatic)
        musicTableView.deselectRow(at: indexPath, animated: true)
    }
    
    @objc func deleteVoiceRecord(_ sender: UIButton) {
        
        if let selectedCell = sender.superview?.superview?.superview as? VoiceRecordTvCell {
            if let indexPath = self.musicTableView.indexPath(for: selectedCell) {
                
                let record = extractAudio[indexPath.row]
                let index = indexPath.row
                debugPrint("selected record : \(record.name)")
                
                if let name = record.name {
                    
                    if  let recordedDirURL = DirectoryManager.shared.extractAudioDirPath(), let thumbImageUrl =  DirectoryManager.shared.extractAudioThumDirPath() {
                        
                        let audioURL = recordedDirURL.appendingPathComponent(name + ".m4a")
                        let thumbUrl = thumbImageUrl.appendingPathComponent(name + ".jpg")
                        debugPrint("delete url: \(audioURL)")
                        
                        DispatchQueue.main.async {
                            let refreshAlert = UIAlertController(title: "", message: "Are you sure you want to delete the Voice Record?", preferredStyle: UIAlertController.Style.alert)
                            
                            refreshAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (action: UIAlertAction!) in
                                
                                GifManager.shared.deleteFile(audioURL)
                                GifManager.shared.deleteFile(thumbUrl)
                                
                                self.context.delete(record)
                                
                                try? self.context.save()
                                self.extractAudio.remove(at: index)
                                self.musicTableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                                
                                if soundOnOff {
                                    audioPlayer.stop()
                                    timerT?.invalidate()
                                    timerT = nil
                                    soundOnOff = false
                                }
                                //self.recordTableView.reloadData()
                                self.checkEmpty()
                            }))
                            
                            refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                                print("Handle Cancel Logic here")
                                refreshAlert .dismiss(animated: true, completion: nil)
                            }))
                            
                            self.present(refreshAlert, animated: true, completion: nil)
                        }
                    }
                }
                
            }
        }
    }
    
    @objc func optionButtonAction(_ sender: UIButton) {
        showAlert(tag: sender.tag)
    }
    
    func showAlert(tag : Int){
        let actionsheet = UIAlertController(title: extractAudio[tag].name, message: "", preferredStyle: .actionSheet)
        
        actionsheet.addAction(UIAlertAction(title: "Share", style: .default , handler: { (UIAlertAction)in
            
            let record = self.extractAudio[tag]
            if let name = record.name {
                
                if  let recordedDirURL = DirectoryManager.shared.extractAudioDirPath() {
                    let activityItem = recordedDirURL.appendingPathComponent(name + ".m4a")
                    
                    let activityVC = UIActivityViewController(activityItems: [activityItem],applicationActivities: nil)
                    activityVC.popoverPresentationController?.sourceView = self.view
                    self.present(activityVC, animated: true, completion: nil)
                }
            }
        }))
        
        actionsheet.addAction(UIAlertAction(title: "Rename", style: .default , handler: { (UIAlertAction)in
            self.renameAudio(tag: tag)
        }))
        
        actionsheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ (UIAlertAction) in
                print("User click Dismiss button")
        }))
        self.present(actionsheet, animated: true)
    }
    
    func renameAudio(tag: Int) {
        
        let record = self.extractAudio[tag]
        if let name = record.name {
            
            let vc = UIAlertController(title: "Rename", message: "Enter Aspected file name", preferredStyle: .alert)
            vc.addTextField { textField in
                textField.placeholder = name
            }
            vc.addAction(UIAlertAction(title: "Rename", style: .default, handler: { action in
                let textField = vc.textFields?.first
                
                if let newFileName = textField?.text {
                    
                    guard let folderPath = DirectoryManager.shared.extractAudioDirPath() else{return}
                    guard let thumbImageDirUrl = DirectoryManager.shared.extractAudioThumDirPath() else{return}

                    let currentAudioURL = URL(fileURLWithPath: folderPath.path.appending("/\(name).m4a"))
                    let currentThumbURL = URL(fileURLWithPath: thumbImageDirUrl.path.appending("/\(name).jpg"))
                    
                    let renameAudioURL = URL(fileURLWithPath: folderPath.path.appending("/\(newFileName).m4a"))
                    let renameThumbURL = URL(fileURLWithPath: thumbImageDirUrl.path.appending("/\(newFileName).jpg"))
                    
                    debugPrint(renameThumbURL)
                    do {
                        try? FileManager.default.moveItem(at: currentAudioURL, to: renameAudioURL)
                        try? FileManager.default.moveItem(at: currentThumbURL, to: renameThumbURL)

                        if !newFileName.isEmpty {
                            self.extractAudio[tag].name = newFileName
                            self.extractAudio[tag].thumbName = newFileName
                            try? self.context.save()
                        }
                        
                        DispatchQueue.main.async {
                            self.musicTableView.reloadRows(at: [IndexPath(row: tag, section: 0)], with: .automatic)
                        }
                    } catch let error {
                        print("Error renaming file: \(error)")
                    }
                }
            }))
            vc.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(vc, animated: true)
        }
    }
}

extension ExtractMusicViewController: PHPickerViewControllerDelegate {
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

private extension ExtractMusicViewController {
    
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
            self.mediaItems.append(item: PhotoPickerModel(with: image))
            
        } else if let url = object as? URL {
            //displayVideoPlayButton(forURL: url)
            recevedCount += 1
            self.mediaItems.append(item: PhotoPickerModel(with: url))
            
        } else if let error = error {
            recevedCount += 1
        }
        
        if recevedCount == selection.count{
            
            DispatchQueue.main.async {
                //self.progressView.isHidden = true
                dismissLoader()
            }
            
            if let url = self.mediaItems.items.first?.url {
                goToVideoToAudioVC(videoUrl: url)
            }
        }
    }
    
    func goToVideoToAudioVC(videoUrl: URL){
        if let vc = loadVCfromStoryBoard(name: "VideoToAudio", identifier: "VideoToAudioViewController") as? VideoToAudioViewController {
            let video = Video(videoUrl)
            vc.video = video
            DispatchQueue.main.async{
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}
