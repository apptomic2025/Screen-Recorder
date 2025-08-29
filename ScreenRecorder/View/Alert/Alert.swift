//
//  Alert.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 23/3/25.
//

import UIKit
import MessageUI

struct AlertModel{
    var title: String?
    var text: String?
    var mailID: String?
    var type: AlertType?
    var subject: String?
}

enum AlertType {
    case share,feedback,contact,follow,review,other
}

protocol AlertTypeButtonActionDelegate: AnyObject{
    func buttonClicked(type: AlertType)
}

class Alert: UIView {
    
    var type: AlertType?
    var title: String?
    var text: String?
    var mailID: String?
    var model: AlertModel?
    weak var delegate: AlertTypeButtonActionDelegate?

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var alertLabel: UILabel!
    @IBOutlet weak var alertTitleLabel: UILabel!
    @IBOutlet weak var mailButton: UIButton!

    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    init(frame: CGRect, model: AlertModel) {
        super.init(frame: frame)
        self.type = model.type
        self.title = model.title
        self.text = model.text
        self.mailID = model.mailID
        commonInit()
    }
    
    
    private func commonInit() {
        /// Loading the nib
        guard let contentView = self.fromNib()
            else { fatalError("View could not load from nib") }
        contentView.frame = CGRect(x: 0, y: 0, width: DEVICE_WIDTH, height: DEVICE_HEIGHT)
        self.alpha = 0.0
        self.alertLabel.text = self.text
        self.alertLabel.setLineSpacing(lineSpacing: 7.0)
        var height = 43 + 15 + (self.alertLabel.heightForView() - 40)
        if height < 43{
            height = 43
        }
        if self.type == .follow{
            self.mailID = "Instagram"
        }
        self.alertLabel.frame.size.height = height
        self.contentView.frame.size.height = 160 + height
        self.contentView.center = self.center
        self.alertTitleLabel.text = self.title
        self.mailButton.setTitle(self.mailID, for: .normal)
        
        self.contentView.alpha = 0.0
        self.contentView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        self.alertLabel.textAlignment = .center
        addSubview(contentView)
    }
    
    @IBAction func buttonPressed(){
        self.delegate?.buttonClicked(type: self.type ?? .contact)
        if type == .other{
            dismissAnimatiom()
        }
        //
    }
    
    
    
    func presentAnimatiom(){
        UIView.animate(withDuration: 0.1, animations: {
            self.alpha = 1.0
        }, completion: nil)
        UIView.animate(withDuration: 0.7, animations: {
            self.contentView.alpha = 1.0
            self.contentView.transform = CGAffineTransform.identity
        }){ (finished) in
            if finished == true{
                
                
            }
        }
    }
    
    @IBAction func dismissAnimatiom(){
        
     UIView.animate(withDuration: 0.35, animations: {
            self.alpha = 0.0
         }) { (finished) in
             if finished == true{
                 self.removeFromSuperview()
                 
             }
         }
     }
    
}

extension Alert: MFMailComposeViewControllerDelegate{
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
                controller.dismiss(animated: true)
            }
}

