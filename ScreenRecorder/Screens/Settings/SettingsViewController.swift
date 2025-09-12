//
//  SettingsViewController.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 23/3/25.
//


import UIKit
import Messages
import MessageUI
import SDWebImage
import FirebaseAnalytics

struct SettingsModel {
    var sectionName: String
    var items: [String]
}

class SettingsViewController: UIViewController, UINavigationControllerDelegate {
    
    var notificationState: NotificationState = .authorised
    
    var nibOrIdentifierName = "SettingsTableViewCell"
    var modelArray: [SettingsModel] = [SettingsModel]()
    let sectionViewFrame = CGRect(x: 0, y: 0, width: DEVICE_WIDTH, height: 40)
    
    var alertModel: [AlertModel] = [Contact_Model, Feedback_Model, Contact_Model, Follow_Model, Photo_Add_Permission_Model]

    private var itranslucentView = ILTranslucentView()

    @IBOutlet weak var navBar: UIView!{
        didSet{
            navBar.backgroundColor = .clear
            itranslucentView = ILTranslucentView(frame: self.navBar.bounds)
            self.navBar.insertSubview(itranslucentView, at: 0)
            itranslucentView.translucentAlpha = 1.0
            itranslucentView.translucentStyle = .blackTranslucent
            itranslucentView.translucentTintColor = .clear
            itranslucentView.backgroundColor = .clear
            itranslucentView.alpha = 0
        }
    }
    
    //outlets
    @IBOutlet weak var settingsTableView: UITableView!{
        didSet{
            settingsTableView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 50, right: 0)
            settingsTableView.register( UINib(nibName: nibOrIdentifierName, bundle: nil), forCellReuseIdentifier: nibOrIdentifierName)
            settingsTableView.register( UINib(nibName: "SeTablettingsBannerViewCell", bundle: nil), forCellReuseIdentifier: "SeTablettingsBannerViewCell")
            settingsTableView.dataSource = self
            settingsTableView.delegate = self
            
            settingsTableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
      
        
        
        //Analytics.logEvent(getClassName + AnalyticsConstants.visitedVc, parameters: nil)

        self.loadData()
        //NotificationCenter.default.addObserver(self, selector: #selector(restoredSuccessfully), name: Constants.successfully_restored, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        getNotificationPermissionState { state in
            self.notificationState = state
        }
        
        DispatchQueue.main.async {
            self.settingsTableView.reloadData()
        }
        
    }
    // MARK: - PRIVATE FUNCS
    
    ///method call from notification when restored successfull
    @objc func restoredSuccessfully(){
        loadData()
    }
    
    private func dismissVC(){
        UIView.animate(withDuration: STANDARD_ANIMATION_DURATION) {
            self.view.alpha = 0.0
            self.view.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        }completion: { (finished) in
            if finished{
                self.removeFromParent()
            }
        }
    }
    
    @IBAction func dismissView(_ button: UIButton){
        self.dismiss(animated: true, completion: nil)
        dismissVC()
        
    }
    private func loadData(){
        
        modelArray.removeAll()
        
        let section1 = SettingsModel(sectionName: "", items: ["Plan"])
        let section2 = SettingsModel(sectionName: "Membership", items: ["Restore Purchases", "About Subscription","Manage Subscription"])
        let section3 = SettingsModel(sectionName: "GENERAL & Storage", items: ["Allow Notifications","Available Storage"])
        let section4 = SettingsModel(sectionName: "Support", items: ["FAQ", "Send Feedback"])
        //let section4 = SettingsModel(sectionName: "Support", items: ["Share App", "Send Feedback", "Rate on the App Store"])
        let section5 = SettingsModel(sectionName: "Stay In Touch", items: ["Share App", "Rate on the App Store"])
        //let section5 = SettingsModel(sectionName: "About", items: ["Privacy Policy", "Terms of Use", "Version: \(Bundle.main.releaseVersionNumber!)"])
        let section6 = SettingsModel(sectionName: "About", items: ["Privacy Policy", "User Agreement", "Version: \(Bundle.main.releaseVersionNumber!)"])

        modelArray.append(contentsOf: [section1,section2,section3,section4,section5,section6])
        settingsTableView.reloadData()
    }
    
}

