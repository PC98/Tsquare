//
//  GlobalUtilityFunctions.swift
//  Tsqaure
//
//  Created by Prabhav Chawla on 8/21/17.
//  Copyright © 2017 Prabhav Chawla. All rights reserved.
//

import UIKit

func networkRequest(request: URLRequest, handler: @escaping(_ data: Data, _ response: URLResponse) -> Void) {
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        // if an error occurs, print it and re-enable the UI
        func displayError(_ error: String) {
            print(error)
            print("URL at time of error: \(String(describing: request.url))")
        }
        
        // GUARD checks if data doesnt exist and exectes the code in else. If data does exist, it is stored in data... Nice as it avoids nested ifs;.. You can also combine all these gaurd statements. Guard gives robust error checks and debug statements
        /* GUARD: Was there an error? */
        guard (error == nil) else {
            displayError("There was an error with your request: \(String(describing: error))")
            return
        }
        
        /* GUARD: Did we get a successful 2XX response? */
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
            displayError("Your request returned a status code other than 2xx!")
            return
        }
        
        /* GUARD: Was there any data returned? */
        guard let data = data else {
            displayError("No data was returned by the request!")
            return
        }
        
        handler(data, response!)
        
    }
    
    task.resume()
}

func presentAlert(title: String = "Error", message: String = "Error", presentingVC vc: UIViewController, handler: (() -> Void)? = nil) {
    let alert = UIAlertController()
    
    alert.title = title
    alert.message = message
    
    let okAction = UIAlertAction(title: "OK", style: .default) { alert in
        if let handler = handler {
            handler()
        }
    }
    
    alert.addAction(okAction)
    
    if let popoverController = alert.popoverPresentationController {
        popoverController.sourceView = vc.view
        popoverController.sourceRect = CGRect(x: vc.view.bounds.midX, y: vc.view.bounds.midY, width: 0, height: 0)
        popoverController.permittedArrowDirections = []
    }
    
    vc.present(alert, animated: true, completion: nil)
}
