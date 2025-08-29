//
//  VisualEffectImageView.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 26/2/25.
//

import UIKit

// MARK: VisualEffectImageView
class VisualEffectImageView: UIImageView {
    private let frameVisualEffectView: UIVisualEffectView = {
        let visualEffect = UIBlurEffect(style: .light)
        let view = UIVisualEffectView(effect: visualEffect)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.frameVisualEffectView)
        self.addConstraints([
            NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: self.frameVisualEffectView, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: self.frameVisualEffectView, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: self.frameVisualEffectView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: self.frameVisualEffectView, attribute: .bottom, multiplier: 1, constant: 0)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showVisualEffect() {
        self.frameVisualEffectView.frame = self.bounds
        self.frameVisualEffectView.alpha = 0.6
        self.frameVisualEffectView.isHidden = false
    }

    func hideVisualEffect() {
        UIView.animate(withDuration: 0.2, animations: {
            self.frameVisualEffectView.alpha = 0
        }, completion: { (_) in
            self.frameVisualEffectView.isHidden = true
        })
    }
}

