//
//  IAPController.swift
//  ScreenRecorder_Into
//
//  Created by Tonmoy  on 8/31/25.
//

import UIKit

class IAPController: UIViewController {

    
    
    @IBOutlet weak var scrollVwBG: UIScrollView!{
        didSet{
            scrollVwBG.showsVerticalScrollIndicator = false
            scrollVwBG.showsHorizontalScrollIndicator = false
            if UIScreen.main.bounds.height <= 812 {
                scrollVwBG.contentInset = UIEdgeInsets(top: 18.5, left: 0, bottom: 150, right: 0)
            } else if UIScreen.main.bounds.height == 852 {
                scrollVwBG.contentInset = UIEdgeInsets(top: 34, left: 0, bottom: 150, right: 0)
            } else {
                scrollVwBG.contentInset = UIEdgeInsets(top: 48, left: 0, bottom: 0, right: 0)
            }
        }
    }
    @IBOutlet weak var cnstSpaceBetweenTopTitle_Units: NSLayoutConstraint!{
        didSet{
            if UIScreen.main.bounds.height <= 812 {
                cnstSpaceBetweenTopTitle_Units.constant = 28
            } else if UIScreen.main.bounds.height == 852 {
                cnstSpaceBetweenTopTitle_Units.constant = 32
            }
        }
    }
    @IBOutlet weak var cnstSpaceBetweenFeatures_Units: NSLayoutConstraint!{
        didSet{
            if UIScreen.main.bounds.height <= 812 {
                cnstSpaceBetweenFeatures_Units.constant = 20
            }
        }
    }
    @IBOutlet weak var cnstHeightContinueBtnBackShade: NSLayoutConstraint!{
        didSet{
            if UIScreen.main.bounds.height <= 667 {
                cnstHeightContinueBtnBackShade.constant = 160
            }
        }
    }
    @IBOutlet weak var imgBackShade: UIImageView!{
        didSet{
            imgBackShade.isHidden = UIScreen.main.bounds.height > 852
        }
    }
    @IBOutlet weak var vwBtnClose: UIView!{
        didSet{
            vwBtnClose.layer.cornerRadius = vwBtnClose.frame.size.height / 2
        }
    }
    @IBOutlet weak var vwBtnRestore: UIView! {
        didSet{
            vwBtnRestore.layer.cornerRadius = vwBtnRestore.frame.size.height / 2
        }
    }
    @IBOutlet weak var btnRestore: UIButton!{
        didSet{
            btnRestore.titleLabel?.font = UIFont(name: "CircularStd-Book", size: 14)
        }
    }
    @IBOutlet weak var vwYearly: UIView!{
        didSet{
            vwYearly.layer.cornerRadius = 20
            vwYearly.layer.borderWidth = 2
        }
    }
    @IBOutlet weak var vwMonthly: UIView!{
        didSet{
            vwMonthly.layer.cornerRadius = 20
            vwMonthly.layer.borderWidth = 2
        }
    }
    @IBOutlet weak var vwContinue: UIView!{
        didSet{
            vwContinue.layer.cornerRadius = 12
        }
    }
    @IBOutlet weak var vwFreeTrial: UIView!{
        didSet{
            vwFreeTrial.layer.cornerRadius = 4
        }
    }
    @IBOutlet weak var vwSave: UIView!{
        didSet{
            vwSave.layer.cornerRadius = vwSave.frame.size.height / 2
        }
    }
    @IBOutlet weak var imgMonthlyBG: UIImageView!
    @IBOutlet weak var imgYearlyBG: UIImageView!
    @IBOutlet weak var imgCheckMonthly: UIImageView!
    @IBOutlet weak var imgCheckYearly: UIImageView!
    
    
    
