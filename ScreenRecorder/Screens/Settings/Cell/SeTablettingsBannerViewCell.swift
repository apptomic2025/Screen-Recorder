//
//  SeTablettingsBannerViewCell.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 23/3/25.
//

import UIKit

class SeTablettingsBannerViewCell: UITableViewCell {
    
    @IBOutlet weak var proLbl: UILabel!
    @IBOutlet weak var proIcon: UIImageView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var planNameLbl: UILabel!
    @IBOutlet weak var planDescriptionLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLbl.attributedText = NSMutableAttributedString(string: "CURRENT PLAN", attributes: [NSAttributedString.Key.kern: 8.76])
        
//        proLbl.backgroundColor = .clear
//        proLbl.layer.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5).cgColor
//        proLbl.layer.cornerRadius = 18.0

        updateData()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        
    }
    
    func updateData(){
        
        if AppData.premiumUser{
            //proLbl.isHidden = true
            proIcon.isHidden = true
            planNameLbl.text = "Premium Plan".uppercased()
            planDescriptionLbl.text = "Premium plan vaid till: \(AppData.expiryDate.get_mm_day_year())"
            
        }else{
            //proLbl.isHidden = false
            proIcon.isHidden = false
            planNameLbl.text = "Basic Plan".uppercased()
            planDescriptionLbl.text = "Get all premium features without ad"
        }
    }
    
}


