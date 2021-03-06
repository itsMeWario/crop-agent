//
//  MainView.swift
//  test
//
//  Created by bertrand DUPUY on 29/03/2015.
//  Copyright (c) 2015 bertrand DUPUY. All rights reserved.
//

import UIKit
import Photos


class MainView: UIView {
      
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var finalView: UIView!
    @IBOutlet weak var interfaceContainer: UIView!
    @IBOutlet weak var interfaceView: UIView!
    @IBOutlet weak var formatLabel: UILabel!
    @IBOutlet weak var finalBackgroundView: UIView!
    @IBOutlet weak var borderView : UIView!
    var tiledImageView : TiledImageView!
    
    var verticalAlignmentView : UIView?
    var horizontalAlignmentView : UIView?
    
    @IBOutlet weak var finalWidth: NSLayoutConstraint!
    @IBOutlet weak var finalHeight: NSLayoutConstraint!
    @IBOutlet weak var finalBackgroundWidth: NSLayoutConstraint!
    @IBOutlet weak var finalBackgroundHeight: NSLayoutConstraint!
    
    @IBOutlet weak var scrollViewWidth: NSLayoutConstraint!
    @IBOutlet weak var scrollViewHeight: NSLayoutConstraint!
    @IBOutlet weak var scrollViewCenterX: NSLayoutConstraint!
    @IBOutlet weak var scrollViewCenterY: NSLayoutConstraint!
    
    var currentImageSize = CGSizeZero
    var initResizedImageSize : CGSize?
    var resizedProjectSize : CGSize?
    var contentOffset = CGPointZero
    
    var isImageRotationEnabled = true
    
