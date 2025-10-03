import UIKit

@IBDesignable
class BarWaveformView: UIView {
    
    // MARK: - Customizable Properties
    
    /// The color of the waveform bars.
    @IBInspectable var barColor: UIColor = .black
    
    /// The width of each bar.
    @IBInspectable var barWidth: CGFloat = 1.5 // Changed as requested
    
    /// The spacing between each bar.
    @IBInspectable var barSpacing: CGFloat = 4.0 // Changed as requested
    
    /// A multiplier to make the waveform appear taller. Default is 1.0 (no change).
    /// Values greater than 1.0 will amplify the bars.
    @IBInspectable var amplificationMultiplier: CGFloat = 1.3
    
    /// An array of normalized CGFloat values (from 0.0 to 1.0) representing the audio samples.
    public var audioSamples: [CGFloat] = [] {
        didSet {
            // Redraw the view whenever the samples are updated.
            setNeedsDisplay()
        }
    }
    
    // MARK: - Drawing Logic
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // Ensure there are samples to draw.
        guard !audioSamples.isEmpty else { return }
        
        // Create a path to draw all the bars.
        let path = UIBezierPath()
        
        // Calculate the vertical center of the view.
        let middleY = rect.height / 2.0
        
        // Iterate through each audio sample to create a bar.
        for (index, sample) in audioSamples.enumerated() {
            let xPosition = CGFloat(index) * (barWidth + barSpacing)
            
            // Stop drawing if the bars go beyond the view's width.
            if xPosition > rect.width {
                break
            }
            
            // Ensure the sample value is within the 0.0 to 1.0 range.
            let normalizedSample = max(0.0, min(1.0, sample))
            
            // Amplify the sample to make bars appear taller
            let amplifiedSample = min(1.0, normalizedSample * amplificationMultiplier)
            
            // Calculate the height of the bar based on the amplified sample.
            let barHeight = max(barWidth, amplifiedSample * rect.height)
            
            // Create the rectangle for the current bar, centered vertically.
            let barRect = CGRect(
                x: xPosition,
                y: middleY - (barHeight / 2.0),
                width: barWidth,
                height: barHeight
            )
            
            // Use a rounded rectangle for the path to create a "pill" shape.
            let barPath = UIBezierPath(roundedRect: barRect, cornerRadius: barWidth / 2)
            path.append(barPath)
        }
        
        // Set the fill color and draw the path.
        barColor.setFill()
        path.fill()
    }
    
    // MARK: - Helper for generating sample data
    
    /// Generates random sample data for demonstration purposes.
    public func generateRandomSamples(count: Int) {
        self.audioSamples = (0..<count).map { _ in
            // Generate a random value between 0.05 and 1.0
            CGFloat.random(in: 0.05...1.0)
        }
    }
}
