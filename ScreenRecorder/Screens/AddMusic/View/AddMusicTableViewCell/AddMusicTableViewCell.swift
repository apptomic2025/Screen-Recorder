//
//  AddMusicTableViewCell.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 22/3/25.
//

import UIKit
import AVFoundation

protocol TrimTime: AnyObject{
    func getTime(startTime: Double, endTime: Double)
}

class AddMusicTableViewCell: UITableViewCell {
    @IBOutlet weak var playView: UIView!
    @IBOutlet weak var musicThumbImage: UIImageView!
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var btnPlayMusic: UIButton!
    @IBOutlet weak var addMusicButton: UIButton!
    @IBOutlet weak var favoriteMusicButton: UIButton!
    @IBOutlet weak var musicTitle: UILabel!
    @IBOutlet weak var musicSubTitle: UILabel!
    
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var trimmerView: TrimmerViewMusic!
    @IBOutlet weak var audioWaveFormImageView: UIImageView!
    @IBOutlet weak var soundValueLabel: UILabel!
    @IBOutlet weak var volumeControlSlider: CustomSlider!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var positionBarDurationLabel: UILabel!
    @IBOutlet weak var positionBarImageView: UIImageView!
    
    var deleget: TrimTime?
    
    var player: AVPlayer?
    var playbackTimeCheckerTimer: Timer?
    var trimmerPositionChangedTimer: Timer?
    var url : URL?{
        didSet{
            if let url{
                let assets = AVAsset(url: url)
                AudioWaveGenerate().WaveFormGenerate(url: url,width: Int(audioWaveFormImageView.bounds.width + 50), size: audioWaveFormImageView.bounds.size) { img in
                    self.audioWaveFormImageView.image = img
                }
                durationLabel.text = stringFromTimeInterval(interval: assets.duration.seconds)
                loadAsset(assets)
                playMusic()
                player?.volume = volumeControlSlider.value / 10
                soundValueLabel.text = String("\(Int(volumeControlSlider.value)) %")
            }else{
                trimmerView.asset = nil
                trimmerView.delegate = nil
                self.player?.pause()
                self.player = nil
                self.playbackTimeCheckerTimer?.invalidate()
                self.playbackTimeCheckerTimer = nil
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        playView.layer.cornerRadius = 9
        musicThumbImage.layer.cornerRadius = 9
        
        btnPlayMusic.imageView?.contentMode = .scaleAspectFit
        btnPlayMusic.contentHorizontalAlignment = .left;
        btnPlayMusic.imageEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        
        trimmerView.handleColor = UIColor.black
        trimmerView.mainColor = UIColor.white
        trimmerView.positionBarColor = UIColor.white

        NotificationCenter.default.addObserver(self, selector: #selector(self.controlAudio(_:)), name: NSNotification.Name(rawValue: "controlAudio"), object: nil)
    }
    
    @objc func controlAudio(_ sender: NSNotification){
        if player?.timeControlStatus == .playing{
            player?.pause()
        }
        view.backgroundColor = .black
        btnPlayMusic.setImage(UIImage(named: "playButton"), for: .normal)
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
    
    @IBAction func volumeChangeSlider(_ sender: UISlider) {
        if let player = player {
            player.volume = sender.value / 10
            soundValueLabel.text = String("\(Int(sender.value)) %")
        }
    }
    
    func loadAsset(_ asset: AVAsset) {
        trimmerView.asset = asset
        trimmerView.delegate = self
        addVideoPlayer(with: asset, playerView: playerView)
    }
    
    private func addVideoPlayer(with asset: AVAsset, playerView: UIView) {
        let playerItem = AVPlayerItem(asset: asset)
        do{
            player = AVPlayer(playerItem: playerItem)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        }catch{}
        NotificationCenter.default.addObserver(self, selector: #selector(itemDidFinishPlaying(_:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)

        let layer: AVPlayerLayer = AVPlayerLayer(player: player)
        layer.backgroundColor = UIColor.white.cgColor
        layer.frame = CGRect(x: 0, y: 0, width: playerView.frame.width, height: playerView.frame.height)
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        playerView.layer.sublayers?.forEach({$0.removeFromSuperlayer()})
        playerView.layer.addSublayer(layer)
    }
    
    @objc func itemDidFinishPlaying(_ notification: Notification) {
        if let startTime = trimmerView.startTime {
            player?.seek(to: startTime)
//            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "imageChange"), object: nil, userInfo: nil)
            player?.pause()
            if (player?.timeControlStatus != .playing) {
                player?.play()
            }
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func playMusic(){
        guard let player = player else { return }
        if player.timeControlStatus != .playing {
            player.play()
            startPlaybackTimeChecker()
        } else {
            player.pause()
            stopPlaybackTimeChecker()
        }
    }

    func startPlaybackTimeChecker() {

        stopPlaybackTimeChecker()
        playbackTimeCheckerTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self,
                                                        selector:
            #selector(onPlaybackTimeChecker), userInfo: nil, repeats: true)
    }

    func stopPlaybackTimeChecker() {
        playbackTimeCheckerTimer?.invalidate()
        playbackTimeCheckerTimer = nil
    }
    
    @objc func onPlaybackTimeChecker() {

        guard let startTime = trimmerView.startTime, let endTime = trimmerView.endTime, let player = player else {
            return
        }

        let playBackTime = player.currentTime()
        trimmerView.seek(to: playBackTime)

        if playBackTime >= endTime {
            player.seek(to: startTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            trimmerView.seek(to: startTime)
        }
    }
}

//MARK: - Trimmer View Delegate -
extension AddMusicTableViewCell: TrimmerViewDelegateMusic {
    //MARK: - Position bar move -
    func positionBarPosition(_ positionX: CGFloat, _ time: CMTime) {
        positionBarDurationLabel.text = stringFromTimeInterval(interval: time.seconds)
        positionBarDurationLabel.frame.origin.x = (positionX + 16)
        positionBarImageView.frame.origin.x = (positionX - 11)
    }
    
    func positionBarStoppedMoving(_ playerTime: CMTime) {
        player?.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        player?.play()
        if btnPlayMusic.imageView?.image == UIImage(named: "playButton"){
            btnPlayMusic.setImage(UIImage(named: "pauseButton"), for: .normal)
        }
        startPlaybackTimeChecker()
    }

    func didChangePositionBar(_ playerTime: CMTime) {
        stopPlaybackTimeChecker()
        player?.pause()
        player?.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        let duration = (trimmerView.endTime! - trimmerView.startTime!).seconds
        durationLabel.text = stringFromTimeInterval(interval: duration)
//        print(playerTime.seconds)
        if let startTime = trimmerView.startTime?.seconds, let endTime = trimmerView.endTime?.seconds{
            deleget?.getTime(startTime: startTime, endTime: endTime)
        }
    }
}


//Class for Custom Slider
class CustomSlider: UISlider {

    @IBInspectable var sliderTrackHeight : CGFloat = 2
    
    @IBInspectable var stepValue: Float = 0.1
        
    override func setValue(_ value: Float, animated: Bool) {
        let roundedValue = round(value / stepValue) * stepValue
        super.setValue(roundedValue, animated: animated)
    }
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let originalRect = super.trackRect(forBounds: bounds)
        return CGRect(origin: CGPoint(x: originalRect.origin.x, y: originalRect.origin.y + (sliderTrackHeight / 2)), size: CGSize(width: bounds.width, height: sliderTrackHeight))
    }
}
