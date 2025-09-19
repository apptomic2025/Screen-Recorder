//
//  BroadCastVC.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 11/3/25.
//

import UIKit
import ReplayKit

enum LiveBroadcastType{
    case fb,uTube,twitch,rtmp
}

class BroadCastVC: UIViewController {
    
    @IBOutlet weak var lblLiveBroadcast: UILabel!{
        didSet{
            self.lblLiveBroadcast.font = .appFont_CircularStd(type: .bold, size: 20)
            self.lblLiveBroadcast.textColor = UIColor(hex: "#151517")
        }
    }
    
    @IBOutlet weak var navView: UIView!
    @IBOutlet weak var cnstNavViewHeight: NSLayoutConstraint!
    
    var isFirstTimeLoaded: Bool = false
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            if !isFirstTimeLoaded {
                isFirstTimeLoaded = true
                setupUI()
            }
        }

        private func setupUI(){
            let uiType = getDeviceUIType()
            switch uiType {
            case .dynamicIsland:
                print("Device has Dynamic Island")
                self.cnstNavViewHeight.constant = NavbarHeight.withDynamicIsland.rawValue
            case .notch:
                print("Device has a Notch")
                self.cnstNavViewHeight.constant = NavbarHeight.withNotch.rawValue
            case .noNotch:
                print("Device has no Notch")
                self.cnstNavViewHeight.constant = NavbarHeight.withOutNotch.rawValue
            }
            
        }
    
    private func gotoDetailVC(_ type: LiveBroadcastType){
        if let vc = loadVCfromStoryBoard(name: "Broadcast", identifier: "BroadcastDetailVC") as? BroadcastDetailVC{
            vc.type = type
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
    }
    
    private func startScreenRecord(){
        
        AppData.liveBroadcastMode = true
        AppData.rtmpLink = "rtmps://live-api-s.facebook.com:443/rtmp/"
        AppData.rtmpKEY = "FB-4075198769231166-0-Abx1lPv6hMh5bBMB"
        
        let pickerView = RPSystemBroadcastPickerView()
        pickerView.preferredExtension = "com.samar.screenrecorder.BroadcastUpload"
        let buttonPressed = NSSelectorFromString("buttonPressed:")
        if pickerView.responds(to: buttonPressed) {
            pickerView.perform(buttonPressed, with: nil)
        }
        pickerView.showsMicrophoneButton = true
    }
    
    @IBAction func dismiss(){
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func fb(){
        gotoDetailVC(.fb)
    }
    @IBAction func rtmp(){
        gotoDetailVC(.rtmp)
    }
    @IBAction func youTube(){
        gotoDetailVC(.uTube)
    }
    @IBAction func twitch(){
        gotoDetailVC(.twitch)
    }
    
    @IBAction func tutorialButtonAction(_ sender: UIButton) {
        if let vc = loadVCfromStoryBoard(name: "Broadcast", identifier: "BroadcastTutorialVC") as? BroadcastTutorialVC{
            self.present(vc, animated: true)
            //self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
