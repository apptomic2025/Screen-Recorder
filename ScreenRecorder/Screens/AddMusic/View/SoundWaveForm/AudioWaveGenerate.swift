//
//  AudioWaveGenerate.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 22/3/25.
//

import Foundation
import UIKit
import AVFoundation

public class AudioWaveGenerate{
    public func WaveFormGenerate(url: URL,width : Int, size : CGSize,_ completion: @escaping (_ img : UIImage) -> ()){
        var image = UIImage()
        let asset = AVAsset(url: url)
        let audioTracks:[AVAssetTrack] = asset.tracks(withMediaType: AVMediaType.audio)
        if let track:AVAssetTrack = audioTracks.first{
            //let timeRange = CMTimeRangeMake(CMTime(seconds: 0, preferredTimescale: 1000), CMTime(seconds: 1, preferredTimescale: 1000))
            let timeRange:CMTimeRange? = nil

            // Let's extract the downsampled samples
            let samplingStartTime = CFAbsoluteTimeGetCurrent()
            SamplesExtractor.samples(audioTrack: track,
                                     timeRange: timeRange,
                                     desiredNumberOfSamples: width,
                                     onSuccess: { s, sMax, _ in
                                        let sampling = (samples: s, sampleMax: sMax)

                                        let samplingDuration = CFAbsoluteTimeGetCurrent() - samplingStartTime

                                        // Image Drawing
                                        // Let's draw the sample into an image.

                                        let configuration = WaveformConfiguration(size: size,
                                                                                  color: UIColor.white,
                                                                                  backgroundColor: UIColor(red: 47/255, green: 47/255, blue: 47/255, alpha: 1),
                                                                                  style: .striped(period: 4),
                                                                                  position: .middle,
                                                                                  scale: 1,
                                                                                  borderWidth: 0.5,
                                                                                  borderColor: UIColor(red: 47/255, green: 47/255, blue: 47/255, alpha: 1))

                                        let drawingStartTime = CFAbsoluteTimeGetCurrent()
                                        image = WaveFormDrawer.image(with: sampling, and: configuration)!
                                        let drawingDuration = CFAbsoluteTimeGetCurrent() - drawingStartTime
                completion(image)
            }, onFailure: { error, id in
                print("The Error is : \(id ?? "") \(error)")
            })
        }
    }
}

