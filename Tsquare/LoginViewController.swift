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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !UserDefaults.standard.bool(forKey: "authenticated") {
            self.setUp()
        } else {
            self.performSegue(withIdentifier: "showPortalViewController", sender: self)
        }
    }
    
    func setUp() {
        webView.delegate = self
        webView.isOpaque = true
        webView.backgroundColor = UIColor.white
        webView.loadRequest(URLRequest(url: URL(string: "https://login.gatech.edu/cas/login")!))
    }
    
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        if webView.stringByEvaluatingJavaScript(from: "document.getElementById(\"msg\").className") == "success" {
            UserDefaults.standard.set(true, forKey: "authenticated")
            self.performSegue(withIdentifier: "showPortalViewController", sender: self)
        }
    }
}
