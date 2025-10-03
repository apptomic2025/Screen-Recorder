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

    @IBOutlet weak var waveformView: BarWaveformView!
    @IBOutlet weak var cnstWaveformViewBottom: NSLayoutConstraint!
    @IBOutlet weak var playButtonBgView: UIView!
    @IBOutlet weak var recordNameLabel: UILabel!
    @IBOutlet weak var recordingDurationLabel: UILabel!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var recordTableView: UITableView!{
        didSet{
            recordTableView.isHidden = true
        }
    }
    @IBOutlet weak var lblEmptyTittle: UILabel!{
        didSet{
            self.lblEmptyTittle.font = .appFont_CircularStd(type: .medium, size: 16)
            self.lblEmptyTittle.textColor = UIColor(hex: "#151517")
        }
    }
    
    @IBOutlet weak var lblEmptySubTittle: UILabel!{
        didSet{
            self.lblEmptySubTittle.font = .appFont_CircularStd(type: .book, size: 14)
            self.lblEmptySubTittle.textColor = UIColor(hex: "#151517").withAlphaComponent(0.60)
        }
    }
    
    @IBOutlet weak var lblRecordName: UILabel!{
        didSet{
            self.lblRecordName.font = .appFont_CircularStd(type: .medium, size: 20)
            self.lblRecordName.textColor = UIColor(hex: "#151517")
        }
    }
    
    @IBOutlet weak var lblRecordDuration: UILabel!{
        didSet{
            self.lblRecordDuration.font = .appFont_CircularStd(type: .book, size: 16)
            self.lblRecordDuration.textColor = UIColor(hex: "#151517").withAlphaComponent(0.60)
        }
    }
    
    @IBOutlet weak var navView: UIView!
    @IBOutlet weak var cnstNavViewHeight: NSLayoutConstraint!
    @IBOutlet weak var lblTittle: UILabel!{
        didSet{
            self.lblTittle.font = .appFont_CircularStd(type: .bold, size: 20)
            self.lblTittle.textColor = UIColor(hex: "#151517")
        }
    }
    
    private var recordButtonView: RecordButtonViewNew?
    var audioRecorder : AVAudioRecorder?
    fileprivate var timer: Timer!
    var isRecording : Bool = false
    var voiceRecords : [VoiceRecord] = []
    var selectedIndex: Int?
    var expandedIndexPath: IndexPath?
    var isVCLoaded: Bool = false
    private var liveAudioSamples: [CGFloat] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if !isVCLoaded{
            isVCLoaded = true
            setupNavHeight()
        }
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
                
                // Normalize the audio power level to a 0.0-1.0 range
                let power = recorder.averagePower(forChannel: 0)
                let normalizedValue = pow(10, power / 20) // Convert decibels to linear scale

                // Add the new sample to our live array
                self.liveAudioSamples.append(CGFloat(normalizedValue))
                
                // Limit the number of bars to keep it scrolling smoothly
                let maxSamples = Int(waveformView.bounds.width / (waveformView.barWidth + waveformView.barSpacing))
                if self.liveAudioSamples.count > maxSamples {
                    self.liveAudioSamples.removeFirst()
                }
                
                // Update the waveform view with the new array of samples
                waveformView.audioSamples = self.liveAudioSamples
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
        let bottomInset: CGFloat = 80.0

      // Apply the inset to the table view's content.
             recordTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
        // Assuming you have an outlet named 'myTableView'
        recordTableView.showsVerticalScrollIndicator = false
        recordTableView.showsHorizontalScrollIndicator = false
    }
    
    public func setupRecordButtonUI() {
        recordButtonView = RecordButtonViewNew(frame: CGRect(x: 0, y: 0, width: 70, height: 70))
        recordButtonView?.delegate = self
        if let recordButton = recordButtonView {
            self.playButtonBgView.addSubview(recordButton)
        }
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
            if indexPath == expandedIndexPath {
                return 176 // Expanded height
            } else {
                return 67  // Collapsed height
            }
        }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
           let cell = recordTableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! VoiceRecordTvCell
           cell.selectionStyle = .none
           
           cell.record = voiceRecords[indexPath.row]
           cell.trashButton.addTarget(self, action: #selector(deleteVoiceRecord), for: .touchUpInside)
           
           // Tag a OptionButton with the row index to identify it later
           cell.optionButton.tag = indexPath.row
           cell.optionButton.addTarget(self, action: #selector(optionButtonAction), for: .touchUpInside)
        if indexPath.row == voiceRecords.count - 1 {
                // If it's the last cell, hide the separator.
                cell.seperatorView.isHidden = true
            } else {
                // For all other cells, make sure the separator is visible.
                // This is important because cells are reused.
                cell.seperatorView.isHidden = false
            }
           return cell
       }
       
       func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
           // Immediately deselect the row to prevent it from staying highlighted
           tableView.deselectRow(at: indexPath, animated: true)

           // Stop any currently playing audio on any tap
           timerT?.invalidate()
           timerT = nil
           if soundOnOff {
               audioPlayer.stop()
               soundOnOff = false
           }
           
           let previouslyExpandedIndexPath = expandedIndexPath
           
           // Case 1: Tapping an already expanded cell to collapse it.
           if previouslyExpandedIndexPath == indexPath {
               expandedIndexPath = nil
           }
           // Case 2: Tapping a new or collapsed cell to expand it.
           else {
               expandedIndexPath = indexPath
               
               // Setup the audio player for the newly selected cell
               if let name = voiceRecords[indexPath.row].name,
                  let recordedDirURL = DirectoryManager.shared.voiceRecordDirPath() {
                   let audioURL = recordedDirURL.appendingPathComponent(name + ".m4a")
                   do {
                       audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
                   } catch {
                       print("AVAudioPlayer init failed: \(error.localizedDescription)")
                   }
               }
           }
           
           // Animate the height changes smoothly for the concerned cells
           var indexPathsToUpdate: [IndexPath] = []
           if let previousPath = previouslyExpandedIndexPath {
               indexPathsToUpdate.append(previousPath)
           }
           if let currentPath = expandedIndexPath, currentPath != previouslyExpandedIndexPath {
               indexPathsToUpdate.append(currentPath)
           }
           
           // Use reloadRows to ensure cell UI is reset correctly upon collapse/expand
           if !indexPathsToUpdate.isEmpty {
               tableView.reloadRows(at: indexPathsToUpdate, with: .automatic)
           } else if let previouslyExpandedIndexPath {
               // This handles collapsing the last expanded cell
               tableView.reloadRows(at: [previouslyExpandedIndexPath], with: .automatic)
           }
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
        
        // 1. Define which options you want to show. You can include any or all of them.
        let options: [RecordCellOptionVC.Option] = [.rename, .duplicate, .share]

        // 2. Instantiate the view controller with the options and their corresponding actions.
        let selectionVC = RecordCellOptionVC.instantiate(
            options: options,
            onSelectRename: { [weak self] in
                print("Rename action triggered.")
                self?.renameAudio(tag: tag)
            },
            onSelectDuplicate: { [weak self] in
                            print("Duplicate action triggered.")
                self?.duplicateAudio(tag: tag)
                        },
            
            onSelectShare: { [weak self] in
                let record = self?.voiceRecords[tag]
                if let name = record?.name {
                    
                    if  let recordedDirURL = DirectoryManager.shared.voiceRecordDirPath() {
                        let activityItem = recordedDirURL.appendingPathComponent(name + ".m4a")
                        
                        let activityVC = UIActivityViewController(activityItems: [activityItem],applicationActivities: nil)
                        activityVC.overrideUserInterfaceStyle = .light
                        activityVC.popoverPresentationController?.sourceView = self?.view
                        self?.present(activityVC, animated: true, completion: nil)
                    }
                }
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
    
    func duplicateAudio(tag: Int) {
        // 1. Ensure the selected index is valid
        guard tag < voiceRecords.count else {
            print("Error: Invalid index for duplication.")
            return
        }
        let originalRecord = voiceRecords[tag]
        
        guard let originalName = originalRecord.name,
              let folderURL = DirectoryManager.shared.voiceRecordDirPath() else {
            print("Error: Could not find original record name or directory path.")
            return
        }

        // 2. Find a unique name for the new (duplicated) file
        var newName = ""
        var copyCount = 1
        let fileManager = FileManager.default
        
        while true {
            let potentialName = (copyCount == 1) ? "\(originalName) (copy)" : "\(originalName) (copy \(copyCount))"
            let destinationURL = folderURL.appendingPathComponent(potentialName + ".m4a")
            
            if !fileManager.fileExists(atPath: destinationURL.path) {
                newName = potentialName
                break
            }
            copyCount += 1
        }
        
        let sourceURL = folderURL.appendingPathComponent(originalName + ".m4a")
        let destinationURL = folderURL.appendingPathComponent(newName + ".m4a")

        // 3. Copy the actual audio file
        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            
            // 4. If file copy succeeds, create a new entry in Core Data
            let newRecord = VoiceRecord(context: context)
            newRecord.name = newName
            newRecord.duration = originalRecord.duration
            newRecord.creationDate = Date()
            
            try context.save()
            
            // 5. Update the UI on the main thread
            DispatchQueue.main.async {
                // Adjust the expanded index path before inserting the new row
                if let oldIndexPath = self.expandedIndexPath {
                    let newRow = oldIndexPath.row + 1
                    self.expandedIndexPath = IndexPath(row: newRow, section: oldIndexPath.section)
                }

                self.voiceRecords.insert(newRecord, at: 0)
                self.recordTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                
                // --- New Line Added Here ---
                // Scroll to the top to show the newly added duplicate
                let topIndexPath = IndexPath(row: 0, section: 0)
                self.recordTableView.scrollToRow(at: topIndexPath, at: .top, animated: true)
                // --- End of New Line ---
                
                self.checkEmpty()
            }
            
        } catch {
            print("Error duplicating audio file: \(error.localizedDescription)")
        }
    }
    func renameAudio(tag: Int) {
        let record = self.voiceRecords[tag]
        guard let name = record.name else { return }
        
        let vc = UIAlertController(title: "Rename", message: "Enter a new name for your recording.", preferredStyle: .alert)
        
        vc.addTextField { textField in
            textField.text = name
            textField.clearButtonMode = .whileEditing
        }
        
        let renameAction = UIAlertAction(title: "Rename", style: .default, handler: { [weak self] _ in
            guard let self = self,
                  let textField = vc.textFields?.first,
                  let newFileName = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), // Trim whitespace
                  !newFileName.isEmpty else {
                return
            }
            
            // Don't do anything if the name hasn't changed
            if newFileName == name {
                return
            }
            
            guard let folderPath = DirectoryManager.shared.voiceRecordDirPath() else { return }
            let newAudioURL = folderPath.appendingPathComponent(newFileName + ".m4a")
            
            // --- KEY CHANGE: Check if a file with the new name already exists ---
            if FileManager.default.fileExists(atPath: newAudioURL.path) {
                // If it exists, show the error alert and stop.
                self.showErrorAlert(message: "A recording with the name \"\(newFileName)\" already exists. Please choose a different name.")
                return
            }
            
            // If the name is unique, proceed with renaming.
            let currentAudioURL = folderPath.appendingPathComponent(name + ".m4a")
            
            do {
                try FileManager.default.moveItem(at: currentAudioURL, to: newAudioURL)
                
                // Update Core Data
                self.voiceRecords[tag].name = newFileName
                try self.context.save()
                
                // Update the UI
                DispatchQueue.main.async {
                    self.recordTableView.reloadRows(at: [IndexPath(row: tag, section: 0)], with: .automatic)
                }
                
            } catch {
                // Catch any other potential file system errors
                print("Error renaming file: \(error)")
                self.showErrorAlert(message: "An unexpected error occurred. Please try again.")
            }
        })
        
        vc.addAction(renameAction)
        vc.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        vc.overrideUserInterfaceStyle = .light
        self.present(vc, animated: true)
    }
    
    // This function can be placed anywhere inside the VoiceRecordViewController class
    func showErrorAlert(title: String = "Unable to Rename", message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        alert.overrideUserInterfaceStyle = .light // To keep the white background
        self.present(alert, animated: true)
    }
}

