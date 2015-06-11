//
//  TiledView.swift
//  testScroolviewWithView
//
//  Created by bertrand DUPUY on 21/05/2015.
//  Copyright (c) 2015 bertrand DUPUY. All rights reserved.
//

import UIKit
import Photos

class TiledView: UIView {

    var topConstraint: NSLayoutConstraint!
    var bottomConstraint: NSLayoutConstraint!
    var leadingConstraint: NSLayoutConstraint!
    var trailingConstraint: NSLayoutConstraint!
    
    var image : UIImage?
    var maskingView : UIImageView?
    
    var compteur = 0
    
    var asset : PHAsset?
    var imageTiles = [[CGImage]]()
    
    var rotationTransform = CGAffineTransformIdentity
    let tileSize = CGSize(width: 512, height: 512)
    var tilesCount = 0
    
    override class func layerClass() -> AnyClass {
        return CATiledLayer.self
    }
    
    func setTileSize(size : CGSize){
        (layer as! CATiledLayer).tileSize = size
    }
    
    func setlevelsOfDetailBias(level : Int){
        (layer as! CATiledLayer).levelsOfDetailBias = level
        (layer as! CATiledLayer).levelsOfDetailBias = 1
    }
        
    override init(frame: CGRect) {
        
        let deviceScale = UIScreen.mainScreen().nativeScale
        let correctedTileSize = CGSize(width: tileSize.width/deviceScale, height: tileSize.height/deviceScale)
        let screenSize = UIScreen.mainScreen().bounds.size
        
        super.init(frame: frame)
        self.contentScaleFactor = 1.0
        self.setTileSize(CGSize(width: tileSize.width*deviceScale, height: tileSize.height*deviceScale))
        setlevelsOfDetailBias(1)
    }
    
    convenience init(frame:CGRect, image : UIImage){
        self.init(frame : frame)
        self.image = image
        
        //ajout d'une vue au premier plan pour masker l'affichages des tiles
        maskingView = UIImageView(image: image)
        maskingView?.center = center
        addSubview(maskingView!)
    }
    
    override func layoutSubviews() {
         compteur = 0
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    //tracé des tiles
    override func drawLayer(layer: CALayer!, inContext ctx: CGContext!) {
        
        if let asImage = self.image{
            
            let contextRect  = CGContextGetClipBoundingBox(ctx)
            let contextScale = CGContextGetCTM(ctx).a
            let tileSize = CGSize(width: (layer as! CATiledLayer).tileSize.width/contextScale, height: (layer as! CATiledLayer).tileSize.height/contextScale)
            let screenSize = UIScreen.mainScreen().bounds.size
            
            let nbTilesPerRow : CGFloat
            let nbRows : CGFloat
            
            if CGRectContainsRect(UIScreen.mainScreen().bounds, self.bounds){
                nbTilesPerRow = ceil(self.bounds.width / tileSize.width)
                nbRows = ceil(self.bounds.height / tileSize.height)
            }else{
                nbTilesPerRow = ceil(screenSize.width / tileSize.width) + 1.0
                nbRows = ceil(screenSize.height / tileSize.height) + 1.0
            }
            
            self.compteur++
            
            CGContextTranslateCTM(ctx, asImage.size.width * 0.5, asImage.size.height * 0.5)
            CGContextScaleCTM(ctx, 1, -1)
            
            CGContextConcatCTM(ctx, self.rotationTransform)
            
            //positionnement de l'image relativement au contextRect
            let imageRect = CGRectApplyAffineTransform(CGRect(origin: CGPoint(x: -asImage.size.width*0.5, y: -asImage.size.height*0.5), size: asImage.size), CGAffineTransformMakeScale(1, 1))
            
            CGContextDrawImage(ctx, imageRect , asImage.CGImage)
            
            //dernière tile - supression du mask
            if self.compteur == Int(nbRows*nbTilesPerRow){
                self.maskingView?.removeFromSuperview()
                self.maskingView = nil
            }
        }
    }
}