extension SettingsViewController: UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return modelArray.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return modelArray[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0{
            
            let cell = self.settingsTableView.dequeueReusableCell(withIdentifier: "SeTablettingsBannerViewCell", for: indexPath) as! SeTablettingsBannerViewCell
            cell.updateData()
            cell.selectionStyle = .none
            return cell
        }
        else{
            
            
            let cell = self.settingsTableView.dequeueReusableCell(withIdentifier: nibOrIdentifierName, for: indexPath) as! SettingsTableViewCell
            cell.titleLbl.text = modelArray[indexPath.section].items[indexPath.row]
            
            if (indexPath.section == 2){
                cell.arrowImgView.isHidden = true
                cell.dwscriptionLbl.isHidden = false
                cell.notificationSwitch.isHidden = false

                if (indexPath.item == 0){
                    cell.dwscriptionLbl.isHidden = true
                    cell.notificationSwitch.isHidden = false
                    cell.notificationSwitch.setOn((self.notificationState) == .authorised ? true : false, animated: false)
                }else{
                    cell.dwscriptionLbl.isHidden = false
                    cell.notificationSwitch.isHidden = true
                    cell.dwscriptionLbl.text = (DiskStatus.freeDiskSpace)
                }
                
                
            }else{
                cell.arrowImgView.isHidden = false
                cell.dwscriptionLbl.isHidden = true
                cell.notificationSwitch.isHidden = true
            }
            
            if (indexPath.section == modelArray.count - 1 && indexPath.row == modelArray[indexPath.section].items.count - 1){
                cell.versionTitleLbl.isHidden = false
                cell.titleLbl.isHidden = true
                cell.arrowImgView.isHidden = true
                cell.dwscriptionLbl.isHidden = true
            }else{
                cell.versionTitleLbl.isHidden = true
                cell.titleLbl.isHidden = false
            }
            
            return cell
        }
       
    }
}

extension SettingsViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = SettingsHeaderView(frame: sectionViewFrame)
        headerView.titleLabel.text = modelArray[section].sectionName.uppercased()
        headerView.titleLabel.textColor = .gray
        //headerView.backgroundColor = .red
        return headerView
        
        
    }
    
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (section == 0) ? 0 : 40
        //return 40.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (indexPath.section == 0) ? (DEVICE_WIDTH * 192)/414 : 60
        //return 60
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        view.tintColor = .clear
    }
    
//    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
//        if section == 3{
//            let view = UIView(frame: CGRect(x: 0, y: 0, width: DEVICE_WIDTH, height: 25))
//            view.backgroundColor = .red
//            return view
//        }
//        return UIView()
//    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        hepticFeedBack()
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 && !AppData.premiumUser{
            if let iapViewController = loadVCfromStoryBoard(name: "IAP", identifier: "IAPController") as? IAPController{
                //iapViewController.delegate = self
                iapViewController.modalPresentationStyle = .fullScreen
                self.present(iapViewController, animated: true, completion: nil)
            }
            
        } else if(indexPath.section == 1){
            if indexPath.row == 0{
                //self.restore(self)
                //Globalprotocol.shared.vcToTabbarDelegate.restoreaction()
            }else if(indexPath.row == 1){
                gotoTermsPolicy(.subscription_info)
            }else if(indexPath.row == 2){
                if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:])
                    }
                }
            }
            
        }
        else if(indexPath.section == 2){
            
//            let alertView = Alert(frame: self.view.bounds, model: Clear_Cache_Model)
//            alertView.delegate = self
//            self.view.addSubview(alertView)
//            alertView.presentAnimatiom()
            

        }
        else if(indexPath.section == 3){
            switch indexPath.row {
            case 0:
//                let alertView = Alert(frame: self.view.bounds, model: Share_Model)
//                alertView.delegate = self
//                self.view.addSubview(alertView)
//                alertView.presentAnimatiom()
                //shareApp()
                gotoTermsPolicy(.faq)
            case 1:
//                let alertView = Alert(frame: self.view.bounds, model: Feedback_Model)
//                alertView.delegate = self
//                self.view.addSubview(alertView)
//                alertView.presentAnimatiom()
                sendEmail()
            case 2:
                let alertView = Alert(frame: self.view.bounds, model: Review_Model)
                alertView.delegate = self
                self.view.addSubview(alertView)
                alertView.presentAnimatiom()
                //rateUS()
            case 3:
                gotoTermsPolicy(.privacy_policy)
            case 4:
                gotoTermsPolicy(.terms_condition)
            default:
                break
            }
        }
        else if(indexPath.section == 4){
            switch indexPath.row {
            case 0:
                shareApp()
            case 1:
                rateUS()
            default:
                break
            }
        }
        else if(indexPath.section == 5){
            switch indexPath.row {
            case 0:
                gotoTermsPolicy(.privacy_policy)
            case 1:
                gotoTermsPolicy(.terms_condition)
            default:
                break
            }
        }
        
    }
    
}

