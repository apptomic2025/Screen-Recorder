//
//  SettingsHeaderView.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 23/3/25.
//

import UIKit

class SettingsHeaderView: UIView {

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required  init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit(){
        Bundle.main.loadNibNamed("SettingsHeaderView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
    }
}
