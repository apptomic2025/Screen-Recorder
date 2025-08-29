//
//  FilterCollectionViewCell.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 5/3/25.
//

import UIKit


class FilterCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var selectedImgView: UIImageView!
    @IBOutlet weak var lbl: UILabel!
    
    var filteredImage: UIImage?{
        didSet{
            guard let filteredImage = filteredImage else { return }
            imgView.image = filteredImage
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        imgView.cornerRadiusV = 4.0
        //self.layer.cornerRadius = 8.0
    }

}
