//
//  BroadcastWriter.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 25/2/25.
//


import AVFoundation
import ReplayKit

enum Errorr: Swift.Error {
    case wrongAssetWriterStatus(AVAssetWriter.Status)
    case selfDeallocated
}


public final class BroadcastWriter {

    private var assetWriterSessionStarted: Bool = false
    private let assetWriterQueue: DispatchQueue
    private let assetWriter: AVAssetWriter

    private lazy var videoInput: AVAssetWriterInput = {

        let maxLength = max(screenSize.width, screenSize.height)
        let minLength = min(screenSize.width, screenSize.height)
        
        let res = AppData.resolution
        var videoResoulationValue: CGFloat
        
        if res == 3840{
            videoResoulationValue = CGFloat(res) / maxLength
        }else{
            videoResoulationValue = CGFloat(res) / minLength
        }
        
        let videoWidth = screenSize.width * videoResoulationValue
        //screenSize.width * screenScale
        let videoHeight = screenSize.height * videoResoulationValue
        //screenSize.height * screenScale
        
        /*
        let compressionProperties: [String: Any] = [
            AVVideoExpectedSourceFrameRateKey: 60.nsNumber,
            AVVideoProfileLevelKey: "HEVC_Main_AutoLevel",
            AVVideoQualityKey: 1.0 //1.0 // Video Quality Range:-> Low(0.0) - High(1.0)
        ]
         NSDictionary *videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                                    [NSNumber numberWithDouble:12*1024*1024.0], AVVideoAverageBitRateKey,
                                                    AVVideoProfileLevelH264High41,AVVideoProfileLevelKey,
        */
        
        let frame_rate = AppData.framerate
        let bit_rate = 12000000
        let compressionProperties: [String: Any] = [
            AVVideoExpectedSourceFrameRateKey: frame_rate.nsNumber,
            AVVideoProfileLevelKey: "HEVC_Main_AutoLevel",
            AVVideoQualityKey: AVCaptureSession.Preset.hd4K3840x2160, //1.0 // Video Quality Range:-> Low(0.0) - High(1.0)
            AVVideoAverageBitRateKey: bit_rate
        ]
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.hevc,
            AVVideoWidthKey: videoWidth.nsNumber,
            AVVideoHeightKey: videoHeight.nsNumber,
            AVVideoCompressionPropertiesKey: compressionProperties,
        ]
        
