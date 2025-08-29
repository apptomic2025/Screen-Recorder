//
//  DirectoryManager.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 21/2/25.
//

import Foundation
import AVFoundation
import AVKit
import Photos
import CoreData

var folderURL: URL?

class DirectoryManager{
    
    static let shared = DirectoryManager()
    
    let manager = FileManager.default
    
    private init(){
        if let containerURL = appGroupBaseURL(){
            do {
                try self.manager.createDirectory(
                    at: containerURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                if let thumbURL = self.appGroupThumbBaseURL(){
                    try self.manager.createDirectory(
                        at: thumbURL,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                }
                
                if let extractAudio = self.extractAudioDirPath(){
                    try self.manager.createDirectory(
                        at: extractAudio,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                }
                
                if let extractAudioThumb = self.extractAudioThumDirPath(){
                    try self.manager.createDirectory(
                        at: extractAudioThumb,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                }
                
                if let extractAudio = self.voiceRecordDirPath(){
                    try self.manager.createDirectory(
                        at: extractAudio,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                }
                
                if let extractAudio = self.tempDirPath(){
                    try self.manager.createDirectory(
                        at: extractAudio,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                }
                
                if let extractAudio = self.commentaryDirURL(){
                    try self.manager.createDirectory(
                        at: extractAudio,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                }
            } catch {
                debugPrint("error creating", containerURL, error)
            }
        }
    }
    
    func homeDirectory()->URL?{
        return self.manager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func appGroupBaseURL()->URL?{
        
        guard let documentsDirectoryPath = manager.containerURL(
                    forSecurityApplicationGroupIdentifier: suitName
        )?.appendingPathComponent("Library/Documents/ScreenRecord/Main") else {
            
            return nil
        }
        return documentsDirectoryPath
    }
    
    func commentaryDirURL()->URL?{
        guard let documentsDirectoryPath = manager.containerURL(
                    forSecurityApplicationGroupIdentifier: suitName
        )?.appendingPathComponent("Library/Documents/ScreenRecord/Commentary") else {
            
            return nil
        }
        return documentsDirectoryPath
    }
    
    func tempDirPath()->URL?{
        guard let documentsDirectoryPath = manager.containerURL(
                    forSecurityApplicationGroupIdentifier: suitName
        )?.appendingPathComponent("Library/Documents/ScreenRecord/TempDirPath") else {
            
            return nil
        }
        return documentsDirectoryPath
    }
    
    func voiceRecordDirPath()->URL?{
        guard let documentsDirectoryPath = manager.containerURL(
                    forSecurityApplicationGroupIdentifier: suitName
        )?.appendingPathComponent("Library/Documents/ScreenRecord/VoiceRecord") else {
            
            return nil
        }
        return documentsDirectoryPath
    }
    
    func extractAudioDirPath()->URL?{
        guard let documentsDirectoryPath = manager.containerURL(
                    forSecurityApplicationGroupIdentifier: suitName
        )?.appendingPathComponent("Library/Documents/ScreenRecord/ExtractAudio") else {
            
            return nil
        }
        return documentsDirectoryPath
    }
    
    func extractAudioThumDirPath()->URL?{
        guard let documentsDirectoryPath = manager.containerURL(
                    forSecurityApplicationGroupIdentifier: suitName
        )?.appendingPathComponent("Library/Documents/ScreenRecord/ExtractAudioThumb") else {
            
            return nil
        }
        return documentsDirectoryPath
    }
    
    func appGroupThumbBaseURL()->URL?{
        
        guard let documentsDirectoryPath = manager.containerURL(
                    forSecurityApplicationGroupIdentifier: suitName
        )?.appendingPathComponent("Library/Documents/ScreenRecord/Thumb") else {
            
            return nil
        }
        return documentsDirectoryPath
    }

    func deleteFile(_ filePath: URL) {
        guard manager.fileExists(atPath: filePath.path) else { return }
        do {
            try manager.removeItem(atPath: filePath.path)
        }catch{
            fatalError("Unable to delete file: \(error) : \(#function).")
        }
    }
    
    
    func fetchVideos(success: @escaping(_ arr: [URL]) -> Void){
        if let container = self.appGroupBaseURL() {
            
            let documentsDirectoryPath = manager.urls(for: .documentDirectory, in: .userDomainMask).first!
            print("documentsDirectoryPath : ", documentsDirectoryPath)
            
            do {
                                
                let contents = try manager.contentsOfDirectory(at: container, includingPropertiesForKeys: [.contentModificationDateKey])
                success(contents)
            }catch {
                print("contents, \(error)")
                success([])
            }
        }
    }
    
}
