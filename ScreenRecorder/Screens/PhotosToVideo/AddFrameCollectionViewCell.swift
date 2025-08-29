//
//  AddFrameCollectionViewCell.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 22/3/25.
//

import UIKit

class AddFrameCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var addButtonView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        addButtonView.cornerRadiusV = 7

    }

}
