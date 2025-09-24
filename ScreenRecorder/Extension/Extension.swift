//
//  Extension.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 20/2/25.
//

import Foundation

import Foundation
import UIKit
import AVKit
import PhotosUI
import StoreKit

extension Dictionary where Value: Equatable {
    func someKey(forValue val: Value) -> Key? {
        return first(where: { $1 == val })?.key
    }
}

@nonobjc extension UIViewController {
    
    func clearTempDirectory(){
        let tempDirectory = NSTemporaryDirectory()

        // Get the contents of the temporary directory
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: tempDirectory)
            for file in files {
                let filePath = "\(tempDirectory)/\(file)"
                try FileManager.default.removeItem(atPath: filePath)
            }
            print("Temporary directory cleared")
        } catch {
            print("Failed to clear temporary directory: \(error.localizedDescription)")
        }
    }
    
    func add(_ child: UIViewController, frame: CGRect? = nil, contentView: UIView) {
        
        self.addChild(child)

        if let frame = frame {
            child.view.frame = frame
        }else{
            child.view.frame = contentView.bounds
        }

        contentView.addSubview(child.view)
        child.didMove(toParent: self)
    }

    func remove() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
    
    func gotoWebVC(_ url_type: URL_TYPE){
        let vc = WebVC(nibName: "WebVC", bundle: nil)
        vc.url_type = url_type
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true, completion: nil)
    }
    func gotoTermsPolicy(_ url_type: URL_TYPE){
        
        let vc = WebVC(nibName: "WebVC", bundle: nil)
        vc.url_type = url_type
        self.navigationController?.pushViewController(vc, animated: true)
        
        if let url = (url_type == .subscription_info) ? Bundle.main.url(forResource: "sub_info", withExtension: "html") : (url_type == .terms_condition) ? URL(string: TERMS_CONDITION) : URL(string: PRIVACY_POLICY){
        }
    }
}

extension UIViewController {
    
    var getClassName: String{
        let name = String(describing: type(of: self))
        return name
    }
    
    
    var isModal: Bool {

           let presentingIsModal = presentingViewController != nil
           let presentingIsNavigation = navigationController?.presentingViewController?.presentedViewController == navigationController
           let presentingIsTabBar = tabBarController?.presentingViewController is UITabBarController

           return presentingIsModal || presentingIsNavigation || presentingIsTabBar
       }
    
    func getTimeString(from time: CMTime) -> String {
        let totalSeconds = CMTimeGetSeconds(time)
        let hours = Int(totalSeconds/3600)
        let minutes = Int(totalSeconds/60) % 60
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        if hours > 0 {
            return String(format: "%i:%02i:%02i", arguments: [hours,minutes,seconds])
        }else {
            return String(format: "%02i:%02i", arguments: [minutes,seconds])
        }
    }
}

extension UILabel {

    @IBInspectable
    var letterSpace: CGFloat {
        set {
            let attributedString: NSMutableAttributedString!
            if let currentAttrString = attributedText {
                attributedString = NSMutableAttributedString(attributedString: currentAttrString)
            }
            else {
                attributedString = NSMutableAttributedString(string: text ?? "")
                text = nil
            }

            attributedString.addAttribute(NSAttributedString.Key.kern,
                                           value: newValue,
                                           range: NSRange(location: 0, length: attributedString.length))

            attributedText = attributedString
        }

        get {
            if let currentLetterSpace = attributedText?.attribute(NSAttributedString.Key.kern, at: 0, effectiveRange: .none) as? CGFloat {
                return currentLetterSpace
            }
            else {
                return 0
            }
        }
    }
}

public extension UIColor {
    
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat) {
        self.init(red: r/255, green: g/255, blue: b/255, alpha: 1)
    }
}

extension Int {
    var degreesToRadians: CGFloat {
        return CGFloat(self) * .pi / 180.0
    }
}

