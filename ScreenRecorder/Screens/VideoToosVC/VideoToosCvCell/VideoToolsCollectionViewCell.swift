//
//  VideoToolsCollectionViewCell.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 23/3/25.
//

import UIKit

class VideoToolsCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var imgViewProBadge: UIImageView!{
        didSet{
            imgViewProBadge.isHidden = true
        }
    }
    @IBOutlet weak var lblTitle: UILabel!{
        didSet{
            self.lblTitle.font = .appFont_CircularStd(type: .medium, size: 12)
            self.lblTitle.textColor = UIColor(hex: "#151517")
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        bgView.cornerRadiusV = 7
    }
    
    public func configure(icon: UIImage, smallText: String, bigText: String){
        iconImageView.image = icon
        lblTitle.text = bigText
    }

}
