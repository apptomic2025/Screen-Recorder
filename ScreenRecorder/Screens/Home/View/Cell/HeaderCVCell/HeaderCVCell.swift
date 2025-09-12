


import UIKit

class HeaderCVCell: UICollectionViewCell {
    
    static let identifier = "HeaderCVCell"
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    var didTappedSeeAll:(() -> Void)?
    
    @IBOutlet weak var lblMyRecordings: UILabel!{
        didSet{
            lblMyRecordings.font = UIFont(name: "CircularStd-Medium", size: 16)
        }
    }
    
    @IBOutlet weak var lblSeeAll: UILabel!{
        didSet{
            lblSeeAll.font = UIFont(name: "CircularStd-Medium", size: 12)
        }
    }
    
    @IBAction func btnSeeAll(_ btn: UIButton) {
        self.didTappedSeeAll?()
    }
}

