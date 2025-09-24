import UIKit

class TrimmerIndicatorView: UIView {
    
    @IBOutlet weak var rularIndicatorView: UIView!{
        didSet{
            self.rularIndicatorView.backgroundColor = UIColor(hex: "#151517").withAlphaComponent(0.6)
            self.rularIndicatorView.alpha = 0.0
        }
    }
    @IBOutlet weak var cnstRularIndicatorViewLeading: NSLayoutConstraint!
    @IBOutlet weak var lblVideoStartTime: UILabel! {
        didSet {
            self.lblVideoStartTime.font = .appFont_CircularStd(type: .book, size: 12)
            self.lblVideoStartTime.textColor = UIColor(hex: "#151517")
        }
    }
    
    @IBOutlet weak var lblVideoDurationTime: UILabel! {
        didSet {
            self.lblVideoDurationTime.font = .appFont_CircularStd(type: .book, size: 12)
            self.lblVideoDurationTime.textColor = UIColor(hex: "#151517")
        }
    }
    @IBOutlet weak var lblIndicatorCurrentTime: UILabel! {
        didSet {
            self.lblIndicatorCurrentTime.font = .appFont_CircularStd(type: .book, size: 12)
            self.lblIndicatorCurrentTime.textColor = UIColor(hex: "#151517").withAlphaComponent(0.6)
            self.lblIndicatorCurrentTime.alpha = 0.0
        }
    }
    @IBOutlet weak var trimmerDurationLbl: UILabel! {
        didSet {
            trimmerDurationLbl.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .medium)
            trimmerDurationLbl.textColor = .white
        }
    }
    @IBOutlet weak var rolerView: UIView! {
        didSet {
            rolerView.backgroundColor = .clear
        }
    }
    @IBOutlet weak var trimmerTimeView: UIView! {
        didSet {
            trimmerTimeView.layer.cornerRadius = 11
        }
    }
    
    private var rulerLayerMid: CAShapeLayer?
    private var rulerLayerEnds: CAShapeLayer?
    private var lastDrawnSize: CGSize = .zero

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    private func commonInit() {
        guard let contentView = self.fromNib() else {
            debugPrint("View could not load from nib")
            return
        }
        contentView.frame = self.bounds
        // Allow the view to be resized with its parent
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(contentView)
        // NOTE: We no longer call drawRuler() from here
    }
    
    // ✅ Call drawing logic from layoutSubviews
    override func layoutSubviews() {
        super.layoutSubviews()
        // Only redraw if the size has actually changed
        if rolerView.bounds.size != lastDrawnSize {
            drawRuler()
            lastDrawnSize = rolerView.bounds.size
        }
    }
    
    private func drawRuler() {
        guard let rolerView = rolerView else { return }
        
        // Clean up old layers before redrawing
        rulerLayerMid?.removeFromSuperlayer()
        rulerLayerEnds?.removeFromSuperlayer()
        
        let rect = rolerView.bounds
        
        // Ensure the view has a valid size to draw in
        guard rect.width > 0, rect.height > 0 else { return }

        // Correctly calculate 1 physical pixel width in points
        let onePixel = 1.0 / UIScreen.main.scale

        // Heights for the tick marks
        let minorH: CGFloat = 2
        let majorH: CGFloat = 6
        let bottom = rect.maxY

        // Colors
        let baseColor = UIColor(hex: "#151517")
        let midColor = baseColor.withAlphaComponent(0.6)

        // Disable animations to prevent flickering during layout changes
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // Middle Ticks (every 4 points)
        let pathMid = UIBezierPath()
        var x = 4.0 // Start from the first 4pt mark
        while x < rect.width - 4.0 { // Loop until the last 4pt mark
            pathMid.move(to: CGPoint(x: x, y: bottom - minorH))
            pathMid.addLine(to: CGPoint(x: x, y: bottom))
            x += 4
        }

        let midLayer = CAShapeLayer()
        midLayer.path = pathMid.cgPath
        midLayer.strokeColor = midColor.cgColor
        midLayer.lineWidth = onePixel
        rolerView.layer.addSublayer(midLayer)
        self.rulerLayerMid = midLayer

        // ✅ First & Last Ticks (corrected positioning)
        let pathEnds = UIBezierPath()
        
        // First tick: offset by half a pixel to draw inside the bounds
        let startX = onePixel / 2.0
        pathEnds.move(to: CGPoint(x: startX, y: bottom - majorH))
        pathEnds.addLine(to: CGPoint(x: startX, y: bottom))
        
        // Last tick: offset by half a pixel to draw inside the bounds
        let lastX = rect.width - (onePixel / 2.0)
        pathEnds.move(to: CGPoint(x: lastX, y: bottom - majorH))
        pathEnds.addLine(to: CGPoint(x: lastX, y: bottom))

        let endsLayer = CAShapeLayer()
        endsLayer.path = pathEnds.cgPath
        endsLayer.strokeColor = baseColor.cgColor
        endsLayer.lineWidth = onePixel * 2.0
        rolerView.layer.addSublayer(endsLayer)
        self.rulerLayerEnds = endsLayer

        CATransaction.commit()
    }
}