        let input: AVAssetWriterInput = .init(
            mediaType: .video,
            outputSettings: videoSettings
        )
        input.expectsMediaDataInRealTime = true
        return input
    }()

    private var audioSampleRate: Double {
        AVAudioSession.sharedInstance().sampleRate
    }
    private lazy var audioInput: AVAssetWriterInput = {

        var audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: 1,
            AVSampleRateKey: audioSampleRate
        ]
        let input: AVAssetWriterInput = .init(
            mediaType: .audio,
            outputSettings: audioSettings
        )
        input.expectsMediaDataInRealTime = true
        return input
    }()

    private lazy var microphoneInput: AVAssetWriterInput = {
        let sampleRate = AVAudioSession.sharedInstance().sampleRate

        var audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: 1,
            AVSampleRateKey: audioSampleRate
        ]
        let input: AVAssetWriterInput = .init(
            mediaType: .audio,
            outputSettings: audioSettings
        )
        input.expectsMediaDataInRealTime = true
        return input
    }()

    private lazy var inputs: [AVAssetWriterInput] = [
        videoInput,
        audioInput,
        microphoneInput
    ]

    private let screenSize: CGSize
    private let screenScale: CGFloat

    public init(
        outputURL url: URL,
        assetWriterQueue queue: DispatchQueue = .init(label: "BroadcastSampleHandler.assetWriterQueue"),
        screenSize: CGSize,
        screenScale: CGFloat
    ) throws {
        assetWriterQueue = queue
        assetWriter = try .init(url: url, fileType: .mp4)

        self.screenSize = screenSize
        self.screenScale = screenScale
    }

    public func start() throws {
        try assetWriterQueue.sync {
            let status = assetWriter.status
            guard status == .unknown else {
                throw Errorr.wrongAssetWriterStatus(status)
            }
            try assetWriter.error.map {
                throw $0
            }
            inputs
                .lazy
                .filter(assetWriter.canAdd(_:))
                .forEach(assetWriter.add(_:))
            try assetWriter.error.map {
                throw $0
            }
            assetWriter.startWriting()
            try assetWriter.error.map {
                throw $0
            }
        }
    }

    public func processSampleBuffer(
        _ sampleBuffer: CMSampleBuffer,
        with sampleBufferType: RPSampleBufferType
    ) throws -> Bool {

        guard sampleBuffer.isValid,
              CMSampleBufferDataIsReady(sampleBuffer) else {
            debugPrint(
                "sampleBuffer.isValid", sampleBuffer.isValid,
                "CMSampleBufferDataIsReady(sampleBuffer)", CMSampleBufferDataIsReady(sampleBuffer)
            )
            return false
        }

        let isWriting = assetWriterQueue.sync {
            assetWriter.status == .writing
        }

        guard isWriting else {
            debugPrint(
                "assetWriter.status",
                assetWriter.status.description,
                "assetWriter.error:",
                assetWriter.error  ?? "no error"
            )
            return false
        }

        assetWriterQueue.sync {
            startSessionIfNeeded(sampleBuffer: sampleBuffer)
        }

        let capture: (CMSampleBuffer) -> Bool
        switch sampleBufferType {
        case .video:
            capture = captureVideoOutput
        case .audioApp:
            capture = captureAudioOutput
        case .audioMic:
            capture = captureMicrophoneOutput
        @unknown default:
            debugPrint(#file, "Unknown type of sample buffer, \(sampleBufferType)")
            capture = { _ in false }
        }

        return assetWriterQueue.sync {
            capture(sampleBuffer)
        }
    }

    public func pause() {
        // TODO: Pause
    }

    public func resume() {
        // TODO: Resume
    }

    public func finish() throws -> URL {
        return try assetWriterQueue.sync {
            let group: DispatchGroup = .init()

            inputs
                .lazy
                .filter { $0.isReadyForMoreMediaData }
                .forEach { $0.markAsFinished() }

            let status = assetWriter.status
            guard status == .writing else {
                throw Errorr.wrongAssetWriterStatus(status)
            }
            group.enter()

            var error: Swift.Error?
            assetWriter.finishWriting { [weak self] in

                defer {
                    group.leave()
                }

                guard let self = self else {
                    error = Errorr.selfDeallocated
                    return
                }

                if let e = self.assetWriter.error {
                    error = e
                    return
                }

                let status = self.assetWriter.status
                guard status == .completed else {
                    error = Errorr.wrongAssetWriterStatus(status)
                    return
                }
            }
            group.wait()
            try error.map { throw $0 }
            return assetWriter.outputURL
        }
    }
}

private extension BroadcastWriter {

    func startSessionIfNeeded(sampleBuffer: CMSampleBuffer) {
        guard !assetWriterSessionStarted else {
            return
        }

        let sourceTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        assetWriter.startSession(atSourceTime: sourceTime)
        assetWriterSessionStarted = true
    }

    func captureVideoOutput(_ sampleBuffer: CMSampleBuffer) -> Bool {
        guard videoInput.isReadyForMoreMediaData else {
            debugPrint("audioInput is not ready")
            return false
        }
        return videoInput.append(sampleBuffer)
    }

    func captureAudioOutput(_ sampleBuffer: CMSampleBuffer) -> Bool {
        guard audioInput.isReadyForMoreMediaData else {
            debugPrint("audioInput is not ready")
            return false
        }
        return audioInput.append(sampleBuffer)
    }

    func captureMicrophoneOutput(_ sampleBuffer: CMSampleBuffer) -> Bool {

        guard microphoneInput.isReadyForMoreMediaData else {
            debugPrint("microphoneInput is not ready")
            return false
        }
        return microphoneInput.append(sampleBuffer)
    }
}

