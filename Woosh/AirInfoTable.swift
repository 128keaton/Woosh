//
//  AirInfoTable.swift
//  Woosh
//
//  Created by Keaton Burleson on 2/21/17.
//  Copyright © 2017 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
class AirInfoTable:UITableViewController{
    var airportData: [String: AnyObject]  = [:]
    override func viewDidLoad() {
        print(self.airportData)
        self.tableView.alwaysBounceVertical = false
        self.tableView.tableFooterView = UIView()
        self.tableView.allowsSelection = false
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let key = Array(airportData.keys)[indexPath.row]
        let detail = self.airportData[key]
        
        cell.textLabel?.text = key.titleized.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "Ft", with: "(ft)")
        cell.detailTextLabel?.text = (detail as! String?)
        print(key)
        return cell
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.airportData.keys.count
    }
}
