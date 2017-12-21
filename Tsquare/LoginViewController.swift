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
        self.webView.delegate = self
        self.webView.isOpaque = true
        self.webView.backgroundColor = UIColor.white
        self.webView.loadRequest(URLRequest(url: URL(string: "https://login.gatech.edu/cas/login")!))
    }
    
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        if webView.request?.url?.absoluteString == "https://login.gatech.edu/cas/login" {
            self.activityIndicator.isHidden = true
            self.webView.isHidden = false
        }
        
        if webView.stringByEvaluatingJavaScript(from: "document.getElementById(\"msg\").className") == "success" {
            UserDefaults.standard.set(true, forKey: "authenticated")
            self.webView.isHidden = true
            self.activityIndicator.isHidden = false
            let portalController = storyboard!.instantiateViewController(withIdentifier: "PortalViewController") as! PortalViewController
            self.navigationController!.pushViewController(portalController, animated: true)
        }
    }
}
