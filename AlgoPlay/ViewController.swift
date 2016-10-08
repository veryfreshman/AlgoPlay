//
//  ViewController.swift
//  AlgoPlay
//
//  Created by Admin on 07.10.16.
//  Copyright © 2016 Vanoproduction. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let MAIN_COLOR:UIColor = UIColor(red: 7/255, green: 151/255, blue: 0, alpha: 1.0)
    let ROW_HEIGHT:CGFloat = 55
    
    var available_algo:[Int] = [0,1,2,3] // in rows
    var navBar:UINavigationBar!
    var algo_table_view:UITableView!
    var algoVC:AlgorithmViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController!.navigationBar.barTintColor = MAIN_COLOR
        navigationController!.navigationBar.barStyle = .Black
        navigationController!.navigationBar.tintColor = UIColor.whiteColor()
        navigationItem.title = "Algorithms"
        algoVC = self.storyboard!.instantiateViewControllerWithIdentifier("algo_vc") as! AlgorithmViewController
        navBar = self.navigationController!.navigationBar
        algo_table_view = UITableView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height), style: UITableViewStyle.Plain)
        algo_table_view.delegate = self
        algo_table_view.dataSource = self
        algo_table_view.rowHeight = ROW_HEIGHT
        view.addSubview(algo_table_view)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var main_text = "", detail_text = ""
        switch indexPath.row {
        case 0:
            main_text = "Prim's tree"
            detail_text = "Minimum spanning tree with random weights"
        case 1:
            main_text = "Random traversal"
            detail_text = "Random spanning tree"
        case 2:
            main_text = "Poisson Disc Sampling"
            detail_text = "Even points distribution with Bridson's algorithm"
        case 3:
            main_text = "Mitchell's Best Candidate"
            detail_text = "Even circle distribution"
        case 4:
            main_text = "Lloyd's Algorithm"
            detail_text = "Creating Voronoi diagram"
        case 5:
            main_text = "Array shuffle"
            detail_text = "Optimal Fisher-Yates algorithms"
        default:
            break
        }
        var ret_cell:UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("algo_cell")
        if ret_cell == nil {
            ret_cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "algo_cell")
        }
        ret_cell!.textLabel!.text = main_text
        ret_cell!.detailTextLabel!.text = detail_text
        ret_cell!.detailTextLabel!.textColor = UIColor.grayColor()
        return ret_cell!
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row <= 2 {
            cell.alpha = 1.0
        }
        else {
            cell.alpha = 0.5
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if indexPath.row <= 2 {
            var type = ""
            switch indexPath.row {
            case 0:
                type = "prim"
            case 1:
                type = "rand"
            case 2:
                type = "poisson"
            default:
                break
            }
            algoVC.prepareWithType(type)
            self.navigationController!.pushViewController(algoVC, animated: true)
        }
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.row >= 3 {
            return false
        }
        else {
            return true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

