//
//  SettingsTableViewCell.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 23/3/25.
//

import UIKit

class SettingsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var dwscriptionLbl: UILabel!
    @IBOutlet weak var arrowImgView: UIImageView!
    @IBOutlet weak var notificationSwitch: UISwitch!{
        didSet{
            //notificationSwitch.tintColor = UIColor(r:44 , g: 43, b: 50)
            notificationSwitch.thumbTintColor = .white
        }
    }
    @IBOutlet weak var versionTitleLbl: UILabel!{
        didSet{
            versionTitleLbl.isHidden = true
        }
    }
    
    var swichState: NotificationState = .authorised{
        didSet{
            if swichState == .authorised{
                //notificationSwitch.thumbTintColor = UIColor(named: "yellowThemecolor")
                notificationSwitch.setOn(true, animated: true)
            }else{
                //notificationSwitch.thumbTintColor = .white
                notificationSwitch.setOn(false, animated: true)
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        
    }
    
    @IBAction func switchAction(_ thisSwitch: UISwitch){
        
        if thisSwitch.isOn{
            //thisSwitch.thumbTintColor = UIColor(named: "yellowThemecolor")
            AppData.isNotificationOn = true
            getNotificationPermissionState { state in
                if state == .unAuthorised{
                    
                }
            }
        }else{
            //thisSwitch.thumbTintColor = .white
            AppData.isNotificationOn = false
        }
    }
    
}

