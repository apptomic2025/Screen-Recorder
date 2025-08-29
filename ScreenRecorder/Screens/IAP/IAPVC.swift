//
//  IAPVC.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 20/2/25.
//

import UIKit

protocol IAPDelegate: NSObject {
    func purchaseSuccess()
}

struct IAPConstants {
    
    /*
     The API key for your app from the RevenueCat dashboard: https://app.revenuecat.com
     */
    //#error("Modify this property to reflect your app's API key, then comment this line out.")
    static let apiKey = "appl_HgDklBdshvPNNetMIkfOVpwTphV"
    
    /*
     The entitlement ID from the RevenueCat dashboard that is activated upon successful in-app purchase for the duration of the purchase.
     */
    //#error("Modify this property to reflect your app's entitlement identifier, then comment this line out.")
    static let entitlementID = "premiumUser"
    
    static let successfully_restored =  NSNotification.Name(rawValue: "successfully_restored")
    static let product_loaded =  NSNotification.Name(rawValue: "product_loaded")

}
struct Trial {
    var isTrialHave: Bool
    var trialPeriod: Int
}
struct PriceUnit{
    
    var title: String
    var price: String
    var trial: Trial
    
    init(title: String, price: String, trial: Trial) {
        self.title = title
        self.price = price
        self.trial = trial
    }
}

var priceDict: [String : PriceUnit] = [:]

enum PurchaseKey: String {
    case  year_key = "sr_1999_1y_notrial"
    case  month_key = "sr_299_1m_No_Trial"
    case  week_key = "sr_0.99_1w_No_Trial"
}

class IAPVC: UIViewController {
    var purchaseKey: PurchaseKey = .year_key
    
    @IBOutlet weak var fiftyOffBgView: UIView!{
        didSet{
            fiftyOffBgView.cornerRadiusV = 6
        }
    }
    
    @IBOutlet weak var continuteButtonView: UIView!{
        didSet{
            continuteButtonView.cornerRadiusV = 10
        }
    }
    
    @IBOutlet weak var firstUnitBgView: UIImageView!
    @IBOutlet weak var secondUnitBgView: UIImageView!
    @IBOutlet weak var thirdUnitBgView: UIImageView!
    
    @IBOutlet weak var firstCheckmarkImageView: UIImageView!
    @IBOutlet weak var secondCheckmarkImageView: UIImageView!
    @IBOutlet weak var thirdCheckmarkImageView: UIImageView!
    
    @IBOutlet weak var lblSubscribeNow: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        setYearlyDefault()
        NotificationCenter.default.addObserver(self, selector: #selector(dismissView), name: IAPConstants.successfully_restored, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadProduct), name: IAPConstants.product_loaded, object: nil)
        
        if let priceUnit = priceDict[PurchaseKey.year_key.rawValue]{
            debugPrint(priceUnit.title)
            debugPrint(priceUnit.price)
            debugPrint(priceUnit.trial.isTrialHave)
            debugPrint(priceUnit.trial.trialPeriod)
        }
    }
    
    @objc private func loadProduct(){
        if let priceUnit = priceDict[PurchaseKey.year_key.rawValue]{
            debugPrint(priceUnit.title)
            debugPrint(priceUnit.price)
            debugPrint(priceUnit.trial.isTrialHave)
            debugPrint(priceUnit.trial.trialPeriod)
        }
    }
    
