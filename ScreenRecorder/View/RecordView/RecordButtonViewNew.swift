//
//  RecordButtonNew.swift
//  ScreenRecorder
//
//  Created by Apptomic on 19/9/25.
//

import Foundation
import UIKit

protocol RecordButtonNewDelegate: AnyObject {
    // দুটি নতুন ডেলিগেট ফাংশন: একটি রেকর্ডিং শুরু হলে, অন্যটি বন্ধ হলে কল হবে
    func didStartRecording()
    func didStopRecording()
}

class RecordButtonViewNew: UIView {

    // MARK: - State Management
    private enum RecordingState {
        case idle
        case countdown
        case recording
    }
    
    // MARK: - Properties
    weak var delegate: RecordButtonNewDelegate?
    private var currentState: RecordingState = .idle
    
    // UI Components
    private var innerView: UIView!
    private var countdownLabel: UILabel!
    
    // Countdown
    private var countdownTimer: Timer?
    private var countdownValue: Int = 3

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup
    private func setupView() {
        // Main red circle
        self.backgroundColor = UIColor(hex: "#FA1A42")
        self.layer.cornerRadius = self.frame.width / 2
        
        // Inner white view (circle/square)
        let innerViewSize = CGSize(width: 36, height: 36)
        innerView = UIView(frame: CGRect(
            origin: .zero,
            size: innerViewSize
        ))
        innerView.backgroundColor = .white
        innerView.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        innerView.layer.cornerRadius = 17.5 // Initial state is a circle
        innerView.isUserInteractionEnabled = false
        self.addSubview(innerView)
        
        // Countdown Label
        countdownLabel = UILabel(frame: self.bounds)
        countdownLabel.textColor = .white
        countdownLabel.font = .appFont_CircularStd(type: .medium, size: 28)
        countdownLabel.textAlignment = .center
        countdownLabel.isHidden = true
        self.addSubview(countdownLabel)
        
        // Tap Gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(buttonTapped))
        self.addGestureRecognizer(tapGesture)
    }

    // MARK: - Actions & State Transitions
    @objc private func buttonTapped() {
        switch currentState {
        case .idle:
            // Start the countdown sequence
            startCountdown()
        case .recording:
            // Stop recording and return to idle
            stopRecording()
        case .countdown:
            // Do nothing while countdown is in progress
            break
        }
    }
    
    private func startCountdown() {
        currentState = .countdown
        countdownValue = 3
        
        // Hide inner circle, show countdown label
        UIView.animate(withDuration: 0.2) {
            self.innerView.alpha = 0
        }
        
        countdownLabel.isHidden = false
        countdownLabel.text = "\(countdownValue)"
        
        // Start the timer
        countdownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCountdown), userInfo: nil, repeats: true)
    }
    
    @objc private func updateCountdown() {
        countdownValue -= 1
        countdownLabel.text = "\(countdownValue)"
        
        if countdownValue == 0 {
            countdownTimer?.invalidate()
            countdownTimer = nil
            startRecording()
        }
    }
    
    private func startRecording() {
        currentState = .recording
        
        // Hide countdown label
        self.countdownLabel.isHidden = true
        
        // Show inner view as a square
        self.innerView.alpha = 1
        UIView.animate(withDuration: 0.3) {
            self.innerView.layer.cornerRadius = 8
        }
        
        // Notify delegate
        delegate?.didStartRecording()
    }

    private func stopRecording() {
        currentState = .idle
        
        // Animate inner view back to a circle
        UIView.animate(withDuration: 0.3) {
            self.innerView.layer.cornerRadius = 17.5
        }
        
        // Notify delegate
        delegate?.didStopRecording()
    }
}
