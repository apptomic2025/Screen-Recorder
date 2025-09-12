

import UIKit

class ToolCVCell: UICollectionViewCell {
    
    static let identifier = "ToolCVCell"
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }

    @IBOutlet weak var cnstCrownIcnWidth: NSLayoutConstraint!
    @IBOutlet weak var cnstCrownIcnHeight: NSLayoutConstraint!
    @IBOutlet weak var imgCrown: UIImageView!
    @IBOutlet weak var imgIcn: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!{
        didSet{
            lblTitle.font = UIFont(name: "CircularStd-Medium", size: 12)
        }
    }
    @IBOutlet weak var vwBG: UIView!{
        didSet{
            vwBG.layer.cornerRadius = 12
        }
    }
    
    func setView(_ tool: ToolModel) {
        self.lblTitle.text = tool.title
        
        if let icn = tool.IconImg {
            self.imgIcn.image = icn
        }
        
        self.imgCrown.isHidden = !tool.isPremium
        
        if UIScreen.main.bounds.height == 667 {
            cnstCrownIcnWidth.constant = 18
            cnstCrownIcnHeight.constant = 18
        }
    }
}

