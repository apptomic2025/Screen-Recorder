//
//  AppData.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 20/2/25.
//

import Foundation
import UIKit

let suitName = "group.com.samar.screenrecorder"

struct User: Codable {
    var firstName: String
    var lastName: String
    var lastLogin: Date?
}

@propertyWrapper
struct Storagee<T: Codable> {
    private let key: String
    private let defaultValue: T

    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get {
            // Read value from UserDefaults
            let shareDefault = UserDefaults(suiteName: suitName)
            if key == "framerate"{
                guard let data = shareDefault?.object(forKey: key) as? Data else {
                    return defaultValue
                }

                // Convert data to the desire data type
                let value = try? JSONDecoder().decode(T.self, from: data)
                return value ?? defaultValue
            }
 
            guard let data = shareDefault?.object(forKey: key) as? Data else {
                return defaultValue
            }

            // Convert data to the desire data type
            let value = try? JSONDecoder().decode(T.self, from: data)
            return value ?? defaultValue
        }
        set {
            // Convert newValue to data
            let data = try? JSONEncoder().encode(newValue)
            if key == "framerate"{
                debugPrint(newValue)
            }
            if key == "bitrate"{
                debugPrint(newValue)
            }
            // Set value to UserDefaults
            let shareDefault = UserDefaults(suiteName: suitName)
            shareDefault!.set(data, forKey: key)
            shareDefault?.synchronize()
        }
    }
}

@propertyWrapper
struct EncryptedStringStorage {

    private let key: String

    init(key: String) {
        self.key = key
    }

    var wrappedValue: String {
        get {
            // Get encrypted string from UserDefaults
            let shareDefault = UserDefaults(suiteName: suitName)
            return shareDefault!.string(forKey: key) ?? ""
        }
        set {
            // Encrypt newValue before set to UserDefaults
            let encrypted = encrypt(value: newValue)
            let shareDefault = UserDefaults(suiteName: suitName)
            shareDefault!.set(encrypted, forKey: key)
            shareDefault?.synchronize()
        }
    }

    private func encrypt(value: String) -> String {
        // Encryption logic here
        return String(value.reversed())
    }
}

struct AppData {
    
    @Storagee(key: "premium_userNew", defaultValue: false)
    static var premiumUser: Bool
    
    @Storagee(key: "premium_user", defaultValue: false)
    static var premiumUserOld: Bool
    
    @Storagee(key: "expiry_date", defaultValue: Date())
    static var expiryDate: Date
    
    @Storagee(key: "faceCamFreeCount", defaultValue: 0)
    static var faceCamFreeCount: Int
    
    @Storagee(key: "review_show_once_singlesession", defaultValue: false)
    static var review_showed_in_session: Bool
    
    @Storagee(key: "tracking_permission", defaultValue: false)
    static var trackingpermission: Bool
    
    @Storagee(key: "resolution", defaultValue: 720)
    static var resolution: Int
    
    @Storagee(key: "bitrate", defaultValue: 12)
    static var bitrate: Int
    
    @Storagee(key: "framerate", defaultValue: 60)
    static var framerate: Int
    
    @Storagee(key: "lastRecorded", defaultValue: nil)
    static var lastRecordedVideo: String?
    
    @Storagee(key: "recordCount", defaultValue: 0)
    static var recordingCount: Int
    
    @Storagee(key: "faceCamCount", defaultValue: 0)
    static var faceCamCount: Int
    
    @Storagee(key: "commentaryCount", defaultValue: 0)
    static var commentaryCount: Int
    
    @Storagee(key: "voiceRecordCount", defaultValue: 1)
    static var voiceRecordCount: Int
    
    @Storagee(key: "live_broadcast_mode", defaultValue: false)
    static var liveBroadcastMode: Bool
    
    @Storagee(key: "rtmpLink", defaultValue: nil)
    static var rtmpLink: String?
    
    @Storagee(key: "rtmpKEY", defaultValue: nil)
    static var rtmpKEY: String?
    
    @Storagee(key: "volume", defaultValue: 1.0)
    static var volume: Float
    
    @Storagee(key: "microphone", defaultValue: 1.0)
    static var microphone: Float
    
    @Storagee(key: "isIntroFinished", defaultValue: false)
    static var isIntroFinished: Bool
    
    @Storagee(key: "isNotificationOn", defaultValue: false)
    static var isNotificationOn: Bool
}

