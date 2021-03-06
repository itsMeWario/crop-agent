//
//  FormatTableVC.swift
//  CropAgent
//
//  Created by bertrand DUPUY on 10/05/2015.
//  Copyright (c) 2015 bertrand DUPUY. All rights reserved.
//

import UIKit

class FormatTableVC: UITableViewController, UITableViewDelegate {
    
    var tableData = [FormatStruct]()
   
    @IBOutlet weak var formatSelected: UIButton!

    @IBAction func back(sender: UIBarButtonItem) {
        navigationController?.popViewControllerAnimated(true)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
        navigationItem.leftBarButtonItem?.image = UIImage(named: "imageCollection")
        tableData = Format.getAllFormats()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showMainVC"{
            var selectedItemIP = tableView.indexPathForSelectedRow()!
            SessionData.setFormat(tableData[selectedItemIP.item])
            SessionData.requestResizedImage({ (image : UIImage) -> Void in
                 //affecte l'image à la tiledView qui va pouvoir calculer le rendu de son CATiledLayer
                (segue.destinationViewController as! MainVC).mainView.tiledImageView.setImage(image, imageDef: ImageDefinition.highRes)
            })
        }
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("formatCell", forIndexPath: indexPath) as! FormatTableCell
        let tmpFormat = tableData[indexPath.item]
        
        cell.initContentView(UIImage(named: "a"+String(tmpFormat.type.rawValue))!, label: tmpFormat.typeLabel + " : " + tmpFormat.sizeLabel)
        
        return cell
    }

    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UIDevice.currentDevice().userInterfaceIdiom == .Phone ? 80 : (max(tableView.frame.width, tableView.frame.height) - topLayoutGuide.length - bottomLayoutGuide.length) / CGFloat(tableData.count)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
           formatSelected.enabled = true
    }
    
    override func viewDidLayoutSubviews() {
        navigationController?.hidesBarsOnTap = false
        navigationController?.toolbarHidden = false
    }
    
    
}
