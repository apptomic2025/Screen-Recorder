//
//  AddMusicViewController.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 22/3/25.
//

import UIKit
import AVFoundation
import MediaPlayer
import PhotosUI

protocol AddMusicDelegate: AnyObject{
    func selectedMusic(addMusicModel: AddMusicModel)
}

enum MusicListType{
    case  musicCollection, iTunes, extract
}
class MusicGroup{
    var type: MusicListType

    init(type: MusicListType) {
        self.type = type
    }
}

class AddMusicViewController: UIViewController {

    @IBOutlet weak var extractFromFileButton: UIButton!
    @IBOutlet weak var extractFromVideo: UIButton!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var tableViewEmptyMessage: UIView!
    @IBOutlet weak var stactViewForExtractTab: UIStackView!
    @IBOutlet weak var sliderIndicatiorView: UIView!
    @IBOutlet weak var tableView : UITableView!
    @IBOutlet weak var favoriteMusicButton: UIButton!
    @IBOutlet weak var musicButton: UIButton!
    @IBOutlet weak var iTunesButton: UIButton!
    @IBOutlet weak var extractButton: UIButton!
    
    var indicatorView = UIView()
    var musicGroups: [MusicGroup] = [ MusicGroup(type: .musicCollection),MusicGroup(type: .iTunes),MusicGroup(type: .extract)]
    var musicType : MusicListType = .musicCollection
    var selectedIndex: Int?
    var prev: Int?
    
    var trimStartTime = 0.0
    var trimEndTime = 0.0
    weak var delegate : AddMusicDelegate?
    
    var tableViewData : [MusicCollectionModel] = []
    