    //MARK: -> UILabels Outlets ___________________________
    @IBOutlet weak var lbl_BottomTitle: UILabel!{
        didSet{
            lbl_BottomTitle.font = UIFont(name: "CircularStd-Book", size: 12)
        }
    }
    @IBOutlet weak var btn_Continue: UIButton!{
        didSet{
            btn_Continue.titleLabel?.font = UIFont(name: "CircularStd-Bold", size: 16)
        }
    }
    @IBOutlet weak var lblUnlockAllFeature: UILabel!{
        didSet{
            lblUnlockAllFeature.font = UIFont(name: "CircularStd-Book", size: 16)
        }
    }
    @IBOutlet weak var lblFeature1: UILabel!{
        didSet{
            lblFeature1.font = UIFont(name: "CircularStd-Book", size: 14)
        }
    }
    @IBOutlet weak var lblFeature2: UILabel!{
        didSet{
            lblFeature2.font = UIFont(name: "CircularStd-Book", size: 14)
        }
    }
    @IBOutlet weak var lblFeature3: UILabel!{
        didSet{
            lblFeature3.font = UIFont(name: "CircularStd-Book", size: 14)
        }
    }
    @IBOutlet weak var lblFeature4: UILabel!{
        didSet{
            lblFeature4.font = UIFont(name: "CircularStd-Book", size: 14)
        }
    }
    //MARK: -> Yearly Labels.............................
    @IBOutlet weak var lblYearly: UILabel!{
        didSet{
            lblYearly.font = UIFont(name: "CircularStd-Medium", size: 16)
        }
    }
    @IBOutlet weak var lblYearlyPrice: UILabel!{
        didSet{
            lblYearlyPrice.font = UIFont(name: "CircularStd-Medium", size: 28)
        }
    }
    @IBOutlet weak var lblFreeTrialYearly: UILabel!{
        didSet{
            lblFreeTrialYearly.font = UIFont(name: "CircularStd-Medium", size: 12)
        }
    }
    @IBOutlet weak var lblYearlyPerWeek: UILabel!{
        didSet{
            lblYearlyPerWeek.font = UIFont(name: "CircularStd-Book", size: 14)
        }
    }
    @IBOutlet weak var lblSaveYearlyUnit: UILabel!{
        didSet{
            lblSaveYearlyUnit.font = UIFont(name: "CircularStd-Bold", size: 10)
        }
    }
    
    //MARK: -> Monthly Labels.............................
    @IBOutlet weak var lblMonthly: UILabel!{
        didSet{
            lblMonthly.font = UIFont(name: "CircularStd-Medium", size: 16)
        }
    }
    @IBOutlet weak var lblMonthlyPrice: UILabel!{
        didSet{
            lblMonthlyPrice.font = UIFont(name: "CircularStd-Medium", size: 28)
        }
    }
    @IBOutlet weak var lblMonthlyPerWeek: UILabel!{
        didSet{
            lblMonthlyPerWeek.font = UIFont(name: "CircularStd-Book", size: 14)
        }
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateBtn(1)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setPriceOnYearlyUnit()
        setPriceOnMonthlyUnit()
    }
    
    
    @IBAction func btnUnits(_ btn: UIButton) {
        //MARK: -> Button tag == 0 -> Monthly
        //MARK: -> Button tag == 1 -> Yearly
        self.updateBtn(btn.tag)
    }
    
    @IBAction func btnDismiss(_ btn: UIButton) {
        print("Dismiss View")
        
        if self.view.window?.rootViewController === self {
            print("I am the root view controller")
            DispatchQueue.main.async {
                AppData.isIntroFinished = true
                if let delegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                    delegate.setOnboardingAsRoot()
                }
            }
        }else{
            if self.isModal{
                self.dismiss(animated: true)
            }else{
                DispatchQueue.main.async {
                    AppData.isIntroFinished = true
                    if let delegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                        delegate.setOnboardingAsRoot()
                    }
                }
            }
        }
        
        
        
    }
    
    @IBAction func btnRestore(_ btn: UIButton) {
        print("Restore Purchase....")
    }
    
    func setPriceOnYearlyUnit() {
        let price = "$29.99"
        let pricePerMonth = "$2.49"
        
        lblYearlyPrice.text = price
        lblYearlyPerWeek.text = "\(pricePerMonth) per month, paid yearly"
    }
    
    func setPriceOnMonthlyUnit() {
        let price = "$9.99"
        
        lblMonthlyPrice.text = price
        lblMonthlyPerWeek.text = "\(price) per month, paid monthly"
    }
    
    
    func updateBtn(_ tag: Int) {
        UIView.animate(withDuration: 0.3) {
            self.imgYearlyBG.isHidden = tag != 1
            self.imgMonthlyBG.isHidden = tag != 0
            let nonSelectedBorder = UIColor(named: "nonSelectedBorder")
            let selectedBorder = UIColor(named: "selectedBorder")
            self.vwYearly.layer.borderColor = (tag == 1) ? selectedBorder?.cgColor : nonSelectedBorder?.cgColor
            self.vwMonthly.layer.borderColor = (tag == 0) ? selectedBorder?.cgColor : nonSelectedBorder?.cgColor
            let checked = UIImage(named: "checked")
            let unchecked = UIImage(named: "unchecked")
            self.imgCheckYearly.image = (tag == 1) ? checked : unchecked
            self.imgCheckMonthly.image = (tag == 0) ? checked : unchecked
            self.view.layoutIfNeeded()
        }
    }
}
