//
//  GradebookViewController.swift
//  Tsquare
//
//  Created by Prabhav Chawla on 8/24/17.
//  Copyright © 2017 Prabhav Chawla. All rights reserved.
//

import UIKit
import SwiftSoup

class GradebookViewController: UIViewController, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var gradebookObj: Gradebook!
    var scoreArr = [Score]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.tableFooterView = UIView.init(frame: .zero)
        tableView.allowsSelection = false
        
        if let scoreArr = gradebookObj.score as? [Score] {
            self.changeUI(isLoading: false)
            self.scoreArr = scoreArr
            return
        }
        
        self.changeUI(isLoading: true)
        self.getIframeSrc()
    }
    
    private func changeUI(isLoading: Bool) {
        activityIndicator.isHidden = !isLoading
        tableView.isHidden = isLoading
    }
    
    private func getIframeSrc() {
        networkRequest(request: URLRequest(url: gradebookObj.siteURL as! URL)) { (data, response) in
            do {
                let html = String(data: data, encoding: .utf8)
                let doc: Document = try SwiftSoup.parse(html!)
                let iframe: Element = try! doc.select("iframe").first()!
                let iframeSrc: String = try! iframe.attr("src")
                
                self.getIframeScores(URL(string: iframeSrc)!)
            }  catch {
                print("error")
            }
        }
    }
    
    private func getIframeScores(_ url: URL) {
        networkRequest(request: URLRequest(url: url)) { (data, response) in
            do {
                let html = String(data: data, encoding: .utf8)
                let doc: Document = try SwiftSoup.parse(html!)
                
                let tableRows: Elements = try! doc.select("tr")
                for tableRow in tableRows {
                    if tableRow.id().hasSuffix("hide_division_") {
                        let scoreElement: Element? = try tableRow.select("td.center + td.center").first()
                        let examScore = try scoreElement?.text()
                        let score = Score(examName: try (tableRow.select("td.left").first()?.text())!, examScore: examScore!)
                        self.scoreArr.append(score)
                    }
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.changeUI(isLoading: false)
                }
                
                CoreDataSingleton.shared.context.perform {
                    self.gradebookObj.score = self.scoreArr as NSObject
                    CoreDataSingleton.shared.saveContext()
                }
            } catch {
                print("error")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scoreArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.textLabel?.text = scoreArr[indexPath.row].examName
        cell.detailTextLabel?.text = scoreArr[indexPath.row].examScore
        return cell
    }
}
