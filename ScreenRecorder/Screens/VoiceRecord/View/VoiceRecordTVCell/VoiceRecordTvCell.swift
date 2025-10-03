//
//  VoiceRecordTvCell.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 21/3/25.
//

import UIKit
import AVFoundation

var audioPlayer = AVAudioPlayer()
var soundOnOff = false
var timerT: Timer?

class VoiceRecordTvCell: UITableViewCell {
    
    @IBOutlet weak var recordNameLeftNSLayout: NSLayoutConstraint!
    @IBOutlet weak var thumbImageView: UIImageView!{
        didSet{
            thumbImageView.cornerRadiusV = 9
        }
    }
    
    @IBOutlet weak var lblRecordingName: UITextField!{
        didSet {
            lblRecordingName.font = .appFont_CircularStd(type: .medium, size: 16)
            lblRecordingName.textColor = UIColor(hex: "#151517")
        }
    }
    @IBOutlet weak var lblCreationDate: UILabel!{
        didSet {
            lblCreationDate.font = .appFont_CircularStd(type: .book, size: 14)
            lblCreationDate.textColor = UIColor(hex: "#151517").withAlphaComponent(0.40)
        }
    }
    
    @IBOutlet weak var lblTotalDuration: UILabel!{
        didSet {
            lblTotalDuration.font = .appFont_CircularStd(type: .book, size: 14)
            lblTotalDuration.textColor = UIColor(hex: "#151517").withAlphaComponent(0.40)
        }
    }
    
    @IBOutlet weak var slider: UISlider!{
        didSet{
            slider.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
        }
    }
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var currentDurationLbl: UILabel!{
        didSet {
            currentDurationLbl.font = .appFont_CircularStd(type: .book, size: 12)
            currentDurationLbl.textColor = UIColor(hex: "#151517").withAlphaComponent(0.40)
        }
    }
    @IBOutlet weak var endingDurationLbl: UILabel!{
        didSet {
            endingDurationLbl.font = .appFont_CircularStd(type: .book, size: 12)
            endingDurationLbl.textColor = UIColor(hex: "#151517").withAlphaComponent(0.40)
        }
    }
    @IBOutlet weak var trashButton: UIButton!
    @IBOutlet weak var optionButton: UIButton!
    @IBOutlet weak var seperatorView: UIView!{
        didSet{
            self.seperatorView.backgroundColor = UIColor(hex: "#151517").withAlphaComponent(0.04)
        }
    }
    var record: VoiceRecord? {
        didSet{
            if let record {
                recordNameLeftNSLayout.constant = 20
                thumbImageView.isHidden = true
                
                lblRecordingName.text = record.name
                lblTotalDuration.text = CMTime(value: CMTimeValue(record.duration), timescale: 1).toHourMinuteSecond()
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d, yyyy h:mm a"
                lblCreationDate.text = dateFormatter.string(from: record.creationDate!)
            }
        }
    }
    
    var extract: ExtractAudio? {
        didSet{
            if let extract {
                
                if let fileName = extract.thumbName, let url = DirectoryManager.shared.extractAudioThumDirPath()?.appendingPathComponent(fileName+".jpg") {
                    thumbImageView.image = UIImage(contentsOfFile: url.path)
                }
                
                lblRecordingName.text = extract.name
                lblTotalDuration.text = CMTime(value: CMTimeValue(extract.duration), timescale: 1).toHourMinuteSecond()
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d, yyyy h:mm a"
                lblCreationDate.text = dateFormatter.string(from: extract.creationDate!)
            }
        }
    }
    
    fileprivate let seekDuration: Float64 = 10.0
    
    var counter: Float = 0.0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        lblRecordingName.isEnabled = false
        // 1. Set the thumb (knob) image
        // Make sure you have an image named "sliderThumb" in your Assets.xcassets
        let thumbImage = UIImage(named: "sliderThumbForVideoAdio")
        slider.setThumbImage(thumbImage, for: .normal)
        slider.setThumbImage(thumbImage, for: .highlighted)
        
        // 2. Set the active and inactive track colors
        // Active color (left side of the thumb)
        slider.minimumTrackTintColor = UIColor(hex: "#FE655C")
        
        // Inactive color (right side of the thumb)
        slider.maximumTrackTintColor = UIColor(hex: "#151517").withAlphaComponent(0.04)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    @objc func onSliderValChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began: break
                // handle drag began
            case .moved:
                // handle drag moved
                
                audioPlayer.stop()
                timerT?.invalidate()
                timerT = nil
                
                slider.maximumValue = Float(audioPlayer.duration)
                counter = slider.value
                audioPlayer.currentTime = TimeInterval(counter)
                
                debugPrint(slider.value)
                
                currentDurationLbl.text = self.stringFromTimeInterval(interval: TimeInterval(counter))
                endingDurationLbl.text = "-" + self.stringFromTimeInterval(interval: TimeInterval(audioPlayer.duration - audioPlayer.currentTime))
                
            case .ended:
                // handle drag ended
                
                if soundOnOff { /// isPlaying
                    
                    playSlider()
                    
                    audioPlayer.prepareToPlay()
                    audioPlayer.play()
                    let iconImage = UIImage(systemName: "pause.fill")
                    playButton.setImage(iconImage, for: .normal)
                    
                }else{ /// not isPlaying
                    audioPlayer.pause()
                    let iconImage = UIImage(named: "PlayBtnIconForVideoToAdio")
                    playButton.setImage(iconImage, for: .normal)
                }
                