    var extractedMusicsFolderPath : URL?
    var trimedMusicsFolderPaht : URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden  = true
        extractFromFileButton.layer.cornerRadius = 6
        extractFromVideo.layer.cornerRadius = 6
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 90, right: 0)
        
        setupTableView()
        
        //MARK: - Indicator View -
        let controlForCenter = musicButton.frame.width / 3
        indicatorView = UIView(frame: CGRect(x: controlForCenter / 2, y: 0, width: musicButton.frame.width - controlForCenter, height: sliderIndicatiorView.bounds.height))
        indicatorView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) //UIColor(red:255/255.0, green:202/255.0, blue:15/255.0, alpha:1.0)
        sliderIndicatiorView.addSubview(indicatorView)
        musicButton.titleLabel?.font = UIFont(name: "CircularStd-Medium.otf", size: 18)
        musicButton.setTitleColor(UIColor.white, for: .normal)
        
        //MARK: - Create Audios Directory and create two Sub Directory -
        do{
            let docURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let appnoPath = createDirectory(url: docURL, folderName: "Audios")
            if FileManager.default.fileExists(atPath: appnoPath){
                extractedMusicsFolderPath = URL(fileURLWithPath: createDirectory(url: URL(fileURLWithPath: appnoPath), folderName: "Extracted Musics"))
                print(appnoPath)
                //trimedMusicsFolderPaht = URL(fileURLWithPath: createDirectory(url: URL(fileURLWithPath: appnoPath), folderName: "Trimmed Musics"))
            }
        }catch{}
        
        loadData(for: musicType)

    }
    //MARK: - Button Click Action -
    
    @IBAction func crossButtonAction(_ sender: UIButton){
        self.dismiss(animated: true)
    }
    
    
    @IBAction func musicGroupButton(_ sender: UIButton){
        buttonSlideControl(sender: sender)
    }
    
    @IBAction func extractAudioFromVideoButton(_ sender: UIButton) {
        
        if selectedIndex != nil{
            guard let index = selectedIndex else{return}
            let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as! AddMusicTableViewCell
            if cell.btnPlayMusic.imageView?.image == UIImage(named: "pauseButton"){
                cell.player?.pause()
                cell.view.backgroundColor = .black
                cell.btnPlayMusic.setImage(UIImage(named: "playButton"), for: .normal)
            }
            selectedIndex = nil
            prev = nil
            tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            tableView.deselectRow(at: IndexPath(row: index, section: 0), animated: true)
        }
        var pickerConfig = PHPickerConfiguration()
        pickerConfig.selectionLimit = 1
        pickerConfig.filter = .videos
        
        let pickerVC = PHPickerViewController(configuration: pickerConfig)
        pickerVC.delegate = self
        self.present(pickerVC, animated: true, completion: nil)
    }
    
    @IBAction func pickAudioFromFileButton(_ sender: UIButton) {
        if selectedIndex != nil{
            guard let index = selectedIndex else{return}
            let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as! AddMusicTableViewCell
            if cell.btnPlayMusic.imageView?.image == UIImage(named: "pauseButton"){
                cell.player?.pause()
                cell.view.backgroundColor = .black
                cell.btnPlayMusic.setImage(UIImage(named: "playButton"), for: .normal)
            }
            selectedIndex = nil
            prev = nil
            tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            tableView.deselectRow(at: IndexPath(row: index, section: 0), animated: true)
        }
        audioPicker(type: .audio)
    }
    
    @IBAction func closeButton(_ sender: UIButton) {
        if selectedIndex != nil{
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "controlAudio"), object: nil, userInfo: nil)
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    //MARK: - Methods for load Data -
    func loadMusicsAudios() -> [MusicCollectionModel]{
        
        func musicAddToArray(name: String, duration: Double, artitstName: String) -> MusicCollectionModel{
            MusicCollectionModel(name: name, duration: duration, songURL: Bundle.main.url(forResource: name, withExtension: ".mp3"), artistName: artitstName, thumbImage: UIImage(named: name) ?? UIImage(named: "default"))
        }
        
        var musics : [MusicCollectionModel] = []
        musics.append(musicAddToArray(name: "Sedative", duration: 181, artitstName: "Lesfm"))
        musics.append(musicAddToArray(name: "The Cradle of Your Soul", duration: 177, artitstName: "lemonmusicstudio"))
        musics.append(musicAddToArray(name: "Cinematic Documentary", duration: 131, artitstName: "Lexin Music"))
        musics.append(musicAddToArray(name: "In the Forest - Ambient Acoustic Guitar Instrumental Background Music For Videos", duration: 119, artitstName: "Lesfm"))
        musics.append(musicAddToArray(name: "Jazzy Abstract Beat", duration: 85, artitstName: "Coma-Media"))
        musics.append(musicAddToArray(name: "Freedom Inspired Cinematic Background Music For Video", duration: 140, artitstName: "Lesfm"))
        musics.append(musicAddToArray(name: "The Beat of Nature", duration: 173, artitstName: "Olexy"))
        musics.append(musicAddToArray(name: "Simple Piano Melody", duration: 91, artitstName: "Daddy s Music"))
        musics.append(musicAddToArray(name: "Bookmark In a Book", duration: 134, artitstName: "AudioCoffee"))
        musics.append(musicAddToArray(name: "Voice Over Music", duration: 130, artitstName: "SoulProdMusic"))
        musics.append(musicAddToArray(name: "Happy Day", duration: 170, artitstName: "Stockaudios"))
        musics.append(musicAddToArray(name: "Inspire Tomorrow", duration: 164, artitstName: "AudioCoffee"))
        musics.append(musicAddToArray(name: "The Weekend", duration: 145, artitstName: "chillmore"))
        musics.append(musicAddToArray(name: "Playful", duration: 148, artitstName: "AudioCoffee"))
        musics.append(musicAddToArray(name: "Lounge House (Where the Light Lives)", duration: 141, artitstName: "AlexGrohl"))
        musics.append(musicAddToArray(name: "Acoustic Motivation", duration: 105, artitstName: "Coma-Media"))
        
        
        
        return musics
    }
    func loadItunesMusic() -> [MusicCollectionModel]{
        var musics : [MusicCollectionModel] = []
        if let iTunesMusicItems = MPMediaQuery.songs().items{
            for item in iTunesMusicItems{
                if let url = item.assetURL{
                    var name : String = ""
                    if let names = item.title{
                        name = names
                    }
                    var artitstName : String = "Unknown"
                    if let artitst = item.artist{
                        artitstName = artitst
                    }
                    var image : UIImage?
                    if let artwork: MPMediaItemArtwork = item.value(forProperty: MPMediaItemPropertyArtwork) as? MPMediaItemArtwork{
                        image = artwork.image(at: CGSize(width: 44, height: 44))
                    }
                    let iTunesMusic = MusicCollectionModel(name: name, duration: item.playbackDuration, songURL:  url, artistName: artitstName, thumbImage: image)
                    musics.append(iTunesMusic)
                }
            }
        }
        return musics
    }
    
    func loadExtractedMusic() -> [MusicCollectionModel]{
        let musics : [MusicCollectionModel] = []
        if let url = extractedMusicsFolderPath{
            return loadMusicFromFolder(folder: url)
        }
        return musics
    }
    
    //Load Extracted Music From Document Directory
    func loadMusicFromFolder(folder: URL) -> [MusicCollectionModel]{
        var musics : [MusicCollectionModel] = []
        do{
            let urls = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.contentTypeKey], options: [.skipsHiddenFiles])
            for url in urls {
                let asset = AVAsset(url: url)
                let music = MusicCollectionModel(name: url.lastPathComponent, duration: asset.duration.seconds, songURL: url)
                musics.append(music)
            }
        }catch{}
        return musics
    }
    
    //MARK: - Private Method -
    func createDirectory(url: URL, folderName: String) -> String{
        let folderPath = url.appendingPathComponent(folderName)
        do{
            if !FileManager.default.fileExists(atPath: folderPath.path){
                try FileManager.default.createDirectory(at: folderPath, withIntermediateDirectories: true, attributes: nil)
                return folderPath.path
            }
            return folderPath.path
        }catch{}
        return folderPath.path
    }
    
    func loadData(for type: MusicListType){
        switch type{
            case .musicCollection:
                tableViewData = loadMusicsAudios()
            case .iTunes:
                tableViewData = loadItunesMusic()
            case .extract:
                tableViewData = loadExtractedMusic()
        }
        
        selectedIndex = nil
        prev = nil
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func buttonSlideControl(sender: UIButton){
        
        musicType = musicGroups[sender.tag].type
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "controlAudio"), object: nil, userInfo: nil)
        if sender.tag == extractButton.tag{
            stactViewForExtractTab.isHidden = false
        }else{
            stactViewForExtractTab.isHidden = true
        }
        
        let controlForCenter = sender.frame.width / 3
        let position = CGRect(x: sender.frame.minX + (controlForCenter / 2), y: 0, width: sender.frame.width - controlForCenter, height: sliderIndicatiorView.bounds.height)
        UIView.animate(withDuration: 0.25, delay: 0.0) {
            self.indicatorView.frame = position
        }
        if sender.tag == musicButton.tag{
                musicButton.titleLabel?.font = UIFont(name: "CircularStd-Medium", size: 18)
                musicButton.setTitleColor(UIColor.white, for: .normal)
                
                textColorChange(for: extractButton)
                textColorChange(for: iTunesButton)
            }
            
            else if sender.tag == iTunesButton.tag{
                iTunesButton.titleLabel?.font = UIFont(name: "CircularStd-Medium", size: 18)
                iTunesButton.setTitleColor(UIColor.white, for: .normal)
                
                textColorChange(for: musicButton)
                textColorChange(for: extractButton)
                
            }else{
                extractButton.titleLabel?.font = UIFont(name: "CircularStd-Medium", size: 18)
                extractButton.setTitleColor(UIColor.white, for: .normal)
                
                textColorChange(for: musicButton)
                textColorChange(for: iTunesButton)
            }
        loadData(for: musicGroups[sender.tag].type)
    }
    
    func textColorChange(for button: UIButton){
        button.titleLabel?.font = UIFont(name: "CircularStd-Book", size: 16)
        button.setTitleColor(UIColor.gray, for: .normal)
    }

    func setupTableView(){
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "AddMusicTableViewCell", bundle: nil), forCellReuseIdentifier: "AddMusicTableViewCell")
    }
    
    //Second Double to Time Format
    func stringFromTimeInterval(interval: TimeInterval) -> String {
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
//        let hours = (interval / 3600)
//        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        return String(format: "%02d:%02d", minutes, seconds)

    }
    
    //File name Generator
    func fileURLGenerator(with url: URL, name: String) -> URL{
        var duplicateName = "\(name).m4a"
        var fileURL = url.appendingPathComponent("\(duplicateName)")
        if FileManager.default.fileExists(atPath: fileURL.path){
            duplicateName = "CopyOf_\(duplicateName)"
            fileURL = url.appendingPathComponent("\(duplicateName)")
        }
        return fileURL
    }
}

