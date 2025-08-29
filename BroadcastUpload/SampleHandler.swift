//
//  SampleHandler.swift
//  BroadcastUpload
//
//  Created by Sajjad Hosain on 25/2/25.
//

import ReplayKit
import UserNotifications
import Photos
import PhotosUI
import HaishinKit
import VideoToolbox

class LiveBroadcast{
    
     lazy var rtmpConnection: RTMPConnection = {
            let conneciton = RTMPConnection()
            conneciton.addEventListener(.rtmpStatus, selector: #selector(rtmpStatusEvent), observer: self)
            conneciton.addEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
            return conneciton
        }()

        
    lazy var rtmpStream: RTMPStream = {
            RTMPStream(connection: rtmpConnection)
        }()
    
    public init(
        broadcastURL str: String, key: String){
        rtmpStream = RTMPStream(connection: rtmpConnection)
        rtmpConnection.connect(str)
        rtmpStream.publish(key.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression))
    }
    
    @objc
    private func rtmpStatusEvent(_ status: Notification) {
        
    }
    
    @objc
        private func rtmpErrorHandler(_ notification: Notification) {
            //logger.info(notification)
            //rtmpConnection.connect(Preference.defaultInstance.uri!)
        }
}

class SampleHandler: RPBroadcastSampleHandler {

    private var liveBroadcaster: LiveBroadcast?
    private var writer: BroadcastWriter?
    private let fileManager: FileManager = .default
    private let notificationCenter = UNUserNotificationCenter.current()
    private let nodeURL: URL
    private var isMirophoneOn = false
    
    override init() {
                
        let fileName = UUID().uuidString
        nodeURL = fileManager.temporaryDirectory
            .appendingPathComponent(fileName)
            .appendingPathExtension(for: .mpeg4Movie)
        fileManager.removeFileIfExists(url: nodeURL)
        super.init()
    }

    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        
        if AppData.liveBroadcastMode{
            if let link = AppData.rtmpLink, let key = AppData.rtmpKEY{
                liveBroadcaster = .init(broadcastURL: link, key: key)
                //return
            }
            
        }
        let screen: UIScreen = .main
        do {
            writer = try .init(
                outputURL: nodeURL,
                screenSize: screen.bounds.size,
                screenScale: screen.scale
            )
        } catch {
            assertionFailure(error.localizedDescription)
            finishBroadcastWithError(error)
            return
        }
        do {
            try writer?.start()
        } catch {
            finishBroadcastWithError(error)
        }
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        
        if AppData.liveBroadcastMode{
            
            switch sampleBufferType {
            case .video:
                if let description = CMSampleBufferGetFormatDescription(sampleBuffer) {
                    let dimensions = CMVideoFormatDescriptionGetDimensions(description)
                    liveBroadcaster?.rtmpStream.videoSettings = [
                        .width: dimensions.width,
                        .height: dimensions.height,
                        .profileLevel: kVTProfileLevel_H264_Baseline_AutoLevel
                    ]
                }
                liveBroadcaster?.rtmpStream.appendSampleBuffer(sampleBuffer, withType: .video)
            case .audioMic:
                isMirophoneOn = true
                if CMSampleBufferDataIsReady(sampleBuffer) {
                    liveBroadcaster?.rtmpStream.appendSampleBuffer(sampleBuffer, withType: .audio)
                }
            case .audioApp:
                if !isMirophoneOn && CMSampleBufferDataIsReady(sampleBuffer) {
                    liveBroadcaster?.rtmpStream.appendSampleBuffer(sampleBuffer, withType: .audio)
                }
            @unknown default:
                break
            }
        }
        //else{
            
            guard let writer = writer else {
                debugPrint("processSampleBuffer: Writer is nil")
                return
            }

            do {
                let captured = try writer.processSampleBuffer(sampleBuffer, with: sampleBufferType)
                debugPrint("processSampleBuffer captured", captured)
            } catch {
                debugPrint("processSampleBuffer error:", error.localizedDescription)
            }
            
       // }
        
    }
    
    

    override func broadcastPaused() {
        debugPrint("=== paused")
        writer?.pause()
    }

    override func broadcastResumed() {
        debugPrint("=== resumed")
        writer?.resume()
    }

    override func broadcastFinished() {
        
        if AppData.liveBroadcastMode {
            liveBroadcaster?.rtmpStream.close()
            liveBroadcaster?.rtmpStream.dispose()
            liveBroadcaster?.rtmpConnection.close()
        }
        //if !AppData.liveBroadcastMode{
            
            guard let writer = writer else {
                return
            }

            let outputURL: URL
            do {
                outputURL = try writer.finish()
            } catch {
                debugPrint("writer failure", error)
                return
            }

            guard let containerURL = DirectoryManager.shared.appGroupBaseURL() else{
                return
            }
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

            let videoName = "Recording_\(dateString).mp4"

            let destination = containerURL.appendingPathComponent(videoName)
            //fileManager.removeFileIfExists(url: destination)
            do {
                debugPrint("Moving", outputURL, "to:", destination)
                try self.fileManager.moveItem(
                    at: outputURL,
                    to: destination
                )
               
                AppData.lastRecordedVideo = videoName
                self.scheduleNotification()

            } catch {
                debugPrint("ERROR", error)
            }

            debugPrint("FINISHED")
        //}
    
        AppData.liveBroadcastMode = false
        AppData.rtmpKEY = nil
        AppData.rtmpLink = nil
    }

    private func scheduleNotification() {
        print("scheduleNotification")
        let content: UNMutableNotificationContent = .init()
        content.title = "broadcastFinished"
        content.subtitle = Date().description
        content.sound = .default
        
        let darwinNotificationName = CFNotificationName("com.samar.videoSaved" as CFString)
        let darwinNotificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(darwinNotificationCenter, darwinNotificationName, nil, nil, false)

        let trigger: UNNotificationTrigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 0.1, repeats: false)
        let notificationRequest: UNNotificationRequest = .init(
            identifier: "com.samar.screenrecorder.Notification",
            content: content,
            trigger: trigger
        )
        notificationCenter.add(notificationRequest) { (error) in
            print("add", notificationRequest, "with ", error?.localizedDescription ?? "no error")
        }
    }
}

extension FileManager {

    func removeFileIfExists(url: URL) {
        guard fileExists(atPath: url.path) else { return }
        do {
            try removeItem(at: url)
        } catch {
            print("error removing item \(url)", error)
        }
    }
}

extension UNNotificationAttachment {

    static func create(identifier: String, image: UIImage, options: [NSObject : AnyObject]?) -> UNNotificationAttachment? {
        let fileManager = FileManager.default
        let tmpSubFolderName = ProcessInfo.processInfo.globallyUniqueString
        let tmpSubFolderURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(tmpSubFolderName, isDirectory: true)
        do {
            try fileManager.createDirectory(at: tmpSubFolderURL, withIntermediateDirectories: true, attributes: nil)
            let imageFileIdentifier = identifier+".png"
            let fileURL = tmpSubFolderURL.appendingPathComponent(imageFileIdentifier)
            let imageData = UIImage.pngData(image)
            try imageData()?.write(to: fileURL)
            let imageAttachment = try UNNotificationAttachment.init(identifier: imageFileIdentifier, url: fileURL, options: options)
            return imageAttachment
        } catch {
            print("error " + error.localizedDescription)
        }
        return nil
    }
}

