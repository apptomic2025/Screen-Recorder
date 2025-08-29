//
//  TouchProgressView.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 5/3/25.
//

import UIKit

protocol TouchProgressDelegate: AnyObject {
    func selectedIndex(_ index: Int, view: UIView)
}

class TouchProgressView: UIView {
    
    enum ProgressViewType{
        case frameRate,pixel,bitrate
    }
    
    var type: ProgressViewType?{
        didSet{
            if let type{
                if type == .pixel{
                    let width = contentView.frame.size.width
                    let singlePart = width/3
                    touchViewLeadingConst.constant = (1 * singlePart) - middleConstant
                    self.layoutIfNeeded()
                }
            }
        }
    }
    
    var initialIndex: CGFloat?{
        didSet{
            if let initialIndex{
                let width = contentView.frame.size.width
                let singlePart = width/3
                touchViewLeadingConst.constant = (initialIndex * singlePart) - middleConstant
                self.layoutIfNeeded()
            }
        }
    }
    
    @IBOutlet weak var contentView:UIView!
    @IBOutlet weak var touchView:UIView!
    @IBOutlet weak var touchViewLeadingConst:NSLayoutConstraint!
    
    var oldX:CGFloat = 0
    var middleConstant:CGFloat = 8
    var stackViewPAdding:CGFloat = 0
    
    weak var delegate:TouchProgressDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit(){
        let viewFromXib = Bundle.main.loadNibNamed("TouchProgressView", owner: self, options: nil)![0] as! UIView
        viewFromXib.frame = self.bounds
        addSubview(viewFromXib)
        
        let panGestureRecognizer = PanDirectionGestureRecognizer(direction: .horizontal, target: self, action: #selector(handlePanGesture(_:)))
        panGestureRecognizer.cancelsTouchesInView = false
        self.touchView.addGestureRecognizer(panGestureRecognizer)
    }

    @objc func handlePanGesture(_ pan: UIPanGestureRecognizer) {
        
        let xPoint = pan.translation(in: contentView).x
        //debugPrint(xPoint)
        pan.setTranslation(CGPoint.zero, in: contentView)
        
        
        let constant = (touchView.center.x + xPoint) - middleConstant
        if constant > 0 && constant < self.frame.width - middleConstant*2{
            touchViewLeadingConst.constant = constant
        }
        
        switch pan.state{
        case .ended:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            
            let width = contentView.frame.size.width
            let singlePart = width/3
            let devider = round(constant/singlePart)
            debugPrint(devider)
            self.delegate?.selectedIndex(Int(round(devider)), view: self)
            if round(devider) == 0{
                touchViewLeadingConst.constant = 0
                UIView.animate(withDuration: 0.15) {
                    self.layoutIfNeeded()
                }
            }else if(round(devider) == 3){
                touchViewLeadingConst.constant = self.frame.width - (middleConstant * 2)
                UIView.animate(withDuration: 0.15) {
                    self.layoutIfNeeded()
                }
            }else{
                touchViewLeadingConst.constant = (devider * singlePart) - middleConstant
                UIView.animate(withDuration: 0.15) {
                    self.layoutIfNeeded()
                }
            }
        default:
            break
        }
        //debugPrint("center:\(touchView.center.x)")

    }
}

import UIKit.UIGestureRecognizerSubclass

enum PanDirection {
    case vertical
    case horizontal
}

class PanDirectionGestureRecognizer: UIPanGestureRecognizer {

    let direction: PanDirection

    init(direction: PanDirection, target: AnyObject, action: Selector) {
        self.direction = direction
        super.init(target: target, action: action)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)

        if state == .began {
            let vel = velocity(in: view)
            switch direction {
            case .horizontal where abs(vel.y) > abs(vel.x):
                state = .cancelled
            case .vertical where abs(vel.x) > abs(vel.y):
                state = .cancelled
            default:
                break
            }
        }
    }
}

