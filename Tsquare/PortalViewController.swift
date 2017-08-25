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
        
        self.automaticallyAdjustsScrollViewInsets = false
        
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
            self.loginGetId()
        }
    }
    
    private func populateClassArr() {
        do {
            classArr = try CoreDataSingleton.shared.context.fetch(Class.fetchRequest())
        } catch {
            fatalError("Can't fetch!")
        }
    }
    
    private func changeUI(isLoading: Bool) {
        activityIndicator.isHidden = !isLoading
        collectionView.isHidden = isLoading
    }
    
    private func loginGetId() {
        networkRequest(request: URLRequest(url: URL(string: "https://login.gatech.edu/cas/login")!)) { data in
            let html_string = String(data: data, encoding: .utf8)
            
            if let lt_id = html_string?.components(separatedBy: "name=\"lt\" value=\"")[1].components(separatedBy: "\" />")[0] {
                self.loginPostCredentials(lt_id)
            }
        }
    }
    
    private func loginPostCredentials(_ id: String) {
        let request = NSMutableURLRequest(url: URL(string: "https://login.gatech.edu/cas/login")!)
        request.httpMethod = "POST"
        request.httpBody = "username=pchawla8&password=GTCSSUMMER@2017&lt=\(id)&execution=e1s1&_eventId=submit&submit=LOGIN".data(using: .utf8)
        
        networkRequest(request: request as URLRequest) { _ in
            self.getTsquare()
        }
    }
    
    private func getTsquare() {
        networkRequest(request: URLRequest(url: URL(string: "https://login.gatech.edu/cas/login?service=https%3A%2F%2Ft-square.gatech.edu%2Fsakai-login-tool%2Fcontainer")!)) { data in
            
            do {
                DispatchQueue.main.sync {
                    
                    let fr: NSFetchRequest<Class> = Class.fetchRequest()
                    
                    if let classes = try? CoreDataSingleton.shared.context.fetch(fr) {
                        for item in classes {
                            CoreDataSingleton.shared.context.delete(item)
                        }

                        self.classArr = [Class]()
                    }
                }
                
                
                let html = String(data: data, encoding: .utf8)
                let doc: Document = try SwiftSoup.parse(html!)
                for element in try doc.select("#siteLinkList > *") {
                    if try element.className().isEmpty {
                        let link = try element.select("a").first()!
                        
                        let name = try link.text()
                        let siteURL = URL(string: try link.attr("href"))!
                        
                        CoreDataSingleton.shared.backgroundContext.performAndWait {
                            self.classArr.append(Class(name: name, siteURL: siteURL, context: CoreDataSingleton.shared.backgroundContext))
                            do {
                                try CoreDataSingleton.shared.backgroundContext.save()
                            } catch {
                                fatalError("Error while saving backgroundContext: \(error)")
                            }
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    self.changeUI(isLoading: false)
                }
                
                UserDefaults.standard.set(true, forKey: "dataDownloaded")
                UserDefaults.standard.set(Date(), forKey: "lastRefreshDate")
                CoreDataSingleton.shared.saveContext()
                
            } catch {
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
        
        
        gradebookController.navigationItem.title = "Gradebook \((collectionView.cellForItem(at: indexPath) as! ClassViewCell).className.text!)"
        
        navigationController!.pushViewController(gradebookController, animated: true)
        
        collectionView.deselectItem(at: indexPath, animated: true)
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
            self.loginGetId()
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

