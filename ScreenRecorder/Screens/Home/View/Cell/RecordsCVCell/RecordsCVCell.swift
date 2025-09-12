

import UIKit

class RecordsCVCell: UICollectionViewCell {
    
    static let identifier = "RecordsCVCell"
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    var didSelectThreeDots:(() -> Void)?
    
    
    @IBOutlet weak var imgThumb: UIImageView!{
        didSet{
            imgThumb.layer.cornerRadius = 12
        }
    }
    @IBOutlet weak var vwFileSizeBG: UIView! {
        didSet{
            vwFileSizeBG.layer.cornerRadius = vwFileSizeBG.frame.size.height / 2
        }
    }
    @IBOutlet weak var vwThreeDots: UIView! {
        didSet{
            vwThreeDots.layer.cornerRadius = vwThreeDots.frame.size.height / 2
        }
    }
    @IBOutlet weak var vwDuration: UIView! {
        didSet{
            vwDuration.layer.cornerRadius = vwDuration.frame.size.height / 2
        }
    }
    @IBOutlet weak var lblFileName: UILabel!{
        didSet{
            lblFileName.font = UIFont(name: "CircularStd-Medium", size: 16)
        }
    }
    @IBOutlet weak var lblDateTime: UILabel!{
        didSet{
            lblDateTime.font = UIFont(name: "CircularStd-Book", size: 12)
        }
    }
    @IBOutlet weak var lblFileSize: UILabel!{
        didSet{
            lblFileSize.font = UIFont(name: "CircularStd-Book", size: 12)
        }
    }
    @IBOutlet weak var lblDuration: UILabel!{
        didSet{
            lblDuration.font = UIFont(name: "CircularStd-Book", size: 12)
        }
    }
    
    func setView() {
        
    }
    
    var video: SavedVideo?{
        didSet{
            if let video = video{
                lblFileName.text = video.displayName
                lblFileSize.text = (video.size ?? "0 MB")
                
                let dateFormatter1 = DateFormatter()
                dateFormatter1.dateFormat = "MMM d, yyyy"
                
                let dateFormatter2 = DateFormatter()
                dateFormatter2.dateFormat = "h:mm a"
                
                if let date = video.date{
                    let dateString = dateFormatter1.string(from: date) + " at " + dateFormatter2.string(from: date)
                    
                    let duration = Int(video.duration)
                    let durationString = duration.secondsToHoursMinutesSecondsInString()

                    lblDateTime.text = dateString
                    lblDuration.text = durationString

                }
                
            }
        }
    }
    
    @IBAction func btnThreeDots(_ btn: UIButton) {
        self.didSelectThreeDots?()
    }

}

