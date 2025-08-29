//
//  File.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 23/3/25.
//

import UIKit

struct CustomViewModel {
    var title: String
    var description: String
    var btnTitle: String
}

//protocol IAPDelegate: NSObject {
//    func purchaseSuccess()
//}

enum AlertState {
case general,premium
}

class CustomAlertViewController: UIViewController {
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var descriptionLbl: UILabel!
    @IBOutlet weak var descriptionPremiumLbl: UILabel!
    @IBOutlet weak var btn: UIButton!
    @IBOutlet weak var btnPremium: UIButton!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var premiumView: UIView!

    private var customViewModel: CustomViewModel?
    private var successfullRestoredState: Bool?
    private var successfullPurchasedState: Bool?
    
    weak var delegate: IAPDelegate?
    var state: AlertState?
    
    //MARK: - LIFE CYCLE
    
    override func viewDidLoad() {
        super.viewDidLoad()

       initialSetup()
        //presentAnimatiom()
    }
    
    static func customInit(customViewModel: CustomViewModel, successfullRestoredState: Bool? = false, successfullPurchasedState: Bool? = false, state: AlertState? = .general) -> CustomAlertViewController {
        
        let VC = UIStoryboard(name: "CustomView", bundle: nil).instantiateViewController(withIdentifier: "CustomAlertViewController") as! CustomAlertViewController
        VC.customViewModel = customViewModel
        VC.successfullRestoredState = successfullRestoredState
        VC.successfullPurchasedState = successfullPurchasedState
        VC.state = state
        return VC
    }
    
    
//MARK: - PRIVATE FUNC
    
    private func dismisVC(){
        
        UIView.animate(withDuration: 0.35, animations: {
            self.view.alpha = 0.0
            }) { (finished) in
                if finished == true{
                    self.remove()
                    if self.successfullRestoredState == true{
                        NotificationCenter.default.post(name: IAPConstants.successfully_restored, object: nil)
                        return
                    }
                    
                    if self.successfullPurchasedState == true{
                        self.delegate?.purchaseSuccess()
                    }
                }
            }
        }
    
    func presentAnimatiom(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIView.animate(withDuration: 0.1, animations: {
                self.view.alpha = 1.0
            }, completion: nil)
            UIView.animate(withDuration: 0.7, animations: {
                self.mainView.alpha = 1.0
                self.mainView.transform = CGAffineTransform.identity
                
                self.premiumView.alpha = 1.0
                self.premiumView.transform = CGAffineTransform.identity
            }){ _ in
            }
        }
        
    }
    
    private func initialSetup(){
        
        self.mainView.backgroundColor = .black
        self.premiumView.backgroundColor = .black
        view.backgroundColor = .clear
        
        //make view blur
        let itranslucentView = ILTranslucentView(frame: self.view.bounds)
        itranslucentView.translucentAlpha = 1.0
        itranslucentView.translucentStyle = .black
        itranslucentView.translucentTintColor = .clear
        itranslucentView.backgroundColor = .clear
        
        self.view.insertSubview(itranslucentView, at: 0)

        //initialize UI according to model
        if let model = customViewModel{
            self.titleLbl.text = model.title.uppercased()
            self.descriptionLbl.text = model.description
            self.descriptionPremiumLbl.text = model.description
            self.btn.setTitle(model.btnTitle, for: .normal)
        }
        
        btn.layer.cornerRadius = 10.0
        btnPremium.layer.cornerRadius = 10.0
        
        //ready UI for presentation
        self.mainView.alpha = 0.0
        self.mainView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        self.premiumView.alpha = 0.0
        self.premiumView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        self.view.alpha = 0.0
        
        if self.state == .general{
            self.premiumView.isHidden = true
            self.mainView.isHidden = false
        }else{
            self.premiumView.isHidden = false
            self.mainView.isHidden = true
        }
    }
    
    
//MARK: - BUTTON ACTION
    @IBAction func okButtonAction(_ button: UIButton){
        hepticFeedBack()
        dismisVC()
    }
    @IBAction func premiumOkButtonAction(_ button: UIButton){
        hepticFeedBack()
        dismisVC()
        presentIAP(self)
    }

}

