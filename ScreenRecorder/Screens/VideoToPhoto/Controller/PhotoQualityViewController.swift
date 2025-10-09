import UIKit

class PhotoQualityViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var previewImageView: UIImageView!
    
    // Outlets for OUTER container views
    @IBOutlet weak var noneOptionView: UIView!
    @IBOutlet weak var softOptionView: UIView!
    @IBOutlet weak var mediumOptionView: UIView!
    @IBOutlet weak var highOptionView: UIView!
    
    // Add these new outlets for the INNER content views and connect them from Storyboard
    @IBOutlet weak var noneContentView: UIView!
    @IBOutlet weak var softContentView: UIView!
    @IBOutlet weak var mediumContentView: UIView!
    @IBOutlet weak var highContentView: UIView!
    
    // Outlets for labels
    @IBOutlet weak var noneLabel: UILabel!{
        didSet {
            noneLabel.textColor = UIColor(hex: "#151517")
            noneLabel.font = .appFont_CircularStd(type: .book, size: 10)
        }
    }
    @IBOutlet weak var softLabel: UILabel!{
        didSet {
            softLabel.textColor = UIColor(hex: "#151517")
            softLabel.font = .appFont_CircularStd(type: .book, size: 10)
        }
    }
    @IBOutlet weak var mediumLabel: UILabel!{
        didSet {
            mediumLabel.textColor = UIColor(hex: "#151517")
            mediumLabel.font = .appFont_CircularStd(type: .book, size: 10)
        }
    }
    @IBOutlet weak var highLabel: UILabel!{
        didSet {
            highLabel.textColor = UIColor(hex: "#151517")
            highLabel.font = .appFont_CircularStd(type: .book, size: 10)
        }
    }
    
    // Outlets for small preview images
    @IBOutlet weak var noneImageView: UIImageView!
    @IBOutlet weak var softImageView: UIImageView!
    @IBOutlet weak var mediumImageView: UIImageView!
    @IBOutlet weak var highImageView: UIImageView!
    
    @IBOutlet weak var lblTitle: UILabel! {
        didSet {
            self.lblTitle.font = .appFont_CircularStd(type: .bold, size: 20)
            self.lblTitle.textColor = UIColor(hex: "#151517")
        }
    }
    
    @IBOutlet weak var navView: UIView!
    @IBOutlet weak var cnstNavViewHeight: NSLayoutConstraint!
    
    // MARK: - Properties
    var selectedFrame: UIImage?
    var shareImage: UIImage?
    
    private var highQualityImage: UIImage?
    private var mediumQualityImage: UIImage?
    private var lowQualityImage: UIImage?
    
    // Updated collection to manage all UI elements
    private var qualityOptions: [(containerView: UIView, contentView: UIView, label: UILabel, image: UIImage?)] = []
    
    private var selectedQualityIndex: Int = 2
    private var isVCLoaded: Bool = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        generateQualityImages()
        setupQualityOptions()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if !isVCLoaded {
            isVCLoaded = true
            setupNavHeight()
        }
    }
    
    // MARK: - Setup Methods
    
    private func generateQualityImages() {
        guard let selectedFrame = selectedFrame else { return }
        highQualityImage = UIImage(data: selectedFrame.jpegData(compressionQuality: 1.0) ?? Data())
        mediumQualityImage = UIImage(data: selectedFrame.jpegData(compressionQuality: 0.7) ?? Data())
        lowQualityImage = UIImage(data: selectedFrame.jpegData(compressionQuality: 0.3) ?? Data())
    }
    
    private func setupQualityOptions() {
        qualityOptions = [
            (containerView: noneOptionView, contentView: noneContentView, label: noneLabel, image: selectedFrame),
            (containerView: softOptionView, contentView: softContentView, label: softLabel, image: lowQualityImage),
            (containerView: mediumOptionView, contentView: mediumContentView, label: mediumLabel, image: mediumQualityImage),
            (containerView: highOptionView, contentView: highContentView, label: highLabel, image: highQualityImage)
        ]
        
        noneImageView.image = selectedFrame
        softImageView.image = lowQualityImage
        mediumImageView.image = mediumQualityImage
        highImageView.image = highQualityImage
        
        updateSelection(selectedIndex: selectedQualityIndex, initialSetup: true)
    }
    
    private func setupNavHeight() {
        let uiType = getDeviceUIType()
        switch uiType {
        case .dynamicIsland: self.cnstNavViewHeight.constant = NavbarHeight.withDynamicIsland.rawValue
        case .notch: self.cnstNavViewHeight.constant = NavbarHeight.withNotch.rawValue
        case .noNotch: self.cnstNavViewHeight.constant = NavbarHeight.withOutNotch.rawValue
        }
    }
    
    // MARK: - Core Logic
    
    private func updateSelection(selectedIndex: Int, initialSetup: Bool = false) {
        self.selectedQualityIndex = selectedIndex

        UIView.animate(withDuration: 0.25) {
            for (index, option) in self.qualityOptions.enumerated() {
                let isSelected = (index == selectedIndex)
                self.applyStyle(to: option.containerView, contentView: option.contentView, label: option.label, isSelected: isSelected)
            }
        }
        
        let selectedImage = qualityOptions[selectedIndex].image
        shareImage = selectedImage
        
        if !initialSetup {
            UIView.transition(with: self.previewImageView,
                              duration: 0.2,
                              options: .transitionCrossDissolve,
                              animations: { self.previewImageView.image = selectedImage },
                              completion: nil)
        } else {
            previewImageView.image = selectedImage
        }
    }
    
    private func applyStyle(to containerView: UIView, contentView: UIView, label: UILabel, isSelected: Bool) {
        if isSelected {
            // Apply selected style
            containerView.layer.borderColor = UIColor(named: "newBrandColor")?.cgColor
            containerView.layer.borderWidth = 2.0
            
            // Shrink the inner content view
            contentView.transform = CGAffineTransform(scaleX: 0.85, y: 0.88)
            contentView.layer.cornerRadius = 4
            
        
        } else {
            // Apply unselected style
            containerView.layer.borderWidth = 0
            
            
            // Revert content view to its original size
            contentView.transform = .identity
            contentView.layer.cornerRadius = 8
        }
        
        // Common styles for the outer container
        contentView.clipsToBounds = true
        containerView.layer.cornerRadius = 8
        containerView.backgroundColor = UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1.0)
    }

    // MARK: - IBActions
    
    @IBAction func qualityOptionTapped(_ sender: UIButton) {
        let selectedIndex = sender.tag
        updateSelection(selectedIndex: selectedIndex)
    }
    
    @IBAction func crossButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true)
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func shareButtonActionButtonAction(_ sender: UIButton) {
        if let shareImage = shareImage {
            shareFrame(image: shareImage)
        }
    }
    
    // MARK: - Helper Methods
    
    func shareFrame(image: UIImage) {
        // 1. Create an instance of our custom item source
        let itemSource = ImageActivityItemSource(image: image)
        
        // 2. Pass the custom item source to the activity controller
        // It will now use the metadata we provided to build the preview
        let activityViewController = UIActivityViewController(activityItems: [itemSource], applicationActivities: nil)
        
        // 3. Optional: Exclude certain activity types to make the share sheet "lighter"
        activityViewController.excludedActivityTypes = [
            .assignToContact,
            .print,
            .addToReadingList,
            .openInIBooks
        ]
        
        // For iPad compatibility
        activityViewController.popoverPresentationController?.sourceView = self.view
        activityViewController.overrideUserInterfaceStyle = .light
        
        self.present(activityViewController, animated: true, completion: nil)
    }
}
