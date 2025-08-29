//
//  CoreDataManager.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 26/2/25.
//

import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    let persistentContainer: NSPersistentContainer
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "ScreenRecorder") // Replace with your Core Data model name
        persistentContainer.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Create SavedVideo
    func createSavedVideo(displayName: String,name: String,size: String? = nil,type: String? = nil,duration: Double = 0.0,index: Int32 = 0,thumbName: String? = nil
    ) -> SavedVideo? {
        let savedVideo = SavedVideo(context: context)
        savedVideo.displayName = displayName
        savedVideo.name = name
        savedVideo.size = size
        savedVideo.type = type
        savedVideo.duration = duration
        savedVideo.index = index
        savedVideo.thumbName = thumbName
        savedVideo.date = Date() // Assign current date
        
        saveContext()
        
        return savedVideo
    }
    
    
    
    // MARK: - Fetch SavedVideos
    func fetchSavedVideos() -> [SavedVideo] {
        let request: NSFetchRequest<SavedVideo> = SavedVideo.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch SavedVideos: \(error)")
            return []
        }
    }
    
    // MARK: - Save Context
     func saveContext() -> Bool {
        if context.hasChanges {
            do {
                try context.save()
                return true
            } catch {
                print("Failed to save context: \(error)")
                return false
            }
        }
        return false
    }
    
    // MARK: - Delete SavedVideo
    func deleteSavedVideo(_ savedVideo: SavedVideo) -> Bool {
        context.delete(savedVideo)
        return saveContext()
    }
}

