//
//  Helper.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 20/2/25.
//

import Foundation
import UIKit
import StoreKit
import AppTrackingTransparency
import NVActivityIndicatorView
import AVKit

func askNotificationPermission(){
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { success, error in
        if error == nil && success {
        }
        else {
            DispatchQueue.main.async {
                //self.showPermissionAlertToGoToSettings()
            }
        }
    }
}

enum NotificationState{
    case authorised,unAuthorised,notAsked
}
func getNotificationPermissionState(completionHandler:@escaping(NotificationState)->()){
    UNUserNotificationCenter.current().getNotificationSettings { (settings) in
        switch settings.authorizationStatus {
        case .notDetermined:
            print("Notification permission not determined")
            completionHandler(.notAsked)
        case .denied:
            print("Notification permission denied")
            completionHandler(.unAuthorised)
        case .authorized:
            print("Notification permission authorized")
            completionHandler(.authorised)
        case .provisional:
            print("Notification permission provisional")
            completionHandler(.unAuthorised)
        default:
            print("default")
            completionHandler(.unAuthorised)
        }
    }
}

func hepticFeedBack(){
    let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .light)
    impactFeedbackgenerator.prepare()
    impactFeedbackgenerator.impactOccurred()
}

func getIAPnibName()-> String{
    return "IAPViewController"
}

func presentIAP(_ rootVC: UIViewController){
    hepticFeedBack()
    let iapViewController = loadVCfromStoryBoard(name: "IAP", identifier: "IAPViewController")
    iapViewController.modalPresentationStyle = .fullScreen
    rootVC.present(iapViewController, animated: true, completion: nil)
}

let loader = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 44, height: 44), type: .orbit)
var keyWindow: UIWindow? {
    return UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow }
}

    let loaderBGView = UIView(frame: keyWindow!.frame)

//let loaderBGView = UIView(frame: DELEGATE.window!.frame)
func showLoader(view: UIView){
    loaderBGView.frame = view.frame
    DELEGATE.window?.addSubview(loaderBGView)
    DELEGATE.window?.addSubview(loader)
    loader.center = view.center
    loaderBGView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
    loaderBGView.alpha = 0.0
    loader.alpha = 0.0
    loader.startAnimating()

    UIView.animate(withDuration: 0.3) {
        loaderBGView.alpha = 1.0
        loader.alpha = 1.0
    }
}



func dismissLoader(){
    UIView.animate(withDuration: 0.3) {
        loaderBGView.alpha = 0.0
        loader.alpha = 0.0
    } completion: { (finished) in
        if finished{
            loader.stopAnimating()
            loader.removeFromSuperview()
            loaderBGView.removeFromSuperview()
        }
    }

}

func mickSetup(_ mode: AVAudioSession.Category)
   {
       let recordingSession = AVAudioSession.sharedInstance()
       
       do {
           try recordingSession.setCategory(mode, mode: .default)
           try recordingSession.setActive(true)
           recordingSession.requestRecordPermission() { allowed in
               DispatchQueue.main.async {
                   if allowed {
                      debugPrint(allowed)
                   } else {
                       
                   }
               }
           }
       } catch {
           
       }
   }

func micSetup(_ category: AVAudioSession.Category, completion: ((_ granted: Bool) -> Void)? = nil) {
    let audioSession = AVAudioSession.sharedInstance()
    
    do {
        // Set the audio session category and mode.
        try audioSession.setCategory(category, mode: .default, options: [])
        // Activate the audio session.
        try audioSession.setActive(true)
        
        // Request permission to record.
        audioSession.requestRecordPermission() { granted in
            // Execute the completion handler on the main thread.
            DispatchQueue.main.async {
                if !granted {
                    print("Microphone permission was denied.")
                }
                completion?(granted)
            }
        }
    } catch {
        // It's crucial to handle errors.
        print("Failed to set up audio session: \(error.localizedDescription)")
        DispatchQueue.main.async {
            completion?(false)
        }
    }
}

//MARK: - NEW LOADER

var loaderNew: [UIImage] = {
    var images = [UIImage]()
    for i in 0...135 {
        if let path = Bundle.main.path(forResource: "Loader_\(i).png", ofType: nil){
            print(path)
            if let original = UIImage(contentsOfFile: path){
                images.append(original)
            }
        }
        
    }
    return images
}()

