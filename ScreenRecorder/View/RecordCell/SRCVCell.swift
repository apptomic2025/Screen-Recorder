//
//  SRCVCell.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 7/3/25.
//

import UIKit

class SRCVCell: UICollectionViewCell {

    
    @IBOutlet weak var fileThumbnailImgView: UIImageView!{
        didSet{
            self.fileThumbnailImgView.layer.cornerRadius = 6
        }
    }
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var lblCreateDate: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var moreBigButton: UIButton!
    @IBOutlet weak var durationLblWidthConstraint: NSLayoutConstraint!

    var video: SavedVideo?{
        didSet{
            if let video = video{
                fileNameLabel.text = video.displayName
                durationLabel.text = (video.size ?? "0 MB")
                let width = self.durationLabel.textWidth()
                self.durationLblWidthConstraint.constant = width + 15
                
                let dateFormatter1 = DateFormatter()
                dateFormatter1.dateFormat = "MMM d, yyyy"
                
                let dateFormatter2 = DateFormatter()
                dateFormatter2.dateFormat = "h:mm a"
                
                if let date = video.date{
                    let dateString = dateFormatter1.string(from: date) + " at " + dateFormatter2.string(from: date)
                    
                    let duration = Int(video.duration)
                    let durationString = duration.secondsToHoursMinutesSecondsInString()

                    lblCreateDate.text = dateString + " | " + durationString

                }
                
            }
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        fileThumbnailImgView.layer.cornerRadius = 6
    }
    
    public func configure(_ fileName: String, createdDate: String, thumbnail: UIImage){
        fileNameLabel.text = fileName
        lblCreateDate.text = createdDate
        fileThumbnailImgView.image = thumbnail
    }

}


extension String {
    static var bullet: String {
        return "•"
    }
}