    let alignmentViewLockedColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.5)
    
    var isInterfaceLoaded = false
    var isImageLocked = false
    var horizontalAlignmentEnabled = false
    var verticalAlignmentEnabled = false
    var isHorizontalAlignmentLocked = false
    var isVerticalAlignmentLocked = false
    
    var initInterfaceOrientation : UIPrintInfoOrientation?
    
    var targetAlignment :[AlignmentAxis : ImageAlignment] = [AlignmentAxis.horizontal : ImageAlignment.none, AlignmentAxis.vertical : ImageAlignment.none]{
        
        didSet{
            
            if targetAlignment[AlignmentAxis.horizontal]! != .none{
                horizontalAlignmentEnabled = true
                isImageRotationEnabled = targetAlignment[AlignmentAxis.horizontal]! == .horizontalCenterAlignment ? true : false
            }else{
                horizontalAlignmentEnabled = false
                isImageRotationEnabled = targetAlignment[AlignmentAxis.vertical]! == .none || targetAlignment[AlignmentAxis.vertical]! == .verticalCenterAlignment ? true : false
                hideAlignmentView(AlignmentAxis.horizontal, cbk : nil)
            }
            
            if targetAlignment[AlignmentAxis.vertical]! != .none{
                verticalAlignmentEnabled = true
                isImageRotationEnabled = targetAlignment[AlignmentAxis.vertical]! == .verticalCenterAlignment ? true : false
            }else{
                verticalAlignmentEnabled = false
                isImageRotationEnabled = targetAlignment[AlignmentAxis.horizontal]! == .none || targetAlignment[AlignmentAxis.horizontal]! == .horizontalCenterAlignment ? true : false
                hideAlignmentView(AlignmentAxis.vertical, cbk : nil)
            }
        }
    }
    
    convenience init(frame: CGRect, containerView : UIView) {
        self.init(frame: frame)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(frame : CGRect, image : UIImage, finalSize : CGSize){
        self.init(frame : frame)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    
    //retourne le nouvelle offset à appliquer à la scrollview pour conformer l'image aux contraintes d'alignement
    func getAlignedPosition(alignmentType : ImageAlignment)->CGPoint{
        
        finalView.layoutIfNeeded()
        
        var originOffset = scrollView.contentOffset
        let refRect = convertRect(self.tiledImageView.frame, fromView: self.tiledImageView.superview)
        
        let finalViewInView = convertRect(finalView.frame, fromView: finalView.superview)
        
        switch(alignmentType){
        
        //si alignement de type horizontal
        case .leftAlignment, .rightAlignment, .horizontalCenterAlignment :
            
            switch(alignmentType){
            
            case .leftAlignment :
                originOffset.x = -finalViewInView.minX
            case .rightAlignment :
                originOffset.x = -(finalViewInView.maxX - refRect.width)
            default : //.horizontalCenterAlignment
                originOffset.x = -(finalViewInView.midX - (refRect.width)*0.5)
            }
            
        default : //si alignement de type vertical
            
            switch(alignmentType){
            case .topAlignment :
                originOffset.y = -finalViewInView.minY
            case .bottomAlignment :
                originOffset.y = -(finalViewInView.maxY - refRect.height)
            default : //.verticalCenterAlignment
                originOffset.y = -(finalViewInView.midY - (refRect.height)*0.5)
            }
        }
        
        return originOffset
    }
    
    //supprime les reperes d'alignement
    func hideAlignmentViews(){
        horizontalAlignmentView?.removeFromSuperview()
        horizontalAlignmentView = nil
        verticalAlignmentView?.removeFromSuperview()
        verticalAlignmentView = nil
    }
    
    
    //supprime le repere d'alignement associée à un type d'alignement
    func hideAlignmentView(alignmentAxis : AlignmentAxis, cbk : (()->Void)?){
        
        var alignmentView : UIView?
        
        if alignmentAxis == .horizontal{
            verticalAlignmentView?.removeFromSuperview()
            verticalAlignmentView = nil
        }else{
            horizontalAlignmentView?.removeFromSuperview()
            horizontalAlignmentView = nil
        }
        
        if cbk != nil{
            cbk!()
        }
    }

    
    
    //affiche le repere d'alignement pour un type d'alignement donné
    func showAlignmentView(parentView : UIView, animated : Bool, alignmentType : ImageAlignment, cbk : (()->Void)?){
        
        var aligmentAxis = alignmentType == .leftAlignment ? AlignmentAxis.horizontal : alignmentType == .rightAlignment ? .horizontal : alignmentType == .horizontalCenterAlignment ? .horizontal : .vertical
        
        hideAlignmentView(aligmentAxis, cbk : {
        
            let viewSize : CGSize!
            let viewOrigin : CGPoint!
            let tmpView = UIView(frame: CGRectZero)
            let viewMaxSide = 2*(max(UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height))
            
            //taille et position du nouveau repere d'alignement
            switch(alignmentType){
            
            case .leftAlignment, .rightAlignment, .horizontalCenterAlignment :
                viewSize = CGSize(width: self.borderView.layer.borderWidth , height: viewMaxSide)
                var offsetX = CGFloat(0)
                
                if alignmentType == .rightAlignment{
                    offsetX = parentView.bounds.maxX - viewSize.width
                }else if alignmentType == .horizontalCenterAlignment{
                    offsetX = parentView.bounds.midX - viewSize.width
                }
                
                viewOrigin = CGPoint(x: offsetX, y: -UIScreen.mainScreen().bounds.midY)
                self.verticalAlignmentView?.removeFromSuperview()
                self.verticalAlignmentView = tmpView
                
                tmpView.backgroundColor =  self.isHorizontalAlignmentLocked ? self.alignmentViewLockedColor : UIColor(white: 0.9, alpha: 1)
                
            case .topAlignment, .bottomAlignment, .verticalCenterAlignment :
                viewSize = CGSize(width: viewMaxSide , height: self.borderView.layer.borderWidth)
                var offsetY = CGFloat(0)
                
                if alignmentType == .bottomAlignment{
                    offsetY = parentView.bounds.maxY - viewSize.height
                }else if alignmentType == .verticalCenterAlignment{
                    offsetY = parentView.bounds.midY - viewSize.height
                }
                
                viewOrigin = CGPoint(x: -UIScreen.mainScreen().bounds.midX, y: offsetY)
                self.horizontalAlignmentView?.removeFromSuperview()
                self.horizontalAlignmentView = tmpView
                
                tmpView.backgroundColor = self.isVerticalAlignmentLocked ? self.alignmentViewLockedColor : UIColor(white: 0.9, alpha: 1)
                
            default :
                viewOrigin = CGPointZero
                viewSize = CGSizeZero
            }
            
            
            //ajout du repere
            parentView.addSubview(tmpView)
            tmpView.frame = CGRect(origin: viewOrigin, size: viewSize)
            
            if animated{
            
                tmpView.alpha = 0
                
                UIView.animateWithDuration(0.2, animations: { () -> Void in
                    tmpView.alpha = 1
                    
                    if cbk != nil{
                        cbk!()
                    }
                })
                
            }else{
            
                if cbk != nil{
                    cbk!()
                }
            }
        })
    }
    
    
    //anime le repere d'alignement en grossissant sa taille
    func animateAlignmentViewSizeChange(alignmentView : UIView?){
        
        if let asView = alignmentView{
            

        }
    }
    
    
    //modifie le layout de la scrollview pour compenser le changement de dimension de l'image
    //lorsqu'une contrainte d'alignement est appliquée
    func adaptContraintsWhileZoomingManually(){
        
        if self.scrollView.zooming{
            
            let deltaX = (currentImageSize.width - tiledImageView.frame.width)
            let deltaY = (currentImageSize.height - tiledImageView.frame.height)
            
            if isImageLocked && horizontalAlignmentEnabled{
                
                scrollView.bounds.origin.x = 0
                scrollViewWidth.constant -= deltaX
                
                if targetAlignment[AlignmentAxis.horizontal] == .rightAlignment{
                    
                    scrollViewCenterX.constant += deltaX*0.5
                
                }else if targetAlignment[AlignmentAxis.horizontal] == .leftAlignment{
                    
                    scrollViewCenterX.constant -= deltaX*0.5
                
                }
            }
            
            if isImageLocked && verticalAlignmentEnabled{
                
                scrollView.bounds.origin.y = 0
                scrollViewHeight.constant -= deltaY
                
                if targetAlignment[AlignmentAxis.vertical] == .bottomAlignment{
                    
                    scrollViewCenterY.constant += deltaY*0.5
                    
                }else if targetAlignment[AlignmentAxis.vertical] == .topAlignment{
                    
                    scrollViewCenterY.constant -= deltaY*0.5
                    
                }
            }
            
            layoutIfNeeded()
            
            currentImageSize = tiledImageView.frame.size
        }
    }

    //retourne systématiquent la scrollview de sorte à ce que les vues placées au premier plan
    //n'empechent le bon fonctionnement des gesturesRecognizers de la scrollview
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        let hitedView = super.hitTest(point, withEvent: event)
        return scrollView
    }
    
    
    //met à jour le layout de la scrollview lorsqu'une contrainte d'alignement se voit appliquée ou retirée
    func updateScrollviewLayout(alignmentType : ImageAlignment?) {
        
        //si ajout
        if let alignmentType = alignmentType{
        
            tiledImageView.layoutIfNeeded()
            
            var imageViewInView = convertRect(self.tiledImageView.frame, fromView: self.tiledImageView.superview)
            let finalVinewInView = convertRect(self.finalView.frame, fromView: self.finalView.superview)
            
            let isHorizontallyAligned = alignmentType == .leftAlignment || alignmentType == .rightAlignment
            let isHorizontallyCentered = alignmentType == .horizontalCenterAlignment
            let isNewAlignmentHorizontal = isHorizontallyAligned || isHorizontallyCentered
            let axisAlignment = isNewAlignmentHorizontal ? AlignmentAxis.horizontal : AlignmentAxis.vertical
            
            if axisAlignment == .horizontal {
                
                scrollView.contentInset.right = 0
                scrollView.contentInset.left = 0
                scrollViewWidth.constant = tiledImageView.frame.width
                scrollView.bounds.origin.x = 0
                
                scrollViewCenterX.constant = alignmentType != .horizontalCenterAlignment ? imageViewInView.midX - finalVinewInView.midX : 0
                
            }else{
                
                scrollView.contentInset.top = 0
                scrollView.contentInset.bottom = 0
                scrollViewHeight.constant = imageViewInView.height
                scrollView.bounds.origin.y = 0
                
                scrollViewCenterY.constant = alignmentType != .verticalCenterAlignment ? imageViewInView.midY - finalVinewInView.midY : 0
            }
            
        }else{
            //si retrait
            
            let imageViewInView = convertPoint(tiledImageView.frame.origin, fromView: tiledImageView.superview)
            
            scrollViewCenterX.constant = 0
            scrollViewCenterY.constant = 0
            scrollViewWidth.constant = frame.size.width
            scrollViewHeight.constant = frame.size.height
            
            updateScrollViewContentInset(bounds)
            
            scrollView.contentOffset = CGPoint(x: -imageViewInView.x, y: -imageViewInView.y)
        
        }
    }
        
    //initialise la vue en définissant la taille de l'image par rapport à celle
    //du modele pour que celui ci s'affiche dans de bonnes proportions
    func initAppInterface(parentBounds : CGRect, resizedImageSize : CGSize, resizedModelSize : CGSize, lowResImage : UIImage){
                 
            initResizedImageSize = resizedImageSize
            resizedProjectSize = resizedModelSize
            initInterfaceOrientation = UIApplication.sharedApplication().statusBarOrientation.isPortrait ? UIPrintInfoOrientation.Portrait : .Landscape
            
            //contraintes de la scrollview
            scrollViewWidth.constant = parentBounds.width
            scrollViewHeight.constant = parentBounds.height
            
            //contraintes de la vue representant le format et son arriere plan
            finalWidth.constant = resizedModelSize.width
            finalHeight.constant = resizedModelSize.height
            finalBackgroundWidth.constant = finalWidth.constant
            finalBackgroundHeight.constant = finalHeight.constant
            
            finalView.layoutIfNeeded()
            finalBackgroundView.layoutIfNeeded()
        
            //création de tiledImageView, affectation de l'image lowRes à l'imageView
            self.tiledImageView = TiledImageView(frame: CGRect(origin: CGPointZero, size: resizedImageSize))
            self.tiledImageView.setImage(lowResImage, imageDef: ImageDefinition.lowRes)
            self.tiledImageView.sizeContent(resizedImageSize)
            self.scrollView.addSubview(self.tiledImageView)
            
            //calcul des maximum et minimum zoomscale de la scrollview
            self.setMaxMinZoomScalesForCurrentBounds(resizedImageSize)
            self.scrollView.zoomScale = 1
            
            //mise à jour de l'inset de la scrollview
            self.updateScrollViewContentInset(parentBounds)
            
            self.scrollView.contentSize = CGSize(width: initResizedImageSize!.width*self.scrollView.zoomScale, height: initResizedImageSize!.height*self.scrollView.zoomScale)
            
            //détermination de l'offset pour que l'image appaisse centré dans l'écran et par raport au modele
            let offsetX = initResizedImageSize!.width*0.5 - parentBounds.midX
            let offsetY = initResizedImageSize!.height*0.5  - parentBounds.midY
            
            self.scrollView.contentOffset = CGPoint(x: offsetX, y: offsetY)
            
            self.isInterfaceLoaded = true
            
       
    }
    
    //déplace l'image dans la scrollview pour qu'elle s'aligne selon la nouvelle contrainte
    func animateAlignment(alignmentType : ImageAlignment, cbk : (()->Void)?){
        
        let isHorizontallyAligned = alignmentType == .leftAlignment || alignmentType == .rightAlignment
        let isHorizontallyCentered = alignmentType == .horizontalCenterAlignment
        let isNewAlignmentHorizontal = isHorizontallyAligned || isHorizontallyCentered
        
        let axisAlignment = isNewAlignmentHorizontal ? AlignmentAxis.horizontal : AlignmentAxis.vertical
        
        UIView.animateWithDuration(Double(0.3), delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: UIViewAnimationOptions.BeginFromCurrentState, animations: { () -> Void in

            let newOffset = self.getAlignedPosition(alignmentType)
            
            if axisAlignment == .horizontal{
                self.scrollView.setContentOffset(newOffset, animated: true)
               
            }else{
                self.scrollView.setContentOffset(newOffset, animated: true)
            }
            
            self.layoutIfNeeded()
            
            }, completion: { (finished) -> Void in
                
                self.targetAlignment[axisAlignment] = alignmentType
                
                if cbk != nil{
                    cbk!()
                }
            }
        )
    }
    
    //affecte le minimumzoomscale et le maximumzooscale de la scrollview
    func setMaxMinZoomScalesForCurrentBounds(imageSize : CGSize){
    
        let boundsSize = UIScreen.mainScreen().bounds.size
        
        //minimumzoomscale de sorte à ce que la plus petite dimension de l'image
        //soit deux plus petit que celle du modele
        let xScale = finalView.bounds.midX  / imageSize.width
        let yScale = finalView.bounds.midY / imageSize.height
        
        

       
        //détermination du minimum selon l'orientation
        let imagePortrait = imageSize.height > imageSize.width
        let phonePortrait = boundsSize.height > boundsSize.width
        var minScale = imagePortrait == phonePortrait ? xScale : min(xScale, yScale)
       
        let maxScale = CGFloat(20)
        
        if (minScale > maxScale) {
            minScale = maxScale
        }
        
        self.scrollView.maximumZoomScale = maxScale
        self.scrollView.minimumZoomScale = minScale
        
    }
    
    
    
    //calcule de le contentInset de la scrollview de sorte à ce que l'image ne s'écarte pas du modele
    func updateScrollViewContentInset(parentBounds : CGRect){
        
        
        
        var insetH = 0.5*(parentBounds.width + finalView.frame.width)
        var insetV = 0.5*(parentBounds.height + finalView.frame.height)
        
        scrollView.contentInset = UIEdgeInsets(top: insetV, left: insetH, bottom: insetV, right: insetH)
    }
    
    
    
    //mise à jour du layout lors d'une rotation du device
    func updateLayoutForSizeTransition(parentBounds : CGRect){
        
//        //initialisation de la vue
//        if !forSizeTransition && !isInterfaceLoaded{
//            
//            initAppInterface(parentBounds)
//                        
//        }else if forSizeTransition { //mise à jour de l'interface suite à rotation du device
        
            //permutation de la longueur et de la hauteur du modele afin que la zone cible reste fixe malgré la rotation
            let currentFinalViewWidth = finalWidth.constant
            finalWidth.constant = finalHeight.constant
            finalHeight.constant = currentFinalViewWidth
            finalBackgroundWidth.constant = finalBackgroundHeight.constant
            finalBackgroundHeight.constant = currentFinalViewWidth
            
            finalView.superview!.layoutIfNeeded()
            
            //mise à jour du layout de la scrollView
            adaptScrollViewLayoutForSizeTransition(parentBounds)
            
            //repositionnement des lignes d'alignement si l'image est bloquée sinon on les supprime par défaut mais l'idéal
            //serait les supprimer seulement si la rotation a rompu l'alignement ce qui n'est pas systématique
            if isImageLocked && horizontalAlignmentEnabled{
                showAlignmentView(borderView, animated : false, alignmentType: targetAlignment[AlignmentAxis.horizontal]!, cbk : nil)
            }else{
                verticalAlignmentView?.removeFromSuperview()
                verticalAlignmentView = nil
            }
            
            if isImageLocked && verticalAlignmentEnabled{
                showAlignmentView(borderView, animated : false, alignmentType: targetAlignment[AlignmentAxis.vertical]!, cbk : nil)
            }else{
                horizontalAlignmentView?.removeFromSuperview()
                horizontalAlignmentView = nil
            }
//        }
    }
    
    
    //mise à jour du layout de la scrollview lorsque que device change d'orientation
    func adaptScrollViewLayoutForSizeTransition(parentBounds : CGRect){
    
        let initMainSize = resizedProjectSize?.width > resizedProjectSize?.height ? CGSize(width: max(frame.width, frame.height), height: min(frame.width, frame.height)) : CGSize(width: min(frame.width, frame.height), height: max(frame.width, frame.height))
        
        updateScrollViewContentInset(parentBounds)
        
        //si aucune contrainte d'alignement n'est appliquée
        //la scrollview est tournée normalement
        if !isImageLocked{
            
            let currentScrollViewWidth = scrollViewWidth.constant
            scrollViewWidth.constant = scrollViewHeight.constant
            scrollViewHeight.constant = currentScrollViewWidth
            scrollView.contentOffset = contentOffset
            
        }else{
            
            //sinon la rotation est compensée de sorte à ce que les contraintes d'alignement soient toujours valables
            let interfaceOrientation = UIApplication.sharedApplication().statusBarOrientation.isPortrait ? UIPrintInfoOrientation.Portrait : .Landscape
            let insetCorrectionX = parentBounds.midY - initMainSize.width*0.5
            let insetCorrectionY = parentBounds.midX - initMainSize.height*0.5
            
            //compensation de l'inset
            if interfaceOrientation != initInterfaceOrientation{
                scrollView.contentInset.top += insetCorrectionY
                scrollView.contentInset.bottom = scrollView.contentInset.top
                scrollView.contentInset.left += insetCorrectionX
                scrollView.contentInset.right = scrollView.contentInset.left
            }
            
            //si alignement horizontal
            if horizontalAlignmentEnabled && targetAlignment[AlignmentAxis.horizontal] != .none{
                
                let centerOffset = tiledImageView.frame.width*0.5 - finalView.frame.width*0.5
                
                //déplacement de la scrollview
                if targetAlignment[AlignmentAxis.horizontal] == .leftAlignment{
                    scrollViewCenterX.constant = centerOffset
                }else if targetAlignment[AlignmentAxis.horizontal] == .rightAlignment{
                    scrollViewCenterX.constant = -centerOffset
                }else{
                    scrollViewCenterX.constant = 0
                }
                
                //image bloquée horizontalement, l'inset horizontal de la scrollview est mis à 0
                scrollView.contentInset.left = 0
                scrollView.contentInset.right = 0
                
                scrollViewWidth.constant = tiledImageView.frame.size.width
                
                if !isImageLocked || !verticalAlignmentEnabled{
                    scrollViewHeight.constant = parentBounds.height
                }
            }
            
            //si alignement vertical
            if verticalAlignmentEnabled && targetAlignment[AlignmentAxis.vertical] != .none{
                
                let centerOffset = tiledImageView.frame.height*0.5 - finalView.frame.height*0.5
                
                if targetAlignment[AlignmentAxis.vertical] == .topAlignment{
                    scrollViewCenterY.constant = centerOffset
                }else if targetAlignment[AlignmentAxis.vertical] == .bottomAlignment{
                    scrollViewCenterY.constant = -centerOffset
                }else{
                    scrollViewCenterY.constant = 0
                }
                
                scrollView.contentInset.top = 0
                scrollView.contentInset.bottom = 0

                scrollViewHeight.constant = scrollView.contentSize.height
                
                if !isImageLocked || !horizontalAlignmentEnabled{
                    scrollViewWidth.constant = parentBounds.width
                }
            }
        }
        
        scrollView.layoutIfNeeded()
    }
    
    

    
    override func awakeFromNib() {
        
        
        scrollView.bouncesZoom = false
        scrollView.bounces = false
        scrollView.panGestureRecognizer.maximumNumberOfTouches = 1
        scrollView.pagingEnabled = false
        scrollView.scrollsToTop = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        
        setTranslatesAutoresizingMaskIntoConstraints(false)
        scrollView.setTranslatesAutoresizingMaskIntoConstraints(false)
        finalView.setTranslatesAutoresizingMaskIntoConstraints(false)
        interfaceContainer.setTranslatesAutoresizingMaskIntoConstraints(false)
        interfaceView.setTranslatesAutoresizingMaskIntoConstraints(false)
        borderView.setTranslatesAutoresizingMaskIntoConstraints(false)
        borderView.layer.borderWidth = CGFloat(2)
        borderView.layer.borderColor = UIColor(red: 0, green: 120/255, blue: 251/255, alpha: 1).CGColor
        
    }
}
