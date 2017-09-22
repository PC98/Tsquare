//
//  LoginViewController.swift
//  Tsquare
//
//  Created by Prabhav Chawla on 9/14/17.
//  Copyright © 2017 Prabhav Chawla. All rights reserved.
//

import UIKit
import WebKit

class LoginViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {
    
    var webView: WKWebView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !UserDefaults.standard.bool(forKey: "authenticated") {
            self.setUp()
        } else {
            let viewController = storyboard?.instantiateViewController(withIdentifier: "portalNavigationViewController") as! UINavigationController
            self.present(viewController, animated: true)
        }
    }
    
    func setUp() {
        let webConfiguration = WKWebViewConfiguration()
        let frame = CGRect(x: 0, y: 20, width: self.view.frame.width, height: self.view.frame.height)
        self.webView = WKWebView(frame: frame, configuration: webConfiguration)
        self.webView.uiDelegate = self
        self.webView.navigationDelegate = self
        self.webView.isHidden = true
        self.view.addSubview(self.webView)
        self.webView.load(URLRequest(url: URL(string: "https://login.gatech.edu/cas/login?service=https%3A%2F%2Ft-square.gatech.edu%2Fsakai-login-tool%2Fcontainer")!))
    }
    
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView.url?.absoluteString == "https://login.gatech.edu/cas/login?service=https%3A%2F%2Ft-square.gatech.edu%2Fsakai-login-tool%2Fcontainer" {
            self.activityIndicator.isHidden = true
            self.webView.isHidden = false
        }
        
        webView.evaluateJavaScript("document.title") { (result, error) in
            print(result ?? "nil")
            if result as? String == "T-Square" {
                UserDefaults.standard.set(true, forKey: "authenticated")
                self.webView.isHidden = true
                self.activityIndicator.isHidden = false
                let viewController = self.storyboard?.instantiateViewController(withIdentifier: "portalNavigationViewController") as! UINavigationController
                self.present(viewController, animated: true)
            }
        }
    }
}
