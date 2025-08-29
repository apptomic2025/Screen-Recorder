//
//  Define.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 20/2/25.
//

import Foundation
import UIKit

var window: UIWindow?
let STANDARD_ANIMATION_DURATION = 0.4

var countRecord = 1
//var resoulationValues : [Int:Int] = [0:3840, 1:1080, 2:720, 3:540, 4:480]

//let coreDataStack = CoreDataStack.shared

let appThemesolidColor = UIColor(named: "appThemesolidColor")!
let appThemesolidColorLessAlpha = UIColor(named: "appThemesolidColorLessAlpha")!
let TEXT_COLOR = UIColor(red: 66.0/255.0, green: 79.0/255.0, blue: 134.0/255.0, alpha: 1.0)
let collectionViewBgColor = UIColor(red: 239.0/255.0, green: 239.0/255.0, blue: 244.0/255.0, alpha: 1.0)
let viewBorderColor = UIColor(red: 226.0/255.0, green: 226.0/255.0, blue: 226.0/255.0, alpha: 1.0)

let DEVICE_HEIGHT = UIScreen.main.bounds.size.height
let DEVICE_WIDTH = UIScreen.main.bounds.size.width
let IS_IPHONE_4 = UIScreen.main.bounds.size.height == 480.0
let IS_IPHONE_5 = UIScreen.main.bounds.size.height == 568.0
let IS_IPHONE_6 = UIScreen.main.bounds.size.height == 667.0
let IS_IPHONE_6S_PLUS = UIScreen.main.bounds.size.height == 736.0
let IS_IPHONE_X = DEVICE_HEIGHT == 812.0
let IS_IPHONE_XMAX = DEVICE_HEIGHT == 896.0 && DEVICE_WIDTH == 414.0
let IS_IPHONE_12_PRO_MAX = DEVICE_HEIGHT == 926.0 && DEVICE_WIDTH == 428.0
let IS_IPHONE_12_PRO = DEVICE_HEIGHT == 844.0 && DEVICE_WIDTH == 390.0
let IS_IPHONE_XR = DEVICE_HEIGHT == 896.0 && DEVICE_WIDTH == 414.0
let IS_IPHONE_XS = DEVICE_HEIGHT == 812.0 && DEVICE_WIDTH == 375.0

let IS_IPHONE_XSMAX_DEVICE = UIScreen.main.nativeBounds.size.height == 2688
let IS_IPHONE_XR_DEVICE = UIScreen.main.nativeBounds.size.height == 1792
let IS_IPHONE_X_XS_DEVICE = UIScreen.main.nativeBounds.size.height == 2436
let IS_IPHONE_6S_DEVICE = (UIScreen.main.nativeBounds.size.height == 1920) || (UIScreen.main.nativeBounds.size.height == 2208)
let IS_IPHONE_6_DEVICE = UIScreen.main.nativeBounds.size.height == 1334
let IS_IPHONE_5_DEVICE = UIScreen.main.nativeBounds.size.height == 1136

let IS_NOTCH_PHONE = (IS_IPHONE_X || IS_IPHONE_XMAX || IS_IPHONE_12_PRO_MAX || IS_IPHONE_12_PRO)
let IS_IPHONE_X_SERIES = IS_IPHONE_X || IS_IPHONE_XMAX || IS_IPHONE_XR || IS_IPHONE_XS || IS_IPHONE_12_PRO_MAX || IS_IPHONE_12_PRO


//---------Ipad ------//

let IS_DEVICE_IPAD = UIDevice.current.responds(to: #selector(getter: UIDevice.userInterfaceIdiom)) && UIDevice.current.userInterfaceIdiom == .pad

let IS_IPAD_PRO_1366 = IS_DEVICE_IPAD && DEVICE_HEIGHT == 1366.0
let IS_IPAD_PRO_1024 = IS_DEVICE_IPAD && DEVICE_HEIGHT == 1024.0
let IS_IPAD_PRO_1194 = IS_DEVICE_IPAD && DEVICE_HEIGHT == 1194.0
let IS_IPAD_PRO_1112 = IS_DEVICE_IPAD && DEVICE_HEIGHT == 1112.0

///directory
let APP_ROOT_DIR = "Directory_SCANNER"
let APP_CACHE_DIR = "Cache_SCANNER"
let APP_ORIGINAL_DIR = "ORIGINAL_SCANNER"

let APP_ID = "1670421848"

let VIDEO_SAVED_NOTIFICATION: Notification.Name = Notification.Name(rawValue: "com.samar.screenrecorder.Notification")
//let IS_DEFAULT_ALBUM_CREATED ""
enum UserDefaults_TAG: String, CaseIterable {
    case iS_default_album_created = "IS_DEFAULT_ALBUM_CREATED";
}

let placeHolderColor = UIColor(red: (190.0/255.0), green: (189.0/255.0), blue: (191.0/255.0), alpha: 1.0)

let DELEGATE = UIApplication.shared.delegate as! AppDelegate

func loadVCfromStoryBoard(name: String, identifier: String) -> UIViewController {
    if #available(iOS 13.0, *) {
        return UIStoryboard(name: name, bundle: nil).instantiateViewController(identifier: identifier)
    } else {
        return UIStoryboard(name: name, bundle: nil).instantiateViewController(withIdentifier: identifier)
    }
}