extension AddMusicViewController : UITableViewDelegate, UITableViewDataSource, TrimTime{
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.selectedIndex == indexPath.row{
            return 197
        }else{
            return 60
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AddMusicTableViewCell", for: indexPath) as! AddMusicTableViewCell
        cell.favoriteMusicButton.isHidden = true
        if musicType == .extract{
            cell.addMusicButton.setImage(UIImage(named: "optionMenu"), for: .normal)
        }else{
            cell.addMusicButton.setImage(UIImage(named: "expandMusic"), for: .normal)
        }
        cell.deleget = self
        let music = tableViewData[indexPath.row]
        
        cell.musicThumbImage.image = music.thumbImage ?? UIImage(named: "defaultMusicThumb")
        cell.musicTitle.text = music.name ?? music.songURL?.deletingPathExtension().lastPathComponent
        cell.musicSubTitle.text = "\(music.artistName ?? "Unknown")  -  \(stringFromTimeInterval(interval: music.duration ?? 0.0))"
        cell.durationLabel.text = stringFromTimeInterval(interval: music.duration ?? 0.0)
        if let url = music.songURL{
            let asset = AVAsset(url: url)
            cell.musicSubTitle.text = "\(music.artistName ?? "Unknown")  -  \(stringFromTimeInterval(interval: asset.duration.seconds))"
            cell.durationLabel.text = stringFromTimeInterval(interval: asset.duration.seconds)
        }
        
        cell.btnPlayMusic.tag = indexPath.row
        cell.favoriteMusicButton.tag = indexPath.row
        cell.addMusicButton.tag = indexPath.row
        cell.addMusicButton.addTarget(self, action: #selector(addMusicToPreviewPage), for: .touchUpInside)
        cell.btnPlayMusic.addTarget(self, action: #selector(musicItemExpandControl), for: .touchUpInside)
        return cell
    }
    
    //MARK: - Play Pause Button Control with Object Method -
    @objc func musicItemExpandControl(_ sender: UIButton){
        
        selectedIndex = sender.tag
        let indexPath = IndexPath(row: sender.tag, section: 0)
        
        if let prev = prev{
            if prev != sender.tag{
                let prevCell = self.tableView.cellForRow(at: IndexPath(row: prev, section: 0)) as! AddMusicTableViewCell
                if musicType == .extract{
                    prevCell.addMusicButton.setImage(UIImage(named: "optionMenu"), for: .normal)
                }
                prevCell.url = nil
                prevCell.player?.pause()
                prevCell.view.backgroundColor = .black
                prevCell.btnPlayMusic.setImage(UIImage(named: "playButton"), for: .normal)
                
                tableView.reloadRows(at: [indexPath], with: .automatic)
                tableView.deselectRow(at: indexPath, animated: true)
                
                //expand new row
                let cell = tableView.cellForRow(at: indexPath) as! AddMusicTableViewCell
                if musicType == .extract{
                    cell.addMusicButton.setImage(UIImage(named: "expandMusic"), for: .normal)
                }
                cell.btnPlayMusic.setImage(UIImage(named: "pauseButton"), for: .normal)
                cell.view.backgroundColor = UIColor(red: 26/255, green: 26/255, blue: 26/255, alpha: 1)
                cell.url = tableViewData[sender.tag].songURL
            }else{
                //Play Pause control
                if let currentCell = self.tableView.cellForRow(at: indexPath) as? AddMusicTableViewCell{
                    
                    if currentCell.btnPlayMusic.imageView?.image == UIImage(named: "pauseButton"){
                        currentCell.btnPlayMusic.setImage(UIImage(named: "playButton"), for: .normal)
                        currentCell.player?.pause()
                    }else{
                        currentCell.btnPlayMusic.setImage(UIImage(named: "pauseButton"), for: .normal)
                        currentCell.player?.play()
                    }
                    
                }
            }
        }else{
            tableView.reloadRows(at: [indexPath], with: .automatic)
            tableView.deselectRow(at: indexPath, animated: true)
            
            let cell = tableView.cellForRow(at: indexPath) as! AddMusicTableViewCell
            if musicType == .extract{
                cell.addMusicButton.setImage(UIImage(named: "expandMusic"), for: .normal)
            }
            cell.btnPlayMusic.setImage(UIImage(named: "pauseButton"), for: .normal)
            cell.view.backgroundColor = UIColor(red: 26/255, green: 26/255, blue: 26/255, alpha: 1)
            cell.url = tableViewData[sender.tag].songURL
        }
        prev = sender.tag
    }
    
    //MARK: - Trim Audio in a time range -
    func trimAudioSave(with range: CMTimeRange, and url: URL, complition: @escaping (URL?) -> Void){
        var asset = AVAsset(url: url)
        if musicType == .iTunes{
            asset = AVURLAsset(url: url)
        }else{
            asset = AVAsset(url: url)
        }
        let composition = AVMutableComposition()
        let track = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        do {
            try track?.insertTimeRange(range, of: asset.tracks(withMediaType: .audio)[0], at: .zero)
        } catch {
            print(error)
        }
        
        // Export the trimmed audio
        let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
        exporter?.outputFileType = .m4a
//        let outputURL = trimedMusicsFolderPaht!.path.appending("/tempAudio.m4a")
       // guard let trimedMusicsFolderPaht = trimedMusicsFolderPaht else{return}
//        guard let trimedMusicsFolderPaht = DirectoryManager.shared.tempDirPath() else { return }
//        let outputURL = fileURLGenerator(with: trimedMusicsFolderPaht, name: url.deletingPathExtension().lastPathComponent)
        
        guard let tempDirURL = DirectoryManager.shared.tempDirPath() else { return }
        let outputURL = tempDirURL.appendingPathComponent("trimWithExtractAudio.m4a")
        
        debugPrint(outputURL)
        
        DirectoryManager.shared.deleteFile(outputURL) /// remove previous url.
        
        exporter?.outputURL = outputURL
        exporter?.exportAsynchronously(completionHandler: {
            switch exporter?.status {
            case .completed:
                complition(outputURL)
                print("Audio trimmed and exported successfully.")
            case .failed:
                complition(nil)
                print("Export failed.")
            case .cancelled:
                complition(nil)
                print("Export cancelled.")
            default:
                complition(nil)
                break
            }
        })
    }
    
    //MARK: - Add music to Preview page
    @objc func addMusicToPreviewPage(sender: UIButton){
        
        //showLoader(view: self.view)

        if musicType == .extract {
            if sender.imageView?.image == UIImage(named: "expandMusic"){
                sender.setImage(UIImage(named: "expandMusic"), for: .normal)
                if let url = tableViewData[sender.tag].songURL{
                    let asset = AVAsset(url: url)
                    let startTime = trimStartTime
                    var endTime = trimEndTime
                    if endTime == 0.0{
                        endTime = asset.duration.seconds
                    }
                    
                    DispatchQueue.main.async {
                        showLoader(view: self.view)
                    }
                    
                    var returnMusicModel = AddMusicModel(startTime: startTime, endTime: endTime, asset: asset)
                    trimAudioSave(with: CMTimeRange(start: CMTime(value: CMTimeValue(startTime), timescale: 1), end: CMTime(value: CMTimeValue(endTime), timescale: 1)), and: url) { [self] url in
                        if let url = url{
                            DispatchQueue.main.async {
                                returnMusicModel = AddMusicModel(startTime: startTime, endTime: endTime, asset: asset, url: url)
                                self.delegate?.selectedMusic(addMusicModel: returnMusicModel)
                                dismissLoader()
                                self.dismiss(animated: true)
                            }
                        }else{
                            DispatchQueue.main.async {
                                self.delegate?.selectedMusic(addMusicModel: returnMusicModel)
                                self.showAlert(title: "Error", message: "Some problem Occure.")
                                dismissLoader()
                                self.dismiss(animated: true)
                            }
                        }
                    }
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "controlAudio"), object: nil, userInfo: nil)
                }
                return
            }else{
                showAlert(tag: sender.tag)
                sender.setImage(UIImage(named: "optionMenu"), for: .normal)
                return
            }
        }
        if let url = tableViewData[sender.tag].songURL {
            let asset = AVAsset(url: url)
            let startTime = trimStartTime
            var endTime = trimEndTime
            if endTime == 0.0{
                endTime = asset.duration.seconds
            }
            
            DispatchQueue.main.async {
                showLoader(view: self.view)
            }
            
            var returnMusicModel = AddMusicModel(startTime: startTime, endTime: endTime, asset: asset)
            trimAudioSave(with: CMTimeRange(start: CMTime(value: CMTimeValue(startTime), timescale: 1), end: CMTime(value: CMTimeValue(endTime), timescale: 1)), and: url) { [self] url in
                if let url = url {
                    DispatchQueue.main.async {
                        returnMusicModel = AddMusicModel(startTime: startTime, endTime: endTime, asset: asset, url: url)
                        self.delegate?.selectedMusic(addMusicModel: returnMusicModel)
                        
                        dismissLoader()
                        self.dismiss(animated: true)
                    }
                }else{
                    DispatchQueue.main.async {
                        self.delegate?.selectedMusic(addMusicModel: returnMusicModel)
                        self.showAlert(title: "Error", message: "Some problem Occure.")
                    }
                }
            }
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "controlAudio"), object: nil, userInfo: nil)
        }
    }
    
    //Showing Alert
    func showAlert(tag : Int){
        let alert = UIAlertController(title: "Option", message: "Pick What you want to do!", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Add Music", style: .default, handler: {[self] alert in
            if let url = tableViewData[tag].songURL{
                let asset = AVAsset(url: url)
                let startTime = trimStartTime
                var endTime = trimEndTime
                if endTime == 0.0{
                    endTime = asset.duration.seconds
                }
                DispatchQueue.main.async {
                    showLoader(view: self.view)
                }
                
                var returnMusicModel = AddMusicModel(startTime: startTime, endTime: endTime, asset: asset)
                trimAudioSave(with: CMTimeRange(start: CMTime(value: CMTimeValue(startTime), timescale: 1), end: CMTime(value: CMTimeValue(endTime), timescale: 1)), and: url) { [self] url in
                    if let url = url{
                        DispatchQueue.main.async {
                            returnMusicModel = AddMusicModel(startTime: startTime, endTime: endTime, asset: asset, url: url)
                            self.delegate?.selectedMusic(addMusicModel: returnMusicModel)
                            dismissLoader()
                            self.dismiss(animated: true)
                        }
                    }else{
                        DispatchQueue.main.async {
                            self.delegate?.selectedMusic(addMusicModel: returnMusicModel)
                            self.showAlert(title: "Error", message: "Some problem Occure.")
                            dismissLoader()
                            self.dismiss(animated: true)
                        }
                    }
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Rename", style: .default, handler: { alert in
            if let url = self.tableViewData[tag].songURL{
                if self.selectedIndex != nil{
                    guard let index = self.selectedIndex else{return}
                    let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as! AddMusicTableViewCell
                    if cell.btnPlayMusic.imageView?.image == UIImage(named: "pauseButton"){
                        cell.player?.pause()
                        cell.view.backgroundColor = .black
                        cell.btnPlayMusic.setImage(UIImage(named: "playButton"), for: .normal)
                    }
                    self.selectedIndex = nil
                    self.prev = nil
                    self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    self.tableView.deselectRow(at: IndexPath(row: index, section: 0), animated: true)
                }
                self.renameAction(currentFileName: url.lastPathComponent) { result in
                    if result{
                        self.loadData(for: .extract)
                    }
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: {[self] alert in
            if let url = tableViewData[tag].songURL{
                deleteMusic(audioURL: url) { result in
                    if result{
                        print("Music Delted Success")
                        self.buttonSlideControl(sender: self.extractButton)
                    }else{
                        print("Music Not Deleted")
                    }
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Cencel", style: .cancel))
        self.present(alert, animated: true)
    }

    // Trim Time get from trim delegate
    func getTime(startTime: Double, endTime: Double) {
        trimStartTime = startTime
        trimEndTime = endTime
    }
    
    // delete music
    func deleteMusic(audioURL: URL, completion: @escaping (Bool) -> Void){
        do {
             let fileManager = FileManager.default
            
            // Check if file exists
            if fileManager.fileExists(atPath: audioURL.path) {
                // Delete file
                try fileManager.removeItem(atPath: audioURL.path)
                completion(true)
            } else {
                completion(false)
                print("File does not exist")
            }
         
        }
        catch let error as NSError {
            print("An error took place: \(error)")
        }
    }
    
    //Rename Extracted Audio File
    func renameFile(currentFileName: String, newFileName: String) {
        guard let folderPath = extractedMusicsFolderPath else{return}
        let currentPath = folderPath.path.appending("/\(currentFileName)")
        let currentURL = URL(fileURLWithPath: currentPath)
        let newPath = folderPath.path.appending("/\(newFileName).m4a")
        let newURL = URL(fileURLWithPath: newPath)

        do {
            try FileManager.default.moveItem(at: currentURL, to: newURL)
        } catch let error {
            print("Error renaming file: \(error)")
        }
    }
    
    func renameAction(currentFileName: String, complition: @escaping (Bool) -> Void){
        let vc = UIAlertController(title: "Rename", message: "Enter Aspected file name", preferredStyle: .alert)
        vc.addTextField { textField in
            textField.placeholder = "Enter aspected file name.."
        }
        vc.addAction(UIAlertAction(title: "Rename", style: .default, handler: { action in
            let textField = vc.textFields?.first
            if let text = textField?.text{
                self.renameFile(currentFileName: currentFileName, newFileName: text)
                complition(true)
            }else{
                complition(false)
            }
        }))
        vc.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(vc, animated: true)
    }
}

//MARK: - Phpicker Delegate Extract Audio From Video Funtonality
extension AddMusicViewController : PHPickerViewControllerDelegate{
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        if results.isEmpty {
            picker.dismiss(animated: true)
            return
        }
        
        let provider = results.first?.itemProvider
        guard let provider = provider else{return}
        progressView.isHidden = false
        provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [self] url, error in
            guard error == nil, let url = url else { return }
            if let destinationPath = extractedMusicsFolderPath{
                let destinationURL = fileURLGenerator(with: destinationPath, name: url.deletingPathExtension().lastPathComponent)
                extractAudioFromVideo(inputURL: url, outputURL: destinationURL) { error in
                    if error == nil{
                        print("Extracted Audio Save in Doc Dir")
                        self.loadData(for: .extract)
                        DispatchQueue.main.async {
//                            self.showAlert(title: "Success", message: "music extracted from video success.")
                            self.progressView.isHidden = true
                        }
                    }else{
                        print(error?.localizedDescription as Any)
                        DispatchQueue.main.async {
                            self.showAlert(title: "Error", message: "Extract audio from video failed!")
                            self.progressView.isHidden = true
                        }
                    }
                    
                }
            }
        }
        self.dismiss(animated: true)
    }
    
    func extractAudioFromVideo(inputURL: URL, outputURL: URL, completion: @escaping (Error?) -> Void) {
        let asset = AVURLAsset(url: inputURL)
        let composition = AVMutableComposition()

        // Extract the audio track from the asset
        guard let audioAssetTrack = asset.tracks(withMediaType: .audio).first else {
            completion(NSError(domain: "Unknown", code: -1, userInfo: nil))
            return
        }

        let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: audioAssetTrack.trackID)

        do {
            try audioCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: asset.duration), of: audioAssetTrack, at: .zero)
        } catch let error {
            completion(error)
            return
        }

        // Export the audio track to a file
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            completion(NSError(domain: "Unknown", code: -1, userInfo: nil))
            return
        }

        exportSession.outputFileType = AVFileType.m4a
        exportSession.outputURL = outputURL

        exportSession.exportAsynchronously {
            if exportSession.status == .completed {
                completion(nil)
            } else {
                let error = exportSession.error ?? NSError(domain: "Unknown", code: -1, userInfo: nil)
                completion(error)
            }
        }
    }
}

//MARK: - Audio Pick and save -
extension AddMusicViewController : UIDocumentPickerDelegate{
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
           if let selectedURL = urls.first {
                saveFile(url: selectedURL)
            }
       }
    
    func saveFile (url: URL) {
        if (CFURLStartAccessingSecurityScopedResource(url as CFURL)) { // <- here
            
            let fileData = try? Data.init(contentsOf: url)
            
            
            guard let extractedMusicsFolderPath = extractedMusicsFolderPath else{ return}
            
            //Modification File Name
            var name = "\(url.lastPathComponent)"
            var fileURL = extractedMusicsFolderPath.appendingPathComponent("\(name)")
            if FileManager.default.fileExists(atPath: fileURL.path){
                name = "CopyOf_\(name)"
                fileURL = extractedMusicsFolderPath.appendingPathComponent("\(name)")
            }
            //-------------
            
//            let actualPath = fileURLGenerator(with: extractedMusicsFolderPath, name: url.deletingPathExtension().lastPathComponent)
            
            do {
//                try FileManager.default.copyItem(at: url, to: fileURL)
//                loadData(for: .extract)
//                tableView.reloadData()
                try fileData?.write(to: fileURL)
                if(fileData == nil){
                    print("Permission error!")
                }
                else {
                    loadData(for: .extract)
                    tableView.reloadData()
                    print("Success.")
                }
            }catch {
                print(error.localizedDescription)
            }
            CFURLStopAccessingSecurityScopedResource(url as CFURL) // <- and here
        }
        else {
            print("Permission error!")
        }
    }
    
    func audioPicker(type: UTType){
        let pickerController = UIDocumentPickerViewController(forOpeningContentTypes: [type])
        pickerController.delegate = self
        //        pickerController.modalPresentationStyle = .fullScreen
        self.present(pickerController, animated: true, completion: nil)
    }
    
    func saveMusic(audioURL: URL, destination: URL?, completion: @escaping (URL?) -> Void){
        DispatchQueue.main.async { [weak self] in
            guard self != nil else { return }
            if let audioData = try? Data(contentsOf: audioURL){
                if let destinationPath = destination?.path.appending("/\(audioURL.lastPathComponent)"){
                    let destinationURL = URL(fileURLWithPath: destinationPath)
                    if !FileManager.default.fileExists(atPath: destinationURL.path){
                        if (try? audioData.write(to: destinationURL)) != nil{
                            completion(destinationURL)
                        }else{
                            completion(nil)
                        }
                    }
                    else{
                        completion(destinationURL)
                    }
                }
            }
        }
    }
}

//MARK: - Showing Alert for event -
extension AddMusicViewController{
    func showAlert(title: String?, message: String?){
        let vc = UIAlertController(title: title, message: message, preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(vc, animated: true)
    }
}

