//
//  ImageViewContainer.swift
//  ImportImage
//
//  Created by bertrand DUPUY on 24/05/2015.
//  Copyright (c) 2015 bertrand DUPUY. All rights reserved.
//

import UIKit





class TiledImageView : UIImageView {
      
    var tiledView : TiledView?
    var maskLayer : CALayer?
    
    var isLosResImageAffected = false
    var isHighResImageAffected = false
    
        
    private var lowResImage : UIImage?{
        didSet{
            if let asImage = lowResImage{
                isLosResImageAffected  = true
                
            }
        }
    }
    
    private var highResImage : UIImage?{
        didSet{
            if let asImage = highResImage{
                isHighResImageAffected  = true
                
               
            }
        }
    }
    
    
    func setImage(image : UIImage, imageDef : ImageDefinition){
    
        if imageDef == .lowRes{
            lowResImage = image
        }else{
            highResImage = image
            sizeContent(image.size)
        }
    }
    
    
    func sizeContent(contentSize : CGSize){
        
        frame.size = contentSize
        image = lowResImage
        tiledView = TiledView(frame: CGRect(origin: CGPointZero, size: contentSize), image: highResImage!)
        addSubview(tiledView!)
        
    }
    
    convenience init(frame : CGRect, highResImage : UIImage, lowResImage : UIImage){
    
        self.init(frame : frame)
        
        setImage(lowResImage, imageDef : ImageDefinition.lowRes)
        setImage(highResImage, imageDef : ImageDefinition.highRes)
        
    }
    
}
