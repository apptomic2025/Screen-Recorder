//
//  ExportSettingsViewController.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 21/2/25.
//


import UIKit
import AVKit
import AVFoundation
import Photos

protocol ExportDelegate: AnyObject{
    func exportClicked(_ video: Video?)
    func dismissExportVC()
    func exportOptionChoosed(_ pixel: Int?, bitRate: Int?, frameRate: Int?)
}

enum ExportSettingsType{
    case screenRecord,videoEdit
}

struct ScreenRecordExportSettings{
    var resouation: Int
    var bitrate: Int
    var framerate: Int
}

class ExportSettingsVC: UIViewController {
        
    var pixeDictionary: [Int : CGFloat] = [540:0, 720:1, 1080:2, 3840:3]
    var pixeDictionaryStr: [Int : String] = [0:exportPresets[0], 1:exportPresets[1], 2:exportPresets[2], 3:exportPresets[3]]
    var frameDictionary: [Int : CGFloat] = [24:0, 30:1, 50:2, 60:3]
    var bitrateDictionary: [Int : CGFloat] = [2:0, 4:1, 6:2, 12:3]

    var type: ExportSettingsType = .videoEdit
    
    weak var delegate: ExportDelegate?
    
    var frameRateArray:[CMTimeScale] = [24,30,50,60]
    let share = EditorManager.shared
    var oldX:CGFloat = 0
    
    var isLoad = false
    var video: Video?
    var videoComposition: AVVideoComposition?
    
    var panGestureRecognizer: UIPanGestureRecognizer?
    var originalPosition: CGPoint?
    var originalPositionY: CGFloat?
    
    @IBOutlet weak var imgViewCrown1: UIImageView!
    @IBOutlet weak var imgViewCrown2: UIImageView!
    
    @IBOutlet weak var exportButton: UIButton!{
        didSet{
            if self.type == .screenRecord{
                exportButton.setTitle("Done", for: .normal)
            }
        }
    }
    @IBOutlet weak var frameRateProgress: TouchProgressView!{
        didSet{
            frameRateProgress.delegate = self
            if type == .screenRecord{
                frameRateProgress.initialIndex = frameDictionary[AppData.framerate]
            }
        }
    }
    @IBOutlet weak var qualityProgress: TouchProgressView!{
        didSet{
            qualityProgress.delegate = self
            qualityProgress.initialIndex = 1.0
            
            if type == .screenRecord{
                qualityProgress.initialIndex = pixeDictionary[AppData.resolution]
            }
        }
    }
    @IBOutlet weak var bitRateProgress: TouchProgressView!{
        didSet{
            bitRateProgress.delegate = self
            if type == .screenRecord{
                bitRateProgress.initialIndex = bitrateDictionary[AppData.bitrate]
            }
        }
    }
    @IBOutlet weak var backgroundTouchView: UIView!
    @IBOutlet weak var mainContentView: UIView!
    @IBOutlet weak var mainContentViewBottomContraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction(_:)))
        mainContentView.addGestureRecognizer(panGestureRecognizer!)
        
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        imgViewCrown1.isHidden = AppData.premiumUser
        imgViewCrown2.isHidden = AppData.premiumUser
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !isLoad{
            isLoad = true
            let height = mainContentView.frame.height
            mainContentViewBottomContraint.constant = -height
            originalPositionY = mainContentView.frame.origin.y
            
            if type == .screenRecord{
                frameRateProgress.initialIndex = frameDictionary[AppData.framerate]
                qualityProgress.initialIndex = pixeDictionary[AppData.resolution]
                bitRateProgress.initialIndex = bitrateDictionary[AppData.bitrate]
            }
        }
    }
    
    private func getSizes(){
        
        guard let asset = video?.asset, let videoTime = video?.videoTime else { return }
        
        let duration = (videoTime.endTime ?? asset.duration) - (videoTime.startTime ?? .zero)
        //TotalTimeRange
        let timeRange = CMTimeRangeMake(start: videoTime.startTime ?? .zero, duration: duration)
        
        var sizeArray = [String]()
        let sizeFormatter = ByteCountFormatter()

        for pixel in exportPresets{
            if let exportSession = AVAssetExportSession(asset: asset, presetName: pixel) {
                exportSession.timeRange = timeRange
                if let videoComposition{
                    exportSession.videoComposition = videoComposition
                }
                sizeArray.append(sizeFormatter.string(fromByteCount: Int64(exportSession.estimatedOutputFileLength)))
            }
        }
    }
    
    @objc func panGestureAction(_ panGesture: UIPanGestureRecognizer) {
        let translation = panGesture.translation(in: view)
        
        if panGesture.state == .began {
            originalPosition = mainContentView.center
        } else if panGesture.state == .changed {
            
            print(translation.y)
            
            let newY = translation.y + (originalPositionY ?? 0)
            if newY > originalPositionY ?? 0{
                mainContentView.frame.origin.y = translation.y + (originalPositionY ?? 0)
            }

        } else if panGesture.state == .ended {
            let velocity = panGesture.velocity(in: view)
            print(translation.y)
            if velocity.y >= 1500 || (mainContentView.frame.origin.y >= DEVICE_HEIGHT - 150){
                
                self.mainContentViewBottomContraint.constant = -self.mainContentView.frame.height
                UIView.animate(withDuration: 0.3) {
                    self.view.layoutIfNeeded()
                }
                self.delegate?.dismissExportVC()
                
            } else {
                UIView.animate(withDuration: 0.2, animations: { [weak self] in
                    //self?.view.alpha = 1.0
                    self?.mainContentView.center = (self?.originalPosition!)!
                })
            }
        }
    }

    @IBAction func dismiss(){
        let height = self.mainContentView.frame.height
        mainContentViewBottomContraint.constant = -height
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        self.delegate?.dismissExportVC()
    }
    
    
    // MARK: - Private Methods
    
    private func saveToDocDir(_ outputURL: URL){
        
        guard let containerURL = DirectoryManager.shared.appGroupBaseURL() else{
            return
        }
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(
                at: containerURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            debugPrint("error creating", containerURL, error)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, h:mm:ss a"
        let dateString = dateFormatter.string(from: Date())
        
        let videoName = "Export_\(dateString).mp4"
        
        let destination = containerURL.appendingPathComponent(videoName)
        //fileManager.removeFileIfExists(url: destination)
        do {
            debugPrint("Moving", outputURL, "to:", destination)
            try fileManager.moveItem(
                at: outputURL,
                to: destination
            )
            
//            self.saveTocoredata(videoName)
            
        } catch {
            debugPrint("ERROR", error)
        }
        
        DispatchQueue.main.async {
            self.dismiss(animated: true)
            
            //self.delegate?.needToExport(destination, cuttingRect: self.videoView.frame, actualRect: self.view.frame)
            
        }
    }
    
    func playVide(_ url: URL){
        let player = AVPlayer(url: url)
        let controller=AVPlayerViewController()
        controller.player=player
        controller.view.frame = self.view.frame
        self.view.addSubview(controller.view)
        self.addChild(controller)
        player.play()
    }
    // MARK: - Button Action
    
    @IBAction func exportButtonAction(_ sender: UIButton) {
        print("export button action")
        mainContentViewBottomContraint.constant = -self.mainContentView.frame.height
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        self.delegate?.exportClicked(video)
    }
    
}

