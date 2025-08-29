//
//  EditorCVCell.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 7/3/25.
//

import UIKit

class EditorCVCell: UICollectionViewCell {

    @IBOutlet weak var iconImgView:UIImageView!
    @IBOutlet weak var titleLbl:UILabel!{
        didSet{
            self.titleLbl.font = .appFont_CircularStd(type: .medium, size: 12)
        }
    }

    var editModel: EditorModel?{
        didSet{
            if let editModel{
                iconImgView.image = UIImage(named: editModel.icon)
                titleLbl.text = editModel.title
            }
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

}
