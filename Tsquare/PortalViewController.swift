//
//  PortalViewController.swift
//  Tsqaure
//
//  Created by Prabhav Chawla on 8/15/17.
//  Copyright © 2017 Prabhav Chawla. All rights reserved.
//

import UIKit
import SwiftSoup
import CoreData

class PortalViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    var classArr = [Class]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        self.view.backgroundColor = UIColor(red: 240/255.0, green: 240/255.0, blue: 240/255.0, alpha: 1.0)
        self.collectionView.backgroundColor = UIColor(red: 240/255.0, green: 240/255.0, blue: 240/255.0, alpha: 1.0)
        
        let space: CGFloat = 20.0
        let dimension = (view.frame.size.width - 3 * space) / 2.0
        
        flowLayout.minimumInteritemSpacing = space // space between items in the same row or column
        flowLayout.minimumLineSpacing = space // space between rows or columns
        flowLayout.itemSize = CGSize(width: dimension, height: dimension * 2 / 3) // governs cell size
        
        if UserDefaults.standard.bool(forKey: "dataDownloaded") {
            self.changeUI(isLoading: false)
            self.populateClassArr()
        } else {
            self.changeUI(isLoading: true)
            self.getTsquare()
        }
    }
    
    private func populateClassArr() {
        do {
            let fetchRequest: NSFetchRequest<Class> = Class.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            
            classArr = try CoreDataSingleton.shared.context.fetch(fetchRequest)
        } catch {
            fatalError("Can't fetch!")
        }
    }
    
    private func changeUI(isLoading: Bool) {
        activityIndicator.isHidden = !isLoading
        collectionView.isHidden = isLoading
    }
    
    private func getTsquare() {
        networkRequest(request: URLRequest(url: URL(string: "https://login.gatech.edu/cas/login?service=https%3A%2F%2Ft-square.gatech.edu%2Fsakai-login-tool%2Fcontainer")!)) { (data, response) in
            
            do {
                let html = String(data: data, encoding: .utf8)
                let doc: Document = try SwiftSoup.parse(html!)
                
                if try doc.select("title").first()?.text() == "GT | GT Login" && UserDefaults.standard.bool(forKey: "dataDownloaded") {
                    
                    DispatchQueue.main.sync {
                        self.activityIndicator.stopAnimating()
                    }
                    presentAlert(title: "Session Expired", message: "Attempt to refresh data has failed since your login session has expired. Old data will be presented. You could try logging out and logging back in.", presentingVC: self) {
                        self.activityIndicator.startAnimating()
                        self.changeUI(isLoading: false)
                    }
                } else {
                    
                    CoreDataSingleton.shared.context.performAndWait {
                        
                        let fr: NSFetchRequest<Class> = Class.fetchRequest()
                        
                        if let classes = try? CoreDataSingleton.shared.context.fetch(fr) {
                            for item in classes {
                                CoreDataSingleton.shared.context.delete(item)
                            }
                            self.classArr = [Class]()
                        }
                    }
                    
                    for element in try doc.select("#siteLinkList > *") {
                        if try element.className().isEmpty {
                            let link = try element.select("a").first()!
                            
                            let name = try link.text()
                            let siteURL = URL(string: try link.attr("href"))!
                            
                            CoreDataSingleton.shared.backgroundContext.performAndWait {
                                let _ = Class(name: name, siteURL: siteURL, context: CoreDataSingleton.shared.backgroundContext)
                                do {
                                    try CoreDataSingleton.shared.backgroundContext.save()
                                } catch {
                                    fatalError("Error while saving backgroundContext: \(error)")
                                }
                            }
                        }
                    }
                    
                    CoreDataSingleton.shared.saveContext()
                    
                    DispatchQueue.main.async { // Perhaps change to core data object queue
                        self.populateClassArr()
                        self.collectionView.reloadData()
                        self.changeUI(isLoading: false)
                    }
                    
                    UserDefaults.standard.set(true, forKey: "dataDownloaded")
                    UserDefaults.standard.set(Date(), forKey: "lastRefreshDate")
                }
            }  catch {
                print("error")
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return classArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ClassViewCell", for: indexPath) as! ClassViewCell
        
        cell.className.text = classArr[indexPath.row].name
        
        cell.contentView.backgroundColor = UIColor(red: 240/255.0, green: 240/255.0, blue: 240/255.0, alpha: 1.0)
        cell.backgroundCardView.layer.cornerRadius = 3.0
        cell.backgroundCardView.layer.masksToBounds = false
        cell.backgroundCardView.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        cell.backgroundCardView.layer.shadowOpacity = 1.0
        cell.backgroundCardView.layer.shadowOffset = CGSize(width: 0, height: 0)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath:IndexPath) {
        
        let gradebookController = storyboard!.instantiateViewController(withIdentifier: "GradebookViewController") as! GradebookViewController
        let classObject = classArr[indexPath.row]
        
        gradebookController.navigationItem.title = "Gradebook \(classObject.name!)"
        
        if let gradebook = classObject.gradebook {
            gradebookController.gradebookObj = gradebook
            self.navigationController!.pushViewController(gradebookController, animated: true)
            return
        }
        
        activityIndicator.isHidden = false
        self.view.isUserInteractionEnabled = false
        self.view.alpha = 0.6
        networkRequest(request: URLRequest(url: classObject.siteURL as! URL)) { (data, response) in
            do {
                
                let html = String(data: data, encoding: .utf8)
                let doc: Document = try SwiftSoup.parse(html!)
                
                if let element = try doc.select("a.icon-sakai-gradebook-tool").first() {
                    
                    CoreDataSingleton.shared.context.perform {
                        let gradebookObj = Gradebook(context: CoreDataSingleton.shared.context)
                        
                        var url: URL!
                        if try! element.parent()?.className() == "selectedTool" {
                            url = response.url!
                        } else {
                            url = URL(string: try! element.attr("href"))!
                        }
                        
                        gradebookObj.siteURL = url as NSObject
                        gradebookObj.classObject = classObject
                        classObject.gradebook = gradebookObj
                        gradebookController.gradebookObj = gradebookObj
                    
                        CoreDataSingleton.shared.saveContext()
                        self.navigationController!.pushViewController(gradebookController, animated: true)
                    }
                } else if try doc.select("title").first()?.text() == "GT | GT Login" && UserDefaults.standard.bool(forKey: "dataDownloaded") {
                    presentAlert(title: "Session Expired", message: "You can't view this class's Gradebook since your session has expired. Please log-in again.", presentingVC: self)
                }
                else {
                    presentAlert(title: "Gradebook Missing", message: "This class doesn't have a Gradebook.", presentingVC: self)
                }
                DispatchQueue.main.sync {
                    self.activityIndicator.isHidden = true
                    self.view.isUserInteractionEnabled = true
                    self.view.alpha = 1.0
                }
            } catch {
                print("error")
            }
        }
    }
    
    @IBAction func logout(_ sender: Any) {
        let alert = UIAlertController()
        
        alert.title = "Logout Confirmation"
        alert.message = "Are you sure you want to logout? All data will be deleted."
        
        let logoutAction = UIAlertAction(title: "Logout", style: .destructive) { (alert: UIAlertAction!) -> Void in
            
            UserDefaults.standard.set(false, forKey: "authenticated")
            UserDefaults.standard.set(false, forKey: "dataDownloaded")
            UserDefaults.standard.removeObject(forKey: "cookies")
            
            if let cookies = HTTPCookieStorage.shared.cookies {
                for cookie in cookies {
                    HTTPCookieStorage.shared.deleteCookie(cookie)
                }
            }
            
            self.dismiss(animated: true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        
        alert.addAction(logoutAction)
        alert.addAction(cancelAction)
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func refresh(_ sender: Any) {
        let str = String(describing: (UserDefaults.standard.object(forKey: "lastRefreshDate") as! Date).customPlaygroundQuickLook)
        let index = str.index(str.startIndex, offsetBy: 6)
        let endIndex = str.index(str.endIndex, offsetBy:-2)
        
        let alert = UIAlertController()
        
        alert.title = "Refresh Confirmation"
        alert.message = "Are you sure you want to refresh the data? Last refresh date was \(str[Range(index ..< endIndex)])"
        
        let refreshAction = UIAlertAction(title: "Refresh", style: .destructive) { (alert: UIAlertAction!) -> Void in
            self.changeUI(isLoading: true)
            self.getTsquare()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        
        alert.addAction(refreshAction)
        alert.addAction(cancelAction)
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        self.present(alert, animated: true, completion: nil)
    }
}

