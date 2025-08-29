//
//  BroadcastDetailVC.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 11/3/25.
//

import UIKit
import ReplayKit

class BroadcastDetailVC: UIViewController {

    var type: LiveBroadcastType = .rtmp
    @IBOutlet weak var broadcastBtnBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var broadcastBtn: UIButton!{
        didSet{
            broadcastBtn.backgroundColor = UIColor.yellow.withAlphaComponent(0.6)
            broadcastBtn.isEnabled = false
        }
    }
    @IBOutlet weak var rtmpLinkTxtF: UITextField!{
        didSet{
            rtmpLinkTxtF.delegate = self
            rtmpLinkTxtF.text = nil
            rtmpLinkTxtF.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

        }
    }
    @IBOutlet weak var rtmpKeyTxtF: UITextField!{
        didSet{
            rtmpKeyTxtF.delegate = self
            rtmpKeyTxtF.text = nil
            rtmpKeyTxtF.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
 
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
             let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))

            view.addGestureRecognizer(tap)
    }
    
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let keyboardRectangle = keyboardFrame.cgRectValue
                let keyboardHeight = keyboardRectangle.height
            
            self.broadcastBtnBottomConstraint.constant = keyboardHeight + 44
            UIView.animate(withDuration: 0.3){

               self.view.layoutIfNeeded()

            }

            }

    }
    @objc func keyboardWillHide(notification: Notification){
        
        self.broadcastBtnBottomConstraint.constant =  44 // or change according to your logic

               UIView.animate(withDuration: 0.3){

                  self.view.layoutIfNeeded()

               }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if let text1 = self.rtmpLinkTxtF.text, let text2 = self.rtmpKeyTxtF.text{
            if !text1.isEmpty && !text2.isEmpty{
                self.broadcastBtn.isEnabled = true
                self.broadcastBtn.backgroundColor = UIColor.yellow.withAlphaComponent(1.0)
            }else{
                self.broadcastBtn.isEnabled = false
                self.broadcastBtn.backgroundColor = UIColor.yellow.withAlphaComponent(0.6)
            }
        }else{
            self.broadcastBtn.isEnabled = false
            self.broadcastBtn.backgroundColor = UIColor.yellow.withAlphaComponent(0.6)
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


}

extension BroadcastDetailVC: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}
