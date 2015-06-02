//
//  SessionData.swift
//  ImportImage
//
//  Created by bertrand DUPUY on 05/05/2015.
//  Copyright (c) 2015 bertrand DUPUY. All rights reserved.
//

import UIKit
import Photos

//let currentSession = SessionData.sharedData

var GlobalMainQueue: dispatch_queue_t {
    return dispatch_get_main_queue()
}

var GlobalUserInteractiveQueue: dispatch_queue_t {
    return dispatch_get_global_queue(Int(QOS_CLASS_USER_INTERACTIVE.value), 0)
}

var GlobalUserInitiatedQueue: dispatch_queue_t {
    return dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.value), 0)
}

var GlobalUtilityQueue: dispatch_queue_t {
    return dispatch_get_global_queue(Int(QOS_CLASS_UTILITY.value), 0)
}

var GlobalBackgroundQueue: dispatch_queue_t {
    return dispatch_get_global_queue(Int(QOS_CLASS_BACKGROUND.value), 0)
}





struct AppData {
    
    var imageAsset : PHAsset?{
        didSet{
            if let asAsset = imageAsset{
                initImageOrientation = asAsset.pixelWidth > asAsset.pixelHeight ? UIPrintInfoOrientation.Landscape : .Portrait
            }
        }
    }
    
    var projectFormat : FormatStruct?{
    
        didSet{
        
            if projectFormat != nil{
                
                let myDevicePpp = devicePpp
                
                let interfaceOrientation = UIApplication.sharedApplication().statusBarOrientation
                
                let size = projectFormat!.size
                let minVal = min(size.width, size.height)
                let maxVal = max(size.width, size.height)
                
                projectRatio = maxVal / minVal
                
                projectSize = interfaceOrientation.isPortrait ? CGSize(width: round(minVal/25.4*myDevicePpp), height: round(maxVal/25.4*myDevicePpp)) : CGSize(width: round(maxVal/25.4*myDevicePpp), height: round(minVal/25.4*myDevicePpp))
            }
        }
    }
   
    var scale = CGFloat(1)
    var rotationTransform = CGAffineTransformIdentity
    var initImageOrientation = UIPrintInfoOrientation.Landscape
    var projectRatio = CGFloat(1)
    var projectSize : CGSize?
    var lowResImage : UIImage?
       
    var imageRectInProjectRect : CGRect?
    
    var devicePpp : CGFloat{
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad{
            return CGFloat(264)
        }else if (UIApplication.sharedApplication().delegate! as! AppDelegate).window?.traitCollection.verticalSizeClass == .Regular{
            return CGFloat(401)
        }
       
        return CGFloat(264)

    }
    
}







class SessionData : NSObject{
    
    static let sharedData = SessionData()
    static private var structuredData : AppData!
        
    func getCopy()->AppData{
        
        
        
        return SessionData.structuredData
    }
    
    override init() {
        SessionData.structuredData = AppData()
        super.init()
    }
    
    static func setAppData(data :AppData){
        structuredData = data
        
        
    }
    
    
}
