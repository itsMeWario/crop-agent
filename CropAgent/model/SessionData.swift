//
//  SessionData.swift
//  ImportImage
//
//  Created by bertrand DUPUY on 05/05/2015.
//  Copyright (c) 2015 bertrand DUPUY. All rights reserved.
//

import UIKit
import Photos







class SessionData {
    
    static let sharedData = SessionData()
    static private var structuredData = AppData()
    static var lowResResizedImage : UIImage?{
        didSet{
            structuredData.lowResResizedImage = lowResResizedImage
        }
    }
    
    static var resizedImage : UIImage?{
        didSet{
            structuredData.resizedImage = resizedImage
        }
    }
    
        
    func getCopy()->AppData{
        return SessionData.structuredData
    }
    
    struct AppData {
        
        var lowResResizedImage : UIImage?
        var resizedImage : UIImage?
        
        var projectFormat : FormatStruct?
        
        var imageAsset : PHAsset?
        var projectSize : CGSize{
            
            if let projectFormat = projectFormat{
                
                let myDevicePpp = devicePpp
                let tmpSize : CGSize
                
                let interfaceOrientation = UIApplication.sharedApplication().statusBarOrientation
                
                let size = projectFormat.size
                let minVal = min(size.width, size.height)
                let maxVal = max(size.width, size.height)
                
                //définition de la taille du format choisi ramené en pixel, devicePpp représantant la densité de pixel par point
                tmpSize = interfaceOrientation.isPortrait ? CGSize(width: round(minVal/25.4*myDevicePpp), height: round(maxVal/25.4*myDevicePpp)) : CGSize(width: round(maxVal/25.4*myDevicePpp), height: round(minVal/25.4*myDevicePpp))
                
                return tmpSize
            }
            
            return CGSizeZero
        }
        
        
        var resizingScale : CGFloat{
            
            let screenBounds = UIScreen.mainScreen().bounds
            let projectBounds = CGRect(origin: CGPointZero, size: projectSize)
            
            //si le format choisi ne peut être contenu par l'écran
            if !CGRectContainsRect(screenBounds, projectBounds){
                let idiomScale :CGFloat = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? 0.7 : 0.9
                return (min(screenBounds.width, screenBounds.height) * idiomScale) / min(projectBounds.width, projectBounds.height)
            }
            
            return 1
        }
        
        
        var resizedProjectSize : CGSize{
            let tmpProjectSize = projectSize
            let tmpResizingScale = resizingScale
            return CGSize(width: tmpProjectSize.width*tmpResizingScale, height: tmpProjectSize.height*resizingScale)
        }
        
        var resizedImageSize : CGSize{
            
            if let imageAsset = imageAsset{
                let tmpResizingScale = resizingScale
                return CGSize(width: CGFloat(imageAsset.pixelWidth)*tmpResizingScale, height: CGFloat(imageAsset.pixelHeight)*tmpResizingScale)
            }
            
            
            return CGSizeZero
        }
        
        var devicePpp : CGFloat{
            
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad{
                return CGFloat(264)
            }else if (UIApplication.sharedApplication().delegate! as! AppDelegate).window?.traitCollection.verticalSizeClass == .Regular{
                return CGFloat(401)
            }
            
            return CGFloat(264)
        }
    }

    
    
    
    //requete une version basse résolution de l'image qui sera utilisée
    //comme background du CATiledLayer afin de limiter l'effet clignotement
    //produit par l'affichage asynchrone des tiles
    static func requestLowResResizedImage(){
        
        if let imageAsset = structuredData.imageAsset{
            
            let manager = PHImageManager.defaultManager()
            let options = PHImageRequestOptions()
            options.synchronous = false
            options.deliveryMode = PHImageRequestOptionsDeliveryMode.HighQualityFormat
            options.resizeMode = PHImageRequestOptionsResizeMode.Exact
            
            let size : CGSize
            
            //si l'image est plus petite que 300 par 300, pas de redimensionnement
            if imageAsset.pixelHeight < 300 && imageAsset.pixelWidth < 300{
                size = CGSize(width: imageAsset.pixelHeight, height: imageAsset.pixelHeight)
            }else{
                //sinon sa taille est fixée à 10% de la taille originale
                size = CGSize(width: CGFloat(imageAsset.pixelWidth)*0.1, height: CGFloat(imageAsset.pixelHeight)*0.1)
            }
            
            manager.requestImageForAsset(imageAsset, targetSize: size, contentMode: PHImageContentMode.AspectFit, options: options) { (image, infos) -> Void in
                
                if let asImage = image{
                    
                    self.lowResResizedImage = asImage
                    
                }
            }
        }
    }
    
    //requete l'image redimensionnée proportionnellement au modele
    static func requestResizedImage(cbk : ((image : UIImage)->Void)){
        
        if let imageAsset = structuredData.imageAsset{
            
            //requete de l'image au dimensions désirées
            let manager = PHImageManager.defaultManager()
            let options = PHImageRequestOptions()
            options.synchronous = false
            options.deliveryMode = PHImageRequestOptionsDeliveryMode.HighQualityFormat
            options.resizeMode = PHImageRequestOptionsResizeMode.Exact
            
            manager.requestImageForAsset(imageAsset, targetSize: structuredData.resizedImageSize, contentMode: PHImageContentMode.AspectFit, options: options) { (image, infos) -> Void in
                
                if let asImage = image{
                    
                    self.resizedImage = asImage
                    cbk(image: asImage)
                    
                }
            }
        }
    }


    
    
    
//    private init() {
//        SessionData.structuredData = AppData()
//    }
    
    static func setFormat(format :FormatStruct){
        structuredData.projectFormat = format
        
        
    }
    
    static func setImageAsset(asset :PHAsset){
        structuredData.imageAsset = asset
    }
    
    static func updateData(data :AppData){
        structuredData = data
        
    }
}
