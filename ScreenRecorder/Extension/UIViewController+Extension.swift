//
//  UIViewController+Extension.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 5/4/25.
//

import Foundation
import UIKit

extension UIViewController {
    
    public func viewDisappearAnimation(){
        if self.view.alpha == 1 {
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveLinear) {
                self.view.alpha = 0.5
            } completion: { _ in
                
            }
        }
    }


    public func viewAppearAnimation(){
        if self.view.alpha != 1 {
            UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut) {
                self.view.alpha = 1
            } completion: { _ in
                
            }
        }
    }
}
