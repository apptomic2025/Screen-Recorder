//
//  ShareCViCell.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 6/3/25.
//

import UIKit

class ShareCVCell: UICollectionViewCell {

    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var lbl: UILabel!{
        didSet {
            lbl.textColor = UIColor(hex: "#2C2C2E")
        }
    }
    

    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

}
