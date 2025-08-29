//
//  ExportBottomSheetViewController.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 5/4/25.
//

import UIKit

class ExportBottomSheetVC: UIViewController {

    @IBOutlet weak var cnstTopbottomSheetView : NSLayoutConstraint!
    @IBOutlet weak var bottomSheetView: UIView!
    @IBOutlet weak var tabView: UIView!
    @IBOutlet weak var grabberView: UIView!
    
    @IBOutlet weak var optionTableView: UITableView!{
        didSet{
            optionTableView.delegate = self
            optionTableView.dataSource = self
            optionTableView.register(UINib(nibName: "OptionsTableViewCell", bundle: nil), forCellReuseIdentifier: "OptionsTableViewCell")
            optionTableView.backgroundColor = .white
        }
    }
    
    var options: [VideoOption] = [
        .init(title: "4K (UHD)", isSelected: false, value: 3840),
        .init(title: "1080p (FHD)", isSelected: false, value: 1080),
        .init(title: "720p (FHD)", isSelected: false, value: 720),
        .init(title: "480p (SD)", isSelected: false, value: 480),
        .init(title: "360p (SD)", isSelected: false, value: 360)
    ]


    var frameRates: [VideoOption] = [
        .init(title: "60fps", isSelected: false, value: 60),
        .init(title: "50fps", isSelected: false, value: 50),
        .init(title: "30fps", isSelected: false, value: 30),
        .init(title: "25fps", isSelected: false, value: 25),
        .init(title: "24fps", isSelected: false, value: 24)
    ]

    var bitRates: [VideoOption] = [
        .init(title: "12 Mbps", isSelected: false, value: 12),
        .init(title: "8 Mbps", isSelected: false, value: 8),
        .init(title: "6 Mbps", isSelected: false, value: 6),
        .init(title: "5 Mbps", isSelected: false, value: 5),
        .init(title: "4 Mbps", isSelected: false, value: 4),
        .init(title: "3 Mbps", isSelected: false, value: 3),
        .init(title: "2 Mbps", isSelected: false, value: 2),
        .init(title: "1 Mbps", isSelected: false, value: 1)
    ]

    var viewTranslation = CGPoint(x: 0, y: 0)
    var dismissCompletion : (()->Void)?
    var optionMode: OptionMode = .resolution
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 16.0, *){
        }else{
            self.setUpForiOS15()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadOptionData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.dismissCompletion?()
    }

    private func loadOptionData(){
        switch optionMode{
        case .resolution:
            let searchKey = AppData.resolution
            if let index = indexForSelection(searchKey) {
                print("Index found at: \(index)") // Output: Index found at: 1
                options[index].isSelected = true
            }
        case .bitRate:
            options = bitRates
            let searchKey = AppData.bitrate
            if let index = indexForSelection(searchKey) {
                print("Index found at: \(index)") // Output: Index found at: 1
                options[index].isSelected = true
            }
        case .frameRate:
            options = frameRates
            let searchKey = AppData.framerate
            if let index = indexForSelection(searchKey) {
                print("Index found at: \(index)") // Output: Index found at: 1
                options[index].isSelected = true
            }
        }
    }
    
    func indexForSelection(_ resolution: Int) -> Int? {
        return options.firstIndex { $0.value == resolution }
    }
    
    private func setUpForiOS15(){
        var pageDetent = CGFloat(299)
        if optionMode == .bitRate {
            pageDetent = 449
        }

        self.addPangGesture()
        self.bottomSheetView.layer.cornerRadius = CGFloat(16)
        let topHeight = UIScreen.main.bounds.height - CGFloat(pageDetent + self.getTotalHeightOfNavBar())
        self.cnstTopbottomSheetView.constant = topHeight
        self.view.backgroundColor = UIColor.clear
        
    }
    
   func getTotalHeightOfNavBar() -> CGFloat{
       let uiType = getDeviceUIType()
       switch uiType {
       case .dynamicIsland:
           return NavbarHeight.withDynamicIsland.rawValue
       case .notch:
           return NavbarHeight.withNotch.rawValue
       case .noNotch:
           return NavbarHeight.withOutNotch.rawValue
       }
    }
    
    private func addPangGesture(){
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        self.bottomSheetView.addGestureRecognizer(pan)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        self.tabView.addGestureRecognizer(tap)

    }
    
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: nil)
        debugPrint(translation)
        switch gesture.state {
        case .began:
            debugPrint("")
            viewTranslation = gesture.translation(in: view)
          case .changed:
            viewTranslation = gesture.translation(in: view)
            if translation.y < -100 {
                return
                
            }else{
                
                UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                    self.bottomSheetView.transform = CGAffineTransform(translationX: 0, y: self.viewTranslation.y)
                })
                
                
            }
              
          case .ended:
            
              if viewTranslation.y < 100 {
                  
                  UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                      
                      self.bottomSheetView.transform = .identity
                      
                  })
                  
              } else {
                  
                  self.dismissCompletion?()
                  dismiss(animated: true, completion: nil)
              }
          default:
              break
          }
    }
   
    @objc func handleTapGesture(_ gesture: UITapGestureRecognizer) {
       
        self.dismissCompletion?()
        dismiss(animated: true, completion: nil)

    }

}


extension ExportBottomSheetVC : UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        options.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50 // Customize if needed
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OptionsTableViewCell", for: indexPath) as! OptionsTableViewCell

                let option = options[indexPath.row]
                cell.configure(with: option)
                return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch optionMode{
        case .resolution:
            AppData.resolution = options[indexPath.row].value
        case .bitRate:
            AppData.bitrate = options[indexPath.row].value
        case .frameRate:
            AppData.framerate = options[indexPath.row].value
        }
        
        self.dismissCompletion?()
        dismiss(animated: true, completion: nil)
    }
    
}
