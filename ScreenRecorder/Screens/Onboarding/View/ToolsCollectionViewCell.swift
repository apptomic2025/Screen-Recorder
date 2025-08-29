//
//  ToolsCollectionViewCell.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 17/3/25.
//

import UIKit

class ToolsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var bgView: UIView!{
        didSet{
            self.bgView.layer.cornerRadius = 12
        }
    }
    @IBOutlet weak var toolsTypeImageView: UIImageView!
    @IBOutlet weak var PremiumToolsImageView: UIImageView!
    @IBOutlet weak var lblToolsName: UILabel!{
        didSet{
            self.lblToolsName.font = .appFont_CircularStd(type: .medium, size: 12)
            self.lblToolsName.textColor = UIColor(hex: "#151517")
        }
    }
    
    var videoTool: VideoTool? {
            didSet {
                guard let tool = videoTool else { return }
                self.toolsTypeImageView.image = UIImage(named: tool.imageName)
                self.lblToolsName.text = tool.title
                self.PremiumToolsImageView.isHidden = !tool.isPremium // Show premium icon only if the tool is premium
            }
        }


    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let uiType = getDeviceUIType()
        switch uiType {
        case .dynamicIsland:
            print("Device has Dynamic Island")
        case .notch:
            print("Device has a Notch")
        case .noNotch:
            print("Device has no Notch")
            self.lblToolsName.font = .appFont_CircularStd(type: .medium, size: 10)
        }
    }
}
