//
//  LightNavVC.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 20/2/25.
//

import UIKit

class LightNavVC: UINavigationController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationBar.isHidden = true
    }
    

}

class DarkNavVC: UINavigationController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .darkContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationBar.isHidden = true
    }
    

}

class NoStatusBarNavVC: UINavigationController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }

    override var prefersStatusBarHidden: Bool{
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationBar.isHidden = true
    }
    

}

