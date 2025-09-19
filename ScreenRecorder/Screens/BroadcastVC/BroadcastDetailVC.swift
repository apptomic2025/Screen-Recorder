//
//  BroadcastDetailVC.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 11/3/25.
//

import UIKit
import ReplayKit

class BroadcastDetailVC: UIViewController {
    
    
    @IBOutlet weak var lblLiveBroadcastType: UILabel!{
        didSet{
            self.lblLiveBroadcastType.font = .appFont_CircularStd(type: .bold, size: 20)
            self.lblLiveBroadcastType.textColor = UIColor(hex: "#151517")
        }
    }
    
    @IBOutlet weak var navView: UIView!
    @IBOutlet weak var cnstNavViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var broadcastBtnBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var broadcastBtn: UIButton!{
        didSet{
            broadcastBtn.backgroundColor = UIColor(hex: "#FE655C").withAlphaComponent(0.6)
            broadcastBtn.isEnabled = false
        }
    }
    
    // ⭐️ Step 1: Update rtmpLinkTxtF's didSet observer
    @IBOutlet weak var rtmpLinkTxtF: UITextField!{
        didSet{
            rtmpLinkTxtF.delegate = self
            rtmpLinkTxtF.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
            
            // Set the font and color for the text the user types
            rtmpLinkTxtF.font = .appFont_CircularStd(type: .book, size: 14)
            rtmpLinkTxtF.textColor = UIColor(hex: "#C2C9CD")
            rtmpLinkTxtF.tintColor = UIColor(hex: "#FE655C")
            
            // --- Placeholder Customization ---
            let placeholderText = "Type or paste stream URL"
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor(hex: "#C2C9CD"),
                .font: UIFont.appFont_CircularStd(type: .book, size: 14)
            ]
            
            rtmpLinkTxtF.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: attributes)
            
        }
    }
    
    // ⭐️ Step 2: (Recommended) Update rtmpKeyTxtF for consistency
    @IBOutlet weak var rtmpKeyTxtF: UITextField!{
        didSet{
            rtmpKeyTxtF.delegate = self
            rtmpKeyTxtF.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

            // Set the font and color for the text the user types
            rtmpKeyTxtF.font = .appFont_CircularStd(type: .book, size: 14)
            rtmpKeyTxtF.textColor = UIColor(hex: "#C2C9CD")
            rtmpKeyTxtF.tintColor = UIColor(hex: "#FE655C")

            // --- Placeholder Customization ---
            let placeholderText = "Type or paste stream key"
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor(hex: "#C2C9CD"),
                .font: UIFont.appFont_CircularStd(type: .book, size: 14)
            ]

            rtmpKeyTxtF.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: attributes)
        }
    }
    
    @IBOutlet weak var lblLink: UILabel!{
        didSet{
            self.lblLink.font = .appFont_CircularStd(type: .medium, size: 14)
            self.lblLink.textColor = UIColor(hex: "#151517")
            self.lblLink.setTextWithColoredPart(
                fullText: "RTMP Link (required)*",
                targetText: "*",
                color: .red
            )
        }
    }
    
    @IBOutlet weak var lblKey: UILabel!{
        didSet{
            self.lblKey.font = .appFont_CircularStd(type: .bold, size: 14)
            self.lblKey.textColor = UIColor(hex: "#151517")
            self.lblKey.setTextWithColoredPart(
                fullText: "Stream Key (required)*",
                targetText: "*",
                color: .red
            )
        }
    }
    
    @IBOutlet weak var btnLinkPaste: UIButton!{
        didSet{
            self.btnLinkPaste.setTitle("Paste", for: .normal)
            self.btnLinkPaste.addTarget(self, action: #selector(btnLinkPasteAction), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var btnKeyPaste: UIButton!{
        didSet{
            self.btnKeyPaste.setTitle("Paste", for: .normal)
            self.btnKeyPaste.addTarget(self, action: #selector(btnKeyPasteAction), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var lblBottomText: UILabel!{
        didSet{
            self.lblBottomText.font = .appFont_CircularStd(type: .book, size: 14)
            self.lblBottomText.textColor = UIColor(hex: "#9AA1A5")
            self.lblBottomText.text = "If the live platform provides stream key, please enter it\nhere. If not, stream key is not necessary."
            self.lblBottomText.numberOfLines = 0
        }
    }
    
    var type: LiveBroadcastType = .rtmp
    var isFirstTimeLoaded: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        updatePasteButtonState(for: rtmpLinkTxtF, button: btnLinkPaste)
        updatePasteButtonState(for: rtmpKeyTxtF, button: btnKeyPaste)
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
        switch type {
        case .rtmp:
            self.lblLiveBroadcastType.text = "RTMP Live"
        case .fb:
            self.lblLiveBroadcastType.text = "Facebook Live"
        case .uTube:
            self.lblLiveBroadcastType.text = "Youtube Live"
        case .twitch:
            self.lblLiveBroadcastType.text = "Twitch Live"
        }
    }
    
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        
//        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
//            let keyboardRectangle = keyboardFrame.cgRectValue
//            let keyboardHeight = keyboardRectangle.height
//            
//            self.broadcastBtnBottomConstraint.constant = keyboardHeight + 44
//            UIView.animate(withDuration: 0.3){
//                self.view.layoutIfNeeded()
//            }
//        }
    }
    
    @objc func keyboardWillHide(notification: Notification){
        
//        self.broadcastBtnBottomConstraint.constant =  44 // or change according to your logic
//
//            UIView.animate(withDuration: 0.3){
//
//                self.view.layoutIfNeeded()
//
//            }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if textField == rtmpLinkTxtF {
                updatePasteButtonState(for: rtmpLinkTxtF, button: btnLinkPaste)
            } else if textField == rtmpKeyTxtF {
                updatePasteButtonState(for: rtmpKeyTxtF, button: btnKeyPaste)
            }
        if let text1 = self.rtmpLinkTxtF.text, let text2 = self.rtmpKeyTxtF.text{
            if !text1.isEmpty && !text2.isEmpty{
                self.broadcastBtn.isEnabled = true
                self.broadcastBtn.backgroundColor =  UIColor(hex: "#FE655C").withAlphaComponent(1.0)
            }else{
                self.broadcastBtn.isEnabled = false
                self.broadcastBtn.backgroundColor = UIColor(hex: "#FE655C").withAlphaComponent(0.6)
            }
        }else{
            self.broadcastBtn.isEnabled = false
            self.broadcastBtn.backgroundColor =  UIColor(hex: "#FE655C").withAlphaComponent(0.6)
        }
    }
    private func updatePasteButtonState(for textField: UITextField, button: UIButton) {
        if let text = textField.text, !text.isEmpty {
            // Text field is NOT empty: Show cross icon
            button.setImage(UIImage(named: "crossForClearText"), for: .normal)
            button.setTitle("", for: .normal)
        } else {
            // Text field is empty: Show "Paste" text
            button.setImage(nil, for: .normal)
            button.setTitle("Paste", for: .normal)
            button.setTitleColor(UIColor(hex: "#151517"), for: .normal)
            button.titleLabel?.font = .appFont_CircularStd(type: .book, size: 12)
        }
    }
    
    private func startBroadcast(){
        
        AppData.liveBroadcastMode = true
        AppData.rtmpLink = self.rtmpLinkTxtF.text
        AppData.rtmpKEY = self.rtmpKeyTxtF.text
        
        let pickerView = RPSystemBroadcastPickerView()
        pickerView.preferredExtension = "com.samar.screenrecorder.BroadcastUpload"
        let buttonPressed = NSSelectorFromString("buttonPressed:")
        if pickerView.responds(to: buttonPressed) {
            pickerView.perform(buttonPressed, with: nil)
        }
        pickerView.showsMicrophoneButton = true
    }
    
    @IBAction func broadcastAction(){
        debugPrint("broadcast button tapped")
        startBroadcast()
    }
    
    @IBAction func dismiss(){
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func btnLinkPasteAction() {
        if let text = rtmpLinkTxtF.text, !text.isEmpty {
            rtmpLinkTxtF.text = ""
        } else {
            if let pasteboardString = UIPasteboard.general.string {
                rtmpLinkTxtF.text = pasteboardString
            }
        }
        textFieldDidChange(rtmpLinkTxtF)
    }

    @objc func btnKeyPasteAction() {
        if let text = rtmpKeyTxtF.text, !text.isEmpty {
            rtmpKeyTxtF.text = ""
        } else {
            if let pasteboardString = UIPasteboard.general.string {
                rtmpKeyTxtF.text = pasteboardString
            }
        }
        textFieldDidChange(rtmpKeyTxtF)
    }

}

extension BroadcastDetailVC: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}