extension Double {
    var toTimeString: String {
        let seconds: Int = Int(self.truncatingRemainder(dividingBy: 60.0))
        let minutes: Int = Int(self / 60.0)
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension UIColor {
    //THIS IS A TEST

  @nonobjc class var darkBlueGrey: UIColor {
    return UIColor(red: 24.0 / 255.0, green: 40.0 / 255.0, blue: 72.0 / 255.0, alpha: 1.0)
  }

}

//MARK: - Vibrate
extension UIDevice {
    static func vibrate() {
        //AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}


extension UIView {
    
    @IBInspectable var cornerRadiusV: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidthV: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColorV: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
}

extension UIViewController {
    
//    func restore(_ rootVC: UIViewController? = nil){
//        
//        DispatchQueue.main.async {
//            AppnotrixLoader.startLoader(rootView: rootVC?.view ?? self.view, text: "Restoring your purchases")
//        }
//        
//        AppnotrixStoreKit.shared.restorePurchases { (result) in
//            DispatchQueue.main.async {
//                AppnotrixLoader.dismissLoader()
//            }
//            
//            
//            switch result{
//
//            case .successFull_restored:
//                Analytics.logEvent(AnalyticsConstants.successRestored, parameters: nil)
//
//                let vc = CustomAlertViewController.customInit(customViewModel: CustomViewModel(title: "SUCCESSFULLY RESTORED", description: "Your previous purchases have now been restored successfully. You can now enjoy premium features.", btnTitle: "OK"), successfullRestoredState: true)
//                rootVC?.add(vc, frame: rootVC?.view.bounds, contentView: rootVC?.view ?? self.view)
//                vc.presentAnimatiom()
//                
//            case .failed:
//                Analytics.logEvent(AnalyticsConstants.failedRestored, parameters: nil)
//
//                break
////                let vc = CustomAlertViewController.customInit(customViewModel: CustomViewModel(title: "Restore Failed", description: "Please check whether your subscription is valid.", btnTitle: "OK"))
////                self.add(vc, frame: self.view.bounds, contentView: self.view)
////                vc.presentAnimatiom()
//
//            case .notFound:
//                let vc = CustomAlertViewController.customInit(customViewModel: CustomViewModel(title: "NO ACTIVE SUBSCRIPTION", description: "There is nothing to restore. Please check whether your subscription is valid.", btnTitle: "OK"))
//                rootVC?.add(vc, frame: rootVC?.view.bounds, contentView: rootVC?.view ?? self.view)
//                vc.presentAnimatiom()
//                
//            case .restored:
//                let vc = CustomAlertViewController.customInit(customViewModel: CustomViewModel(title: "NO ACTIVE SUBSCRIPTION", description: "Your purchase were restored successfully, no active subscription found.", btnTitle: "OK"))
//                rootVC?.add(vc, frame: rootVC?.view.bounds, contentView: rootVC?.view ?? self.view)
//                vc.presentAnimatiom()
//                
//            default:
//                break
//                
//            }
//        }
//    }
    
    func secondsToHoursMinutesSeconds(seconds: Int) -> (Int, Int, Int) {
        return ((seconds / 3600), ((seconds % 3600) / 60),((seconds % 3600) % 60))
    }
    
    func makeTimeString(hours: Int, minutes: Int, seconds : Int) -> String {
        var timeString = ""
        timeString += String(format: "%02d", hours)
        timeString += ":"
        timeString += String(format: "%02d", minutes)
        timeString += ":"
        timeString += String(format: "%02d", seconds)
        return timeString
    }
}
extension UIView {
    /// Eventhough we already set the file owner in the xib file, where we are setting the file owner again because sending nil will set existing file owner to nil.
    @discardableResult
    func fromNib<T : UIView>() -> T? {
        guard let contentView = Bundle(for: type(of: self))
            .loadNibNamed(String(describing: type(of: self)), owner: self, options: nil)?.first as? T else {
                return nil
        }
        return contentView
    }
    
}

extension TimeInterval {
    func format(using units: NSCalendar.Unit) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = units
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .pad

        return formatter.string(from: self)
    }
}

extension TimeInterval {

  func format() -> String? {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.day, .hour, .minute, .second, .nanosecond]
    formatter.unitsStyle = .abbreviated
    formatter.maximumUnitCount = 1
    return formatter.string(from: self)
  }
}

extension Double {
    
    func splitIntoParts(decimalPlaces: Int, round: Bool) -> (leftPart: Int, rightPart: Int) {
        
        var number = self
        if round {
            //round to specified number of decimal places:
            let divisor = pow(10.0, Double(decimalPlaces))
            number = Darwin.round(self * divisor) / divisor
        }
        
        //convert to string and split on decimal point:
        let parts = String(number).components(separatedBy: ".")
        
        //extract left and right parts:
        let leftPart = Int(parts[0]) ?? 0
        let rightPart = Int(parts[1]) ?? 0
        
        return(leftPart, rightPart)
        
    }
}

extension Int{
    func secondsToHoursMinutesSeconds() -> (Int, Int, Int) {
        return (self / 3600, (self % 3600) / 60, (self % 3600) % 60)
    }
    
    func secondsToHoursMinutesSecondsInString() -> String {
        let (h,m,s) = (self / 3600, (self % 3600) / 60, (self % 3600) % 60)
        if h>0 && m>0{
            let hr = (h < 10) ? "0\(h)" : "\(h)"
            let min = (m < 10) ? "0\(m)" : "\(m)"
            let sec = (s < 10) ? "0\(s)" : "\(s)"
            return hr+":"+min+":"+sec
        }
        
        let min = (m < 10) ? "0\(m)" : "\(m)"
        let sec = (s < 10) ? "0\(s)" : "\(s)"
        return min+":"+sec
    }
}

extension UILabel {
    func textWidth() -> CGFloat {
        return UILabel.textWidth(label: self)
    }
    
    class func textWidth(label: UILabel) -> CGFloat {
        return textWidth(label: label, text: label.text!)
    }
    
    class func textWidth(label: UILabel, text: String) -> CGFloat {
        return textWidth(font: label.font, text: text)
    }
    
    class func textWidth(font: UIFont, text: String) -> CGFloat {
        let myText = text as NSString
        
        let rect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let labelSize = myText.boundingRect(with: rect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        return ceil(labelSize.width)
    }
}

extension URL{
    func generateThumbnail() -> UIImage? {
        do {
            let asset = AVURLAsset(url: self)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            // Select the right one based on which version you are using
            // Swift 4.2
            let cgImage = try imageGenerator.copyCGImage(at: .zero,
                                                         actualTime: nil)
            // Swift 4.0
            //let cgImage1 = try imageGenerator.copyCGImage(at: CMTime.zero,
                                                         //actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}
extension UIImage{
    func filterImage(name:String)->UIImage?{
        
        guard let currentCGImage = self.cgImage else { return nil}
        let currentCIImage = CIImage(cgImage: currentCGImage)
        
        let filter = CIFilter(name: name)
        filter?.setValue(currentCIImage, forKey: kCIInputImageKey)
        
        guard let outputImage = filter?.outputImage else { return nil}
        
        let context = CIContext()
        
        guard let cgimg = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        let processedImage = UIImage(cgImage: cgimg)
        print(processedImage.size)
        return processedImage
    }
}

extension Double{
    
    func getTime()->String{
        let duration = self
        let time: String
        
        if duration > 3600 {
            time = String(format:"%dh %dm %ds",
                Int(duration/3600),
                Int((duration/60).truncatingRemainder(dividingBy: 60)),
                Int(duration.truncatingRemainder(dividingBy: 60)))
        } else {
            time = String(format:"%dm %ds",
                Int((duration/60).truncatingRemainder(dividingBy: 60)),
                Int(duration.truncatingRemainder(dividingBy: 60)))
        }
        return time

    }
}

extension URL {
    var attributes: [FileAttributeKey : Any]? {
        do {
            return try FileManager.default.attributesOfItem(atPath: path)
        } catch let error as NSError {
            print("FileAttribute error: \(error)")
        }
        return nil
    }

    var fileSize: UInt64 {
        return attributes?[.size] as? UInt64 ?? UInt64(0)
    }

    var fileSizeString: String {
        return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
    }

    var creationDate: Date? {
        return attributes?[.creationDate] as? Date
    }
}

extension UIViewController {
    func internetConnectionCheck(success: @escaping(Bool) -> Void){
        guard Connection.isConnectedToNetwork() else {
            self.customAlert(title: "No Internet Connection", message: "You have no Internet. Please re-check your internet connection.", time: 3)
            success(false)
            return
        }
        success(true)
    }
    func customAlert(title : String, message : String, time : Double, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
        // Delay the dismissal by 3 seconds
        let when = DispatchTime.now() + time
        
        DispatchQueue.main.asyncAfter(deadline: when){
            alert.dismiss(animated: true) {
                if let mCompletion = completion {
                    DispatchQueue.main.async {
                        mCompletion()
                    }
                }
            }
        }
    }
}

extension UIView {
    func rotateVideo(degrees: CGFloat) {
        let degreesToRadians: (CGFloat) -> CGFloat = { (degrees: CGFloat) in
            return degrees / 180.0 * CGFloat.pi
        }
        self.transform =  CGAffineTransform(rotationAngle: degreesToRadians(degrees))
        // If you like to use layer you can uncomment the following line
        //layer.transform = CATransform3DMakeRotation(degreesToRadians(degrees), 0.0, 0.0, 1.0)
    }
}

extension PHAsset {

    func getURL(completionHandler : @escaping ((_ responseURL : URL?) -> Void)){
        if self.mediaType == .image {
            let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
            options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
                return true
            }
            self.requestContentEditingInput(with: options, completionHandler: {(contentEditingInput: PHContentEditingInput?, info: [AnyHashable : Any]) -> Void in
                completionHandler(contentEditingInput!.fullSizeImageURL as URL?)
            })
        } else if self.mediaType == .video {
            let options: PHVideoRequestOptions = PHVideoRequestOptions()
            options.version = .original
            PHImageManager.default().requestAVAsset(forVideo: self, options: options, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
                if let urlAsset = asset as? AVURLAsset {
                    let localVideoUrl: URL = urlAsset.url as URL
                    completionHandler(localVideoUrl)
                } else {
                    completionHandler(nil)
                }
            })
        }
    }
}
extension UILabel{
    
    
    func heightForView() -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: 334, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = self.font
        label.text = self.text

        label.sizeToFit()
        return label.frame.height
    }
    
    func setLineSpacing(lineSpacing: CGFloat = 0.0, lineHeightMultiple: CGFloat = 0.0) {

        guard let labelText = self.text else { return }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.lineHeightMultiple = lineHeightMultiple

        let attributedString:NSMutableAttributedString
        if let labelattributedText = self.attributedText {
            attributedString = NSMutableAttributedString(attributedString: labelattributedText)
        } else {
            attributedString = NSMutableAttributedString(string: labelText)
        }

        // (Swift 4.2 and above) Line spacing attribute
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))


        // (Swift 4.1 and 4.0) Line spacing attribute
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))

