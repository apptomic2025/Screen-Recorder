//
//  FrameCollectionViewCell.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 22/3/25.
//

import UIKit

class FrameCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var frameImageView: UIImageView!
    @IBOutlet weak var removeButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        frameImageView.cornerRadiusV = 7
    }

}
