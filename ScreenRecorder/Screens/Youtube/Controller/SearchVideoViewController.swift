//
//  SearchVideoViewController.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 20/3/25.
//



import UIKit

class SearchVideoViewController: UIViewController {
    
    var SearchVideoViewController: SearchVideoViewController?
    
    @IBOutlet weak var searchVideoButton: UIButton! {
        didSet{
            searchVideoButton.backgroundColor = #colorLiteral(red: 0.3335984945, green: 0.3089770675, blue: 0.9526864886, alpha: 1)
            // searchVideoButton.isEnabled = false
        }
    }
    
    @IBOutlet weak var linkTxtF: UITextField!
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //linkTxtF.text = "https://www.youtube.com/watch?v=YLslsZuEaNE&ab_channel=KhaiLoOn"
        
        let color = UIColor.white
        let attributes = [NSAttributedString.Key.foregroundColor: color]
        let attributedPlaceholder = NSAttributedString(string: linkTxtF.placeholder ?? "", attributes: attributes)
        // Set the attributed string as the text field's placeholder
        linkTxtF.attributedPlaceholder = attributedPlaceholder
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Private Methods
    
    func goToReactToYoutubeVideoVC(videoUrl: String? = nil, id: String? = nil) {
        let vc = loadVCfromStoryBoard(name: "ReactToYoutube", identifier: "ReactToYoutubeViewController") as! ReactToYoutubeViewController
        vc.videoLink = videoUrl
        vc.videoId = id
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func getYoutubeId(youtubeUrl: String) -> String? {
        return URLComponents(string: youtubeUrl)?.queryItems?.first(where: { $0.name == "v" })?.value
    }
    
    // MARK: - Button Action
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true)
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func searchVideoButtonAction(_ sender: UIButton) {
        
        if let url = linkTxtF.text, !url.isEmpty {
            
            if let videoID = URL(string: url)?.lastPathComponent, videoID.count == 11 {
                internetConnectionCheck { internetIsOk in
                    if internetIsOk {
                        self.goToReactToYoutubeVideoVC(id: videoID)
                    } else {
                        print("No internet")
                    }
                }
                return
            }
            
            if let validUrl = getYoutubeId(youtubeUrl: url), !validUrl.isEmpty {
                internetConnectionCheck { internetIsOk in
                    if internetIsOk {
                        self.goToReactToYoutubeVideoVC(videoUrl: url)
                    } else {
                        print("No internet")
                    }
                }
                return
            }
            
            self.customAlert(title: "Invalid URL", message: "Please enter a valid URL.", time: 3)
        } else {
            self.customAlert(title: "Invalid URL", message: "Please enter a valid URL.", time: 3)
        }
        
        
    }
}