        self.attributedText = attributedString
    }
}

open class CustomLabel : UILabel {
    @IBInspectable open var characterSpacing:CGFloat = 1 {
        didSet {
            let attributedString = NSMutableAttributedString(string: self.text!)
            attributedString.addAttribute(NSAttributedString.Key.kern, value: self.characterSpacing, range: NSRange(location: 0, length: attributedString.length))
            self.attributedText = attributedString
        }

    }
}

public extension UIDevice{
    static var osVersion: String{
        return self.current.systemVersion
    }
    
    static let modelName: String = {
            var systemInfo = utsname()
            uname(&systemInfo)
            let machineMirror = Mirror(reflecting: systemInfo.machine)
            let identifier = machineMirror.children.reduce("") { identifier, element in
                guard let value = element.value as? Int8, value != 0 else { return identifier }
                return identifier + String(UnicodeScalar(UInt8(value)))
            }

            func mapToDevice(identifier: String) -> String { // swiftlint:disable:this cyclomatic_complexity
                #if os(iOS)
                switch identifier {
                case "iPod5,1":                                       return "iPod touch (5th generation)"
                case "iPod7,1":                                       return "iPod touch (6th generation)"
                case "iPod9,1":                                       return "iPod touch (7th generation)"
                case "iPhone3,1", "iPhone3,2", "iPhone3,3":           return "iPhone 4"
                case "iPhone4,1":                                     return "iPhone 4s"
                case "iPhone5,1", "iPhone5,2":                        return "iPhone 5"
                case "iPhone5,3", "iPhone5,4":                        return "iPhone 5c"
                case "iPhone6,1", "iPhone6,2":                        return "iPhone 5s"
                case "iPhone7,2":                                     return "iPhone 6"
                case "iPhone7,1":                                     return "iPhone 6 Plus"
                case "iPhone8,1":                                     return "iPhone 6s"
                case "iPhone8,2":                                     return "iPhone 6s Plus"
                case "iPhone8,4":                                     return "iPhone SE"
                case "iPhone9,1", "iPhone9,3":                        return "iPhone 7"
                case "iPhone9,2", "iPhone9,4":                        return "iPhone 7 Plus"
                case "iPhone10,1", "iPhone10,4":                      return "iPhone 8"
                case "iPhone10,2", "iPhone10,5":                      return "iPhone 8 Plus"
                case "iPhone10,3", "iPhone10,6":                      return "iPhone X"
                case "iPhone11,2":                                    return "iPhone XS"
                case "iPhone11,4", "iPhone11,6":                      return "iPhone XS Max"
                case "iPhone11,8":                                    return "iPhone XR"
                case "iPhone12,1":                                    return "iPhone 11"
                case "iPhone12,3":                                    return "iPhone 11 Pro"
                case "iPhone12,5":                                    return "iPhone 11 Pro Max"
                case "iPhone12,8":                                    return "iPhone SE (2nd generation)"
                case "iPhone13,1":                                    return "iPhone 12 mini"
                case "iPhone13,2":                                    return "iPhone 12"
                case "iPhone13,3":                                    return "iPhone 12 Pro"
                case "iPhone13,4":                                    return "iPhone 12 Pro Max"
                case "iPhone14,4":                                    return "iPhone 13 mini"
                case "iPhone14,5":                                    return "iPhone 13"
                case "iPhone14,2":                                    return "iPhone 13 Pro"
                case "iPhone14,3":                                    return "iPhone 13 Pro Max"
                case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":      return "iPad 2"
                case "iPad3,1", "iPad3,2", "iPad3,3":                 return "iPad (3rd generation)"
                case "iPad3,4", "iPad3,5", "iPad3,6":                 return "iPad (4th generation)"
                case "iPad6,11", "iPad6,12":                          return "iPad (5th generation)"
                case "iPad7,5", "iPad7,6":                            return "iPad (6th generation)"
                case "iPad7,11", "iPad7,12":                          return "iPad (7th generation)"
                case "iPad11,6", "iPad11,7":                          return "iPad (8th generation)"
                case "iPad12,1", "iPad12,2":                          return "iPad (9th generation)"
                case "iPad4,1", "iPad4,2", "iPad4,3":                 return "iPad Air"
                case "iPad5,3", "iPad5,4":                            return "iPad Air 2"
                case "iPad11,3", "iPad11,4":                          return "iPad Air (3rd generation)"
                case "iPad13,1", "iPad13,2":                          return "iPad Air (4th generation)"
                case "iPad2,5", "iPad2,6", "iPad2,7":                 return "iPad mini"
                case "iPad4,4", "iPad4,5", "iPad4,6":                 return "iPad mini 2"
                case "iPad4,7", "iPad4,8", "iPad4,9":                 return "iPad mini 3"
                case "iPad5,1", "iPad5,2":                            return "iPad mini 4"
                case "iPad11,1", "iPad11,2":                          return "iPad mini (5th generation)"
                case "iPad14,1", "iPad14,2":                          return "iPad mini (6th generation)"
                case "iPad6,3", "iPad6,4":                            return "iPad Pro (9.7-inch)"
                case "iPad7,3", "iPad7,4":                            return "iPad Pro (10.5-inch)"
                case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":      return "iPad Pro (11-inch) (1st generation)"
                case "iPad8,9", "iPad8,10":                           return "iPad Pro (11-inch) (2nd generation)"
                case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7":  return "iPad Pro (11-inch) (3rd generation)"
                case "iPad6,7", "iPad6,8":                            return "iPad Pro (12.9-inch) (1st generation)"
                case "iPad7,1", "iPad7,2":                            return "iPad Pro (12.9-inch) (2nd generation)"
                case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":      return "iPad Pro (12.9-inch) (3rd generation)"
                case "iPad8,11", "iPad8,12":                          return "iPad Pro (12.9-inch) (4th generation)"
                case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11":return "iPad Pro (12.9-inch) (5th generation)"
                case "AppleTV5,3":                                    return "Apple TV"
                case "AppleTV6,2":                                    return "Apple TV 4K"
                case "AudioAccessory1,1":                             return "HomePod"
                case "AudioAccessory5,1":                             return "HomePod mini"
                case "i386", "x86_64", "arm64":                                return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
                default:                                              return identifier
                }
                #elseif os(tvOS)
                switch identifier {
                case "AppleTV5,3": return "Apple TV 4"
                case "AppleTV6,2": return "Apple TV 4K"
                case "i386", "x86_64": return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS"))"
                default: return identifier
                }
                #endif
            }

            return mapToDevice(identifier: identifier)
        }()
}

