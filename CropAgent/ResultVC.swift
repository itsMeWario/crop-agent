//
//  ResultVC.swift
//  ImportImage
//
//  Created by bertrand DUPUY on 27/04/2015.
//  Copyright (c) 2015 bertrand DUPUY. All rights reserved.
//

import UIKit
import Photos

class ResultVC: UIViewController, UIPrintInteractionControllerDelegate, UIPrinterPickerControllerDelegate{
   
    @IBOutlet weak var imageContainerWidth: NSLayoutConstraint!
    @IBOutlet weak var imageContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var  resultImageSize : CGSize?
    var  contentHasBeenSaved = false
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        navigationItem.setHidesBackButton(true, animated: false)
        navigationItem.setLeftBarButtonItem(UIBarButtonItem(image: UIImage(named: "backBtn"), style: UIBarButtonItemStyle.Plain, target: self, action: "closeMe:"), animated: false)
        
        loadToolBar()
        
        activityIndicator.hidden = true
    }
    
    func loadToolBar(){

        let flexibleEmptySpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        let fixedEmptySpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)

        fixedEmptySpace.width = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? 42 : 10
        var items = [UIBarButtonItem]()
        items.append(flexibleEmptySpace)
    
        let printBtn = UIBarButtonItem(image :UIImage(named: "printer"), style: UIBarButtonItemStyle.Plain, target: self, action: "imageforPrinters:")
        let saveBtn = UIBarButtonItem(image :UIImage(named: "save"), style: UIBarButtonItemStyle.Plain, target: self, action: "saveToPhotos:")

        items.append(printBtn)
        items.append(fixedEmptySpace)
        items.append(fixedEmptySpace)
        items.append(saveBtn)
        
        items.append(flexibleEmptySpace)
        setToolbarItems(items, animated: true)
    }
    
    
    @IBAction func saveToPhotos(sender: UIBarButtonItem) {
        
        if !contentHasBeenSaved{
            
            activityIndicator.startAnimating()
            activityIndicator.hidden = false
            contentHasBeenSaved = true
            
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
                
                let manager = PHImageManager.defaultManager()
                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = NSPredicate(format: "title = %@", argumentArray: ["tranbersApp"])
                let fetchResult = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)!
                let devicePpp = SessionData.sharedData.getCopy().devicePpp
                
                if let resultCollection = fetchResult.firstObject as? PHAssetCollection{
                    let collectionRequest = PHAssetCollectionChangeRequest(forAssetCollection: resultCollection)
                    let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(self.imageView.image!)
                    collectionRequest.addAssets([assetRequest.placeholderForCreatedAsset])
                }
                    
            }, completionHandler: { (finished, error) -> Void in
                
                self.activityIndicator.hidden = true
                self.activityIndicator.stopAnimating()
            })
        }
    }
    
    
    func setImage(image : UIImage){
    
        self.imageView.layer.opacity = 0
        imageView.image = image
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.imageView.layer.opacity = 1
        })
    }
    
    override func viewWillLayoutSubviews() {
        imageContainerWidth.constant = resultImageSize!.width
        imageContainerHeight.constant = resultImageSize!.height
        imageView.layoutIfNeeded()
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        let screenRatio = view.frame.width / view.frame.height
        let rotationScale :CGFloat = UIApplication.sharedApplication().statusBarOrientation.isPortrait ? 0.8 : 1.0/0.8
        imageContainerWidth.constant *= 1/screenRatio
        imageContainerHeight.constant *= 1/screenRatio
        
        imageView.superview!.layoutIfNeeded()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func closeMe(sender : UIBarButtonItem){
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        navigationController?.popViewControllerAnimated(true)
    }
    
    
    func printerPickerController(printerPickerController: UIPrinterPickerController, shouldShowPrinter printer: UIPrinter) -> Bool {
        return false
    }
    
        
    @IBAction func imageforPrinters(sender: UIBarButtonItem){
    
        if let image = imageView.image, let printController = UIPrintInteractionController.sharedPrintController(){
            
            printController.delegate = self
            
            printController.showsPaperSelectionForLoadedPapers = false
            printController.showsNumberOfCopies = false
            printController.printPageRenderer = PageRenderer(image: image)
            printController.printingItem = image
            
            let printInfo = UIPrintInfo.printInfo()
            printInfo.outputType = UIPrintInfoOutputType.Photo
            printInfo.orientation = image.size.width > image.size.height ? UIPrintInfoOrientation.Landscape : UIPrintInfoOrientation.Portrait
            printInfo.jobName = "aa"
            printController.printInfo = printInfo
            
            printController.presentFromBarButtonItem(sender, animated: true, completionHandler: { (completionHandler, completed, error) -> Void in
                if let error = error where completed == true {
                    println("Printing failed due to error in domain %@ with error code %lu. Localized description: %@, and failure reason: %@", error.domain, error.code, error.localizedDescription, error.localizedFailureReason )
                }else if completed{
                    println("print ok")
                }
            })
        }
    }
    
    
    func printInteractionController(printInteractionController: UIPrintInteractionController, choosePaper paperList: [AnyObject]) -> UIPrintPaper? {
        
        let pageSize = imageView.image!.size
        let paper = UIPrintPaper.bestPaperForPageSize(pageSize, withPapersFromArray: paperList)
        
        return paper
    }
    

}
