//
//  PhotoToVideoViewController.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 22/3/25.
//


import UIKit
import AVFoundation
import AVKit
import PhotosUI
import SlideShowMaker

class PhotoToVideoViewController: UIViewController {
    
   
    
    @IBOutlet weak var playerContainerView: UIView!{
        didSet{
            self.playerContainerView.backgroundColor = .clear
        }
    }
    
    @IBOutlet weak var playPauseButton: UIButton!{
        didSet{
            playPauseButton.addTarget(self, action: #selector(playButtonAction), for: .touchUpInside)
        }
    }
    @IBOutlet weak var styleCollectionView: UICollectionView!
    @IBOutlet weak var transitionContainerView: UIView!
    @IBOutlet weak var transitionContainerNSLayoutConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var addMusicContainerView: UIView!
    @IBOutlet weak var addMusicContainerNSLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var currentDurationLbl: UILabel!
    @IBOutlet weak var endingDurationLbl: UILabel!
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var audioPlayButton: UIButton!
    @IBOutlet weak var slider: UISlider!{
        didSet{
            slider.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
            slider.setThumbImage(#imageLiteral(resourceName: "slider"), for: .normal)
        }
    }

    @IBOutlet weak var frameCollectionView: UICollectionView!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!{
        didSet{
            playButton.addTarget(self, action: #selector(playButtonAction), for: .touchUpInside)
        }
    }
    
    private var selection = [String: PHPickerResult]()
    private var selectedAssetIdentifiers = [String]()
    private var selectedAssetIdentifierIterator: IndexingIterator<[String]>?
    private var currentAssetIdentifier: String?
    var recevedCount = 0
    var mediaItems: PickedMediaItems = PickedMediaItems()
    
    var selectedPhoto: [UIImage] = []
    
    //var playerView: PlayerView?
    //NEW VIDEO VIEW
    private var videoView: VideoView = {
        let videoView = VideoView(frame: CGRect(x: 0, y: 0, width: 100, height: 100), viewType: .default)
        //videoView.translatesAutoresizingMaskIntoConstraints = false
        return videoView
    }()
    private var isPlaying = false
    
    var playerStatus: PlayerStatus = .stop
    var video: Video?
    var isFirstTimeLoaded = false
    
    var selectedIndexPath : IndexPath?

    var transitionImageArray = [ "dNone", "dWipeRight", "dWipeLeft", "dWipeUp", "dWipeDown", "dWipeMixed", "dSlideRight", "dSlideLeft", "dSlideUp", "dSlideDown", "dSlideMixed", "dPushRight", "dPushLeft", "dPushUp", "dPushDown", "dPushMixed", "dZoomIn", "dZoomOut", "dFade", "dFadeLong"
    ]

    var selectedTransition = ImageTransition.none
    var audioSongURL: URL?
    
    var counter: Float = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        
        transitionContainerNSLayoutConstraint.constant = -232
        addMusicContainerNSLayoutConstraint.constant = -232
        
        guard let songURL = Bundle.main.url(forResource: "Happy Day", withExtension: "mp3") else { return }
        audioSongURL = songURL
        
        setupMusic()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !isFirstTimeLoaded{
            isFirstTimeLoaded = true
            
            loadVideo()
        }
        
        if let video = video, let url = video.videoURL {
            let totalDuration = AVAsset(url: url).duration.seconds
            endTimeLabel.text = totalDuration.toTimeString
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isFirstTimeLoaded {
            loadVideo()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.videoView.invalidate()
    }
    
    @objc @IBAction func playButtonAction(_ sender: UIButton) {
        if self.playerStatus == .stop || self.playerStatus == .pause{
            self.playerStatus = .play
            self.videoView.play()
            playPauseButton.isHidden = true
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        }else{
            self.playerStatus = .pause
            self.videoView.pause()
            playPauseButton.isHidden = false
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        }
        
    }
    
    /// button action
    @objc func handleLongPressGesture(_ gesture: UILongPressGestureRecognizer){
        guard let collectionView = frameCollectionView else {
            return
        }
        switch gesture.state {
        case .began:
            guard let targetIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else {
                return
            }
            collectionView.beginInteractiveMovementForItem(at: targetIndexPath)
        case .changed:
            collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: collectionView))
        case .ended:
            collectionView.endInteractiveMovement()
        default:
            collectionView.cancelInteractiveMovement()
        }
    }
    
    func stringFromTimeInterval(interval: TimeInterval) -> String {
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        return String(format: "%02d:%02d", minutes, seconds)
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
                    playButton.setImage(UIImage(named: "playICON")!, for: .normal)
                    
                }else{ /// not isPlaying
                    audioPlayer.pause()
                    playButton.setImage(UIImage(named: "pauseICON")!, for: .normal)
                }
                
            default:
                break
            }
        }
    }
    
    @objc func updateTime(_ timer: Timer) {
        if Double(counter) >= audioPlayer.duration {
            timerT?.invalidate()
            timerT = nil
            soundOnOff = false
            
            counter = 0.0
            slider.value = counter
            currentDurationLbl.text = self.stringFromTimeInterval(interval: TimeInterval(counter))

            playButton.setImage(UIImage(named: "playICON")!, for: .normal)
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
    
    func setupMusic(){
        if let audioSongURL = audioSongURL {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: audioSongURL)
                
                let duration = (audioPlayer.currentTime)
                let seconds = TimeInterval(duration)
                
                songNameLabel.text = audioSongURL.deletingPathExtension().lastPathComponent
                
                currentDurationLbl.text = self.stringFromTimeInterval(interval: seconds)
                endingDurationLbl.text = "-" + self.stringFromTimeInterval(interval: TimeInterval(audioPlayer.duration - audioPlayer.currentTime))
                
            } catch let error as NSError {
                print(error.localizedDescription)
            } catch {
                print("AVAudioPlayer init failed")
            }
        }
    }
    // MARK: - Private Methods -
    
    func setupCollectionView() {
        let nib = UINib(nibName: "FrameCollectionViewCell", bundle: nil)
        frameCollectionView.register(nib, forCellWithReuseIdentifier: "cell")
        
        let nib2 = UINib(nibName: "AddFrameCollectionViewCell", bundle: nil)
        frameCollectionView.register(nib2, forCellWithReuseIdentifier: "addCell")
        
        let nib3 = UINib(nibName: "TransitionCollectionViewCell", bundle: nil)
        styleCollectionView.register(nib3, forCellWithReuseIdentifier: "cell")
        
        frameCollectionView.delegate = self
        frameCollectionView.dataSource = self
        
        styleCollectionView.delegate = self
        styleCollectionView.dataSource = self
        
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(_:)))
        frameCollectionView?.addGestureRecognizer(gesture)
    }
    
    private func loadVideo() {
       
        if let video{
            guard let url = video.videoURL else { return }

            self.videoView = VideoView(frame: self.playerContainerView.bounds, viewType: .default)
            self.playerContainerView.addSubview(self.videoView)
            
            self.videoView.delegate = self
            
            self.videoView.url = url
            let asset = AVAsset(url: url)
            let videoTime = VideoTime(startTime: .zero, endTime: asset.duration)
            video.asset = asset
            video.videoTime = videoTime
            video.duration = video.videoTime?.duration
            
            self.videoView.videoTime = videoTime
           
            
        }
    }
    
    private func presentPicker() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        
        // Set the filter type according to the user’s selection.
        configuration.filter = .any(of: [.images])
        // configuration.filter = .any(of: [.videos])
        // Set the mode to avoid transcoding, if possible, if your app supports arbitrary image/video encodings.
        configuration.preferredAssetRepresentationMode = .current
        // Set the selection behavior to respect the user’s selection order.
        //configuration.selection = .ordered
        // Set the selection limit to enable multiselection.
        configuration.selectionLimit = 90
        // configuration.selectionLimit = 1
        // Set the preselected asset identifiers with the identifiers that the app tracks.
        //configuration.preselectedAssetIdentifiers = selectedAssetIdentifiers
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true)
    }
    
    func updateVideo(songURL: URL, frameArra: [UIImage], frameTransition: ImageTransition) {
        
        DispatchQueue.main.async {
            showLoader(view: self.view)
        }
        
        GifManager.shared.makeSlideShowVideo(audioURL: songURL, images: frameArra, frameTransition: frameTransition) { videoURL in
         
            if let video = self.video {
                video.videoURL = videoURL
                
                DispatchQueue.main.async {
                    self.videoView.pause()
                    self.videoView.removeFromSuperview()

                    self.loadVideo()
                    dismissLoader()
                    
                    self.setupMusic()
                }
                
                
            }
        }
    }
    
    func controlVideo(){
            if playerStatus == .play {
                videoView.pause()
                playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
                playPauseButton.isHidden = false
                playerStatus = .pause
            }
        
    }
    
    func controlAudioPlayer(){
        if soundOnOff {
            audioPlayer.stop()
            timerT?.invalidate()
            timerT = nil
            soundOnOff = false
            
            slider.value = 0
            counter = 0.0
            audioPlayer.currentTime = 0.0
            
            let duration = (audioPlayer.currentTime)
            
            currentDurationLbl.text = "00:00"
            endingDurationLbl.text = "-" + self.stringFromTimeInterval(interval: TimeInterval(audioPlayer.duration - audioPlayer.currentTime))
    
            audioPlayButton.setImage(UIImage(named: "playICON")!, for: .normal)
        }
    }
    
    func videoSaveAndShare(url: URL) {
        let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        
        //If user on iPad
        if UIDevice.current.userInterfaceIdiom == .pad {
            if activityViewController.responds(to: #selector(getter: UIViewController.popoverPresentationController)) {
                activityViewController.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            }
        }
        
        //present(activityViewController, animated: true, completion: nil)
        present(activityViewController, animated: true)
        
//        activityViewController.completionWithItemsHandler = { activity, success, items, error in
//            if activity == nil {
//                guard ((try? FileManager.default.removeItem(at: url)) != nil) else { return }
//            }
//        }
    }
    
    // MARK: - Button Action -
    
    @IBAction func crossButtonAction(_ sender: UIButton){
        self.dismiss(animated: true)
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func playOrPauseBtnAction(_ sender: UIButton) {
        if soundOnOff {
            timerT?.invalidate()
            timerT = nil
            audioPlayer.stop()
            sender.setImage(UIImage(named: "playICON")!, for: .normal)
            soundOnOff = false

        }else {
            playSlider()
            
            audioPlayer.prepareToPlay()
            audioPlayer.play()
            sender.setImage(UIImage(named: "pauseICON")!, for: .normal)
            soundOnOff = true
        }
    }
    
    @IBAction func addMusicButtonAction(_ sender: UIButton){
        controlVideo()
        controlAudioPlayer()
        
        frameCollectionView.isHidden = false
        self.addMusicContainerNSLayoutConstraint.constant = -232
        if let vc = loadVCfromStoryBoard(name: "AddMusic", identifier: "AddMusic") as? AddMusicViewController {
            vc.delegate = self
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        }
    }
    
    @IBAction func dismissAddMusicView(){
        controlVideo()
        controlAudioPlayer()

        frameCollectionView.isHidden = false
        self.addMusicContainerNSLayoutConstraint.constant = -232
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func musicButtonAction(_ sender: UIButton){
        controlVideo()
        
        frameCollectionView.isHidden = true
        self.addMusicContainerNSLayoutConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func editButtonAction(_ sender: UIButton){
        controlVideo()
        controlAudioPlayer()
        
//        if let vc = loadVCfromStoryBoard(name: "Editor", identifier: "EditorViewController") as? EditorViewController{
//            
//            if let video = video, let url = video.videoURL {
//                let video = Video(url)
//                vc.video = video
//                vc.isComeFromPreviewVC = true
//                DispatchQueue.main.async{
//                    self.navigationController?.pushViewController(vc, animated: true)
//                }
//            }
//        }
        
        if let vc = loadVCfromStoryBoard(name: "Editor", identifier: "EditorViewController") as? EditorVC {
            
            if let video = video, let url = video.videoURL {
                let video = Video(url)
                if let img = url.generateThumbnail(){
                    video.videoThumb = img
                }
                vc.video = video
                vc.isComeFromPreviewVC = true
                DispatchQueue.main.async{
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    @IBAction func transitionButtonAction(_ sender: UIButton){
        controlVideo()

        frameCollectionView.isHidden = true
        self.transitionContainerNSLayoutConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func dismissTransitionView(){
        frameCollectionView.isHidden = false
        self.transitionContainerNSLayoutConstraint.constant = -232
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func doneTransition(){
        print(selectedTransition)

        if let url = audioSongURL {
            updateVideo(songURL: url, frameArra: selectedPhoto, frameTransition: selectedTransition)
        }
        
        frameCollectionView.isHidden = false
        self.transitionContainerNSLayoutConstraint.constant = -232
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func shareButtonAction(_ sender: UIButton){
            if playerStatus == .play {
                videoView.pause()
            }
        
        
        controlVideo()
        if let video = video, let url = video.videoURL {
            videoSaveAndShare(url: url)
        }
    }
    
}

extension PhotoToVideoViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == frameCollectionView {
            return selectedPhoto.count+1

        }else{
            return transitionImageArray.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == frameCollectionView {
            if indexPath.row == 0 {
                let cell = frameCollectionView.dequeueReusableCell(withReuseIdentifier: "addCell", for: indexPath) as! AddFrameCollectionViewCell
                return cell
                
            }else{
                let cell = frameCollectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! FrameCollectionViewCell
                cell.frameImageView.image = selectedPhoto[indexPath.row-1]
                cell.removeButton.addTarget(self, action: #selector(handleRemoveItem), for: .touchUpInside)
                return cell
            }
            
        }else{ /// styleCollectionView collection view
            
            let cell = styleCollectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! TransitionCollectionViewCell
            cell.transitionImageView.image = UIImage(named: transitionImageArray[indexPath.row])!
            cell.selectedImgView.image = UIImage(named: String(transitionImageArray[indexPath.row].dropFirst()))
            
            cell.selectedImgView.isHidden = (selectedIndexPath != nil && indexPath == selectedIndexPath) ? false : true

            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == frameCollectionView {
            
            if indexPath.row == 0 {
                    if playerStatus == .play {
                        videoView.pause()
                        self.playerStatus = .pause
                        self.playPauseButton.isHidden = false
                        self.playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
                    }
                
                presentPicker()
            }
            
        }else{

            let cell = styleCollectionView.cellForItem(at: indexPath) as! TransitionCollectionViewCell
            cell.selectedImgView.isHidden = false
            self.selectedIndexPath = indexPath
            
            switch indexPath.row {

            case ImageTransition.none.rawValue:
                debugPrint("none")
                selectedTransition = .none
                //updateVideo(selectedPhoto, frameTransition: .none)
                
            case ImageTransition.wipeRight.rawValue:
                debugPrint("none")
                selectedTransition = .wipeRight
                //updateVideo(selectedPhoto, frameTransition: .wipeRight)

            case ImageTransition.wipeLeft.rawValue:
                debugPrint("none")
                selectedTransition = .wipeLeft
                //updateVideo(selectedPhoto, frameTransition: .wipeLeft)

            case ImageTransition.wipeUp.rawValue:
                debugPrint("none")
                selectedTransition = .wipeUp
                //updateVideo(selectedPhoto, frameTransition: .wipeUp)

            case ImageTransition.wipeDown.rawValue:
                debugPrint("none")
                selectedTransition = .wipeDown
                //updateVideo(selectedPhoto, frameTransition: .wipeDown)

            case ImageTransition.wipeMixed.rawValue:
                debugPrint("none")
                selectedTransition = .wipeMixed
                //updateVideo(selectedPhoto, frameTransition: .wipeMixed)
                
            case ImageTransition.slideRight.rawValue:
                debugPrint("none")
                selectedTransition = .slideRight
                //updateVideo(selectedPhoto, frameTransition: .slideRight)

            case ImageTransition.slideLeft.rawValue:
                debugPrint("none")
                selectedTransition = .slideLeft
                //updateVideo(selectedPhoto, frameTransition: .slideLeft)

            case ImageTransition.slideUp.rawValue:
                debugPrint("none")
                selectedTransition = .slideUp
                //updateVideo(selectedPhoto, frameTransition: .slideUp)

            case ImageTransition.slideDown.rawValue:
                debugPrint("none")
                selectedTransition = .slideDown
                //updateVideo(selectedPhoto, frameTransition: .slideDown)

            case ImageTransition.slideMixed.rawValue:
                debugPrint("none")
                selectedTransition = .slideMixed
                //updateVideo(selectedPhoto, frameTransition: .slideMixed)
                
            case ImageTransition.pushRight.rawValue:
                debugPrint("none")
                selectedTransition = .pushRight
                //updateVideo(selectedPhoto, frameTransition: .pushRight)

            case ImageTransition.pushLeft.rawValue:
                debugPrint("none")
                selectedTransition = .pushLeft
                //updateVideo(selectedPhoto, frameTransition: .pushLeft)

            case ImageTransition.pushUp.rawValue:
                debugPrint("none")
                selectedTransition = .pushUp
                //updateVideo(selectedPhoto, frameTransition: .pushUp)

            case ImageTransition.pushDown.rawValue:
                debugPrint("none")
                selectedTransition = .pushDown
                //updateVideo(selectedPhoto, frameTransition: .pushDown)
            
            case ImageTransition.pushMixed.rawValue:
                debugPrint("none")
                selectedTransition = .pushMixed
                //updateVideo(selectedPhoto, frameTransition: .pushMixed)
                
            case ImageTransition.crossFadeUp.rawValue:
                debugPrint("fade right is zoom in")
                selectedTransition = .crossFadeUp
                //updateVideo(selectedPhoto, frameTransition: .crossFadeUp)
                
            case ImageTransition.crossFadeDown.rawValue:
                debugPrint("fade left is zoom out")
                selectedTransition = .crossFadeDown
                //updateVideo(selectedPhoto, frameTransition: .crossFadeDown)
                
            case ImageTransition.crossFade.rawValue:
                selectedTransition = .crossFade
                //updateVideo(selectedPhoto, frameTransition: .crossFade)

            case ImageTransition.crossFadeLong.rawValue:
                debugPrint("none")
                selectedTransition = .crossFadeLong
                //updateVideo(selectedPhoto, frameTransition: .crossFadeLong)
                
            default:
                break
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let cell = styleCollectionView.cellForItem(at: indexPath) as? TransitionCollectionViewCell {
            cell.selectedImgView.isHidden = true
            selectedIndexPath = nil
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if collectionView == frameCollectionView {
            if sourceIndexPath.row != 0 {
                let item = selectedPhoto.remove(at: sourceIndexPath.item-1)
                selectedPhoto.insert(item, at: destinationIndexPath.item-1)
                
                controlVideo()
                if let url = audioSongURL {
                    updateVideo(songURL: url, frameArra: selectedPhoto, frameTransition: selectedTransition)
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        if collectionView == frameCollectionView {
            if indexPath.row != 0 {
                return true
            }
            return false
        }
        return false
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if collectionView == frameCollectionView {
            if indexPath.row != 0 {
                if let cell = collectionView.cellForItem(at: indexPath) {
                    cell.contentView.layer.borderColor = UIColor.yellow.cgColor
                    cell.contentView.layer.borderWidth = 1
                    cell.contentView.layer.cornerRadius = 7
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if collectionView == frameCollectionView {
            if indexPath.row != 0 {
                if let cell = collectionView.cellForItem(at: indexPath) {
                    cell.contentView.layer.borderColor = nil
                    cell.contentView.layer.borderWidth = 0
                }
            }
        }
    }
    
    @objc func handleRemoveItem(sender: UIButton) {
        if let photoCVCell = sender.superview?.superview as? FrameCollectionViewCell {
            guard let indexPath = frameCollectionView.indexPath(for: photoCVCell) else { return  }
            selectedPhoto.remove(at: indexPath.row-1)
            
            print("Remove item")
            self.frameCollectionView.deleteItems(at: [indexPath])
            self.frameCollectionView.reloadItems(at: [indexPath])
            
            if let url = audioSongURL {
                updateVideo(songURL: url, frameArra: selectedPhoto, frameTransition: selectedTransition)
            }
        }
    }
}

extension PhotoToVideoViewController : UICollectionViewDelegateFlowLayout {
    /// cell layout
    ///
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if collectionView == frameCollectionView {
            let w = (DEVICE_WIDTH - 60) / 4
            return CGSize(width: w, height: w)
        }else{
            let w = (DEVICE_WIDTH - 60) / 5
            return CGSize(width: w, height: 66)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        if collectionView == frameCollectionView {
            return 20
        }else{
            return 10
        }
        //return 20
    }
    
}

extension PhotoToVideoViewController: PHPickerViewControllerDelegate {
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

private extension PhotoToVideoViewController {
    
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

            if itemProvider.canLoadObject(ofClass: UIImage.self) {
                progress = itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    DispatchQueue.main.async {
                        self?.handleCompletion(assetIdentifier: assetIdentifier, object: image, error: error)
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
        
        if object is UIImage {
            
            recevedCount += 1
            if let pickedImage = object as? UIImage {
                selectedPhoto.append(pickedImage)
            }
            
        }else if error != nil {
            recevedCount += 1
        }
        
        if recevedCount == selection.count {
            frameCollectionView.reloadData()
            
            if let audioSongURL = audioSongURL {
                updateVideo(songURL: audioSongURL, frameArra: selectedPhoto, frameTransition: selectedTransition)
            }
            
            DispatchQueue.main.async {
                dismissLoader()
            }
        }
    }
}

extension PhotoToVideoViewController : AddMusicDelegate{
    func selectedMusic(addMusicModel: AddMusicModel) {
        print(addMusicModel.url)
        
        controlVideo()
        
        if let musicURL = addMusicModel.url {
            audioSongURL = musicURL
            updateVideo(songURL: musicURL, frameArra: selectedPhoto, frameTransition: selectedTransition)
        }
    }
}

// MARK: ViewController + VideoDelegate
extension PhotoToVideoViewController: VideoDelegate {
    
    func videoFinishedFromVideoView() {
        self.playerStatus = .pause
        self.videoView.pause()
        playPauseButton.isHidden = false
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
    }
    
    
    func videoPlaying() {
        if let mainCurrentTime = self.videoView.player?.currentTime(){
            let currentTime = mainCurrentTime - self.videoView.startTime
            let currentProgress = currentTime.seconds / self.videoView.durationTime.seconds
            debugPrint(currentProgress)
            currentTimeLabel.text = (currentProgress * self.videoView.durationTime.seconds).toTimeString

        }
    }
}