extension Locale{
    static var language: String{
        return self.current.languageCode ?? ""

    }
}

extension Bundle {
    
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
    
    static func appName() -> String {
        guard let dictionary = Bundle.main.infoDictionary else {
            return ""
        }
        if let version : String = dictionary["CFBundleName"] as? String {
            return version
        } else {
            return ""
        }
    }
    
    var bundleId: String? {
            return bundleIdentifier
        }

        var versionNumber: String? {
            return infoDictionary?["CFBundleShortVersionString"] as? String
        }

        var buildNumber: String? {
            return infoDictionary?["CFBundleVersion"] as? String
        }

}



extension Int64{
    func formatBytesToGigabytes() -> String {
        let gigabytes = Double(self) / 1073741824.0
        return String(format: "%.2f GB", gigabytes)
    }
}

class DiskStatus {

    //MARK: Formatter MB only
    class func MBFormatter(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = ByteCountFormatter.Units.useMB
        formatter.countStyle = ByteCountFormatter.CountStyle.decimal
        formatter.includesUnit = false
        return formatter.string(fromByteCount: bytes) as String
    }


    //MARK: Get String Value
    class var totalDiskSpace:String {
        get {
            return ByteCountFormatter.string(fromByteCount: totalDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.file)
        }
    }

    class var freeDiskSpace:String {
        get {
           
            return ByteCountFormatter.string(fromByteCount: freeDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.file)
        }
    }

