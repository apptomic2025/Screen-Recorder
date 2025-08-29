//
//  VoiceRecordViewController.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 21/3/25.
//

import UIKit
import AVFoundation
import CoreData

class VoiceRecordViewController: UIViewController {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    @IBOutlet weak var waveformView: WaveformView!
    @IBOutlet weak var waveformViewNSButtonLayout: NSLayoutConstraint!
    
    @IBOutlet weak var playButtonBgView: UIView!
    
    @IBOutlet weak var recordNameLabel: UILabel!
    @IBOutlet weak var recordingDurationLabel: UILabel!
    @IBOutlet weak var emptyView: UIView!
    var recordButton: RecordButton?
    
    @IBOutlet weak var recordTableView: UITableView!{
        didSet{
            recordTableView.isHidden = true
        }
    }

    var audioRecorder : AVAudioRecorder?
    //var audioPlayer : AVAudioPlayer?
    
    fileprivate var timer: Timer!
    var isRecording : Bool = false
    
    var voiceRecords : [VoiceRecord] = []
    
    var selectedIndex: Int?
    var prev: Int?
    
    var previousCell: Int?
    var nextCell: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        recordTableView.estimatedRowHeight = 190
        recordTableView.rowHeight = UITableView.automaticDimension
        
        setupTableView()
        setupRecordButtonUI()
        
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
        if let recordsData = try? context.fetch(VoiceRecord.fetchRequest()){
            voiceRecords = recordsData
            voiceRecords.sort { $0.creationDate! > $1.creationDate! }

            DispatchQueue.main.async { [self] in
                recordTableView.reloadData()
            }
            checkEmpty()
        }
    }
    
    private func checkEmpty(){
        
        if voiceRecords.count > 0{
            DispatchQueue.main.async { [self] in
                recordTableView.isHidden = false
                emptyView.isHidden = true
            }
        }else{
            DispatchQueue.main.async { [self] in
                recordTableView.isHidden = true
                emptyView.isHidden = false
            }
        }
    }
    
    @objc func updateAudioMeter(_ timer: Timer) {
        if let recorder = self.audioRecorder {
            if recorder.isRecording {
                let min = Int(recorder.currentTime / 60)
                let sec = Int(recorder.currentTime.truncatingRemainder(dividingBy: 60))
                let s = String(format: "%02d:%02d", min, sec)
                recordingDurationLabel.text = s
                recorder.updateMeters()
                
                let normalizedValue = pow(10, recorder.averagePower(forChannel: 0) / 70) //20)
                print("normalizedValue \(normalizedValue)")
                waveformView.updateWithLevel(CGFloat(normalizedValue))
            }
        }
    }
    
    func micSetup() {
        /// Session
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord)
        try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        if let voiceRecordDirPath = DirectoryManager.shared.voiceRecordDirPath() {
            if let audioURL = NSURL.fileURL(withPathComponents: [voiceRecordDirPath.path, recordName()]) {
                print(audioURL)
                
                let settings: [String : AnyObject] = [
                    AVSampleRateKey: 44100.0 as AnyObject,
                    AVFormatIDKey: NSNumber(value: kAudioFormatMPEG4AAC),
                    AVNumberOfChannelsKey: 2 as AnyObject,
                    AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue as AnyObject
                ]
                
                try! AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord)
                
                audioRecorder = try? AVAudioRecorder(url: audioURL, settings: settings)
                audioRecorder?.isMeteringEnabled = true
                audioRecorder?.prepareToRecord()
            }
        }
    }
    
    func recordName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, h:mm:ss a"
        let dateString = dateFormatter.string(from: Date())
        let name = "New_Recording_\(AppData.voiceRecordCount).m4a"
        return name
    }
    
    // MARK: - Private Methods -

    private func setupTableView() {
        recordTableView.delegate = self
        recordTableView.dataSource = self
        recordTableView.register(UINib(nibName: "VoiceRecordTvCell", bundle: nil), forCellReuseIdentifier: "cell")
    }
    
    public func setupRecordButtonUI() {
        recordButton = RecordButton(frame: CGRect(
                                                x: 0,
                                                y: 0,
                                                width: 60,
                                                height: 60))
        recordButton?.delegate = self
        self.playButtonBgView.addSubview(recordButton!)
    }
    
    func startVoiceRecord() {
        recordNameLabel.text = "New_Recording_\(AppData.voiceRecordCount)"
        micSetup()
        if let recorder = audioRecorder {
            self.timer = Timer.scheduledTimer(timeInterval: 0.1,
                                                   target: self,
                                                   selector: #selector(self.updateAudioMeter(_:)),
                                                   userInfo: nil,
                                                   repeats: true)
            
            recordingDurationLabel.isHidden = false
            recorder.record()
        }
    }
    
    func stopVoiceRecord() {
        recordingDurationLabel.isHidden = true
        if let recorder = audioRecorder {
            if recorder.isRecording {
                recorder.stop()
                
                let url = recorder.url
                let duration = AVAsset(url: url).duration.seconds
                
                let record = VoiceRecord(context: context)
                record.name = "New_Recording_\(AppData.voiceRecordCount)"
                record.duration = duration
                record.creationDate = Date()
                
                voiceRecords.insert(record, at: 0)
                recordTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                try? context.save()
                
                AppData.voiceRecordCount += 1
                
                checkEmpty()
            }
        }
    }
    
    // MARK: - Button Action -
    
    @IBAction func crossButtonAction(_ sender: UIButton){
        if soundOnOff {
            audioPlayer.stop()
            timerT?.invalidate()
            timerT = nil
            soundOnOff = false
        }
        self.navigationController?.popViewController(animated: true)
    }
    
}

