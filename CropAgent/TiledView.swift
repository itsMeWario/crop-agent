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
    
    var image : UIImage?{
        didSet{
            //layer.setNeedsDisplay()
        }
    }
    
    
    
    
    var asset : PHAsset?
    var imageTiles = [[CGImage]]()
    
    
    //var manager : PHImageManager?
    
        
    var rotationTransform = CGAffineTransformIdentity
    let tileSize = CGSize(width: 256, height: 256)
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
    }
    

    required init(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
    
    
    override func drawLayer(layer: CALayer!, inContext ctx: CGContext!) {
        
        if let asImage = image{
            
            let contextRect  = CGContextGetClipBoundingBox(ctx)
            let contextScale = CGContextGetCTM(ctx).a
            
            CGContextTranslateCTM(ctx, asImage.size.width * 0.5, asImage.size.height * 0.5)
            CGContextScaleCTM(ctx, 1, -1)
            
            CGContextConcatCTM(ctx, rotationTransform)
            let imageRect = CGRectApplyAffineTransform(CGRect(origin: CGPoint(x: -asImage.size.width*0.5, y: -asImage.size.height*0.5), size: asImage.size), CGAffineTransformMakeScale(1, 1))
            
            CGContextDrawImage(ctx, imageRect , asImage.CGImage)
            
        }

    }
}