    class var usedDiskSpace:String {
        get {
            return ByteCountFormatter.string(fromByteCount: usedDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.file)
        }
    }


    //MARK: Get raw value
    class var totalDiskSpaceInBytes:Int64 {
        get {
            do {
                let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String)
                let space = (systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.int64Value
                return space!
            } catch {
                return 0
            }
        }
    }
    
    

    class var freeDiskSpaceInBytes:Int64 {
        get {

            if #available(iOS 11.0, *) {
                if let space = try? URL(fileURLWithPath: NSHomeDirectory() as String).resourceValues(forKeys: [URLResourceKey.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage {
                    return space
                } else {
                    return 0
                }
            } else {
                if let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
                let freeSpace = (systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.int64Value {
                    return freeSpace
                } else {
                    return 0
                }
            }


        }
    }

    class var usedDiskSpaceInBytes:Int64 {
        get {
            let usedSpace = totalDiskSpaceInBytes - freeDiskSpaceInBytes
            return usedSpace
        }
    }

}

extension Date{
    
    func get_mm_day_year()->String{
        
        ///Nov 15, 2021

        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "MMM d, yyyy"
        //"MMM d, yyyy HH:mm a"

        return dateFormatterPrint.string(from: self)
    }
}

extension Dictionary where Value: Equatable {
    func findKey(forValue val: Value) -> Key? {
        return first(where: { $1 == val })?.key
    }
}

extension UIImage {
    enum JPEGQuality: CGFloat {
        case low     = 0.25
        case soft    = 0.5
        case medium  = 0.75
        case highest = 1.5
    }

    /// Returns the data for the specified image in JPEG format.
    /// If the image object’s underlying image data has been purged, calling this function forces that data to be reloaded into memory.
    /// - returns: A data object containing the JPEG data, or nil if there was a problem generating the data. This function may return nil if the image has no data or if the underlying CGImageRef contains data in an unsupported bitmap format.
    func jpeg(_ quality: JPEGQuality) -> Data? {
        return self.jpegData(compressionQuality: quality.rawValue)
    }
}

func createThumbnail(path: URL) -> UIImage {
    do {
        let asset = AVURLAsset(url: path, options: nil)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        imgGenerator.appliesPreferredTrackTransform = true
        let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
        let thumbnail = UIImage(cgImage: cgImage)
        return thumbnail
    } catch let error {
        print("*** Error generating thumbnail: \(error.localizedDescription)")
        return UIImage(named: "defaultMusicThumb")!
    }
}


