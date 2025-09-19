//
//  VideoSourceSelectionViewController.swift
//  ScreenRecorder
//
//  Created by Apptomic on 16/9/25.
//

import UIKit

class VideoSourceSelectionViewController: UIViewController {
    
    @IBOutlet weak var lblTitle: UILabel!{
        didSet{
            self.lblTitle.font = .appFont_CircularStd(type: .medium, size: 20)
            self.lblTitle.textColor = UIColor(hex: "#151517")
        }
    }
    
    @IBOutlet weak var lblSubTitle: UILabel!{
        didSet{
            self.lblSubTitle.font = .appFont_CircularStd(type: .book, size: 14)
            self.lblSubTitle.textColor = UIColor(hex: "#151517")
        }
    }
    
    @IBOutlet weak var lblCameraRoll: UILabel!{
        didSet{
            self.lblCameraRoll.font = .appFont_CircularStd(type: .book, size: 16)
            self.lblCameraRoll.textColor = UIColor(hex: "#151517")
        }
    }
    
    @IBOutlet weak var lblMyRecordings: UILabel!{
        didSet{
            self.lblMyRecordings.font = .appFont_CircularStd(type: .book, size: 16)
            self.lblMyRecordings.textColor = UIColor(hex: "#151517")
        }
    }
    
    @IBOutlet weak var lblYouTube: UILabel!{
        didSet{
            self.lblYouTube.font = .appFont_CircularStd(type: .book, size: 16)
            self.lblYouTube.textColor = UIColor(hex: "#151517")
        }
    }
    
    
    var onSelectMyRecordings: (() -> Void)?
    var onSelectCameraRoll: (() -> Void)?
    var onSelectYouTube: (() -> Void)?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func didTapCameraRoll(_ sender: UIButton){
        self.dismiss(animated: true) {
            self.onSelectCameraRoll?()
        }
        
    }
    
    @IBAction func didTapMyRecordings(_ sender: UIButton) {
        self.dismiss(animated: true) {
            self.onSelectMyRecordings?()
        }
        
    }
    
    @IBAction func didTapYouTube(_ sender: UIButton) {
        self.dismiss(animated: true) {
            self.onSelectYouTube?()
        }
    }
    
}
