//
//  ImageActivityItemSource.swift
//  ScreenRecorder
//
//  Created by Apptomic on 9/10/25.
//

import Foundation
import LinkPresentation
// Helper function to format file size from bytes to a readable string (e.g., "1.2 MB")
func formatFileSize(bytes: Int) -> String {
    guard bytes > 0 else {
        return "0 KB"
    }
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useKB, .useMB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: Int64(bytes))
}

/**
 A custom UIActivityItemSource to provide rich content to the UIActivityViewController.
 This class generates a preview with a title showing the image's file size.
*/
class ImageActivityItemSource: NSObject, UIActivityItemSource {

    private var image: UIImage
    private var title: String

    init(image: UIImage) {
        self.image = image
        // Calculate the image data size and format it for the title
        let imageData = image.jpegData(compressionQuality: 1.0) ?? Data()
        self.title = "Photo Size: \(formatFileSize(bytes: imageData.count))"
        super.init()
    }

    // Returns a placeholder item for the activity view controller
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return image
    }

    // Returns the actual item to be shared
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return image
    }
    
    // Provides rich link metadata for a better preview in the share sheet header
    @available(iOS 13.0, *)
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = self.title
        // The iconProvider shows the small thumbnail next to the title
        metadata.iconProvider = NSItemProvider(object: image)
        return metadata
    }
}
