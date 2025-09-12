//
//  IntroFirstPageCVCell.swift
//  ScreenRecorder_Into
//
//  Created by Tonmoy  on 8/31/25.
//

import UIKit

class IntroFirstPageCVCell: UICollectionViewCell {
    
    static let identifier = "IntroFirstPageCVCell"
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    
    @IBOutlet weak var imgBGView: UIImageView!
    @IBOutlet weak var vwTopContent: UIView!
    @IBOutlet weak var imgViewThumb: UIImageView!
    @IBOutlet weak var imgTimerView: UIImageView!
    @IBOutlet weak var imgTools: UIImageView!
    @IBOutlet weak var imgShapes: UIImageView!
    @IBOutlet weak var imgReviewStars: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblSubtitle: UILabel!
    
    @IBOutlet weak var cnstBottom: NSLayoutConstraint!
    @IBOutlet weak var cnstBottomThumb: NSLayoutConstraint!
    @IBOutlet weak var cnstBottomTools: NSLayoutConstraint!
    @IBOutlet weak var cnstBottomShapes: NSLayoutConstraint!
    
    func setView(_ intro: IntroModel, _ index: Int) {
        
        if UIScreen.main.bounds.height <= 667 {
            self.cnstBottom.constant = 100
            self.cnstBottomThumb.constant = 28
            self.cnstBottomTools.constant = 20
            self.cnstBottomShapes.constant = 16
        }
        
        self.lblTitle.font = UIFont(name: "Dress Code Bold", size: 14)
        self.lblSubtitle.font = UIFont(name: "CircularStd-Bold", size: 36)
        self.lblTitle.text = intro.title.uppercased()
        self.lblSubtitle.text = intro.subTitle
        if let image = intro.imgBG {
            imgBGView.image = image
        }
        
        self.imgViewThumb.isHidden = index != 0
        self.imgTimerView.isHidden = index != 0
        self.vwTopContent.isHidden = index != 0
        self.imgTools.isHidden = index != 2
        self.imgShapes.isHidden = index != 3
        self.imgReviewStars.isHidden = index != 4
    }
}