extension VoiceRecordViewController: RecordButtonNewDelegate {
    func didStartRecording() {
        // 1. Reset the live waveform display
        self.liveAudioSamples.removeAll()
        waveformView?.audioSamples = []

        // 2. Animate the waveform view to make it visible
        UIView.animate(withDuration: 0.3) {
            self.cnstWaveformViewBottom.constant = 0
            self.view.layoutIfNeeded()
        }
        
        // 3. Collapse any previously expanded cell using the new logic
        if let indexPathToCollapse = expandedIndexPath {
            expandedIndexPath = nil
            recordTableView.reloadRows(at: [indexPathToCollapse], with: .automatic)
        }
        
        // 4. Stop any audio that is currently playing
        if soundOnOff {
            audioPlayer.stop()
            timerT?.invalidate()
            timerT = nil
            soundOnOff = false
        }
        
        // 5. Start the new voice recording
        self.startVoiceRecord()
    }
    
    func didStopRecording() {
        print("stop recording")
        self.liveAudioSamples.removeAll()
           waveformView.audioSamples = []
        UIView.animate(withDuration: 0.3) {
            self.cnstWaveformViewBottom.constant = -150
            self.view.layoutIfNeeded()
        }
        self.stopVoiceRecord()
    }
    
//    func tapButton(isRecording: Bool) {
//        if isRecording {
//            print("start recording")
//            UIView.animate(withDuration: 0.3) {
//                self.waveformViewNSButtonLayout.constant = 0
//                self.view.layoutIfNeeded()
//            }
//            
//            if let previousCell = previousCell {
//                self.nextCell = nil
//                recordTableView.reloadRows(at: [IndexPath(row: previousCell, section: 0)], with: .automatic)
//                self.previousCell = nil
//            }
//                    
//            if soundOnOff {
//                audioPlayer.stop()
//                timerT?.invalidate()
//                timerT = nil
//                soundOnOff = false
//                
//                self.startVoiceRecord()
//                
//            }else{
//                
//                self.startVoiceRecord()
//            }
//            
//        }else{
//            print("stop recording")
//            UIView.animate(withDuration: 0.3) {
//                self.waveformViewNSButtonLayout.constant = -150
//                self.view.layoutIfNeeded()
//            }
//            
//            self.stopVoiceRecord()
//        }
//    }
}

