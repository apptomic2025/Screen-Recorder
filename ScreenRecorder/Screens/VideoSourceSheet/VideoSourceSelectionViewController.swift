//
//  VideoSourceSelectionViewController.swift
//  ScreenRecorder
//
//  Created by Apptomic on 16/9/25.
//

import UIKit

class VideoSourceSelectionViewController: UIViewController {

    enum Option {
        case cameraRoll
        case myRecordings
        case youTube
    }

    // MARK: - IBOutlets (existing)
    @IBOutlet weak var lblTitle: UILabel! {
        didSet {
            lblTitle.font = .appFont_CircularStd(type: .medium, size: 20)
            lblTitle.textColor = UIColor(hex: "#151517")
        }
    }

    @IBOutlet weak var lblSubTitle: UILabel! {
        didSet {
            lblSubTitle.font = .appFont_CircularStd(type: .book, size: 14)
            lblSubTitle.textColor = UIColor(hex: "#151517")
        }
    }

    @IBOutlet weak var lblCameraRoll: UILabel! {
        didSet {
            lblCameraRoll.font = .appFont_CircularStd(type: .book, size: 16)
            lblCameraRoll.textColor = UIColor(hex: "#151517")
        }
    }

    @IBOutlet weak var lblMyRecordings: UILabel! {
        didSet {
            lblMyRecordings.font = .appFont_CircularStd(type: .book, size: 16)
            lblMyRecordings.textColor = UIColor(hex: "#151517")
        }
    }

    @IBOutlet weak var lblYouTube: UILabel! {
        didSet {
            lblYouTube.font = .appFont_CircularStd(type: .book, size: 16)
            lblYouTube.textColor = UIColor(hex: "#151517")
        }
    }
    
    @IBOutlet weak var cnstStackViewHeight: NSLayoutConstraint!

    // 👉 নতুন: প্রতিটি অপশনের container view/stack IBOutlet (Storyboard-এ connect করো)
    @IBOutlet weak var rowCameraRollView: UIView!
    @IBOutlet weak var rowMyRecordingsView: UIView!
    @IBOutlet weak var rowYouTubeView: UIView!

    // MARK: - Callbacks
    var onSelectMyRecordings: (() -> Void)?
    var onSelectCameraRoll: (() -> Void)?
    var onSelectYouTube: (() -> Void)?

    // MARK: - Configuration
    private(set) var options: [Option] = [.cameraRoll, .myRecordings, .youTube]
    private var titleText: String?
    private var subtitleText: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        applyTexts()
        applyOptionsVisibility()
        configureSheetHeight()
    }
    

    // MARK: - IBActions
    @IBAction func didTapCameraRoll(_ sender: UIButton){
        self.dismiss(animated: true) { [weak self] in
            self?.onSelectCameraRoll?()
        }
    }

    @IBAction func didTapMyRecordings(_ sender: UIButton) {
        self.dismiss(animated: true) { [weak self] in
            self?.onSelectMyRecordings?()
        }
    }

    @IBAction func didTapYouTube(_ sender: UIButton) {
        self.dismiss(animated: true) { [weak self] in
            self?.onSelectYouTube?()
        }
    }

    // MARK: - Visibility + Sheet Height
    private func applyOptionsVisibility() {
        // কোন option আছে/নেই তার উপর ভিত্তি করে row hide/show
        rowCameraRollView.isHidden  = !options.contains(.cameraRoll)
        rowMyRecordingsView.isHidden = !options.contains(.myRecordings)
        rowYouTubeView.isHidden      = !options.contains(.youTube)
        
        

        view.layoutIfNeeded()
    }
    
    private func applyTexts() {
          lblTitle?.text = titleText
          lblSubTitle?.text = subtitleText
      }

    private func configureSheetHeight() {
        guard let sheet = sheetPresentationController else { return }

        
        let base: CGFloat = 160   // title, subtitle, top/bottom padding
        let row: CGFloat  = 56    // প্রতি option row উচ্চতা
        let visibleCount  = CGFloat(options.count)
        let spacingNum = visibleCount - 1
        let targetHeight  = base + (row * visibleCount) + (10 * spacingNum)
        self.cnstStackViewHeight.constant = targetHeight - base
        if #available(iOS 16.0, *) {
            sheet.detents = [
                .custom(identifier: .init("dynamic")) { context in
                    return targetHeight
                }
            ]
            sheet.selectedDetentIdentifier = UISheetPresentationController.Detent.Identifier("dynamic")
        } else {
            sheet.detents = [.medium()]
        }

        sheet.prefersGrabberVisible = true
        sheet.preferredCornerRadius = 16
    }

    // MARK: - Convenience instantiate (with title & subtitle)
    static func instantiate(
        options: [Option],
        title: String? = nil,
        subtitle: String? = nil,
        onSelectCameraRoll: (() -> Void)? = nil,
        onSelectMyRecordings: (() -> Void)? = nil,
        onSelectYouTube: (() -> Void)? = nil
    ) -> VideoSourceSelectionViewController {
        let sb = UIStoryboard(name: "VideoSource", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "VideoSourceSelectionViewController") as! VideoSourceSelectionViewController
        vc.modalPresentationStyle = .pageSheet

        // set config
        vc.options = options
        vc.titleText = title
        vc.subtitleText = subtitle
        vc.onSelectCameraRoll = onSelectCameraRoll
        vc.onSelectMyRecordings = onSelectMyRecordings
        vc.onSelectYouTube = onSelectYouTube

        return vc
    }

}
