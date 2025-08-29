//
//  ScreenRecorder.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 20/3/25.
//

import Foundation
import ReplayKit
import AVKit

protocol RPScreenRecordDelegate: AnyObject{
    func startRecord()
    func userDeniedTheRecordPermission()
}

class GlobalDelegate{
    weak var rpScreenRecordDelegate: RPScreenRecordDelegate?
    static let shared = GlobalDelegate()
}


@objc class ScreenRecorder:NSObject
{
    private var writer: BroadcastWriter?
    var assetWriter:AVAssetWriter!
    var videoInput:AVAssetWriterInput!
    var firstTime = false
    let viewOverlay = WindowUtil()

    //MARK: Screen Recording
    public func startRecording(withFileName fileName: String, recordingHandler:@escaping (URL?)-> Void)
    {
        if #available(iOS 11.0, *)
        {
            let fileURL = URL(fileURLWithPath: ReplayFileUtil.filePath(fileName))
            
            let screen: UIScreen = .main
            do {
                writer = try .init(
                    outputURL: fileURL,
                    screenSize: screen.bounds.size,
                    screenScale: screen.scale
                )
            } catch {
                assertionFailure(error.localizedDescription)
                
                return
            }
           
            
            RPScreenRecorder.shared().isMicrophoneEnabled = true
            RPScreenRecorder.shared().startCapture(handler: { (sample, bufferType, error) in
                
                if !self.firstTime{
                    self.firstTime = true
                    GlobalDelegate.shared.rpScreenRecordDelegate?.startRecord()
                }
                DispatchQueue.main.async {
                    guard let writer = self.writer else {
                        debugPrint("processSampleBuffer: Writer is nil")
                        return
                    }
                    
                    do {
                        try writer.start()
                    } catch {
                        
                    }
                    
                    do {
                        let captured = try writer.processSampleBuffer(sample, with: bufferType)
                        debugPrint("processSampleBuffer captured", captured)
                    } catch {
                        debugPrint("processSampleBuffer error:", error.localizedDescription)
                    }
                }
                
                
            }) { (error) in
                
                recordingHandler(nil)
                GlobalDelegate.shared.rpScreenRecordDelegate?.userDeniedTheRecordPermission()
            }
        } else
        {
            
        }
    }

    public func stopRecording(handler: @escaping (URL?) -> Void)
    {
        if #available(iOS 11.0, *)
        {
            RPScreenRecorder.shared().stopCapture { (Error) in
//                self.assetWriter.finishWriting {
//                    print(ReplayFileUtil.fetchAllReplays())
//                }
//
                guard let writer = self.writer else {
                    return
                }

                let outputURL: URL
                do {
                    outputURL = try writer.finish()
                    let asset = AVAsset(url: outputURL)
                    
                    handler(outputURL)
                } catch {
                    debugPrint("writer failure", error)
                    handler(nil)
                    return
                }

                
            }
        } else {
            // Fallback on earlier versions
        }
    }


}