// MARK: -TABLE VIEW SELECTION OPTIONS
extension SettingsViewController{
   
    
    private func shareApp(){
        let textToShare = "Hi! I've been using \(Bundle.appName()) for a while and I like it a lot. \(Bundle.appName()) is a free screen recorder app. Check it out:\n"
    
            if let myWebsite = NSURL(string: "https://apps.apple.com/us/app/screen-recorder-game-record/id\(APP_ID)") {
                let objectsToShare: [Any] = [textToShare, myWebsite]
                let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                self.present(activityVC, animated: true, completion: nil)
            }
    }
    
    private func sendEmail() {
            let composeVC = MFMailComposeViewController()
            composeVC.mailComposeDelegate = self
            composeVC.delegate = self
            // Configure the fields of the interface.
            composeVC.setToRecipients(["support@snowpex.com"])
            composeVC.setSubject("[Feedback] - Screen Recorder - Game Record")
        composeVC.setMessageBody("\n\n\n\n\n\n--------------------------\nDiagnostic information:\n\nApp Version: \(Bundle.main.releaseVersionNumber!)\nModel: \(UIDevice.modelName)\nOS Version: \(UIDevice.osVersion)\nLanguage: \(Locale.language)\nTotal Disk Space: \(DiskStatus.totalDiskSpace)\nFree Disk Space: \(DiskStatus.freeDiskSpace)\n--------------------------", isHTML: false)
            // Present the view controller modally.
            self.present(composeVC, animated: true, completion: nil)
        }
    
    private func rateUS(){
        let urlStr = "https://itunes.apple.com/app/id\(APP_ID)?action=write-review" // (Option 2) Open App Review Page
        guard let url = URL(string: urlStr), UIApplication.shared.canOpenURL(url) else { return }
                
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url) // openURL(_:) is deprecated from iOS 10.
                }
    }
}

extension SettingsViewController: MFMailComposeViewControllerDelegate{
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?){
        controller.dismiss(animated: true, completion: nil)
    }
}

extension SettingsViewController: AlertTypeButtonActionDelegate{
    func buttonClicked(type: AlertType) {
        if type == .contact || type == .feedback{
            sendEmail()
        }else if(type == .share){
            shareApp()
        }else if (type == .review){
            rateUS()
        }
        else{
            
            
            if type == .follow{
                if let instaUrl = URL(string: Follow_Model.mailID!){
                    if UIApplication.shared.canOpenURL(instaUrl) {
                        UIApplication.shared.open(instaUrl, completionHandler: { (success) in
                            print("insta opened: \(success)") // Prints true
                        })
                    }
                }
            }
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                        return
                    }

                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                            print("Settings opened: \(success)") // Prints true
                        })
                    }
        }
    }


}

extension SettingsViewController: UIScrollViewDelegate{
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print(-scrollView.contentOffset.y)
        if -scrollView.contentOffset.y >= 64{
            self.itranslucentView.alpha = 0.0
        }else{
            self.itranslucentView.alpha = 1.0
        }
    }
}

