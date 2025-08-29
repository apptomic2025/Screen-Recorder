//
//  OptionsTableViewCell.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 5/4/25.
//

import UIKit

class OptionsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var selectDeselectImageView: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!{
        didSet{
            self.lblTitle.font = .appFont_CircularStd(type: .medium, size: 15)
            self.lblTitle.textColor = .black
        }
    }
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configure(with option: VideoOption) {
        
        self.lblTitle.text = option.title

          if option.isSelected {
              self.lblTitle.textColor = UIColor(hex: "#FE655C")
              self.selectDeselectImageView.image = UIImage(named: "selectedIconForExport")
          } else {
              self.lblTitle.textColor = .black
              self.selectDeselectImageView.image = UIImage(named: "DeselectedIconForExport")
          }
      }

    
}
