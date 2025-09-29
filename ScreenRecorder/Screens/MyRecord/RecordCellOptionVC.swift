//
//  RecordCellOptionVC.swift
//  ScreenRecorder
//
//  Created by Apptomic on 26/9/25.
//

import UIKit

class RecordCellOptionVC: UIViewController {

    // MARK: - Enum
    enum Option {
        case rename
        case duplicate
        case share
        case delete
    }

    // MARK: - IBOutlets
    @IBOutlet weak var lblRename: UILabel! {
        didSet {
            lblRename.font = .appFont_CircularStd(type: .book, size: 16)
            lblRename.textColor = UIColor(hex: "#151517")
        }
    }
    @IBOutlet weak var lblDuplicate: UILabel! {
        didSet {
            lblDuplicate.font = .appFont_CircularStd(type: .book, size: 16)
            lblDuplicate.textColor = UIColor(hex: "#151517")
        }
    }
    @IBOutlet weak var lblShare: UILabel! {
        didSet {
            lblShare.font = .appFont_CircularStd(type: .book, size: 16)
            lblShare.textColor = UIColor(hex: "#151517")
        }
    }
    @IBOutlet weak var lblDelete: UILabel! {
        didSet {
            lblDelete.font = .appFont_CircularStd(type: .book, size: 16)
            lblDelete.textColor = UIColor(hex: "#FE4E51")
        }
    }
    
    @IBOutlet weak var cnstStackViewHeight: NSLayoutConstraint!

    @IBOutlet weak var rowRenameView: UIView!
    @IBOutlet weak var rowDuplicateView: UIView!
    @IBOutlet weak var rowShareView: UIView!
    @IBOutlet weak var rowDeleteView: UIView!

    // MARK: - Callbacks
    var onSelectRename: (() -> Void)?
    var onSelectDuplicate: (() -> Void)?
    var onSelectShare: (() -> Void)?
    var onSelectDelete: (() -> Void)?

    // MARK: - Configuration
    private(set) var options: [Option] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        applyOptionsVisibility()
        configureSheetHeight()
    }
    
    // MARK: - IBActions
    @IBAction func didTapRename(_ sender: UIButton) {
        self.dismiss(animated: true) { [weak self] in
            self?.onSelectRename?()
        }
    }

    @IBAction func didTapDuplicate(_ sender: UIButton) {
        self.dismiss(animated: true) { [weak self] in
            self?.onSelectDuplicate?()
        }
    }

    @IBAction func didTapShare(_ sender: UIButton) {
        self.dismiss(animated: true) { [weak self] in
            self?.onSelectShare?()
        }
    }

    @IBAction func didTapDelete(_ sender: UIButton) {
        self.dismiss(animated: true) { [weak self] in
            self?.onSelectDelete?()
        }
    }
    
    // MARK: - UI Configuration
    private func applyOptionsVisibility() {
        rowRenameView.isHidden    = !options.contains(.rename)
        rowDuplicateView.isHidden = !options.contains(.duplicate)
        rowShareView.isHidden     = !options.contains(.share)
        rowDeleteView.isHidden    = !options.contains(.delete)
        view.layoutIfNeeded()
    }

    private func configureSheetHeight() {
        guard let sheet = sheetPresentationController else { return }
        
        // Removed the base height for title/subtitle.
        // The total height is now purely based on the number of option rows.
        let topPadding: CGFloat = 24 // Space above the first item
        let bottomPadding: CGFloat = 24 // Space below the last item
        let rowHeight: CGFloat  = 72
        let visibleCount  = CGFloat(options.count)
        
        let targetHeight = (rowHeight * visibleCount) + topPadding + bottomPadding
        
        self.cnstStackViewHeight.constant = (rowHeight * visibleCount)

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

    // MARK: - Convenience Initializer
    // Updated instantiate method to remove title and subtitle
    static func instantiate(
        options: [Option],
        onSelectRename: (() -> Void)? = nil,
        onSelectDuplicate: (() -> Void)? = nil,
        onSelectShare: (() -> Void)? = nil,
        onSelectDelete: (() -> Void)? = nil
    ) -> RecordCellOptionVC {
        let sb = UIStoryboard(name: "MyRecord", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "RecordCellOptionVC") as! RecordCellOptionVC
        vc.modalPresentationStyle = .pageSheet

        // set config
        vc.options = options
        
        // Assign callbacks
        vc.onSelectRename = onSelectRename
        vc.onSelectDuplicate = onSelectDuplicate
        vc.onSelectShare = onSelectShare
        vc.onSelectDelete = onSelectDelete

        return vc
    }
}
