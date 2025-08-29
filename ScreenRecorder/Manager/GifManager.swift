//
//  GifManager.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 21/2/25.
//

import UIKit
import Foundation
import MobileCoreServices
import AVKit
import AVFoundation
import SlideShowMaker

class GifManager: NSObject {
    
    static let shared = GifManager()
    
    func deleteFile(_ filePath: URL) {
        let manager = FileManager.default
        guard manager.fileExists(atPath: filePath.path) else { return }
        do {
            try manager.removeItem(atPath: filePath.path)
        }catch{
            fatalError("Unable to delete file: \(error) : \(#function).")
        }
    }

    
    func createGif(_ imageArr: [UIImage], loopCount: Double?=nil, success: @escaping((URL) -> Void)) {
        let fileProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]]  as CFDictionary
        let frameProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [(kCGImagePropertyGIFDelayTime as String): loopCount]] as CFDictionary
        
        let documentsDirectoryURL: URL? = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
        guard let fileURL = documentsDirectoryURL?.appendingPathComponent("animated.gif") else { return }
        self.deleteFile(fileURL)

        if let url = fileURL as CFURL? {
            if let destination = CGImageDestinationCreateWithURL(url, kUTTypeGIF, imageArr.count, nil) {
                CGImageDestinationSetProperties(destination, fileProperties)
                for image in imageArr {
                    if let cgImage = image.cgImage {
                        CGImageDestinationAddImage(destination, cgImage, frameProperties)
                    }
                }
                if !CGImageDestinationFinalize(destination) {
                    print("Failed to finalize the image destination")
                }
                
                print("video_to_gif_url : \(fileURL)")
                success(fileURL)
            }
        }
    }
    
    func makeSlideShowVideo(audioURL: URL, images: [UIImage], frameTransition: ImageTransition,  completion: @escaping (URL?) -> Void) {
        
        var audio: AVURLAsset?
        var timeRange: CMTimeRange?
        
        audio = AVURLAsset(url: audioURL)
        let audioDuration = CMTime(seconds: 30, preferredTimescale: audio!.duration.timescale)
        timeRange = CMTimeRange(start: CMTime.zero, duration: audioDuration)
        
        let maker = VideoMaker(images: images, transition: frameTransition)

        maker.contentMode = .scaleAspectFit
        
        maker.exportVideo(audio: audio, audioTimeRange: timeRange, completed: { success, videoURL in
            
            if let url = videoURL {
                print(url)  // /Library/Mov/merge.mov
                completion(url)
            }
            
        }).progress = { progress in
            print(progress)
        }
    }
    
    func imageToGif(framesArray:[UIImage], progress: ((Double?) -> Void)? = nil, success: @escaping ((URL) -> Void), failure: @escaping ((String?) -> Void)) {
        
        var images = framesArray
        let outputSize = CGSize(width:images[0].size.width, height: images[0].size.height)
        
        guard var tempDirURL = DirectoryManager.shared.tempDirPath() else { return }
        let videoOutputURL = tempDirURL.appendingPathComponent("gif.mp4")

        print("GIF URL --- \(videoOutputURL)")
        deleteFile(videoOutputURL) //remove existing file
        
        guard let videoWriter = try? AVAssetWriter(outputURL: URL(fileURLWithPath: videoOutputURL.path), fileType: AVFileType.mp4) else {
            fatalError("AVAssetWriter error")
        }
        
        let outputSettings = [AVVideoCodecKey : AVVideoCodecType.h264, AVVideoWidthKey : NSNumber(value: Float(outputSize.width)), AVVideoHeightKey : NSNumber(value: Float(outputSize.height))] as [String : Any]
        
        guard videoWriter.canApply(outputSettings: outputSettings, forMediaType: AVMediaType.video) else {
            fatalError("Negative : Can't apply the Output settings...")
        }
        
        let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
        let sourcePixelBufferAttributesDictionary = [
            kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: NSNumber(value: Float(outputSize.width)),
            kCVPixelBufferHeightKey as String: NSNumber(value: Float(outputSize.height))
        ]
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        
        if videoWriter.canAdd(videoWriterInput) {
            videoWriter.add(videoWriterInput)
        }
        
        if videoWriter.startWriting() {
            videoWriter.startSession(atSourceTime: CMTime.zero)
            assert(pixelBufferAdaptor.pixelBufferPool != nil)
            
            let media_queue = DispatchQueue(__label: "mediaInputQueue", attr: nil)
            
            videoWriterInput.requestMediaDataWhenReady(on: media_queue, using: { () -> Void in
  
                let frameRate: Int64 = 15 // 30 // fps
                let waitPerFrameSecond: Int64 = 1

                var frameCount: Int64 = 0
                var appendSucceeded = true

                while (!images.isEmpty) {
                    if (videoWriterInput.isReadyForMoreMediaData) {
                        let nextPhoto = images.remove(at: 0)

                        let presentationTime = CMTimeMake(value: frameCount * waitPerFrameSecond, timescale: Int32(frameRate)) // timescale is fps
                        
                        var pixelBuffer: CVPixelBuffer? = nil
                        let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferAdaptor.pixelBufferPool!, &pixelBuffer)

                        if let pixelBuffer = pixelBuffer, status == 0 {
                            let managedPixelBuffer = pixelBuffer

                            CVPixelBufferLockBaseAddress(managedPixelBuffer, [])

                            let data = CVPixelBufferGetBaseAddress(managedPixelBuffer)
                            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
                            let context = CGContext(data: data, width: Int(outputSize.width), height: Int(outputSize.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(managedPixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)

                            context?.clear(CGRect(x: 0, y: 0, width: outputSize.width, height: outputSize.height))

                            let horizontalRatio = CGFloat(outputSize.width) / nextPhoto.size.width
                            let verticalRatio = CGFloat(outputSize.height) / nextPhoto.size.height

                            let aspectRatio = min(horizontalRatio, verticalRatio) // ScaleAspectFit

                            let newSize = CGSize(width: nextPhoto.size.width * aspectRatio, height: nextPhoto.size.height * aspectRatio)

                            let x = newSize.width < outputSize.width ? (outputSize.width - newSize.width) / 2 : 0
                            let y = newSize.height < outputSize.height ? (outputSize.height - newSize.height) / 2 : 0

                            context?.draw(nextPhoto.cgImage!, in: CGRect(x: x, y: y, width: newSize.width, height: newSize.height))
                            
                            CVPixelBufferUnlockBaseAddress(managedPixelBuffer, [])
                            
                            appendSucceeded = pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                            frameCount += 1
                        } else {
                            print("Failed to allocate pixel buffer")
                            appendSucceeded = false
                        }
                    }
                    if !appendSucceeded {
                        break
                    }
                }
                videoWriterInput.markAsFinished()
                videoWriter.finishWriting { () -> Void in
                    print("Done saving")
                    success(videoOutputURL)
                }
            })
        }
    }
}