extension ExportSettingsVC: TouchProgressDelegate{
    func selectedIndex(_ index: Int, view: UIView) {
        
        if view == self.frameRateProgress{
            
            if type == .screenRecord{
                if let key = frameDictionary.findKey(forValue: CGFloat(index)){
                    AppData.framerate = key
                    debugPrint("sr framerate = \(key)")
                    self.delegate?.exportOptionChoosed(nil, bitRate: nil, frameRate: index)
                }
            }else{
                self.video?.frameRate = frameRateArray[index]
                debugPrint("frame rate: \(frameRateArray[index])")
            }
            
        }else if view == self.qualityProgress{
            
            if type == .screenRecord{
                if let key = pixeDictionary.findKey(forValue: CGFloat(index)){
                    if key >= 1080{
                        
                        if !AppData.premiumUser{
//                            DispatchQueue.main.async {
//                                if let iapViewController = loadVCfromStoryBoard(name: "IAP", identifier: "IAPViewController") as? IAPViewController{
//                                    //iapViewController.delegate = self
//                                    iapViewController.modalPresentationStyle = .fullScreen
//                                    self.present(iapViewController, animated: true, completion: nil)
//                                }
//                                self.qualityProgress.initialIndex = self.pixeDictionary[AppData.resolution]
//                                return
//                            }
                            
                        }else{
                            AppData.resolution = key
                            debugPrint("sr pixel = \(key)")
                            self.delegate?.exportOptionChoosed(index, bitRate: nil, frameRate: nil)
                        }
                        
                    }else{
                        AppData.resolution = key
                        debugPrint("sr pixel = \(key)")
                        self.delegate?.exportOptionChoosed(index, bitRate: nil, frameRate: nil)
                    }
                    
                }
                
            }else{
                
                if let key = pixeDictionary.findKey(forValue: CGFloat(index)){
                    if key >= 1080{
                        
                        if !AppData.premiumUser{
//                            DispatchQueue.main.async {
//                                if let iapViewController = loadVCfromStoryBoard(name: "IAP", identifier: "IAPViewController") as? IAPViewController{
//                                    //iapViewController.delegate = self
//                                    iapViewController.modalPresentationStyle = .fullScreen
//                                    self.present(iapViewController, animated: true, completion: nil)
//                                }
//                                self.qualityProgress.initialIndex = self.pixeDictionary[540]
//                                return
//                            }
                            
                        }else{
                            self.video?.pixel = (pixeDictionaryStr[index])
                            debugPrint("pixel : \(pixeDictionaryStr[index] ?? "no data")")
                        }
                        
                    }else{
                        self.video?.pixel = (pixeDictionaryStr[index])
                        debugPrint("pixel : \(pixeDictionaryStr[index] ?? "no data")")
                    }
                    
                }
                
                
            }
            
        }else if view == self.bitRateProgress{
            if type == .screenRecord{
                if let key = bitrateDictionary.findKey(forValue: CGFloat(index)){
                    AppData.bitrate = key
                    self.delegate?.exportOptionChoosed(nil, bitRate: index, frameRate: nil)
                    debugPrint("sr bitrate = \(key)")
                }
            }
        }
        
        
    }
}