    @objc private func dismissView(){
         
        if self.isModal{
            self.dismiss(animated: true)
        }else{
            DispatchQueue.main.async {
                if let delegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                    delegate.setOnboardingAsRoot()
                }
            }
        }
     }
    
    private func setYearlyDefault(){
        
        self.purchaseKey = .year_key
                
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.firstUnitBgView.image = UIImage(named: "selectedUnitBG")
            self?.secondUnitBgView.image = UIImage(named: "unitBG")
            self?.thirdUnitBgView.image = UIImage(named: "unitBG")

            
            self?.firstCheckmarkImageView.image = UIImage(named: "selectedIcon")
            self?.secondCheckmarkImageView.image = UIImage(named: "unSelectedIcon")
            self?.thirdCheckmarkImageView.image = UIImage(named: "unSelectedIcon")
        }
        
    }
    
    // MARK: - Button Action
    @IBAction func crossButtonAction(_ sender: UIButton) {
        
        if self.isModal{
            self.dismiss(animated: true)
        }else{
            DispatchQueue.main.async {
                if let delegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                    delegate.setOnboardingAsRoot()
                }
            }
        }
    }
    
    
    @IBAction func yearlyUnitAction(_ sender: UIButton) {
        print("yearlyUnitAction btn action")
        lblSubscribeNow.text = "Try free and subscribe"
        
        self.purchaseKey = .year_key
        
        hepticFeedBack()
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.firstUnitBgView.image = UIImage(named: "selectedUnitBG")
            self?.secondUnitBgView.image = UIImage(named: "unitBG")
            self?.thirdUnitBgView.image = UIImage(named: "unitBG")

            
            self?.firstCheckmarkImageView.image = UIImage(named: "selectedIcon")
            self?.secondCheckmarkImageView.image = UIImage(named: "unSelectedIcon")
            self?.thirdCheckmarkImageView.image = UIImage(named: "unSelectedIcon")
        }
    }
    
    @IBAction func monthlyUnitAction(_ sender: UIButton) {
        print("monthlyUnitAction btn action")

        lblSubscribeNow.text = "Continue"
        //Subscribe Now
        
        self.purchaseKey = .month_key
        hepticFeedBack()
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.firstUnitBgView.image = UIImage(named: "unitBG")
            self?.secondUnitBgView.image = UIImage(named: "selectedUnitBG")
            self?.thirdUnitBgView.image = UIImage(named: "unitBG")
            
            self?.firstCheckmarkImageView.image = UIImage(named: "unSelectedIcon")
            self?.secondCheckmarkImageView.image = UIImage(named: "selectedIcon")
            self?.thirdCheckmarkImageView.image = UIImage(named: "unSelectedIcon")
        }
    }
    
    @IBAction func weeklyUnitAction(_ sender: UIButton) {
        print("weeklyUnitAction btn action")

        lblSubscribeNow.text = "Continue"
        
        self.purchaseKey = .week_key
        hepticFeedBack()
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.firstUnitBgView.image = UIImage(named: "unitBG")
            self?.secondUnitBgView.image = UIImage(named: "unitBG")
            self?.thirdUnitBgView.image = UIImage(named: "selectedUnitBG")
            
            self?.firstCheckmarkImageView.image = UIImage(named: "unSelectedIcon")
            self?.secondCheckmarkImageView.image = UIImage(named: "unSelectedIcon")
            self?.thirdCheckmarkImageView.image = UIImage(named: "selectedIcon")
        }
    }
    
    //MARK: - PURCHASE RELATED BUTTON ACTIONS

    @IBAction func restoreButtonAction(_ sender: UIButton){
        
        hepticFeedBack()
       // self.restore(self)

    }
    
    @IBAction func purchaseButtonAction(_ sender: UIButton){
        
        hepticFeedBack()
        
        
//        if !Connectivity.isConnectedToInternet {
//            // no internet
//            
//            let vc = CustomAlertViewController.customInit(customViewModel: CustomViewModel(title: "NO INTERNET", description: "Please check your internet connection and try again.", btnTitle: "OK"),successfullPurchasedState: true)
//          
//                self.add(vc, frame: self.view.bounds, contentView: self.view)
//                vc.presentAnimatiom()
//            
//            
//            return
//         }
        
        
        
//        AppnotrixStoreKit.shared.purcahseProduct(self.purchaseKey) { (result) in
//
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ){
//                AppnotrixLoader.dismissLoader()
//            }
//            
//            switch result{
//
//            case .success:
//                
//                Analytics.logEvent(AnalyticsConstants.successPurchased, parameters: nil)
//
//                
//                AppnotrixStoreKit.shared.refreshPurchaseStatus()
//                
//                let vc = CustomAlertViewController.customInit(customViewModel: CustomViewModel(title: "Congratulation!", description: "You've unlocked Screen Recorder Pro.", btnTitle: "OK"),successfullPurchasedState: true)
//                vc.delegate = self
//                self.add(vc, frame: self.view.bounds, contentView: self.view)
//                vc.presentAnimatiom()
//                
//                
//            case .failed:
//                Analytics.logEvent(AnalyticsConstants.failedPurchased, parameters: nil)
//
//                let vc = CustomAlertViewController.customInit(customViewModel: CustomViewModel(title: "Subscription Failed", description: "Something went wrong.", btnTitle: "OK"))
//                self.add(vc, frame: self.view.bounds, contentView: self.view)
//                vc.presentAnimatiom()
//                
//            case .canceled:
//                Analytics.logEvent(AnalyticsConstants.cancelPurchased, parameters: nil)
//
//                break
//            case .notFound:
//                break
//
//            }
//        }
    }

}

extension IAPVC: IAPDelegate{
    func purchaseSuccess() {
        dismissView()
    }
}
