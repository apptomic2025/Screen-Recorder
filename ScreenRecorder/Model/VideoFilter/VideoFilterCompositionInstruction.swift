//
//  VideoFilterCompositionInstruction.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 5/3/25.
//

import Foundation
import AVKit

class VideoFilterCompositionInstruction : AVMutableVideoCompositionInstruction{
    
   // For implementation in Swift 2.x, look at the history of this file at
   // https://github.com/jojodmo/VideoFilterExporter/blob/1d506238a445b6684ef40d2701419cc01158331e/VideoFilterCompositionInstruction.swift
   
    let trackID: CMPersistentTrackID
    let filters: [CIFilter]
    let context: CIContext
    
    override var requiredSourceTrackIDs: [NSValue]{get{return [NSNumber(value: Int(self.trackID))]}}
    override var containsTweening: Bool{get{return false}}
    
    init(trackID: CMPersistentTrackID, filters: [CIFilter], context: CIContext){
        self.trackID = trackID
        self.filters = filters
        self.context = context
        
        super.init()
        
        self.enablePostProcessing = true
    }
    
    required init?(coder aDecoder: NSCoder){
        fatalError("init(coder:) has not been implemented")
    }
}

