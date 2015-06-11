//
//  PageRenderer.swift
//  CropAgent
//
//  Created by bertrand DUPUY on 28/04/2015.
//  Copyright (c) 2015 bertrand DUPUY. All rights reserved.
//

import UIKit

class PageRenderer: UIPrintPageRenderer {
    
    var destinationSize : CGSize!
    var image : UIImage?
    
    override init() {
        super.init()
    }
    
    convenience init(image : UIImage) {
        self.init()
        destinationSize = image.size
        self.image = image
    }
    
    
    override func numberOfPages() -> Int {
        return 1
    }
    
    
    override func drawPageAtIndex(pageIndex: Int, inRect printableRect: CGRect) {
        
        let ctx = UIGraphicsGetCurrentContext()
        image!.drawInRect(CGRect(origin: CGPointZero, size: printableRect.size))
        UIGraphicsEndImageContext()
    }
    
   
}