var loaderImageView:UIImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
func showNewLoader(view: UIView){
    loaderBGView.frame = view.frame
    //loaderImageView.animationImages = DELEGATE.newLoaderImages
    loaderImageView.animationDuration = 2.0
    DELEGATE.window?.addSubview(loaderBGView)
    DELEGATE.window?.addSubview(loaderImageView)
    loaderImageView.center = view.center
    loaderBGView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
    loaderBGView.alpha = 0.0
    loaderImageView.alpha = 0.0
    loaderImageView.startAnimating()

    UIView.animate(withDuration: 0.3) {
        loaderBGView.alpha = 1.0
        loaderImageView.alpha = 1.0
    }
}

func dismissNewLoader(){
    UIView.animate(withDuration: 0.3) {
        loaderBGView.alpha = 0.0
        loaderImageView.alpha = 0.0
    } completion: { (finished) in
        if finished{
            loaderImageView.stopAnimating()
            loaderImageView.removeFromSuperview()
            loaderBGView.removeFromSuperview()
        }
    }

}

extension SKStoreReviewController {
    public static func requestReviewInCurrentScene() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            DispatchQueue.main.async {
                requestReview(in: scene)
            }
        }
    }
}

extension AppDelegate{
    
    // MARK: - REVIEW
    func requestReview(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
            //SKStoreReviewController.requestReview()
            SKStoreReviewController.requestReviewInCurrentScene()

        }
        
        if !AppData.review_showed_in_session{
            AppData.review_showed_in_session = true
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
//                //SKStoreReviewController.requestReview()
//                SKStoreReviewController.requestReviewInCurrentScene()
//
//            }
        }
//        else{
//            if !AppData.premiumUser{
//                guard let topViewController = topViewController else { return }
//                GoogleAdsens.shared.presentInterstitialAd(viewController: topViewController)
//            }
//
//        }
        
    }
    
    // MARK: - NEWLY ADDED PERMISSIONS FOR iOS 14
    func requestIDFA() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
                // Tracking authorization completed. Start loading ads here.
            })
        } else {
            // Fallback on earlier versions
        }
    }
    func requestIDFAPermission() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    // Tracking authorization dialog was shown
                    // and we are authorized
                    print("Authorized")
                    
//                    GADMobileAds.sharedInstance().start { (status) in
//                        GoogleAdsens.shared.createAndLoadInterstitial()
//                    }

                    // Now that we are authorized we can get the IDFA
                    //print(ASIdentifierManager.shared().advertisingIdentifier)
                    
                case .denied:
                    // Tracking authorization dialog was
                    // shown and permission is denied
                    print("Denied")
//                    GADMobileAds.sharedInstance().start { (status) in
//                        GoogleAdsens.shared.createAndLoadInterstitial()
//                    }
                    
                case .notDetermined:
                    // Tracking authorization dialog has not been shown
                    print("Not Determined")
                    self.requestIDFA()
                case .restricted:
                    print("Restricted")
                    
                    
//                    GADMobileAds.sharedInstance().start { (status) in
//                        GoogleAdsens.shared.createAndLoadInterstitial()
//                    }
                @unknown default:
                    print("Unknown")
                }
            }
        }
    }
}

import Alamofire
class Connectivity {
    class var isConnectedToInternet:Bool {
        return NetworkReachabilityManager()?.isReachable ?? false
    }
}

import Foundation
import UIKit




extension UIViewController {
    