var topViewController: UIViewController?{
    let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
    
    if var topController = keyWindow?.rootViewController {
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        // topController should now be your topmost view controller
        return topController
    }else{
        return nil
    }
}

let REVIEW_TEXT = "Your reviews keep our small team motivated to make \(Bundle.appName()) even better."

let FEEDBACK_TEXT = "Found a bug? Have an idea for a feature or improvement? Have a suggestion you'd love us to add? You can drop us an email at:"

let PERMISSION_TEXT = """
\(Bundle.appName()) needs access to your photo library in order to save wallpapers. To enable access, go to settings and turn on photos.
"""

let CACHE_TEXT = "To free up space on your device, you can remove the contents stored on device. Note that it will affect the speed of browsing since the contents will be redownloaded from our servers."

let CONTACT_TEXT = """
Need help or have a general enquiry? Feel free to drop us an email at:
"""

let FOLLOW_TEXT = """
We're just getting started on social media. Join us early and follow our process behind the scenes, keep up to date
on product updates and get sneak peeks of upcoming portals being filmed around the world.
"""

let SHARE_TEXT = """
We hope you enjoy the app. We are trying to give you a fresh feelings by giving regularly updated wallpapers. Feel free to share the app with your family and friends.
"""

let Review_Model = AlertModel(title: "Enjoying \(Bundle.appName())?", text: REVIEW_TEXT, mailID: "Rate Us", type: .review)

let Share_Model = AlertModel(title: "SHARE US", text: SHARE_TEXT, mailID: "Share", type: .share)

let Feedback_Model = AlertModel(title: "FEEDBACK", text: FEEDBACK_TEXT, mailID: "support@snowpex.com", type: .feedback, subject: "Feedback - \(Bundle.appName())")
let Follow_Model = AlertModel(title: "FOLLOW US", text: FOLLOW_TEXT, mailID: "https://instagram.com/livewallpaper4kforme", type: .follow)
let Contact_Model = AlertModel(title: "CONTACT US", text: CONTACT_TEXT, mailID: "contact@snowpex.com", type: .contact, subject: "Contact - \(Bundle.appName())")

let Photo_Add_Permission_Model = AlertModel(title: "PLEASE ALLOW ACCESS", text: PERMISSION_TEXT, mailID: "Go to Settings", type: .other, subject: "Contact - \(Bundle.appName())")

let Clear_Cache_Model = AlertModel(title: "CLEAR CACHE", text: CACHE_TEXT, mailID: "Confirm", type: .other, subject: "Contact - \(Bundle.appName())")

let tmpDirURL = URL.init(fileURLWithPath:NSTemporaryDirectory() , isDirectory: true)
let PUBLIC_API_KEY = "dxooaJbnhwZHTeTlEnPCvVPsjgaGufce"


//GOOGLE AD
let REWARD_SUCCESS_NOTIFICATION_NAME = "REWARD_SUCCESS"

enum NavbarHeight: CGFloat {
    case withOutNotch = 64
    case withNotch = 92
    case withDynamicIsland = 103
}

enum DeviceUIType {
    case dynamicIsland
    case notch
    case noNotch
}

func scaledHeight(for viewHeight: CGFloat, baseDeviceHeight: CGFloat = 932) -> CGFloat {
    let screenHeight = UIScreen.main.bounds.height
    return (screenHeight / baseDeviceHeight) * viewHeight
}

func getDeviceUIType() -> DeviceUIType {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first else {
        return .noNotch
    }

    let topInset = window.safeAreaInsets.top

    // Dynamic Island devices typically have top inset ≥ 59
    if topInset >= 59 {
        return .dynamicIsland
    } else if topInset > 20 {
        return .notch
    } else {
        return .noNotch
    }
}
