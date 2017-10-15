//
//  Score.swift
//  Tsquare
//
//  Created by Prabhav Chawla on 8/23/17.
//  Copyright © 2017 Prabhav Chawla. All rights reserved.
//
import Foundation

class Score: NSObject, NSCoding {
    var examName: String
    var examScore: String
    var categoryName: String
    
    init(examName: String, examScore: String, categoryName: String = "") {
        self.examName = examName
        self.examScore = examScore
        self.categoryName = categoryName
    }
    
    required init(coder decoder: NSCoder) {
        self.examName = decoder.decodeObject(forKey: "examName") as! String
        self.examScore = decoder.decodeObject(forKey: "examScore") as! String
        self.categoryName = decoder.decodeObject(forKey: "categoryName") as! String
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.examName, forKey: "examName")
        coder.encode(self.examScore, forKey: "examScore")
        coder.encode(self.categoryName, forKey: "categoryName")
    }
}
