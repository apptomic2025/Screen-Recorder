//
//  PhotoQualityViewController.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 21/3/25.
//

import UIKit

class PhotoQualityViewController: UIViewController {

    @IBOutlet weak var previewImageView: UIImageView!
    
    @IBOutlet weak var noneImageView: UIImageView!
    @IBOutlet weak var softImageView: UIImageView!
    @IBOutlet weak var mediumImageView: UIImageView!
    @IBOutlet weak var highImageView: UIImageView!
    
    @IBOutlet weak var noneLabel: UILabel!{
        didSet{
            self.noneLabel.font = .appFont_CircularStd(type: .book, size: 14)
        }
    }
    @IBOutlet weak var softLabel: UILabel!{
        didSet{
            self.softLabel.font = .appFont_CircularStd(type: .book, size: 14)
        }
    }
    @IBOutlet weak var mediumLabel: UILabel!{
        didSet{
            self.mediumLabel.font = .appFont_CircularStd(type: .book, size: 14)
            self.mediumLabel.textColor = UIColor(named: "newBrandColor")
        }
    }
        
    @IBOutlet weak var highLabel: UILabel!{
        didSet{
            self.highLabel.font = .appFont_CircularStd(type: .book, size: 14)
        }
    }
    
    @IBOutlet weak var lblTitle: UILabel!{
        didSet{
            self.lblTitle.font = .appFont_CircularStd(type: .bold, size: 20)
            self.lblTitle.textColor = UIColor(hex: "#151517")
        }
    }
    
    var selectedFrame: UIImage?

    var shareImage: UIImage?
    
    var highQualityImage: UIImage?
    var mediumQualityImage: UIImage?
    var lowQualityImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the image data for different quality levels
        if let highQualityImageData = selectedFrame?.jpegData(compressionQuality: 1.0),
        let mediumQualityImageData = selectedFrame?.jpegData(compressionQuality: 0.7),
           let lowQualityImageData = selectedFrame?.jpegData(compressionQuality: 0.3){
            
            // Create UIImage objects from the image data
            highQualityImage = UIImage(data: highQualityImageData)
            mediumQualityImage = UIImage(data: mediumQualityImageData)
            lowQualityImage = UIImage(data: lowQualityImageData)
        }
        

        //shareImage = selectedFrame
        
        previewImageView.image = selectedFrame
        
        noneImageView.image = selectedFrame
        softImageView.image = UIImage(data: selectedFrame?.jpeg(.soft) ?? Data())
        mediumImageView.image = UIImage(data: selectedFrame?.jpeg(.medium) ?? Data())
        highImageView.image = UIImage(data: selectedFrame?.jpeg(.highest) ?? Data())
        
//        noneImageView.cornerRadiusV = 3
//        softImageView.cornerRadiusV = 3
//        mediumImageView.cornerRadiusV = 3
//        highImageView.cornerRadiusV = 3
        
        

        

    }
    
    // MARK: - Private Methods -
    
//    func shareImage(image: UIImage, quality: Float){
//        selectedFrame = UIImage(data: image.jpeg(.medium) ?? Data())
//        previewImageView.image = selectedFrame
//    }
    
    
    func saveImageToTemp(_ image: UIImage)->URL?{
        // Get the path to the temporary directory
        
        self.clearTempDirectory()
        
        let tempDirectory = NSTemporaryDirectory()

        // Generate a unique file name
        let uuid = UUID().uuidString
        let fileName = "\(uuid).jpg"

        // Combine the temporary directory path and the file name to get the full file path
        let filePath = "\(tempDirectory)/\(fileName)"

        // Get the JPEG representation of the image data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            fatalError("Failed to get image data")
        }

        // Save the image data to a file in the temporary directory
        do {
            try imageData.write(to: URL(fileURLWithPath: filePath))
            print("Image saved to temporary directory: \(filePath)")
            return URL(fileURLWithPath: filePath)
            
        } catch {
            debugPrint("Failed to save image: \(error.localizedDescription)")
            return nil
            //fatalError("Failed to save image: \(error.localizedDescription)")
        }
    }
    func shareFrame(image: UIImage) {
        
        var itemss: [Any] = [image]
        if let url = self.saveImageToTemp(image){
            itemss = [url]
        }
        let activityViewController = UIActivityViewController(activityItems: itemss, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.airDrop, UIActivity.ActivityType.postToFacebook ]
        DispatchQueue.main.async {
            self.present(activityViewController, animated: true, completion: nil)
        }
    }

    // MARK: - Button Action -
    
    @IBAction func crossButtonAction(_ sender: UIButton){
        self.dismiss(animated: true)
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func shareButtonActionButtonAction(_ sender: UIButton){
        if let shareImage = shareImage {
            shareFrame(image: shareImage)
            //UIImageWriteToSavedPhotosAlbum(shareImage, nil, nil, nil)
        }
    }
    
    @IBAction func noneButtonAction(_ sender: UIButton){
        DispatchQueue.main.async { [self] in
            //shareImage = selectedFrame
            shareImage = selectedFrame
            previewImageView.image = selectedFrame
            noneLabel.textColor = UIColor(named: "newBrandColor")
            softLabel.textColor = UIColor(hex: "#151517")
            mediumLabel.textColor = UIColor(hex: "#151517")
            highLabel.textColor = UIColor(hex: "#151517")
        }
    }
    
    @IBAction func softButtonAction(_ sender: UIButton){
        DispatchQueue.main.async { [self] in
            //shareImage = UIImage(data: selectedFrame?.jpeg(.soft) ?? Data())
            shareImage = lowQualityImage
            previewImageView.image = lowQualityImage
            noneLabel.textColor = UIColor(hex: "#151517")
            softLabel.textColor = UIColor(named: "newBrandColor")
            mediumLabel.textColor = UIColor(hex: "#151517")
            highLabel.textColor = UIColor(hex: "#151517")
            
        }
    }
    
    @IBAction func mediumButtonAction(_ sender: UIButton){
        DispatchQueue.main.async { [self] in
            //shareImage = UIImage(data: selectedFrame?.jpeg(.medium) ?? Data())
            shareImage = mediumQualityImage
            previewImageView.image = mediumQualityImage
            noneLabel.textColor = UIColor(hex: "#151517")
            softLabel.textColor = UIColor(hex: "#151517")
            mediumLabel.textColor = UIColor(named: "newBrandColor")
            highLabel.textColor = UIColor(hex: "#151517")
        }
    }
    
    @IBAction func highButtonAction(_ sender: UIButton){
        DispatchQueue.main.async { [self] in
            //shareImage = UIImage(data: selectedFrame?.jpeg(.highest) ?? Data())
            shareImage = highQualityImage
            previewImageView.image = highQualityImage
            noneLabel.textColor = UIColor(hex: "#151517")
            softLabel.textColor = UIColor(hex: "#151517")
            mediumLabel.textColor = UIColor(hex: "#151517")
            highLabel.textColor = UIColor(named: "newBrandColor")
        }
    }
    
}



