//
//  WebVC.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 20/2/25.
//

import UIKit
import WebKit

let PRIVACY_POLICY = "https://snowpex.com/apps/screenRecorder/privacy.html"
let TERMS_CONDITION = "https://snowpex.com/apps/screenRecorder/terms.html"

let FAQ = "https://snowpex.com/apps/screenRecorder/faq"

var myContext = 0

enum URL_TYPE {
    case privacy_policy, terms_condition, subscription_info, faq
}

class WebVC: UIViewController {
    
    private var isInjected: Bool = false

    
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!

    public var url_type: URL_TYPE = .privacy_policy
    
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        let date = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date, completionHandler:{ })
        
        webView.isOpaque = false
        webView.backgroundColor = .clear
        
        titleLabel.text = (url_type == .privacy_policy) ? "Privacy Policy" : "User Agreement"

        if url_type == .faq{
            if let url = URL(string: FAQ){
                titleLabel.text = "FAQ"
                webView.load(URLRequest(url: url))
                webView.allowsBackForwardNavigationGestures = true
                webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: &myContext)
            }
            
        }else{
            if let url = URL(string: (url_type == .privacy_policy) ? PRIVACY_POLICY : TERMS_CONDITION){
                webView.load(URLRequest(url: url))
                webView.allowsBackForwardNavigationGestures = true
                webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: &myContext)
               
            }
            
            if url_type == .subscription_info{
                titleLabel.text = "About Subscription"
                if let url = Bundle.main.url(forResource: "sub_info", withExtension: "html"){
                    webView.loadFileURL(url, allowingReadAccessTo: url)
                    let request = URLRequest(url: url)
                    webView.load(request)
                }
                
            }
        }
        
        
        
        webView.navigationDelegate = self
       
    }
    
    //observer
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            
            guard let change = change else { return }
            if context != &myContext {
                super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
                return
            }
            
            if keyPath == "title" {
                if let title = change[NSKeyValueChangeKey.newKey] as? String {
                    self.navigationItem.title = title
                }
                return
            }
            if keyPath == "estimatedProgress" {
                if let progress = (change[NSKeyValueChangeKey.newKey] as AnyObject).floatValue {
                    progressView.progress = progress;
                }
                return
            }
        }
    
    // MARK: - BUTTON ACTIONS
    @IBAction func dismissView(_ sender: UIButton){
        //dismiss(animated: true, completion: nil)
        self.navigationController?.popViewController(animated: true)
    }

}

extension WebVC: WKNavigationDelegate{
   
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            progressView.isHidden = true
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            progressView.isHidden = false
        }
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let serverTrust = challenge.protectionSpace.serverTrust  else {
            completionHandler(.useCredential, nil)
            return
        }
        let credential = URLCredential(trust: serverTrust)
        completionHandler(.useCredential, credential)
        
    }
}

extension WKWebView {
    class func clean() {
        guard #available(iOS 9.0, *) else {return}

        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)

        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
                #if DEBUG
                    print("WKWebsiteDataStore record deleted:", record)
                #endif
            }
        }
    }
}