            default:
                break
            }
        }
    }
    
    // MARK: - Private Methods -
    
    func stringFromTimeInterval(interval: TimeInterval) -> String {
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    @objc func updateTime(_ timer: Timer) {
        if Double(counter) >= audioPlayer.duration {
            timerT?.invalidate()
            timerT = nil
            soundOnOff = false
            
            counter = 0.0
            slider.value = counter
            currentDurationLbl.text = self.stringFromTimeInterval(interval: TimeInterval(counter))
            
            let iconImage = UIImage(named: "PlayBtnIconForVideoToAdio")
            playButton.setImage(iconImage, for: .normal)
        }else{
            counter += 0.01
            debugPrint(counter)
            slider.value = Float(audioPlayer.currentTime)
            
            let duration = (audioPlayer.currentTime)
            let seconds = TimeInterval(duration)
            
            currentDurationLbl.text = self.stringFromTimeInterval(interval: seconds)
            endingDurationLbl.text = "-" + self.stringFromTimeInterval(interval: TimeInterval(audioPlayer.duration - audioPlayer.currentTime))
        }
    }
    
    
    func playSlider(){
        slider.maximumValue = Float(audioPlayer.duration)
        timerT = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.updateTime), userInfo: nil, repeats: true)
    }
    
    // MARK: - Button Action.
    @IBAction func fifteenSecondBackwardBtnAction(_ sender: UIButton) {
        print("15 second backward")
        let currentTime = audioPlayer.currentTime
        let newTime = currentTime < seekDuration ? 0.0 : currentTime - seekDuration
        
        if audioPlayer.isPlaying {
            audioPlayer.currentTime = newTime
            
            counter = Float(newTime)
            slider.value = counter
            
            currentDurationLbl.text = self.stringFromTimeInterval(interval: audioPlayer.currentTime)
            endingDurationLbl.text = "-" + self.stringFromTimeInterval(interval: TimeInterval(audioPlayer.duration - audioPlayer.currentTime))
            
            audioPlayer.prepareToPlay()
            audioPlayer.play()
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            
        }else{
            audioPlayer.currentTime = newTime
            
            counter = Float(newTime)
            slider.value = counter
            
            currentDurationLbl.text = self.stringFromTimeInterval(interval: audioPlayer.currentTime)
            endingDurationLbl.text = "-" + self.stringFromTimeInterval(interval: TimeInterval(audioPlayer.duration - audioPlayer.currentTime))
            
            audioPlayer.pause()
            let iconImage = UIImage(named: "PlayBtnIconForVideoToAdio")
            playButton.setImage(iconImage, for: .normal)
        }
    }
    
    @IBAction func playOrPauseBtnAction(_ sender: UIButton) {
        if soundOnOff {
            timerT?.invalidate()
            timerT = nil
            audioPlayer.stop()
            let iconImage = UIImage(named: "PlayBtnIconForVideoToAdio")
            playButton.setImage(iconImage, for: .normal)
            soundOnOff = false
            
        }else {
            playSlider()
            
            audioPlayer.prepareToPlay()
            audioPlayer.play()
            sender.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            soundOnOff = true
        }
    }
    
    @IBAction func fifteenSecondForwardBtnAction(_ sender: UIButton) {
        print("15 second forward.")
        let currentTime = audioPlayer.currentTime
        let newTime = currentTime + seekDuration
        
        if audioPlayer.isPlaying { /// play
            let currentDuration = audioPlayer.duration - currentTime
            
            if currentDuration <= seekDuration {
                audioPlayer.currentTime = audioPlayer.duration - 3.0
                
                counter = Float(audioPlayer.duration - 3.0)
                slider.value = counter
                
                currentDurationLbl.text = self.stringFromTimeInterval(interval: audioPlayer.currentTime)
                endingDurationLbl.text = "-" + self.stringFromTimeInterval(interval: TimeInterval(audioPlayer.duration - audioPlayer.currentTime))
                
                audioPlayer.prepareToPlay()
                audioPlayer.play()
                playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
                
            }else{
                
                audioPlayer.currentTime = newTime
                
                counter = Float(newTime)
                slider.value = counter
                
                currentDurationLbl.text = self.stringFromTimeInterval(interval: audioPlayer.currentTime)
                endingDurationLbl.text = "-" + self.stringFromTimeInterval(interval: TimeInterval(audioPlayer.duration - audioPlayer.currentTime))
                
                audioPlayer.prepareToPlay()
                audioPlayer.play()
                playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            }
            
        }else{ // stop
            
            let currentDuration = audioPlayer.duration - currentTime
            
            if currentDuration <= seekDuration {
                audioPlayer.currentTime = audioPlayer.duration - 3.0
                
                counter = Float(audioPlayer.duration - 3.0)
                slider.value = counter
                
                currentDurationLbl.text = self.stringFromTimeInterval(interval: audioPlayer.currentTime)
                endingDurationLbl.text = "-" + self.stringFromTimeInterval(interval: TimeInterval(audioPlayer.duration - audioPlayer.currentTime))
                
                audioPlayer.pause()
                let iconImage = UIImage(named: "PlayBtnIconForVideoToAdio")
                playButton.setImage(iconImage, for: .normal)
                
            }else{
                
                audioPlayer.currentTime = newTime
                
                counter = Float(newTime)
                slider.value = counter
                
                currentDurationLbl.text = self.stringFromTimeInterval(interval: audioPlayer.currentTime)
                endingDurationLbl.text = "-" + self.stringFromTimeInterval(interval: TimeInterval(audioPlayer.duration - audioPlayer.currentTime))
                
                audioPlayer.pause()
                let iconImage = UIImage(named: "PlayBtnIconForVideoToAdio")
                playButton.setImage(iconImage, for: .normal)
            }
        }
    }
    
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        
    }
}