extension VoiceRecordViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return voiceRecords.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if nextCell == indexPath.row {
            return 180
        }else{
            return 75
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = recordTableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! VoiceRecordTvCell
        cell.selectionStyle = .none
        
        cell.record = voiceRecords[indexPath.row]
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
            
            let cell = recordTableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! VoiceRecordTvCell
            cell.playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            cell.currentDurationLbl.text = "00:00"
            cell.endingDurationLbl.text = "00:00"
            
            cell.slider.value = 0
            cell.counter = 0.0
            audioPlayer.currentTime = 0.0
            
            if let name = voiceRecords[indexPath.row].name {
                if  let recordedDirURL = DirectoryManager.shared.voiceRecordDirPath() {
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
        
        recordTableView.reloadRows(at: [indexPath], with: .automatic)
        recordTableView.deselectRow(at: indexPath, animated: true)
    }
    
    @objc func deleteVoiceRecord(_ sender: UIButton) {
        
        if let selectedCell = sender.superview?.superview?.superview as? VoiceRecordTvCell {
            if let indexPath = self.recordTableView.indexPath(for: selectedCell) {
                
                let record = voiceRecords[indexPath.row]
                let index = indexPath.row
                debugPrint("selected record : \(record.name)")
                
                if let name = record.name {
                    
                    if  let recordedDirURL = DirectoryManager.shared.voiceRecordDirPath() {
                        
                        let audioURL = recordedDirURL.appendingPathComponent(name + ".m4a")
                        debugPrint("delete url: \(audioURL)")
                        
                        DispatchQueue.main.async {
                            let refreshAlert = UIAlertController(title: "", message: "Are you sure you want to delete the Voice Record?", preferredStyle: UIAlertController.Style.alert)
                            
                            refreshAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (action: UIAlertAction!) in
                                GifManager.shared.deleteFile(audioURL)
                                self.context.delete(record)
                                
                                try? self.context.save()
                                self.voiceRecords.remove(at: index)
                                self.recordTableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                                
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
        let actionsheet = UIAlertController(title: voiceRecords[tag].name, message: "", preferredStyle: .actionSheet)
        
        actionsheet.addAction(UIAlertAction(title: "Share", style: .default , handler: { (UIAlertAction)in
            
            let record = self.voiceRecords[tag]
            if let name = record.name {
                
                if  let recordedDirURL = DirectoryManager.shared.voiceRecordDirPath() {
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
        
        let record = self.voiceRecords[tag]
        if let name = record.name {
            
            let vc = UIAlertController(title: "Rename", message: "Enter Aspected file name", preferredStyle: .alert)
            vc.addTextField { textField in
                textField.placeholder = name
            }
            vc.addAction(UIAlertAction(title: "Rename", style: .default, handler: { action in
                let textField = vc.textFields?.first
                
                if let newFileName = textField?.text {
                    
                    guard let folderPath = DirectoryManager.shared.voiceRecordDirPath() else{return}
                    let currentAudioURL = URL(fileURLWithPath: folderPath.path.appending("/\(name).m4a"))
                    
                    let renameAudioURL = URL(fileURLWithPath: folderPath.path.appending("/\(newFileName).m4a"))
                    do {
                        try? FileManager.default.moveItem(at: currentAudioURL, to: renameAudioURL)
                        
                        if !newFileName.isEmpty {
                            self.voiceRecords[tag].name = newFileName
                            try? self.context.save()
                        }
                        
                        DispatchQueue.main.async {
                            self.recordTableView.reloadRows(at: [IndexPath(row: tag, section: 0)], with: .automatic)
                        }
                    } catch let error {
                        print("Error renaming file: \(error)")
                    }
                    //self.renameFile(currentFileName: name, newFileName: newFileName, tag: tag)
                }
            }))
            vc.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(vc, animated: true)
        }
    }
}

extension VoiceRecordViewController: RecordButtonDelegate {
    func tapButton(isRecording: Bool) {
        if isRecording {
            print("start recording")
            UIView.animate(withDuration: 0.3) {
                self.waveformViewNSButtonLayout.constant = 0
                self.view.layoutIfNeeded()
            }
            
            if let previousCell = previousCell {
                self.nextCell = nil
                recordTableView.reloadRows(at: [IndexPath(row: previousCell, section: 0)], with: .automatic)
                self.previousCell = nil
            }
                    
            if soundOnOff {
                audioPlayer.stop()
                timerT?.invalidate()
                timerT = nil
                soundOnOff = false
                
                self.startVoiceRecord()
                
            }else{
                
                self.startVoiceRecord()
            }
            
            //self.startVoiceRecord()
        }else{
            print("stop recording")
            UIView.animate(withDuration: 0.3) {
                self.waveformViewNSButtonLayout.constant = -150
                self.view.layoutIfNeeded()
            }
            
            self.stopVoiceRecord()
        }
    }
}

