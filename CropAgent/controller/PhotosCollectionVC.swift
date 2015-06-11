//
//  PhotosCollectionVC.swift
//  ImportImage
//
//  Created by bertrand DUPUY on 25/04/2015.
//  Copyright (c) 2015 bertrand DUPUY. All rights reserved.
//

import UIKit
import Photos

let reuseIdentifier = "Cell"

class PhotosCollectionVC: UICollectionViewController{
    
    var assets = [PHAsset]()
    var selectedAsset  :PHAsset?
    
    @IBOutlet weak var deniedMessageView: UIView!
    @IBOutlet weak var selectImgBtn: UIButton!
    
    var timerContainerView : UIView?
    
    var selectionLayer : CALayer?
    
    var selectedCell : UICollectionViewCell?{
        didSet{
            
            //suppression du layer indiquant l'état "sélectionné"
            selectionLayer?.removeFromSuperlayer()
            
            //ajout du layer
            if let selectedCell = selectedCell{
                
                let borderWidth = CGFloat(4)
                let parentBounds = selectedCell.contentView.layer.bounds
                
                selectionLayer = CALayer()
                selectionLayer!.frame = parentBounds
                selectionLayer!.borderWidth = borderWidth
                selectionLayer!.borderColor = UIColor(white: 1, alpha: 0.5).CGColor
                
                selectedCell.contentView.layer.addSublayer(selectionLayer)
            
            }
        }
    }
    
   
    override func viewDidLoad() {
        super.viewDidLoad()
       
        self.clearsSelectionOnViewWillAppear = false
        navigationController?.toolbarHidden = true
        self.navigationController?.navigationBarHidden = true

        // Register cell classes
        self.collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        
        // Gestion de l'affichage selon l'obtention ou pas du droit d'accès aux photos
        requestPhotosAutorization()
        
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

   

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        //#warning Incomplete method implementation -- Return the number of sections
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //#warning Incomplete method implementation -- Return the number of items in the section
        return assets.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! UICollectionViewCell
        
        //récupération de l'asset correspondant à la présente cell
        let tmpAsset = assets[indexPath.item]
        
        //définition des options de requete
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.FastFormat
        requestOptions.resizeMode = PHImageRequestOptionsResizeMode.Fast
        
        let manager = PHImageManager.defaultManager()
        
        //requete de l'image associée à l'asset désigné par l'indexPath
        manager.requestImageForAsset(tmpAsset, targetSize: cell.frame.size, contentMode: PHImageContentMode.AspectFill, options: requestOptions) { (image, _) -> Void in
            
            //affectation de l'image au layer de la cell
            if let resultImage = image{
                cell.layer.contents = image.CGImage
            }
        }
        
        return cell
    }
    
    
    //demande autorisation d'accéder à Photos
    func requestPhotosAutorization(){
    
        switch PHPhotoLibrary.authorizationStatus(){
            
        case .NotDetermined :
            //si autorisation pas encore obtenue, demande d'accès et affichage d'un spinner
            //en attendant la réponse de "Photos" qui peut être relativement longue à venir
            
            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
            activityIndicator.hidden = false
            view.addSubview(activityIndicator)
            activityIndicator.startAnimating()
            let label = UILabel(frame: CGRectZero)
            label.text = "validation de l'autorisation en cours..."
            label.font = label.font.fontWithSize(16)
            label.textColor = UIColor.lightTextColor()
            label.frame.size = label.intrinsicContentSize()
            
            let containerView = UIView(frame: CGRectZero)
            containerView.frame.size.width = label.frame.size.width
            containerView.frame.size.height = label.frame.size.height + 20 + activityIndicator.frame.height
            containerView.layer.opacity = 0
            
            activityIndicator.frame.origin = CGPoint(x: containerView.frame.midX - activityIndicator.frame.midX, y: containerView.frame.midY - activityIndicator.frame.midY + 20)
            
            containerView.addSubview(label)
            containerView.addSubview(activityIndicator)
            
            containerView.center = view.center
            view.addSubview(containerView)
            
            self.timerContainerView = containerView
            
            UIView.animateWithDuration(1, delay: 2, options: nil, animations: { () -> Void in
                containerView.layer.opacity = 1
                }, completion: nil)
            
            PHPhotoLibrary.requestAuthorization { (autorization) -> Void in
                
                self.timerContainerView!.removeFromSuperview()
                
                if autorization == .Denied{
                    //autorisation refusée
                    
                    //affichage d'une vue d'information
                    self.deniedMessageView.hidden = false
                    
                }else if autorization == .Authorized{
                    //autorisation accordée
                    
                    //récupération des assets, dataSource de la collectionView
                    self.initAssetsData()
                    self.navigationController?.navigationBarHidden = false
                }
            }
            
        case .Authorized :
            
            //récupération des assets, dataSource de la collectionView
            self.navigationController?.navigationBarHidden = false
            self.initAssetsData()
            
        default :
            self.deniedMessageView.hidden = false
        }

    }
    
    
    //récupere tous les assets de type image disponibles dans "Photos"
    func initAssetsData(){
    
        if let fetchResult = PHAsset.fetchAssetsWithMediaType(PHAssetMediaType.Image, options: nil){
            
            fetchResult.enumerateObjectsUsingBlock { (elt, index, test) -> Void in
                if let elt = elt as? PHAsset{
                    
                    //ajout de chaque elt à la dataSource de la collectionView
                    self.assets.append(elt)
                }
                
                self.collectionView?.reloadData()
                
            }
        }
    }
    
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "imageSelected"{
            
            SessionData.setImageAsset(self.selectedAsset!)
            SessionData.requestLowResResizedImage()
            
            
//            var sessionData = SessionData.sharedData.getCopy()
//            sessionData.imageAsset = self.selectedAsset!
//            sessionData.requestLowResResizedImage()
//            SessionData.updateData(sessionData)
//            
//            let test = SessionData.sharedData.getCopy()
            
//            println(test)
            
        }
    }
    
    
    
  //    func requestLowResResizedImage(asset : PHAsset){
