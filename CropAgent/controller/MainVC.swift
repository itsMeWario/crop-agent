//
//  MainVC.swift
//  ImportImage
//
//  Created by bertrand DUPUY on 24/03/2015.
//  Copyright (c) 2015 bertrand DUPUY. All rights reserved.


import UIKit
import Photos




class MainVC: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate, UINavigationBarDelegate {
    
    @IBOutlet weak var mainView: MainView!
    
    var isTraitChangingAfterRotation = false
    var rotateReco : UIRotationGestureRecognizer?
    var rotationTransform = CGAffineTransformIdentity
//    var sessionData  = SessionData.sharedData.getCopy()
    var currentImageOrientation : UIPrintInfoOrientation?
    var initImageOrientation : UIPrintInfoOrientation?
    var mirrorApplied = false
    var ghostView : UIView?
//    var imageHighRes : UIImage?
//    var imageLowRes : UIImage?
    var imageTitle = ""
    
    
    var isLocked : Bool{
        didSet{
            mainView.isImageLocked = isLocked
        }
    }
    
    var appContextId :Int{
        didSet{
            mainView.scrollView.pinchGestureRecognizer?.enabled = appContextId == 1 ? true : false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sessionData = SessionData.sharedData.getCopy()
        
        //récupération du nom de l'asset
        let asset = sessionData.imageAsset!
        
        requestAssetName(asset, cbk: {
            self.navigationController?.toolbarHidden = false
            self.navigationController?.hidesBarsOnTap = true
        })
        
        currentImageOrientation = asset.pixelWidth > asset.pixelHeight ? UIPrintInfoOrientation.Landscape : .Portrait
        initImageOrientation = currentImageOrientation
        
        //initialisation du rotation recognizer
        rotateReco = UIRotationGestureRecognizer(target: self, action: "rotateGesture:")
        rotateReco?.enabled = false
        view.addGestureRecognizer(self.rotateReco!)
        
        //ajout d'une target au pinchGestureRecognizer de la scrollview pour compenser son action
        mainView.scrollView.pinchGestureRecognizer?.addTarget(self, action: "scrollPinchObserve:")
        
        //ajout d'une target au panGestureRecognizer de la scrollview
        mainView.scrollView.panGestureRecognizer.addTarget(self, action: "panObserve:")
        
        //désactivation du pinch recognizer
        self.mainView.scrollView.pinchGestureRecognizer?.enabled = false
        
        //désignation du délégué de la scrollview
        mainView.scrollView.delegate = self
        
        //affichage du format en arrière plan du modele
        mainView.formatLabel.text = sessionData.projectFormat?.typeLabel
        
        //initialosation du contexte
        self.updateContext(0)
        
        //création d'une collection dans "Photos" où seront enregistrés les rendus
        dispatch_async(GlobalBackgroundQueue) {
            self.createPhotosCollectionIfNeeded()
        }
    }
    
    
    //affichage du container affichant le rendu final
    @IBAction func showResultVC(sender: UIBarButtonItem) {
        
        //initialisation du controlleur
        let resultVC = self.storyboard?.instantiateViewControllerWithIdentifier("resultvc") as! ResultVC
        resultVC.resultImageSize = mainView.finalView.frame.size
        
        //affectation de l'image lowRes pour fluidifier l'affichage du rendu highres
        resultVC.lowResPreview = getRenderedImagePreview()
        
        self.navigationController?.pushViewController(resultVC, animated: true)

        //calcul du rendu dans un autre thread pour affichage highres asynchrone
        dispatch_async(GlobalBackgroundQueue) {
            
            self.renderImage({(image : UIImage) in
                resultVC.setImage(image)
            })
        }
    }
    
    
    //retourne une vue "snaphot" de l'image dans le modele
    func getRenderedImagePreview()->UIView{
    
        let finalViewInMainview =  mainView.convertRect(mainView.finalView.frame, fromView: mainView.finalView.superview)
        
        mainView.borderView.hidden = true
        mainView.finalBackgroundView.hidden = true
        
        //snapshot de la vue - si image contenue dans vue -> snapshot image sinon snapshot vue pour limiter sa taille
        let imageSnapshot = mainView.snapshotViewAfterScreenUpdates(true)
        imageSnapshot.frame.origin = CGPoint(x: -finalViewInMainview.origin.x, y: -finalViewInMainview.origin.y)

        mainView.finalView.addSubview(imageSnapshot)
        let resultSnapshot = mainView.finalView.snapshotViewAfterScreenUpdates(true)
        imageSnapshot.removeFromSuperview()
        
        mainView.finalBackgroundView.hidden = false
        mainView.borderView.hidden = false
        
        return resultSnapshot
        
    }
    
    
    
    
    //Déplace l'image pour la center ou l'aligner avec le modele
    @IBAction func alignmentRequired(asBtn: UIBarButtonItem) {
        
        let aligmentTypeId = asBtn.tag
        let alignmentType = ImageAlignment(rawValue: aligmentTypeId)!
        let isHorizontallyAligned = alignmentType == .leftAlignment || alignmentType == .rightAlignment
        let isHorizontallyCentered = alignmentType == .horizontalCenterAlignment
        let isNewAlignmentHorizontal = isHorizontallyAligned || isHorizontallyCentered
        
        let axisAlignment = isNewAlignmentHorizontal ? AlignmentAxis.horizontal : AlignmentAxis.vertical
        
        //si l'image est "bloquée", les vues d'alignment sont animées pour le signifier
        if (mainView.isHorizontalAlignmentLocked &&  axisAlignment == .horizontal) || (mainView.isVerticalAlignmentLocked &&  axisAlignment == .vertical){
            
            let alignmentView = axisAlignment == .horizontal ? mainView.verticalAlignmentView : mainView.horizontalAlignmentView
            mainView.animateAlignmentViewSizeChange(alignmentView)
        
        }else if mainView.targetAlignment[axisAlignment] != alignmentType{
            // sinon l'image est animée et déplacée vers sa nouvelle position
            
            view.userInteractionEnabled = false
            
            //affiche la vue d'alignement
            mainView.showAlignmentView(mainView.borderView, animated : true, alignmentType: alignmentType, cbk : nil)
            
            //anime l'image vers sa nouvelle position
            mainView.animateAlignment(alignmentType, cbk: {
                
                //conserve la valeur de l'alignement actuel
                self.mainView.targetAlignment[axisAlignment] = alignmentType
                
                self.view.userInteractionEnabled = true
                
                //le boutopn cadenas devient actif
                self.navigationItem.rightBarButtonItem?.enabled = true
                
            })
        }
    }
    
    // bloque ou débloque l'image
    @IBAction func lockImage(btn : UIBarButtonItem){
        
        isLocked = !isLocked
        
        if isLocked{
            
            //si l'état du blocage est actif, les contraintes d'alignement
            //appliquées sont récupérées, activées, et le layout de la scrollview est modifié en conséquence
            
            if mainView.verticalAlignmentEnabled{
                mainView.updateScrollviewLayout(mainView.targetAlignment[AlignmentAxis.vertical]!)
                mainView.horizontalAlignmentView?.backgroundColor = mainView.alignmentViewLockedColor
                mainView.isVerticalAlignmentLocked = true
            }
            
            if mainView.horizontalAlignmentEnabled{
                mainView.updateScrollviewLayout(mainView.targetAlignment[AlignmentAxis.horizontal]!)
                mainView.verticalAlignmentView?.backgroundColor = mainView.alignmentViewLockedColor
                mainView.isHorizontalAlignmentLocked = true
            }
        
        }else{
            
            //si l'état du blocage est inactif, les contraintes d'alignement
            //sont désactivées, et le layout de la scrollview est réinitialisé
            
            mainView.updateScrollviewLayout(nil)
            
            mainView.verticalAlignmentView?.backgroundColor = UIColor(white: 0.9, alpha: 1)
            mainView.horizontalAlignmentView?.backgroundColor = UIColor(white: 0.9, alpha: 1)

            mainView.isHorizontalAlignmentLocked = false
            mainView.isVerticalAlignmentLocked = false
            
        }
        
        //activation ou désactivation du bouton de blocage de l'image
        let imageBtn = isLocked ? UIImage(named: "lockOn")! : UIImage(named: "lockOff")!
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: imageBtn, style: UIBarButtonItemStyle.Plain, target: self, action: "lockImage:")
        
    }
    
    
    //requete le nom de l'asset
    func requestAssetName(asset : PHAsset, cbk : (()->Void)?){
        
        let manager = PHImageManager.defaultManager()
        let options = PHImageRequestOptions()
        options.synchronous = false
        
        manager.requestImageDataForAsset(asset, options: options, resultHandler: { (data, dataUTI, orientation, infos) -> Void in
            
            if let infos = infos, let asNSURL = infos["PHImageFileURLKey"] as? NSURL, let elts = asNSURL.pathComponents as? [String] where elts.last != nil && elts.last != ""{
                
                self.navigationItem.title = elts.last!
                self.imageTitle = elts.last!
                
                if cbk != nil{
                    cbk!()
                }
            }
        })
    }

    
    
