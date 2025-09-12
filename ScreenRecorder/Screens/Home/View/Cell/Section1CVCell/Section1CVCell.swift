

import UIKit

class Section1CVCell: UICollectionViewCell {
    
    static let identifier = "Section1CVCell"
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    var didTappedSeeAll:(() -> Void)?
    var didTappedToStart:(() -> Void)?
    var didTappedResolutionSettings: ((Int) -> Void)?
    var didSelectTool:((IndexPath) -> Void)?
    
    
    @IBOutlet weak var cnstTapToStartIconWidth: NSLayoutConstraint!
    @IBOutlet weak var cnstTapToStartIconHeight: NSLayoutConstraint!
    @IBOutlet weak var cnstTopSpaceTapToStart: NSLayoutConstraint!
    @IBOutlet weak var cnstTopSpaceResolutionSettings: NSLayoutConstraint!
    @IBOutlet weak var lblResolution: UILabel!{
        didSet{
            lblResolution.font = UIFont(name: "CircularStd-Book", size: 15)
        }
    }
    @IBOutlet weak var lblResolutionTitle: UILabel!{
        didSet{
            lblResolutionTitle.font = UIFont(name: "CircularStd-Book", size: 12)
        }
    }
    @IBOutlet weak var lblMbSize: UILabel!{
        didSet{
            lblMbSize.font = UIFont(name: "CircularStd-Book", size: 15)
        }
    }
    @IBOutlet weak var lblMbSizeTitle: UILabel!{
        didSet{
            lblMbSizeTitle.font = UIFont(name: "CircularStd-Book", size: 12)
        }
    }
    @IBOutlet weak var lblFrameRate: UILabel!{
        didSet{
            lblFrameRate.font = UIFont(name: "CircularStd-Book", size: 15)
        }
    }
    @IBOutlet weak var lblFrameRateTitle: UILabel!{
        didSet{
            lblFrameRateTitle.font = UIFont(name: "CircularStd-Book", size: 12)
        }
    }
    @IBOutlet weak var lblRotation: UILabel!{
        didSet{
            lblRotation.font = UIFont(name: "CircularStd-Book", size: 15)
        }
    }
    @IBOutlet weak var lblTools: UILabel!{
        didSet{
            lblTools.font = UIFont(name: "CircularStd-Medium", size: 16)
        }
    }
    @IBOutlet weak var cnstCollectionOfToolsHeight: NSLayoutConstraint!
    @IBOutlet weak var collectionOfTools: UICollectionView!{
        didSet{
            collectionOfTools.delegate = self
            collectionOfTools.dataSource = self
            collectionOfTools.register(ToolCVCell.nib(), forCellWithReuseIdentifier: ToolCVCell.identifier)
            collectionOfTools.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        }
    }
    @IBOutlet weak var lblSeeAll: UILabel! {
        didSet{
            lblSeeAll.font = UIFont(name: "CircularStd-Medium", size: 12)
        }
    }
    @IBOutlet weak var lblRecordingSettings: UILabel! {
        didSet{
            lblRecordingSettings.font = UIFont(name: "CircularStd-Medium", size: 16)
        }
    }
    @IBOutlet weak var vwRecordingSettings: UIView!{
        didSet{
            vwRecordingSettings.layer.cornerRadius = 12
        }
    }
    @IBOutlet weak var lblTapToStart: UILabel! {
        didSet{
            lblTapToStart.font = UIFont(name: "CircularStd-Bold", size: 36)
        }
    }
    @IBOutlet weak var lblRecordingScreen: UILabel! {
        didSet{
            let systemFont = UIFont.systemFont(ofSize: 14)
            let font = UIFont(name: "CircularStd-Book", size: 14)
            let text = "RECORDING SCREEN"

            let attributedString = NSMutableAttributedString(string: text)
            attributedString.addAttribute(.font, value: font ?? systemFont, range: NSMakeRange(0, text.count))
            attributedString.addAttribute(.kern, value: (font?.pointSize ?? systemFont.pointSize) * 0.22, range: NSMakeRange(0, text.count))
            
            lblRecordingScreen.attributedText = attributedString
        }
    }
    
    func setView(_ recordingSetting: RecordingSettingsModel) {
//        if recordingSetting.resolution == "4K" {
//            self.lblResolution.attributedText = styledText(from: recordingSetting.resolution)
//        } else {
//            self.lblResolution.text = recordingSetting.resolution
//        }
//        lblMbSize.attributedText = styledText(from: recordingSetting.fileSize)
        lblResolution.text = recordingSetting.resolution
        lblMbSize.text = recordingSetting.fileSize
        lblFrameRate.text = recordingSetting.frameRate
        lblRotation.text = recordingSetting.rotation
        
        let height = UIScreen.main.bounds.size.height
        let ratio: CGFloat = (120 / 932)
        var newSize = ratio*height
        if newSize < 90 {
            newSize = 95
        }
        cnstCollectionOfToolsHeight.constant = newSize
        collectionOfTools.reloadData()
        
        let ratioTapToStartIcn: CGFloat = (180 / 932)
        let ratioTapToStartIcnTopSpacing: CGFloat = (58 / 932)
        let sz = ratioTapToStartIcn * height
        self.cnstTapToStartIconHeight.constant = sz
        self.cnstTapToStartIconWidth.constant = sz
        let topSpace = ratioTapToStartIcnTopSpacing * height
        if UIScreen.main.bounds.height == 667 {
            cnstTopSpaceTapToStart.constant = 30
            cnstTopSpaceResolutionSettings.constant = 20
        } else {
            self.cnstTopSpaceTapToStart.constant = topSpace
        }
    }


    @IBAction func btnSeeAll(_ btn: UIButton) {
        self.didTappedSeeAll?()
    }
    
    @IBAction func btnTapToStart(_ btn: UIButton) {
        self.didTappedToStart?()
    }
    
    @IBAction func btnResolutionSettings(_ btn: UIButton) {
        self.didTappedResolutionSettings?(btn.tag)
    }
}



extension Section1CVCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tools.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ToolCVCell.identifier, for: indexPath) as? ToolCVCell {
            cell.setView(tools[indexPath.row])
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.didSelectTool?(indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let newSize = collectionView.frame.size.height
        return CGSize(width: newSize, height: newSize)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