//        
//        let manager = PHImageManager.defaultManager()
//        let options = PHImageRequestOptions()
//        options.synchronous = false
//        options.deliveryMode = PHImageRequestOptionsDeliveryMode.HighQualityFormat
//        options.resizeMode = PHImageRequestOptionsResizeMode.Exact
//        
//        let size : CGSize
//        
//        //si l'image est plus petite que 300 par 300, pas de redimensionnement
//        if selectedAsset?.pixelHeight < 300 && selectedAsset?.pixelWidth < 300{
//            size = CGSize(width: selectedAsset!.pixelHeight, height: selectedAsset!.pixelHeight)
//        }else{
//            //sinon sa taille est fixée à 10% de la taille originale
//            size = CGSize(width: CGFloat(selectedAsset!.pixelWidth)*0.1, height: CGFloat(selectedAsset!.pixelHeight)*0.1)
//        }
//        
//        manager.requestImageForAsset(selectedAsset, targetSize: size, contentMode: PHImageContentMode.AspectFit, options: options) { (image, infos) -> Void in
//            
//            if let asImage = image{
//                var sessionData = SessionData.sharedData.getCopy()
//                sessionData.imageAsset = self.selectedAsset!
//                sessionData.lowResResizedImage = asImage
//                SessionData.setAppData(sessionData)
//            }
//        }
//    }
    
    

    //gestion de la selection
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        let newSelectedCell = collectionView.cellForItemAtIndexPath(indexPath)
        
        if selectedCell == newSelectedCell{
            selectImgBtn.enabled = false
            selectedAsset = nil
            selectedCell = nil
            
        }else{
            selectImgBtn.enabled = true
            selectedAsset = assets[indexPath.item]
            selectedCell = newSelectedCell
        }
        
        return true
    }
}