    //controle si une rotation peut être aplliquée à l'image
    func prepareRotateTransform(angle : CGFloat){
    
        //si une animation n'est pas déjà en cours
        if view.userInteractionEnabled{
            
            //déclenchement de la rotation
            if !isLocked || mainView.isImageRotationEnabled{
                
                view.userInteractionEnabled = false
                let transform = CGAffineTransformMakeRotation(angle)
                
                rotationTransform = CGAffineTransformConcat(rotationTransform, transform)
                
                self.applyTransformToImage(transform, isRotation : true)
                
            }else{
              //si rotation impossible, animation des vues d'alignement pour le signifier
                if mainView.verticalAlignmentView != nil{
                    mainView.animateAlignmentViewSizeChange(mainView.verticalAlignmentView!)
                }
                
                if mainView.horizontalAlignmentView != nil{
                    mainView.animateAlignmentViewSizeChange(mainView.horizontalAlignmentView!)
                }
            }
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        isLocked = false
        appContextId = 0
        super.init(coder: aDecoder)
    }
    
    
    @IBAction func preprareMirrorTransform(sender: UIBarButtonItem){
        
        if self.view.userInteractionEnabled{
            
            mirrorApplied = !mirrorApplied
            
            self.view.userInteractionEnabled = false
            
            let transform :CGAffineTransform
            
            if sender.tag == AlignmentAxis.horizontal.rawValue{
                transform = CGAffineTransformMakeScale(1, -1)
            }else{
                transform = CGAffineTransformMakeScale(-1, 1)
            }
            
            rotationTransform = CGAffineTransformConcat(rotationTransform, transform)
            
            self.applyTransformToImage(transform, isRotation : false)
            
        }
    }

    
    
    //répond à la demande de rotation faite par l'utilisateur en tournant directement l'image
    func rotateGesture(sender : UIRotationGestureRecognizer){
        if sender.state == .Began{
            let angle = CGFloat(Double(sender.rotation/abs(sender.rotation))*M_PI_2)
            prepareRotateTransform(angle)
        }
    }
    
    
    //répond à la demande de rotation faite par l'utilisateur en appuyant sur l'un des btns
    @IBAction func rotateActionBtn(sender : UIBarButtonItem){
        let angle :CGFloat
    
        if sender.tag == 0{ //clockwise
            angle = CGFloat(M_PI_2)
        }else{
            angle = -CGFloat(M_PI_2)
        }
        prepareRotateTransform(angle)
    }
    
    
    //créé si nécessaire une collection dans l'application "Photos" afin d'y stocker les photos rendues par l'application
    func createPhotosCollectionIfNeeded(){
        
        let manager = PHImageManager.defaultManager()
        
        //options de la requete
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", argumentArray: ["tranbersApp"])
        let fetchResult = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.Album, subtype: PHAssetCollectionSubtype.SmartAlbumUserLibrary, options: fetchOptions)
        
        //si aucun résultat, la collection est créée
        if fetchResult.count == 0{
            
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
                
                let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle("tranbersApp")
                let albumPlaceHolder = request.placeholderForCreatedAssetCollection
                
                }, completionHandler: nil
            )
        }
    }
    
    
    //redimensionne l'image de sorte à ce que sa largeur ou sa longueur soit égale à celle du modele
    @IBAction func changeAspectSize(sender: UIBarButtonItem){
        
        let finalViewInView = self.mainView.convertRect(self.mainView.finalView.frame, fromView: self.mainView.finalView.superview)
        let imageViewInView = self.mainView.convertRect(self.mainView.tiledImageView.frame, fromView: self.mainView.tiledImageView.superview)
        let targetRatio = finalViewInView.width / finalViewInView.height
        
        //multiplicateur à appliquer aux dimensions de l'image
        let zoomScale = sender.tag == AspectSizeChange.equalHeight.rawValue ? finalViewInView.height / imageViewInView.height : finalViewInView.width / imageViewInView.width
        
        //bloque les intéractions utilisateur le tps d'animer le redimensionnement
        view.userInteractionEnabled = false
        
        //suppression des repères d'alignement si l'image n'est pas bloquée
        if !isLocked{
            mainView.targetAlignment[AlignmentAxis.vertical]! = .none
            mainView.targetAlignment[AlignmentAxis.horizontal]! = .none
        }
       
        UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions.BeginFromCurrentState, animations:  { () -> Void in
            
            self.mainView.scrollView.zoomScale *= zoomScale
            
            //mise à jour des contraintes autolayout de la scrollviewx
            if self.isLocked && self.mainView.horizontalAlignmentEnabled{
                self.mainView.scrollViewWidth.constant *= zoomScale
                if self.mainView.targetAlignment[AlignmentAxis.horizontal] == .rightAlignment{
                    self.mainView.scrollViewCenterX.constant -= (self.mainView.tiledImageView.frame.width - imageViewInView.width)*0.5
                }else if self.mainView.targetAlignment[AlignmentAxis.horizontal] == .leftAlignment{
                    self.mainView.scrollViewCenterX.constant += (self.mainView.tiledImageView.frame.width - imageViewInView.width)*0.5
                }
            }
            
            if self.isLocked && self.mainView.verticalAlignmentEnabled{
                self.mainView.scrollViewHeight.constant *= zoomScale
                if self.mainView.targetAlignment[AlignmentAxis.vertical] == .bottomAlignment{
                    self.mainView.scrollViewCenterY.constant -= (self.mainView.tiledImageView.frame.height - imageViewInView.height)*0.5
                }else if self.mainView.targetAlignment[AlignmentAxis.vertical] == .topAlignment{
                    self.mainView.scrollViewCenterY.constant += (self.mainView.tiledImageView.frame.height - imageViewInView.height)*0.5
                }
            }
            
            self.mainView.scrollView.layoutIfNeeded()

            
        }) { (finished) -> Void in
            
            //déblocage des intéractions utilisateur
            self.view.userInteractionEnabled = true
        }
    }
    
    
    
    //applique une transformation affine de type rotation ou scale négatif à vue affichant l'image highRes (tiledView)
    //pour ne pas "casser" le fonctionnement normal de la scrollview, la vue à transformer est déplacée hors de la scrollview
    //avant d'y revenir une fois la transformation terminée
    func applyTransformToImage(transform : CGAffineTransform, isRotation : Bool){
        
        let sessionData = SessionData.sharedData.getCopy()
        
        let tiledViewInMainView = self.mainView.convertRect(self.mainView.tiledImageView.tiledView!.frame, fromView: self.mainView.tiledImageView.tiledView!.superview)
        let zoomScale = self.mainView.scrollView.zoomScale
        let scaleTransform = CGAffineTransformMakeScale(zoomScale, zoomScale)
        
        //taille de l'image après transformation
        var newImageSize = (!isRotation && initImageOrientation != currentImageOrientation) || (isRotation && initImageOrientation == currentImageOrientation) ? CGSize(width: mainView.initResizedImageSize!.height, height: mainView.initResizedImageSize!.width) : mainView.initResizedImageSize!
        
        //modification de l'image lowRes pour la conformer à la transformation
        self.mainView.tiledImageView.image = UIImage(CGImage: transformImage(newImageSize, image: sessionData.lowResResizedImage!, transform: rotationTransform))!
       
        //transformation affine supplémentaire appliquée à la vue porteuse de l'image de si l'effet "mirror" est appliqué
        if (isRotation &&  (mirrorApplied)) ||  (!isRotation && initImageOrientation != currentImageOrientation){
            self.mainView.tiledImageView.tiledView!.transform = CGAffineTransformConcat(self.mainView.tiledImageView.tiledView!.transform, CGAffineTransformMakeScale(-1, -1))
        }
        
        self.mainView.tiledImageView.tiledView!.transform = CGAffineTransformConcat(self.mainView.tiledImageView.tiledView!.transform, scaleTransform)
        
        //masquage de l'image lowRes le tps de la transformation et redimensionnement de cette dernière
        self.mainView.tiledImageView.hidden = true
        self.mainView.tiledImageView.frame.size = CGSize(width: newImageSize.width*mainView.scrollView.zoomScale, height: newImageSize.height*mainView.scrollView.zoomScale)
        
        //déplacement de l'image highRes de sa vue parent le tps de la transformation
        self.mainView.tiledImageView.tiledView!.frame.origin = tiledViewInMainView.origin
        self.mainView.insertSubview(self.mainView.tiledImageView.tiledView!, belowSubview: mainView.scrollView)
        
        UIView.animateWithDuration(0.5, delay: 0, options: nil, animations: { () -> Void in
            
            self.mainView.tiledImageView.tiledView!.layer.transform = CATransform3DConcat(self.mainView.tiledImageView.tiledView!.layer.transform, CATransform3DMakeAffineTransform(transform))
            
        }, completion: { (finished) -> Void in
            
            let newTiledViewCenter = self.mainView.convertPoint(self.mainView.tiledImageView.tiledView!.center, fromView: self.mainView.tiledImageView.tiledView!.superview)
            
            //si les dimensions de l'image ont changé
            if isRotation{
                self.mainView.scrollView.contentSize = CGSize(width: newImageSize.width*zoomScale, height: newImageSize.height*zoomScale)
                
                if self.isLocked{
                    if self.mainView.isHorizontalAlignmentLocked{
                        self.mainView.updateScrollviewLayout(self.mainView.targetAlignment[AlignmentAxis.horizontal]!)
                    }
                    
                    if self.mainView.isVerticalAlignmentLocked{
                        self.mainView.updateScrollviewLayout(self.mainView.targetAlignment[AlignmentAxis.vertical]!)
                    }
                }
            }
            
            self.mainView.tiledImageView.frame.size = self.mainView.scrollView.contentSize
            
            if !self.mainView.horizontalAlignmentEnabled{
                self.mainView.scrollView.contentOffset.x = -self.mainView.tiledImageView.tiledView!.frame.origin.x
            }
            
            if !self.mainView.verticalAlignmentEnabled{
                self.mainView.scrollView.contentOffset.y = -self.mainView.tiledImageView.tiledView!.frame.origin.y
            }
            
            //replacement de l'image highres dans son conteneur d'origine
            self.mainView.tiledImageView.tiledView!.removeFromSuperview()
            self.mainView.tiledImageView.tiledView!.transform = CGAffineTransformConcat(self.mainView.tiledImageView.tiledView!.transform, CGAffineTransformInvert(scaleTransform))
            self.mainView.tiledImageView.addSubview(self.mainView.tiledImageView.tiledView!)
            self.mainView.tiledImageView.tiledView!.frame.origin = CGPointZero
            
            //affichage de l'image lowres en arrière plan
            self.mainView.tiledImageView.hidden = false
            
            //actualisation de l'orientation de l'image
            self.currentImageOrientation = self.mainView.tiledImageView.frame.size.width > self.mainView.tiledImageView.frame.size.height ? .Landscape : .Portrait

            
            self.view.userInteractionEnabled = true
        })
    }
    
   
    
    //retourne un CGRect normalisé du rectangle d'intersaction ramené au modele
    var normalizedIntersection : CGRect{
        
        let imageViewInFinalView = mainView.finalView.convertRect(mainView.tiledImageView.frame, fromView: mainView.tiledImageView.superview)
        let imageViewInView = mainView.convertRect(mainView.tiledImageView.frame, fromView: mainView.tiledImageView.superview)
        let finalViewInView = mainView.convertRect(mainView.finalView.frame, fromView: mainView.finalView.superview)
        let intersection = CGRectIntersection(finalViewInView, imageViewInView)

        let normalizedIntersectionOrigin = CGPoint(x: imageViewInFinalView.origin.x > 0 ? imageViewInFinalView.origin.x / finalViewInView.width : 0, y: imageViewInFinalView.origin.y > 0 ? imageViewInFinalView.origin.y / finalViewInView.height : 0)
        let normalizedInsectionSize = CGSize(width: intersection.width / finalViewInView.width, height: intersection.height / finalViewInView.height)
        let normalizedIntersion = CGRect(origin: normalizedIntersectionOrigin, size: normalizedInsectionSize)
        
        return normalizedIntersion
    }
    
    
    //retourne un CGRect normalisé du rectangle d'intersaction ramené à l'image
    var normalizedCropedImageRect : CGRect{
    
        let imageViewInFinalView = mainView.finalView.convertRect(mainView.tiledImageView.frame, fromView: mainView.tiledImageView.superview)
        let imageViewInView = mainView.convertRect(mainView.tiledImageView.frame, fromView: mainView.tiledImageView.superview)
        let finalViewInView = mainView.convertRect(mainView.finalView.frame, fromView: mainView.finalView.superview)
        let intersection = CGRectIntersection(finalViewInView, imageViewInView)

        let cropedRectOrigin = CGPoint(x: imageViewInFinalView.origin.x > 0 ? 0 : -imageViewInFinalView.origin.x, y : imageViewInFinalView.origin.y > 0 ? 0 : -imageViewInFinalView.origin.y)
        let cropedRectSize = intersection.size
        let resizedCropedRect = CGRect(origin: cropedRectOrigin, size: cropedRectSize)
        let normalizedCropedImageRect = CGRectApplyAffineTransform(resizedCropedRect, CGAffineTransformMakeScale(1.0 / imageViewInFinalView.width, 1.0 / imageViewInFinalView.height))

        return normalizedCropedImageRect
       
    }
        
    
    //calcul du rendu final en "croppant" l'image à l'intersection du modele
    //avant d'appliquer les transformations voulues par l'utilisateur
    func renderImage(cbk : ((image : UIImage)->Void)?){
        
        let sessionData = SessionData.sharedData.getCopy()
        
        let screenScale = UIScreen.mainScreen().scale
        let targetSize = sessionData.projectSize
        let finalViewInView = mainView.convertRect(mainView.finalView.frame, fromView: mainView.finalView.superview)
        
        //récupération de l'image à ses dimensions d'origine
        let manager = PHImageManager.defaultManager()
        let options = PHImageRequestOptions()
        options.synchronous = false
        options.resizeMode = PHImageRequestOptionsResizeMode.Fast
      
        manager.requestImageForAsset(sessionData.imageAsset, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.AspectFit, options: options) { (image, _) -> Void in

            if let initImage = image {
                
                let transformedImageSize = self.currentImageOrientation == self.initImageOrientation ? initImage.size : CGSize(width: initImage.size.height, height: initImage.size.width)
                let transformedImage = UIImage(CGImage: self.transformImage(transformedImageSize, image: initImage, transform: self.rotationTransform))!
                let zoomScale = self.mainView.scrollView.zoomScale
                
                var contextSize = CGSize(width: self.normalizedCropedImageRect.width*transformedImage.size.width, height: self.normalizedCropedImageRect.height*transformedImage.size.height)
                
                UIGraphicsBeginImageContext(contextSize)
                var ctx = UIGraphicsGetCurrentContext()
                
                transformedImage.drawInRect(CGRect(origin: CGPoint(x: -self.normalizedCropedImageRect.origin.x*transformedImage.size.width, y: -self.normalizedCropedImageRect.origin.y*transformedImage.size.height), size: transformedImage.size))
                
                //portion croppée de l'image
                let resImage = UIImage(CGImage: CGBitmapContextCreateImage(ctx))!
                
                UIGraphicsEndImageContext()
                
                contextSize = finalViewInView.width == self.mainView.resizedProjectSize?.width ? targetSize : CGSize(width: targetSize.height, height: targetSize.width)
                
                UIGraphicsBeginImageContext(contextSize )
                ctx = UIGraphicsGetCurrentContext()
                
                CGContextSetFillColorWithColor(ctx, UIColor.whiteColor().CGColor)
                CGContextFillRect(ctx, CGContextGetClipBoundingBox(ctx))
                
                //tracé de la portion d'image dont les dimensions et la position se conforme au rectangle normalisé
                resImage.drawInRect(CGRect(origin: CGPoint(x: self.normalizedIntersection.origin.x*contextSize.width, y: self.normalizedIntersection.origin.y*contextSize.height), size: CGSize(width: self.normalizedIntersection.width*contextSize.width, height: self.normalizedIntersection.height*contextSize.height)))
                
                let finalRes = UIImage(CGImage: CGBitmapContextCreateImage(ctx))!
                UIGraphicsEndImageContext()
                
                if cbk != nil{
                    cbk!(image: finalRes)
                }
            }
        }
    }


    
    
    //applique une transformation affine à une image et retourne l'image résultante
    func transformImage(finalSize : CGSize, image : UIImage, transform : CGAffineTransform) ->CGImageRef{
        
        let initWidth : CGFloat?
        let initHeight : CGFloat?
        
        let nextOrientation = finalSize.width > finalSize.height ? UIPrintInfoOrientation.Landscape : .Portrait
        
        if initImageOrientation == nextOrientation{
            
            initWidth = finalSize.width
            initHeight = finalSize.height
            
        }else{
            
            initWidth = finalSize.height
            initHeight = finalSize.width
        }
        
        UIGraphicsBeginImageContext(finalSize)
        let ctx = UIGraphicsGetCurrentContext()
        
        CGContextTranslateCTM(ctx, finalSize.width*0.5, finalSize.height*0.5)
        CGContextConcatCTM(ctx, transform)
        
        image.drawInRect(CGRect(origin: CGPoint(x: -initWidth!*0.5, y: -initHeight!*0.5), size: CGSize(width: initWidth!, height: initHeight!)))
        
        var resultImage = CGBitmapContextCreateImage(ctx)
        
        UIGraphicsEndImageContext()
        
        return resultImage
    }
    
   

    override func viewDidAppear(animated: Bool) {
//        imageHighRes = mainView.tiledImageView.tiledView?.image
//        imageLowRes = mainView.tiledImageView.image
    }
    
    
    //mise à jour du context
    func updateContext(contextId : Int){
        appContextId = contextId
        loadToolBar(appContextId)
        updateNavigationItem(appContextId)
    }
    
    
    //mise à jour du navigationItem selin le context
    func updateNavigationItem(contextId : Int){
        
        let idiom = UIDevice.currentDevice().userInterfaceIdiom
        let horizontalSizeClass = traitCollection.horizontalSizeClass
        
        if contextId != 0{
            
            navigationItem.rightBarButtonItems = []
            
            if contextId == 1{
                self.navigationItem.title = "Dimension"
            }else if contextId == 2{
                self.navigationItem.title = "Rotation"
            }else{
                if contextId == 3{
                    
                    navigationController?.navigationItem.title = "Alignement"
                    self.navigationItem.title = "Alignement"
                    
                }else{
                    self.navigationItem.title = "Centrage"
                }
            }
            
            let lockImage = self.isLocked ? UIImage(named: "lockOn") : UIImage(named: "lockOff")
            let lockBtn = UIBarButtonItem(image: lockImage, style: UIBarButtonItemStyle.Plain, target: self, action: "lockImage:")
            lockBtn.enabled = mainView.targetAlignment[AlignmentAxis.vertical]! != .none || mainView.targetAlignment[AlignmentAxis.horizontal]! != .none ? true  : false
            
            navigationItem.rightBarButtonItems = [lockBtn]
            navigationItem.leftBarButtonItem?.image = UIImage(named: "backBtn")
            
        }else{
            
            self.navigationItem.title = imageTitle
            navigationItem.leftBarButtonItem?.image = UIImage(named: "formatList")
            let exportBtn = UIBarButtonItem(image: UIImage(named: "export"), style: UIBarButtonItemStyle.Plain, target: self, action: "showResultVC:")
            navigationItem.rightBarButtonItems = [exportBtn]
        }
    }
    
    //mise à jour de la toolbar selon le context
    func loadToolBar(contextId : Int){
                   
            let flexibleEmptySpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
            let fixedEmptySpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
            
            fixedEmptySpace.width = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? 42 : 10
            
            var items = [UIBarButtonItem]()
            items.append(flexibleEmptySpace)
            
            switch(contextId){
                
            case 0 : //main
                
                let resize = UIBarButtonItem(image: UIImage(named: "resize"), style: UIBarButtonItemStyle.Plain, target: self, action: "changeAppContextAction:")
                resize.tag = 1
                let rotate = UIBarButtonItem(image: UIImage(named: "rotate"), style: UIBarButtonItemStyle.Plain, target: self, action: "changeAppContextAction:")
                rotate.tag = 2
                let align = UIBarButtonItem(image: UIImage(named: "crop"), style: UIBarButtonItemStyle.Plain, target: self, action: "changeAppContextAction:")
                align.tag = 3
                let center = UIBarButtonItem(image: UIImage(named: "center"), style: UIBarButtonItemStyle.Plain, target: self, action: "changeAppContextAction:")
                center.tag = 4
                
                items.append(align)
                items.append(fixedEmptySpace)
                items.append(fixedEmptySpace)
                items.append(center)
                items.append(fixedEmptySpace)
                items.append(fixedEmptySpace)
                items.append(resize)
                items.append(fixedEmptySpace)
                items.append(fixedEmptySpace)
                items.append(rotate)
                
            case 1 : //resize
                
                let aspectFit = UIBarButtonItem(image: UIImage(named: "aspectFit"), style: UIBarButtonItemStyle.Plain, target: self, action: "changeAspectSize:")
                aspectFit.tag = 0
                let aspectFill = UIBarButtonItem(image: UIImage(named: "aspectFill"), style: UIBarButtonItemStyle.Plain, target: self, action: "changeAspectSize:")
                aspectFill.tag = 1
                
                items.append(aspectFill)
                items.append(fixedEmptySpace)
                items.append(fixedEmptySpace)
                items.append(aspectFit)
                
            case 2 : //rotate
                
                let horizontalMirror = UIBarButtonItem(image :UIImage(named: "horizontalMirror"), style: UIBarButtonItemStyle.Plain, target: self, action: "preprareMirrorTransform:")
                horizontalMirror.tag = AlignmentAxis.horizontal.rawValue
                let verticalMirror = UIBarButtonItem(image :UIImage(named: "verticalMirror"), style: UIBarButtonItemStyle.Plain, target: self, action: "preprareMirrorTransform:")
                verticalMirror.tag = AlignmentAxis.vertical.rawValue
                let rotateAntiClockwise = UIBarButtonItem(image :UIImage(named: "turnLeft"), style: UIBarButtonItemStyle.Plain, target: self, action: "rotateActionBtn:")
                rotateAntiClockwise.tag = 1
                let rotateClockwise = UIBarButtonItem(image :UIImage(named: "turnRight"), style: UIBarButtonItemStyle.Plain, target: self, action: "rotateActionBtn:")
                rotateClockwise.tag = 0
                
                items.append(rotateClockwise)
                items.append(fixedEmptySpace)
                items.append(fixedEmptySpace)
                items.append(horizontalMirror)
                items.append(fixedEmptySpace)
                items.append(fixedEmptySpace)
                items.append(verticalMirror)
                items.append(fixedEmptySpace)
                items.append(fixedEmptySpace)
                items.append(rotateAntiClockwise)
                
            case 3 : //align
                
                let btnImage = UIImage(named: "top")!
                let btnSize = CGSize(width: bottomLayoutGuide.length, height: bottomLayoutGuide.length)
                
                let left = UIBarButtonItem(image :UIImage(named: "right"), style: UIBarButtonItemStyle.Plain, target: self, action: "alignmentRequired:")
                left.tag = ImageAlignment.leftAlignment.rawValue
                
                let top = UIBarButtonItem(image :UIImage(named: "bottom"), style: UIBarButtonItemStyle.Plain, target: self, action: "alignmentRequired:")
                top.tag = ImageAlignment.topAlignment.rawValue
                
                let right = UIBarButtonItem(image :UIImage(named: "left"), style: UIBarButtonItemStyle.Plain, target: self, action: "alignmentRequired:")
                right.tag = ImageAlignment.rightAlignment.rawValue
                
                let bottom = UIBarButtonItem(image :UIImage(named: "top"), style: UIBarButtonItemStyle.Plain, target: self, action: "alignmentRequired:")
                bottom.tag = ImageAlignment.bottomAlignment.rawValue
                
                items.append(left)
                items.append(fixedEmptySpace)
                items.append(fixedEmptySpace)
                items.append(top)
                items.append(fixedEmptySpace)
                items.append(fixedEmptySpace)
                items.append(bottom)
                items.append(fixedEmptySpace)
                items.append(fixedEmptySpace)
                items.append(right)
                
            case 4 : //center
                
                let centerX = UIBarButtonItem(image :UIImage(named: "centerV"), style: UIBarButtonItemStyle.Plain, target: self, action: "alignmentRequired:")
                centerX.tag = ImageAlignment.horizontalCenterAlignment.rawValue
                
                let centerY = UIBarButtonItem(image :UIImage(named: "centerH"), style: UIBarButtonItemStyle.Plain, target: self, action: "alignmentRequired:")
                centerY.tag = ImageAlignment.verticalCenterAlignment.rawValue
                
                items.append(centerX)
                items.append(fixedEmptySpace)
                items.append(fixedEmptySpace)
                items.append(centerY)
                
                
            default : //home
                println("home")
            }
            
            items.append(flexibleEmptySpace)
            self.setToolbarItems(items, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()

        
        //si le layout s'actualise suite à une rotation du device
        if mainView.initInterfaceOrientation != nil && isTraitChangingAfterRotation{
            
            //demande une mise à jour du layout de mainView
            mainView.updateLayoutForSizeTransition(view.bounds)
            isTraitChangingAfterRotation = false
            
        }else if mainView.initInterfaceOrientation == nil{ //si initialisation du controlleur
            
            let sessionData = SessionData.sharedData.getCopy()
            
            let test = sessionData.resizedProjectSize
        
            mainView.initAppInterface(view.bounds, resizedImageSize : sessionData.resizedImageSize, resizedModelSize : test, lowResImage : sessionData.lowResResizedImage!)
        }
        
        
        self.mainView.scrollView.pinchGestureRecognizer?.enabled = appContextId == 1 ? true : false

       
    }


    
     override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        isTraitChangingAfterRotation = true
        
        //calcul de l'offset après rotation pour que l'image reste positionnée par rapport au modele
        let imageViewInMainView = mainView.convertPoint(mainView.tiledImageView.center, fromView: mainView.tiledImageView.superview)
        let imageRect = mainView.tiledImageView.frame
        let finalRect = mainView.finalView.frame
        let newFinalRect = CGRect(x: finalRect.origin.y, y: finalRect.origin.x, width: finalRect.height, height: finalRect.width)
        let centerOffset = CGPoint(x: imageViewInMainView.x - finalRect.midX, y: imageViewInMainView.y - finalRect.midY)
        let newImageCenter = CGPoint(x: newFinalRect.midX + centerOffset.x, y: newFinalRect.midY + centerOffset.y)
        let offset = CGPoint(x: -(newImageCenter.x - imageRect.midX), y: -(newImageCenter.y - imageRect.midY))
        
        mainView.contentOffset = offset
        
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    }

    
    
    @IBAction func popVC(sender: UIBarButtonItem) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func changeAppContextAction(sender: UIBarButtonItem) {
        updateContext(sender.tag)
    }
    
    //permet d'observer le pinchGestureRecognizer la scrollView et 
    //d'adapter le layout lorsque des contraintes d'alignement sont appliquées
    func scrollPinchObserve(sender : UIPinchGestureRecognizer){
        if sender.state == .Began || sender.state == .Changed{
            mainView.adaptContraintsWhileZoomingManually()
        }
    }
    
    func panObserve(sender : UIPanGestureRecognizer){
        
        
    }
    
    
    //
    //scrollView delegate
    //
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView!, atScale scale: CGFloat) {
       mainView.tiledImageView.tiledView?.setNeedsDisplayInRect(CGRect(origin: CGPointZero, size: CGSize(width: 500, height: 500)))
    }
    
    func scrollViewWillBeginZooming(scrollView: UIScrollView, withView view: UIView!) {
        if appContextId == 1{
            mainView.currentImageSize = view.frame.size
        }
    }
    
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        
        //les vues d'alignement sont supprimées si l'image est libre de tout mouvement
        if !isLocked{
        
            self.mainView.hideAlignmentViews()
            
            self.mainView.targetAlignment[AlignmentAxis.horizontal]! = .none
            self.mainView.targetAlignment[AlignmentAxis.vertical]! = .none
            
            if appContextId != 0{
                navigationItem.rightBarButtonItem?.enabled = false
            }
        
        }else{
            // elles sont animées pour signifier le blocage de l'image
            
            if mainView.isVerticalAlignmentLocked{
                mainView.animateAlignmentViewSizeChange(mainView.horizontalAlignmentView)
            }else{
                self.mainView.targetAlignment[AlignmentAxis.vertical]! = .none
            }
            
            if mainView.isHorizontalAlignmentLocked{
                mainView.animateAlignmentViewSizeChange(mainView.verticalAlignmentView)
            }else{
                self.mainView.targetAlignment[AlignmentAxis.horizontal]! = .none
            }
        }
    }
    
    
    
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return mainView.tiledImageView
    }
    
    
}

