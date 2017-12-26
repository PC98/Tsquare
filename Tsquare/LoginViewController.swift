//
//  LoginViewController.swift
//  Tsquare
//
//  Created by Prabhav Chawla on 9/14/17.
//  Copyright © 2017 Prabhav Chawla. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var activityLabel: UILabel!
    
    static var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem?.target = webView
        self.navigationItem.leftBarButtonItem?.action = #selector(webView.goBack)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !UserDefaults.standard.bool(forKey: "authenticated") {
            self.setUp()
        } else {
            let portalController = storyboard!.instantiateViewController(withIdentifier: "PortalViewController") as! PortalViewController
            self.navigationController!.pushViewController(portalController, animated: true)
        }
    }
    
    func setUp() {
        self.activityIndicator.isHidden = false
        self.activityIndicator.startAnimating()
        self.activityLabel.isHidden = false
        self.activityLabel.text = "Loading..."
        self.self.navigationItem.leftBarButtonItem?.isEnabled = false
        self.webView.isHidden = true
        self.webView.delegate = self
        self.webView.isOpaque = true
        self.webView.backgroundColor = UIColor.white
        self.webView.loadRequest(URLRequest(url: URL(string: "https://login.gatech.edu/cas/login")!))
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        self.activityIndicator.stopAnimating()
        presentAlert(message: "There was an error in loading Georgia Tech's log-in services. You will be redirected to the main log-in page.", presentingVC: self) {
            UserDefaults.standard.removeObject(forKey: "cookies")
            
            if let cookies = HTTPCookieStorage.shared.cookies {
                for cookie in cookies {
                    HTTPCookieStorage.shared.deleteCookie(cookie)
                }
            }
            
            self.setUp()
        }
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        LoginViewController.timer?.invalidate()
        LoginViewController.timer = Timer.scheduledTimer(withTimeInterval: 45, repeats: false, block: { (Timer) in
            self.webView.isHidden = true
            self.activityIndicator.isHidden = false
            self.activityLabel.isHidden = false
            self.activityLabel.text = "Slow or no internet connection..."
        })
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        LoginViewController.timer?.invalidate()

        if webView.stringByEvaluatingJavaScript(from: "document.getElementById(\"msg\").className") == "success" {
            UserDefaults.standard.set(true, forKey: "authenticated")
            self.webView.isHidden = true
            self.activityIndicator.isHidden = false
            let portalController = storyboard!.instantiateViewController(withIdentifier: "PortalViewController") as! PortalViewController
            self.navigationController!.pushViewController(portalController, animated: true)
            return
        }
        
        self.self.navigationItem.leftBarButtonItem?.isEnabled = true
        self.webView.isHidden = false
        self.activityIndicator.isHidden = true
        self.activityLabel.isHidden = true
    }
}
