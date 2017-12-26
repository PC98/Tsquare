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
    @IBOutlet weak var activityLabel: UILabel!
    
    var gradebookObj: Gradebook!
    var scoresDict = [Int:[Score]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.tableFooterView = UIView.init(frame: .zero)
        tableView.allowsSelection = false
        tableView.rowHeight = 44;
        
        if let scoresDict = gradebookObj.score as? [Int:[Score]] {
            self.changeUI(isLoading: false)
            if scoresDict.count == 0 {
                noDataUI()
            } else {
                self.scoresDict = scoresDict
            }
            return
        }
        
        self.changeUI(isLoading: true, "Fetching Grades...")
        self.getIframeSrc()
    }
    
    private func noDataUI() {
        presentAlert(title: "No Data Found", message: "This class has no items in it's Gradebook.", presentingVC: self) {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func changeUI(isLoading: Bool, _ labelText: String? = nil) {
        activityIndicator.isHidden = !isLoading
        activityLabel.isHidden = !isLoading
        if let labelText = labelText {
            activityLabel.text = labelText
        }
        tableView.isHidden = isLoading
    }
    
    private func getIframeSrc() {
        let timer = Timer.scheduledTimer(withTimeInterval: 20, repeats: false, block: { (Timer) in
            self.activityLabel.text = "Slow or no internet connection..."
        })
        
        networkRequest(request: URLRequest(url: gradebookObj.siteURL as! URL)) { (data, response) in
            timer.invalidate()
            do {
                let html = String(data: data, encoding: .utf8)
                let doc: Document = try SwiftSoup.parse(html!)
                let iframe: Element = try! doc.select("iframe").first()!
                let iframeSrc: String = try! iframe.attr("src")
                
                self.getIframeScores(URL(string: iframeSrc)!)
            }  catch {
                fatalError("Error in getIframeSrc method: \(error)")
            }
        }
    }
    
    private func getIframeScores(_ url: URL) {
        let timer = Timer.scheduledTimer(withTimeInterval: 40, repeats: false, block: { (Timer) in
            self.activityLabel.text = "Slow or no internet connection..."
        })
        
        networkRequest(request: URLRequest(url: url)) { (data, response) in
            timer.invalidate()

            DispatchQueue.main.sync {
                self.activityLabel.text = "Processing data..."
            }
            do {
                let html = String(data: data, encoding: .utf8)
                let doc: Document = try SwiftSoup.parse(html!)

                let tableRows: Elements = try! doc.select("table.listHier.wideTable.lines tbody tr")
                
                var dictIndex = 0
                var currentCategory = ""
                
                for i in 0 ..< tableRows.size() {
                    let current_tableRow = tableRows.get(i)

                    if try current_tableRow.className().isEmpty && i < tableRows.size() - 1 && tableRows.get(i + 1).id().hasSuffix("hide_division_") {
                        
                        if self.scoresDict[dictIndex] != nil {
                            dictIndex += 1
                        }
                        currentCategory = try current_tableRow.select("span.categoryHeading").first()?.text() ?? ""
                        
                    } else if current_tableRow.id().hasSuffix("hide_division_") {
                        let scoreElement: Element? = try current_tableRow.select("td.center + td.center").first()
                        let examScore = try scoreElement?.text()
                        let score = Score(examName: try (current_tableRow.select("td.left").first()?.text())!, examScore: examScore!, categoryName: currentCategory)
                        
                        if self.scoresDict[dictIndex] == nil {
                            self.scoresDict[dictIndex] = [Score]()
                        }
                        self.scoresDict[dictIndex]!.append(score)
                    }
                }
                
                CoreDataSingleton.shared.context.perform {
                    self.changeUI(isLoading: false)
                    
                    if self.scoresDict.count == 0 {
                        self.noDataUI()
                    } else {
                        self.tableView.reloadData()
                    }
                    
                    self.gradebookObj.score = self.scoresDict as NSObject
                    CoreDataSingleton.shared.saveContext()
                }
            } catch {
                fatalError("Error in getIframeScores method: \(error)")
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! GradebookTableViewCell
        let scoreObj: Score = scoresDict[indexPath.section]![indexPath.row]
        cell.examName.text = scoreObj.examName
        cell.examScore.text = scoreObj.examScore
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return scoresDict.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scoresDict[section]!.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return scoresDict[section]![0].categoryName
    }
}