    public func showAccessDeniedAlert(_ message: String){
        let alertController = UIAlertController(title: "Permission Requires", message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        let gotoSettingsAction = UIAlertAction(title: "Open Settings", style: .default){_ in
            gotoSettings()
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(gotoSettingsAction)
        self.present(alertController, animated: true)
    }
   
    public func autoTopBottomCalculateLessThan16(value : CGFloat,idle : CGFloat)->CGFloat{
        
        let height = UIScreen.main.bounds.size.height
        
        print("Device Height = \(height)")
        print("Value : \(value)")
        print("Calculative value : \((value / idle) * height)")
        
        let idle = height > idle ? CGFloat(1024) : CGFloat(896)
        
        print("Idle : \(idle)")
        
        
        
        if height == idle {
            
            return value
            
        }else{
            
            //            if ((value / idle) * height) <= 16 {
            //
            //
            //                return CGFloat(16)
            //            }
            return (value / idle) * height
            
        }
    }
    
    
    
    
    public func autoTopBottomCalculate(value : CGFloat,idle : CGFloat)->CGFloat{
        
        let height = UIScreen.main.bounds.size.height
        
        print("Device Height = \(height)")
        print("Value : \(value)")
        print("Calculative value : \((value / idle) * height)")
        
        let idle = height > idle ? CGFloat(1024) : CGFloat(896)
        
        print("Idle : \(idle)")
        
        
        
        if height == idle {
            
            return value
            
        }else if value == CGFloat(16){
            
            return value
            
        } else{
            
            if ((value / idle) * height) <= 16 {
                
                
                return CGFloat(16)
            }
            return (value / idle) * height
            
        }
    }
    
    public func autoLeadingCalculate(value : CGFloat,idle : CGFloat)->CGFloat{
        
        let width = UIScreen.main.bounds.size.width
        
        let idle = width >= CGFloat(768) ? CGFloat(768) : CGFloat(414)
        
        print("height : \(width)")
        
        if width == idle {
            
            return value
            
        }else if value == CGFloat(16){
            
            return value
            
        } else{
            if ((value / idle) * width) <= 16 {
                
                return CGFloat(16)
            }
            return (value / idle) * width
        }
    }
    
    public func autoHeightCalculate(value : CGFloat,idle : CGFloat)->CGFloat{
        
        let height = UIScreen.main.bounds.size.height
        
        print("Device Height = \(height)")
        print("Value : \(value)")
        print("Calculative value : \((value / idle) * height)")
        
//        let idle = height > idle ? CGFloat(1024) : CGFloat(896)
        
        if height == idle {
            
            return value
            
        }else if value == CGFloat(45){
            
            return value
            
        } else{
            
            if ((value / idle) * height) <= 45 {
                
                
                return CGFloat(45)
            }
            return (value / idle) * height
            
        }
        
    }
    
    public func autoWidthCalculate(value : CGFloat,idle : CGFloat)->CGFloat{
        
        let width = UIScreen.main.bounds.size.width
        
        print("height : \(width)")
        
        let idle = width >= CGFloat(768) ? CGFloat(768) : CGFloat(414)
        
        if width == idle {
            
            return value
            
        }else{
            return (value / idle) * width
        }
    }
    
    
}

func gotoSettings() {
    if let appSettings = URL(string: UIApplication.openSettingsURLString) {
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(appSettings)
        }
    }
}



//func presentMeterPaywall(_ rootVc: UIViewController, description: String? = "It's an premium feature. Simply upgrade to premium and unlock all features."){
//
//    DispatchQueue.main.async {
//        let vc = CustomAlertViewController.customInit(customViewModel: CustomViewModel(title: "NO INTERNET", description: description ?? "It's an premium feature. Simply upgrade to premium and unlock all features.", btnTitle: "OK"),successfullPurchasedState: true, state: .premium)
//
//            rootVc.add(vc, frame: rootVc.view.bounds, contentView: rootVc.view)
//            vc.presentAnimatiom()
//    }
//
//}

class VideoHelper{
    
    private var generator: AVAssetImageGenerator?

    static let shared = VideoHelper()

    func generateImages(for asset: AVAsset, at times: [NSValue], with maximumSize: CGSize, filterName:String? = nil, completionHandler: @escaping (_ imagee: UIImage) -> Void) {
        
        generator = AVAssetImageGenerator(asset: asset)
        generator?.appliesPreferredTrackTransform = true

        let scaledSize = CGSize(width: maximumSize.width * UIScreen.main.scale, height: maximumSize.height * UIScreen.main.scale)
        generator?.maximumSize = scaledSize

        let handler: AVAssetImageGeneratorCompletionHandler = { [weak self] (_, cgimage, _, result, error) in
            if let cgimage = cgimage, error == nil && result == AVAssetImageGenerator.Result.succeeded {
                DispatchQueue.main.async(execute: { [weak self] () -> Void in
                    let uiimage = UIImage(cgImage: cgimage, scale: 1.0, orientation: UIImage.Orientation.up)
                    
                    if let filterName, filterName != "No Filter"{
                        if let filteredImage = uiimage.filterImage(name: filterName){
                            completionHandler(filteredImage)
                        }else{
                            completionHandler(uiimage)
                        }
                    }else{
                        completionHandler(uiimage)
                    }
                })
            }
        }

        generator?.generateCGImagesAsynchronously(forTimes: times, completionHandler: handler)
    }
          
    static func generateThumbnail(path: URL?, value: Int64 = 0) -> UIImage? {
        
        guard let path = path else{
            return nil
        }
        do {
            let asset = AVURLAsset(url: path, options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: value, timescale: 1000), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            return thumbnail
        } catch let error {
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }

}

enum ConverterDegree: String {
    case degree0
    case degree90
    case degree180
    case degree270

    static func convert(degree: CGFloat) -> ConverterDegree {
        if degree == 0 || degree == 360 {
            return .degree0
        } else if degree == 90 {
            return .degree90
        } else if degree == 180 {
            return .degree180
        } else if degree == 270 {
            return .degree270
        } else {
            return .degree90
        }
    }
}
